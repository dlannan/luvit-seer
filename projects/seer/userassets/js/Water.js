/**
 * @author jbouny / https://github.com/jbouny
 *
 * Work based on :
 * @author Slayvin / http://slayvin.net : Flat mirror for three.js
 * @author Stemkoski / http://www.adelphi.edu/~stemkoski : An implementation of water shader based on the flat mirror
 * @author Jonas Wagner / http://29a.ch/ && http://29a.ch/slides/2012/webglwater/ : Water shader explanations in WebGL
 */

THREE.Water = function ( geometry, options ) {

	THREE.Mesh.call( this, geometry );

	var scope = this;

	options = options || {};

	var textureWidth = options.textureWidth !== undefined ? options.textureWidth : 512;
	var textureHeight = options.textureHeight !== undefined ? options.textureHeight : 512;

	var clipBias = options.clipBias !== undefined ? options.clipBias : 0.0;
	var alpha = options.alpha !== undefined ? options.alpha : 1.0;
	var time = options.time !== undefined ? options.time : 0.0;
	var normalSampler = options.waterNormals !== undefined ? options.waterNormals : null;
	var heightSampler = options.heightMap !== undefined ? options.heightMap : null;
	var sunDirection = options.sunDirection !== undefined ? options.sunDirection : new THREE.Vector3( 0.70707, 0.70707, 0.0 );
	var sunColor = new THREE.Color( options.sunColor !== undefined ? options.sunColor : 0xffffff );
	var waterColor = new THREE.Color( options.waterColor !== undefined ? options.waterColor : 0x006994 );
	var eye = options.eye !== undefined ? options.eye : new THREE.Vector3( 0, 0, 0 );
	var distortionScale = options.distortionScale !== undefined ? options.distortionScale : 20.0;
	var side = options.side !== undefined ? options.side : THREE.FrontSide;
	var fog = options.fog !== undefined ? options.fog : false;


	//

	var mirrorPlane = new THREE.Plane();
	var normal = new THREE.Vector3();
	var mirrorWorldPosition = new THREE.Vector3();
	var cameraWorldPosition = new THREE.Vector3();
	var rotationMatrix = new THREE.Matrix4();
	var lookAtPosition = new THREE.Vector3( 0, 0, - 1 );
	var clipPlane = new THREE.Vector4();

	var view = new THREE.Vector3();
	var target = new THREE.Vector3();
	var q = new THREE.Vector4();

	var textureMatrix = new THREE.Matrix4();

	var mirrorCamera = new THREE.PerspectiveCamera();

	var parameters = {
		minFilter: THREE.LinearFilter,
		magFilter: THREE.LinearFilter,
		format: THREE.RGBFormat,
		stencilBuffer: false
	};

	var renderTarget = new THREE.WebGLRenderTarget( textureWidth, textureHeight, parameters );

	if ( ! THREE.Math.isPowerOfTwo( textureWidth ) || ! THREE.Math.isPowerOfTwo( textureHeight ) ) {

		renderTarget.texture.generateMipmaps = false;

	}

	var mirrorShader = {

		uniforms: THREE.UniformsUtils.merge( [
			THREE.UniformsLib[ 'fog' ],
			THREE.UniformsLib[ 'lights' ],
			{
				normalSampler: { value: null },
				mirrorSampler: { value: null },
				heightSampler: { value: null },
				alpha: { value: 1.0 },
				time: { value: 0.0 },
				size: { value: 1.0 },
				distortionScale: { value: 20.0 },
				textureMatrix: { value: new THREE.Matrix4() },
				sunColor: { value: new THREE.Color( 0x7F7F7F ) },
				sunDirection: { value: new THREE.Vector3( 0.70707, 0.70707, 0 ) },
				eye: { value: new THREE.Vector3() },
				waterColor: { value: new THREE.Color( 0x006994 ) },
				entity: { value: new THREE.Vector3() },
				entityCheck: { value: 0 },
				iresolution: { value: new THREE.Vector3() }
			}
		] ),

		vertexShader: [
			'uniform mat4 textureMatrix;',
			'uniform float time;',

			'varying vec4 mirrorCoord;',
			'varying vec4 worldPosition;',

			THREE.ShaderChunk[ 'fog_pars_vertex' ],
			THREE.ShaderChunk[ 'shadowmap_pars_vertex' ],

			'void main() {',
			'	mirrorCoord = modelMatrix * vec4( position, 1.0 );',
			'	mirrorCoord = textureMatrix * mirrorCoord;',
			'	vec4 mvPosition =  modelViewMatrix * vec4( position, 1.0 );',
			'	worldPosition = modelMatrix * vec4( position, 1.0 );',
			'	gl_Position = projectionMatrix * mvPosition;',

			THREE.ShaderChunk[ 'fog_vertex' ],
			THREE.ShaderChunk[ 'shadowmap_vertex' ],

			'}'
		].join( '\n' ),

		fragmentShader: [
			'const vec3 SEA_WATER_COLOR = vec3(0.8,0.9,0.6);',
			'const vec3 SEA_BASE = vec3(0.1, 0.19, 0.22);',
			'const float PI      = 3.141592;',
			'uniform sampler2D mirrorSampler;',
			'uniform float alpha;',
			'uniform float time;',
			'uniform float size;',
			'uniform float entityCheck;',
			'uniform float distortionScale;',
			'uniform sampler2D normalSampler;',
			'uniform sampler2D heightSampler;',
			'uniform vec3 sunColor;',
			'uniform vec3 sunDirection;',
			'uniform vec3 eye;',
			'uniform vec3 waterColor;',
			'uniform vec2 iresolution;',

			'uniform vec3 entity;',
			'uniform vec3 heights;',

			'varying vec4 mirrorCoord;',
			'varying vec4 worldPosition;',

			'// lighting',
			'float diffuse(vec3 n, vec3 l, float p)',
			'{',
				'return pow(dot(n, l) * 0.4 + 0.6, p);',
			'}',

			'float specular(vec3 n, vec3 l, vec3 e, float s)',
			'{',
				'float nrm = (s + 8.0) / (PI * 8.0);',
				'return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;',
			'}',			

			'// Get sky color by eye position.',
			'// So, The color changed smoothly by eye level.',
			'vec3 getSkyColor(vec3 e)',
			'{',
				'e.y = max(e.y, 0.0);',
				'float r = pow(1.0 - e.y, 2.0);',
				'float g = 1.0 - e.y;',
				'float b = 0.6 + (1.0 - e.y) * 0.4;',
				'return vec3(r, g, b);',
			'}',			

			'// p = ray position',
			'// n = surface normal',
			'// l = light',
			'// eye = eye',
			'// dist = ray marching distance',
			'// http://glslsandbox.com/e#61664.0',
			'vec3 getSeaColor(float seaHeight, vec3 n, vec3 l, vec3 eye, vec3 dist)',
			'{',
				'float fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);',
				'fresnel = pow(fresnel, 3.0) * 0.65;',

				'vec3 reflected = getSkyColor(reflect(eye, n));    ',
				//'vec3 reflected = sunColor;    ',
				'vec3 refracted = SEA_BASE + diffuse(n, l, 80.0) * SEA_WATER_COLOR * 0.12; ',

				'vec3 color = mix(refracted, reflected, fresnel);',

				'float atten = max(1.0 - dot(dist, dist) * 0.001, 0.0);',
				'color += SEA_WATER_COLOR * seaHeight * 0.18 * atten;',

				'color += vec3(specular(n, l, eye,60.0));',

				'return color;',
			'}',


			'vec4 getNoise( vec2 uv ) {',
			'	vec2 uv0 = ( uv / 103.0 ) + vec2(time / 17.0, time / 29.0);',
			'	vec2 uv1 = uv / 107.0-vec2( time / -19.0, time / 31.0 );',
			'	vec2 uv2 = uv / vec2( 8907.0, 9803.0 ) + vec2( time / 101.0, time / 97.0 );',
			'	vec2 uv3 = uv / vec2( 1091.0, 1027.0 ) - vec2( time / 109.0, time / -113.0 );',
			'	vec4 noise = texture2D( normalSampler, uv0 ) +',
			'		texture2D( normalSampler, uv1 ) +',
			'		texture2D( normalSampler, uv2 ) +',
			'		texture2D( normalSampler, uv3 );',
			'	return noise * 0.5 - 1.0;',
			'}',

			THREE.ShaderChunk[ 'common' ],
			THREE.ShaderChunk[ 'packing' ],
			THREE.ShaderChunk[ 'bsdfs' ],
			THREE.ShaderChunk[ 'fog_pars_fragment' ],
			THREE.ShaderChunk[ 'lights_pars_begin' ],
			THREE.ShaderChunk[ 'shadowmap_pars_fragment' ],
			THREE.ShaderChunk[ 'shadowmask_pars_fragment' ],

			'void main() {',
			'	vec4 noise = getNoise( worldPosition.xz * size );',
			'	vec3 surfaceNormal = normalize( noise.xzy * vec3(1.5, 1.0, 1.5) );',

			'	vec3 diffuseLight = vec3(0.0);',
			'	vec3 specularLight = vec3(0.0);',

			'	vec3 worldToEye = cameraPosition-worldPosition.xyz;',
			'	vec3 eyeDirection = normalize( worldToEye );',

			'	float distance = length(worldToEye);',
			'	vec2 coo = worldPosition.xz * vec2(0.005, -0.0025) + 0.5;',
			'	float height = texture2D( heightSampler, coo ).r ;',

			'	vec2 distortion = surfaceNormal.xz * ( 0.001 + 1.0 / distance ) * distortionScale;',
			'	vec3 reflectionSample = vec3( texture2D( mirrorSampler, mirrorCoord.xy / mirrorCoord.w + distortion ) );',

			'	float theta = max( dot( eyeDirection, surfaceNormal ), 0.0 );',
			'	float rf0 = 0.3;',
			'	float reflectance = rf0 + (1.0 - rf0 ) * pow( ( 1.0 - theta ), 20.0 );',

			'	// color',
			' 	vec3 dist = (worldPosition.xyz - cameraPosition) * 0.1;',
			'	vec3 sky = getSkyColor(eyeDirection);',
			'	vec3 seaColor = getSeaColor(noise.y, surfaceNormal,  sunDirection.xyz, -eyeDirection.xyz, dist);',

			'	// This is coefficient for smooth blending sky and sea with ',
			'	float t = pow(smoothstep(0.0, -0.05, -eyeDirection.y), 0.3);',
			'	seaColor *= clamp(getShadowMask() + 0.3, 0.0, 1.0);',

			'	vec3 input1 = mix(sky, seaColor, t);',
			'	vec3 input2 = ( vec3(0.1) + reflectionSample * 0.3 );',
			'	vec3 albedo = mix( input1, input2, reflectance);',
			'	height = (1.0 - height) * 0.1 + 0.9;',
			'	gl_FragColor = vec4( albedo, alpha * height * distance );',
			'	if(cameraPosition.y < 0.1){',
			'		vec3 underSeaColor = getSeaColor(noise.y, -surfaceNormal,  sunDirection.xyz, -eyeDirection.xyz, dist);',			
			'		float fog = 1.0 - smoothstep(.015, .1, distance/ 200.0);',
			'		gl_FragColor = vec4( mix( SEA_BASE, underSeaColor, fog), 1.0-fog);',
			'	}',
			// ' 	if (entityCheck > 0.0) {',
			// ' 		vec2 p1 = vec2( entity.x, entity.z );',
			// ' 		if(length(worldPosition.xz - p1) < entityCheck) {',
			// '			gl_FragColor = vec4( noise.y * 0.5 + 0.5, 0.0, 0.0, alpha);',
			// '   	}',
			// '	}',

			THREE.ShaderChunk[ 'tonemapping_fragment' ],
			THREE.ShaderChunk[ 'fog_fragment' ],

			'}'
		].join( '\n' )

	};

	var material = new THREE.ShaderMaterial( {
		fragmentShader: mirrorShader.fragmentShader,
		vertexShader: mirrorShader.vertexShader,
		uniforms: THREE.UniformsUtils.clone( mirrorShader.uniforms ),
		transparent: true,
		lights: true,
		side: THREE.DoubleSide,
		shadowSide: THREE.BackSide,
		fog: fog
	} );

	material.uniforms.mirrorSampler.value = renderTarget.texture;
	material.uniforms.textureMatrix.value = textureMatrix;
	material.uniforms.alpha.value = alpha;
	material.uniforms.time.value = time;
	material.uniforms.normalSampler.value = normalSampler;
	material.uniforms.heightSampler.value = heightSampler;
	material.uniforms.sunColor.value = sunColor;
	material.uniforms.waterColor.value = waterColor;
	material.uniforms.sunDirection.value = sunDirection;
	material.uniforms.distortionScale.value = distortionScale;
	material.uniforms.iresolution.value = new THREE.Vector2(textureWidth, textureHeight);

	scope.material = material;

	scope.onBeforeRender = function ( renderer, scene, camera ) {

		mirrorWorldPosition.setFromMatrixPosition( scope.matrixWorld );
		cameraWorldPosition.setFromMatrixPosition( camera.matrixWorld );

		rotationMatrix.extractRotation( scope.matrixWorld );

		normal.set( 0, 0, 1 );
		normal.applyMatrix4( rotationMatrix );

		view.subVectors( mirrorWorldPosition, cameraWorldPosition );

		// Avoid rendering when mirror is facing away

		if ( view.dot( normal ) > 0 ) return;

		view.reflect( normal ).negate();
		view.add( mirrorWorldPosition );

		rotationMatrix.extractRotation( camera.matrixWorld );

		lookAtPosition.set( 0, 0, - 1 );
		lookAtPosition.applyMatrix4( rotationMatrix );
		lookAtPosition.add( cameraWorldPosition );

		target.subVectors( mirrorWorldPosition, lookAtPosition );
		target.reflect( normal ).negate();
		target.add( mirrorWorldPosition );

		mirrorCamera.position.copy( view );
		mirrorCamera.up.set( 0, 1, 0 );
		mirrorCamera.up.applyMatrix4( rotationMatrix );
		mirrorCamera.up.reflect( normal );
		mirrorCamera.lookAt( target );

		mirrorCamera.far = camera.far; // Used in WebGLBackground

		mirrorCamera.updateMatrixWorld();
		mirrorCamera.projectionMatrix.copy( camera.projectionMatrix );

		// Update the texture matrix
		textureMatrix.set(
			0.5, 0.0, 0.0, 0.5,
			0.0, 0.5, 0.0, 0.5,
			0.0, 0.0, 0.5, 0.5,
			0.0, 0.0, 0.0, 1.0
		);
		textureMatrix.multiply( mirrorCamera.projectionMatrix );
		textureMatrix.multiply( mirrorCamera.matrixWorldInverse );

		// Now update projection matrix with new clip plane, implementing code from: http://www.terathon.com/code/oblique.html
		// Paper explaining this technique: http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
		mirrorPlane.setFromNormalAndCoplanarPoint( normal, mirrorWorldPosition );
		mirrorPlane.applyMatrix4( mirrorCamera.matrixWorldInverse );

		clipPlane.set( mirrorPlane.normal.x, mirrorPlane.normal.y, mirrorPlane.normal.z, mirrorPlane.constant );

		var projectionMatrix = mirrorCamera.projectionMatrix;

		q.x = ( Math.sign( clipPlane.x ) + projectionMatrix.elements[ 8 ] ) / projectionMatrix.elements[ 0 ];
		q.y = ( Math.sign( clipPlane.y ) + projectionMatrix.elements[ 9 ] ) / projectionMatrix.elements[ 5 ];
		q.z = - 1.0;
		q.w = ( 1.0 + projectionMatrix.elements[ 10 ] ) / projectionMatrix.elements[ 14 ];

		// Calculate the scaled plane vector
		clipPlane.multiplyScalar( 2.0 / clipPlane.dot( q ) );

		// Replacing the third row of the projection matrix
		projectionMatrix.elements[ 2 ] = clipPlane.x;
		projectionMatrix.elements[ 6 ] = clipPlane.y;
		projectionMatrix.elements[ 10 ] = clipPlane.z + 1.0 - clipBias;
		projectionMatrix.elements[ 14 ] = clipPlane.w;

		eye.setFromMatrixPosition( camera.matrixWorld );
		var currentRenderTarget = renderer.getRenderTarget();

		var currentVrEnabled = renderer.vr.enabled;
		var currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

		scope.visible = false;

		renderer.vr.enabled = false; // Avoid camera modification and recursion
		renderer.shadowMap.autoUpdate = false; // Avoid re-computing shadows

		renderer.setRenderTarget( renderTarget );
		renderer.clear();
		renderer.render( scene, mirrorCamera );

		scope.visible = true;

		renderer.vr.enabled = currentVrEnabled;
		renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;

		renderer.setRenderTarget( currentRenderTarget );

	};

};

THREE.Water.prototype = Object.create( THREE.Mesh.prototype );
THREE.Water.prototype.constructor = THREE.Water;
