/**
 * @author dlannan
 * Lidar implementation based around a simple depth buffer and some lidar meta information
 *    Parameters are width and height of a single camera resolution. All camera views are 90 degrees FOV (horizontal). If
 *    resolution is non-square, then height FOV is modified to match the resolution. 
 * 
 *      This initial implementation will be expanded with Lidar features: 
 *          16 line, 64 line, 256 line.
 *          update rate (20 ksamples/sec etc)
 *          noise injection (various types)
 */

THREE.TimeBearingSALDO = function ( width, height, _params ) {

    THREE.Pass.call( this );

    // Lidar RayCasting type rendering
    //    -- if this frag is a point needing a ray cast (is a valid scanline?)
    //    -- we cast from viewer pos, outwards to "depth". 
    //    -- return the depth "hit" or nothing.
    this.depthDisplay  = {
        uniforms: {
            //"tDiffuse": { value: null },
            "tDepth": { value: null },
            "tColorMap": { value: null },
            "cameraNear":   { value: 0.3 },
            "cameraFar":   { value: 100.0 },
            "timeLast": { value: 0.0 },
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
            //"uniform sampler2D tDiffuse;",
            "uniform sampler2D tColorMap;",
			"uniform sampler2D tDepth;",
			"uniform float cameraNear;",
			"uniform float cameraFar;",

            "uniform float timeLast;",

            "float readDepth( sampler2D depthSampler, vec2 coord ) {",
            "    float fragCoordZ = texture2D( depthSampler, coord ).x;",
            "    float viewZ = perspectiveDepthToViewZ( fragCoordZ, cameraNear, cameraFar );",
            "    return viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );",
			"}",
            "void main() {",
                "vec2 uv = vec2( vUv.x, vUv.y );",
                "float depth = readDepth( tDepth, uv);",
                // Clip out near field objects like the sub itself.
                "if(depth > 0.002) {",
                "gl_FragColor.rgb = texture2D( tColorMap, vec2(depth, 0.0) ).rgb;",
                "}",
			"}"
        ].join("\n")
    };   

    //var warpIdx = this.depthDisplay.fragmentShader.indexOf("<<<< INSERT WARPING >>>>");
    //console.log("Got Idx:", warpIdx);
    //Array.prototype.splice.apply(this.depthDisplay.fragmentShader, [warpIdx, 1].concat(this.warping));
    //this.depthDisplay.fragmentShader;

    this.cameracount = 4;
    this.params = JSON.parse( JSON.stringify(_params) );

    var vfov = Math.atan( (this.params.vertAzimuth/2.0) / ( (45/2.0) / Math.tan(Math.radians(45.0)) ) );
    this.params.vfov = Math.degrees( 2.0 * vfov );

    // Also need rendertarget for depth map (will be 4x camera wide)
    this.lidarWidth = width / this.cameracount;
    this.lidarHeight = height;

    this.tbCamera = new THREE.PerspectiveCamera( 90.0, width / height, this.params.cameraNear, this.params.cameraFar );

 	this.postCamera = new THREE.OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );
    this.postMaterial = new THREE.ShaderMaterial( this.depthDisplay );
    this.postScene = new THREE.Scene();

    this.rtargetWidth = width;
    this.rtargetHeight = height;

    var parameters = { 
        minFilter: THREE.LinearFilter, 
        magFilter: THREE.LinearFilter, 
        format: THREE.RGBFormat,
        stencilBuffer: false,
        generateMipmaps: false
    };    

    this.renderTarget = new THREE.WebGLRenderTarget( this.rtargetWidth, this.rtargetHeight, parameters );
    this.renderTarget.depthBuffer = true;
    this.renderTarget.depthTexture = new THREE.DepthTexture();
    this.renderTarget.depthTexture.type = THREE.UnsignedShortType;
    this.renderTarget.autoClearColor = false;
    this.renderTarget.autoClearDepth = false;

    var postPlane = new THREE.PlaneBufferGeometry( 2, 2 );
    this.quad = new THREE.Mesh( postPlane, this.postMaterial );
//    this.quad.scale.set( 1, 0.01, 1 );
    
 	this.quad.frustumCulled = false;
    this.postScene.add( this.quad );
};

THREE.TimeBearingSALDO.prototype = Object.assign( Object.create( THREE.Pass.prototype ), {
	constructor: THREE.TimeBearingSALDO,

	render: function ( renderer, writeBuffer, readBuffer, delta, maskActive ) {

        var top = 0;
        var camwidth = this.rtargetWidth / this.cameracount;
        var cam = 0;
        var rot = Math.PI / 2;

        this.tbCamera.position.set( camera.position.x, camera.position.y, camera.position.z );
        this.renderTarget.scissorTest = true;
        this.tbCamera.rotation.set( camera.rotation.x, camera.rotation.y, camera.rotation.z );

        var oceanvis = ocean.visible;
        var gridvis = gridhelper.visible;

        ocean.visible = false;
        gridhelper.visible = false; 

        this.tbCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tbCamera );
        cam = camwidth;

        this.tbCamera.rotateY( rot );
        this.tbCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tbCamera );
        cam = camwidth * 2;

        this.tbCamera.rotateY( rot );
        this.tbCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tbCamera );
        cam = camwidth * 3;

        this.tbCamera.rotateY( rot );
        this.tbCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tbCamera );

        this.renderTarget.scissorTest = false;
        
        ocean.visible = oceanvis;
        gridhelper.visible = gridvis;

        // This is like the spinning rpm clock for the device.This time delta gives a "how much it has spun"
        //   with the last frame period (based on design specs)
        this.params.lastTime += simstate.deltat;
        this.postMaterial.uniforms['tColorMap'].value = this.params.colorMap;
        
        // Enable this to view normal color pixel view
        //this.postMaterial.uniforms['tDiffuse'].value = this.renderTarget.texture;
        this.postMaterial.uniforms['tDepth'].value = this.renderTarget.depthTexture;
        this.postMaterial.uniforms['cameraNear'].value = this.params.cameraNear;
        this.postMaterial.uniforms['cameraFar'].value = this.params.cameraFar;
        this.postMaterial.uniforms['timeLast'].value = this.params.lastTime;

 		if ( this.renderToScreen == false ) {
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
            renderer.render( this.postScene, this.postCamera );
		} else {
            renderer.setRenderTarget(null);
        }
        renderer.render( this.postScene, this.postCamera );
    },

 	setSize: function ( width, height ) {
 	}
});

