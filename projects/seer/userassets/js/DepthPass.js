/**
 * @author dlannan
 * Depth implementation based around various depth implementations and SAO
 */

THREE.DepthPassSALDO = function ( depthTexture ) {

	THREE.Pass.call( this );

    //custom shader pass
    this.depthEffect  = {
        uniforms: {
            "tDiffuse": { value: null },
            "tDepth": { value: null },
            "cameraNear":   { value: 0.3 },
            "cameraFar":   { value: 500.0 }
        },
        vertexShader: [
            "varying vec2 vUv;",
			"void main() {",
            "vUv = uv;",
            "gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);",
			"}"
        ].join( "\n" ),
        fragmentShader: [
            "#include <packing>",
			"varying vec2 vUv;",
			"uniform sampler2D tDiffuse;",
			"uniform sampler2D tDepth;",
			"uniform float cameraNear;",
			"uniform float cameraFar;",
			"float readDepth( sampler2D depthSampler, vec2 coord ) {",
            "    float fragCoordZ = texture2D( depthSampler, coord ).x;",
            "    float viewZ = perspectiveDepthToViewZ( fragCoordZ, cameraNear, cameraFar );",
            "    return viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );",
			"}",
			"void main() {",
				"vec3 diffuse = texture2D( tDiffuse, vUv ).rgb;",
				"float depth = readDepth( tDepth, vUv );",
				"gl_FragColor.rgb = 1.0 - vec3( depth * 32.0 );",
				"gl_FragColor.a = 1.0;",
			"}"
        ].join( "\n" )
    };

    this.depthTexture = depthTexture;
    //console.log(depthTexture);
   
 	this.camera = new THREE.OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );
    this.material = new THREE.ShaderMaterial( this.depthEffect );

    this.scene = new THREE.Scene();

    var postPlane = new THREE.PlaneBufferGeometry( 2, 2 );
    var quad = new THREE.Mesh( postPlane, this.material );
 	quad.frustumCulled = false;
 	this.scene.add( quad );
};

THREE.DepthPassSALDO.prototype = Object.assign( Object.create( THREE.Pass.prototype ), {
	constructor: THREE.DepthPassSALDO,

	render: function ( renderer, writeBuffer, readBuffer, delta, maskActive ) {

        this.material.uniforms['tDiffuse'].value = readBuffer.texture;
        this.material.uniforms['tDepth'].value = this.depthTexture;
        this.material.uniforms['cameraNear'].value = camera.near;
        this.material.uniforms['cameraFar'].value = camera.far;

 		if ( this.renderToScreen == false ) {
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
		} else {
            renderer.setRenderTarget(null);
        }
        renderer.render( this.scene, this.camera );
     },
     
 	setSize: function ( width, height ) {

 	}
});

