

THREE.MoonSky = function () {

    var w = camera.width;
    var h = camera.offsetHeight;
	
	var shader = makeMoonSky(w, h);

	var material = new THREE.ShaderMaterial( {
		fragmentShader: shader.fragmentShader,
		vertexShader: shader.vertexShader,
		uniforms: THREE.UniformsUtils.clone( shader.uniforms ),
		side: THREE.BackSide
	} );

	THREE.Mesh.call( this, new THREE.SphereBufferGeometry( 1, 32, 15 ),
							material );

};

THREE.MoonSky.prototype = Object.create( THREE.Mesh.prototype );


function makeMoonSky( w, h) {

	moonSky = {

	uniforms: {
		sunPosition: { value: new THREE.Vector3() },
		coverage: { value: 0.5 },
		time: { value: 0.0 },
        iResolution: { type: 'v2', value: new THREE.Vector2( w,h ) },
	},

	vertexShader: [
	'varying vec3 vWorldPosition;',

	'void main() {',

	'	vec4 worldPosition = modelMatrix * vec4( position, 1.0 );',
	'	vWorldPosition = worldPosition.xyz;',

	'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
	'}'
	].join( '\n' ),

	fragmentShader: [

// #### realistic display of star in Hubble images ################
//                            Fabrice NEYRET 15 oct 2013

// see also https://www.shadertoy.com/view/Xty3zc
//          https://www.shadertoy.com/view/tlc3zM

'uniform float time;',
'uniform float coverage;',
'varying vec3 vSunDirection;',
'varying vec3 vWorldPosition;',
'uniform vec2 iResolution;',

'const float PI = 3.1415927;',
'vec2 FragCoord, R;',

'float hash( vec2 p ) {',
'  float h = dot(p,vec2(127.1,311.7));	',
'  return fract(sin(h)*43758.5453123);',
'}',


'float noise( in vec2 p ) {',
'  vec2 i = floor(p);',
'  vec2 f = fract(p);	',
'  vec2 u = f * f * (3.0 - 2.0 * f);',
'  return -1.0 + 2.0 * mix(',
'      mix(',
'        hash(i + vec2(0.0,0.0)',
'    ), ',
'      hash(i + vec2(1.0,0.0)), u.x),',
'      mix(hash(i + vec2(0.0,1.0) ), ',
'      hash(i + vec2(1.0,1.0) ), u.x), ',
'    u.y',
'  );',
'}',

'const vec3 cameraPos = vec3( 0.0, 0.0, 0.0 );',
'const float PHI = 1.61803398874989484820459;', // Φ = Golden Ratio 

'float gold_noise(in vec2 xy, in float seed)',
'{',
'    return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);',
'}',

// --- main -----------------------------------------
'void main( ) {',
'	vec3 col;',
'  	FragCoord = gl_FragCoord.xy;',
'   R = iResolution.xy;',
'    float t = time*.1;',
'   ',
'	',
// --- camera

'	vec3 direction = normalize( vWorldPosition - cameraPos );',
'	float theta = acos( direction.y ); ',
'	float phi = atan( direction.z, direction.x ); ',
'	float c=cos(phi),s=sin(phi);',
'	mat2 im=mat2(c,s, -s,c);',
'	',
	// --- display stars 
		// background
'		vec2 uv = im * (gl_FragCoord.xy) + cameraPos.xy;',
'		float bg = gold_noise(uv, 1.0) * 50.0;',
'		col += .5*exp(-7.*bg);',
'',
'	gl_FragColor = vec4(col,1.0);',
'}',

].join( '\n' )
};

return moonSky;

};
