
/**
 * @author dlannan / https://github.com/dlannan
 *
 * Work based on :
 * @author David Pratie / https://davideprati.com/demo/grass/ : BufferGeometry Grass
 */

function createPlanesGeometryGrass(n_planes){
    var containerGeometry = new THREE.Geometry();
    var planeGeometry = new THREE.PlaneGeometry(10, 0.2, 14, 1);
    for (var i = 0; i < planeGeometry.vertices.length; i++) {
        planeGeometry.vertices[i].z = Math.sin(planeGeometry.vertices[i].x * 40.0);
    };
    planeGeometry.applyMatrix( new THREE.Matrix4().setPosition( new THREE.Vector3( 0, 0.15, 0 ) ) );
    var x = 0;
    var z = 0;
    var rot = (Math.PI*2)/3;

    var mesh = new THREE.Mesh(planeGeometry);

    for (var i = 0; i < n_planes; i++) {
        mesh.rotation.y = (i%3 * rot) + Math.random() - 0.5;
        mesh.position.set(x * 1.25 - 2.25 , 0, z * 2.0 - 1.25 );
        mesh.position.x += Math.random() * 1 - 0.5;
        mesh.position.z += Math.random() * 1 - 0.5;
        mesh.scale.y = 1.1-Math.random()*0.4;

        if (i%3 == 2) {
            ++x;
        }
        if (x == 11) {
            x = 0;
            ++z;
        }
        mesh.updateMatrix();
        containerGeometry.merge(mesh.geometry, mesh.matrix);
    };
    // I've used a BufferGeometry only here, and not previously, because buffered geometries
    // do not work with the merge method
    var bufferedGeometry = new THREE.BufferGeometry().fromGeometry(containerGeometry);
    return bufferedGeometry;
}


THREE.Grass = function ( options ) {

    var material = makeGrass( options );

    //GRASS
    var geometry = createPlanesGeometryGrass(50);
    var mesh = new THREE.Mesh( geometry, material );
    mesh.position.set(0, 0, 0);
    mesh.matrixAutoUpdate = false;
    mesh.receiveShadow = true;    
    mesh.castShadow = false;    

    // mesh.rotation.set(Math.PI/2, 0.0, 0.0);
    return mesh;
};

THREE.Grass.prototype = Object.create( THREE.Mesh.prototype );

function makeGrass( options ) {

	options = options || {};

	var textureWidth = options.textureWidth !== undefined ? options.textureWidth : 512;
	var textureHeight = options.textureHeight !== undefined ? options.textureHeight : 512;

	var clipBias = options.clipBias !== undefined ? options.clipBias : 0.0;
	var alpha = options.alpha !== undefined ? options.alpha : 1.0;
	var time = options.time !== undefined ? options.time : 0.0;
	var noiseSampler = options.noiseSampler !== undefined ? options.noiseSampler : null;
	var maskSampler = options.grassMask !== undefined ? options.grassMask : null;
	var texture = options.grassTexture !== undefined ? options.grassTexture : null;
	var lightColor = new THREE.Color( options.sunColor !== undefined ? options.sunColor : 0xffffff );
	var lightPos = new THREE.Vector3();
	var fog = options.fog !== undefined ? options.fog : false;

	var grassShader = {

		uniforms: THREE.UniformsUtils.merge( [
			THREE.UniformsLib[ 'fog' ],
			THREE.UniformsLib[ 'lights' ],
			{
				noiseSampler: { value: noiseSampler },
				maskSampler: { value: maskSampler },
                texture:    { value: texture },

                alpha: { value: 1.0 },
				time: { value: 0.0 },
				size: { value: 1.0 },
				entity: { value: new THREE.Vector3() },
                entityCheck: { value: 0 },
                clipDistance: { value: 30.0 },

                lightPos:   { value: new THREE.Vector3() },
                lightColor: { value: new THREE.Color('#872b17') },
                magnitude:  { value: 0.03 },
                lightPower: { value: 0.2 },
                ambientLightPower: { value: 0.15 },
                uvScale:    { value: new THREE.Vector2( 50.0, 1.0 ) }        
            }
		] ),

		vertexShader: [
            'precision mediump float;',
            'uniform float time;',
            'uniform float magnitude;',
            'uniform vec2 uvScale;',
            'uniform vec3 lightPos;',
            'varying vec2 vUv;',
            'varying vec3 vNormal;',
            'varying vec4 vLightPos;',
            'varying vec4 vecPos;',
            'varying vec4 worldPosition;',
            'varying vec3 camPos;',
            '',
            'float random (in vec2 st) {',
                'return fract(sin(dot(st.xy,',
                                    'vec2(12.9898,78.233)))',
                    '* 43758.5453123);',
            '}',
            '',
            '',
            // 'Simplex 2D noise',
            //'',
            'vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }',

            'float snoise(vec2 v){',
            'const vec4 C = vec4(0.211324865405187, 0.366025403784439,',
                    '-0.577350269189626, 0.024390243902439);',
            'vec2 i  = floor(v + dot(v, C.yy) );',
            'vec2 x0 = v -   i + dot(i, C.xx);',
            'vec2 i1;',
            'i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);',
            'vec4 x12 = x0.xyxy + C.xxzz;',
            'x12.xy -= i1;',
            'i = mod(i, 289.0);',
            'vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))',
            '+ i.x + vec3(0.0, i1.x, 1.0 ));',
            'vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),',
                'dot(x12.zw,x12.zw)), 0.0);',
            'm = m*m ;',
            'm = m*m ;',
            'vec3 x = 2.0 * fract(p * C.www) - 1.0;',
            'vec3 h = abs(x) - 0.5;',
            'vec3 ox = floor(x + 0.5);',
            'vec3 a0 = x - ox;',
            'm *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );',
            'vec3 g;',
            'g.x  = a0.x  * x0.x  + h.x  * x0.y;',
            'g.yz = a0.yz * x12.xz + h.yz * x12.yw;',
            'return 130.0 * dot(m, g);',
            '}',
            '',
			THREE.ShaderChunk[ 'fog_pars_vertex' ],
			THREE.ShaderChunk[ 'shadowmap_pars_vertex' ],
            
			'void main() {',
                'vNormal =  (modelMatrix * vec4(normal, 0.0)).xyz;',
                'vec3 pos = position;',
                '// animate only the pixels that are upon the ground',
                'if (pos.y > 0.2) {',
                    'float noised = snoise(pos.xy);',
                    // 'pos.y += sin(time * magnitude * noised);',
                    'pos.z += sin(time * noised) * magnitude;',
                    'if (pos.y > 0.275){',
                        'pos.x += sin(time * 1.2 * noised) * magnitude;',
                    '}',
                '}',
                'vUv = uvScale * uv;',
                'vec4 mvPosition = modelViewMatrix * vec4( pos, 1.0 );',
                'worldPosition = modelMatrix * vec4( position, 1.0 );',

                'vLightPos = projectionMatrix * modelViewMatrix * vec4(lightPos, 1.0);',
                'vecPos = projectionMatrix * mvPosition;',
                'camPos = cameraPosition;',
                'gl_Position = vecPos;',

                THREE.ShaderChunk[ 'fog_vertex' ],
                THREE.ShaderChunk[ 'shadowmap_vertex' ],
            '}',

		].join( '\n' ),

		fragmentShader: [
        'uniform vec3 lightColor;',
        'uniform float lightPower;',
        'uniform float ambientLightPower;',

        'uniform sampler2D texture;',
        'uniform sampler2D maskSampler;',
        'uniform sampler2D noiseSampler;',

        'uniform float clipDistance;',
        'varying vec3 vNormal;',
        'varying vec2 vUv;',
        'varying vec4 vLightPos;',
        'varying vec4 vecPos;',
        'varying vec3 camPos;',
        'varying vec4 worldPosition;',        
        '',
        THREE.ShaderChunk[ 'common' ],
        THREE.ShaderChunk[ 'packing' ],
        THREE.ShaderChunk[ 'bsdfs' ],
        THREE.ShaderChunk[ 'fog_pars_fragment' ],
        THREE.ShaderChunk[ 'lights_pars_begin' ],
        THREE.ShaderChunk[ 'shadowmap_pars_fragment' ],
        THREE.ShaderChunk[ 'shadowmask_pars_fragment' ],

        'const float threshold = 0.5;',
        'void main() {',

            'vec4 textureColor = texture2D(texture, vec2(vUv.s, clamp(vUv.t, 0.02, 0.98)));',
            'if (textureColor[3] < threshold ) {',
                'discard;',
            '} else {',
                '// Calculate the twiceLuminance of the texture color',
                'float twiceLuminance =  dot(textureColor, vec4(0.2126, 0.7152, 0.0722, 0)) * 2.0 ;',

                'float dist = length(vLightPos - vecPos) * 0.0015;',
                'vec4 llightColor = vec4(lightColor, 1.0);',
                'vec3 lightDirection = normalize(vecPos.xyz - vLightPos.xyz);',
                'float cosTheta = clamp( dot( vNormal,lightDirection ),0.0, 1.0);',
                // 'vec4 materialAmbientColor = vec4(vec3(ambientLightPower), 1.0) * textureColor;',
                // 'float attenuation = 1.0 / (1.0 + 0.2 * pow(length(vLightPos - vecPos), 2.0));',
                
                'vec4 groundColor = texture2D(maskSampler, worldPosition.xz / 10.0);',

                // The actual Overlay/High Light method is based on the shader
                'vec4 combinedColor;',
                'if (twiceLuminance < 1.0) {',
                '    combinedColor = mix(vec4(0, 0, 0, 0), groundColor, twiceLuminance);',
                '} else {',
                '    combinedColor = mix(groundColor, vec4(1, 1, 1, 1), twiceLuminance - 1.0);',
                '}',

                'float vdist = clamp((clipDistance - length(camPos - worldPosition.xyz)) / clipDistance, 0.0, 1.0);',
                'gl_FragColor = combinedColor * llightColor * (1.0 - 0.3 * (1.0 - getShadowMask()));',
                'gl_FragColor.a = vdist;',            
            '}',

            THREE.ShaderChunk[ 'tonemapping_fragment' ],
            THREE.ShaderChunk[ 'fog_fragment' ],    
        '}',
    ].join( '\n' )

    };

	var material = new THREE.ShaderMaterial( {
		fragmentShader: grassShader.fragmentShader,
		vertexShader: grassShader.vertexShader,
		uniforms: THREE.UniformsUtils.clone( grassShader.uniforms ),
		transparent: true,
		lights: true,
		fog: fog
    } );
    
	material.uniforms.alpha.value = alpha;
	material.uniforms.time.value = time;
	material.uniforms.noiseSampler.value = noiseSampler;
	material.uniforms.maskSampler.value = maskSampler;
	material.uniforms.texture.value = texture;
    material.uniforms.lightColor.value = lightColor;
    material.uniforms.lightPos.value = lightPos;
    
    return material;
};
