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

THREE.LidarPassSALDO = function ( width, height, _params, cameracount ) {

    THREE.Pass.call( this );

    var warpvalue = 0.125;
    if(_params.warping) {
        warpvalue = _params.warping;
    }

    this.warped = [
        "    float cam = floor(vUv.x * 4.0);",
        "    float camoff = cam * 0.25;",
        "    vec2 uv = vec2( (vUv.x - camoff) * 4.0, ypos) * 2.0 - 1.0;",

        "    // Calculate l2 norm",
        "    float r = uv.x*uv.x + uv.y*uv.y;",
  
        "    // Calculate the deflated or inflated new coordinate (reverse transform)",
        "    float x3 = uv.x / (1.0 - " + warpvalue + " * r);",
        "    float y3 = uv.y / (1.0 - " + warpvalue + " * r);",
        "    float x2 = uv.x / (1.0 - " + warpvalue + " * (x3 * x3 + y3 * y3));",
        "    float y2 = uv.y / (1.0 - " + warpvalue + " * (x3 * x3 + y3 * y3));",

        "    // De-normalize to the original range",
        "    float i2 = (x2 + 1.0) * 0.5;",
        "    float j2 = (y2 + 1.0) * 0.5;",

        "    uv = vec2(i2 * 0.25 + camoff, j2);",
    ].join("\n");

    this.unwarped = "    vec2 uv = vec2( vUv.x, ypos);";

    this.warping = this.unwarped;
    if(_params.warping) {
        this.warping = this.warped;
    }

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
            "startAzimuth":   { value: -15.0 },
            "vertAzimuth":   { value: 30.0 },
            "stepAzimuth":   { value: 2.0 },
            "startRes": { value: 0.0 },
            "stepRes": { value: 0.4 },
            "startResH": { value: 0.0 },
            "endResH": { value: 0.333 },
            "timeLast": { value: 0.0 },
            "vfov": { value: 0.0 }
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
            "float rand(vec2 co){",
            "   highp float a = 12.9898;",
            "   highp float b = 78.233;",
            "   highp float c = 43758.5453;",
            "   highp float dt= dot(co.xy ,vec2(a,b));",
            "   highp float sn= mod(dt,3.14);",
            "   return fract(sin(sn) * c);",
            "}",
            "varying vec2 vUv;",
            //"uniform sampler2D tDiffuse;",
            "uniform sampler2D tColorMap;",
			"uniform sampler2D tDepth;",
			"uniform float cameraNear;",
			"uniform float cameraFar;",

            "uniform float startAzimuth;",
            "uniform float vertAzimuth;",
            "uniform float stepAzimuth;",

            "uniform float stepRes;",
            "uniform float startResH;",
            "uniform float endResH;",

            "uniform float vfov;",
            "uniform float timeLast;",

            "float readDepth( sampler2D depthSampler, vec2 coord ) {",
            "    float fragCoordZ = texture2D( depthSampler, coord ).x;",
            "    float viewZ = perspectiveDepthToViewZ( fragCoordZ, cameraNear, cameraFar );",
            "    return viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );",
			"}",
            "void main() {",
                // 0.2 horizontal degrees of 'jitter' or noise
                "float vscale = vertAzimuth / vfov;",
                "float vsteps = floor(vertAzimuth / stepAzimuth) + 1.0;", 
                "float currvstep = floor(vUv.y * vsteps) / vsteps;", 
                "float jitter = rand(vec2(timeLast + vUv.x, currvstep)) * stepRes * 0.75;",
                "float pixelSkip = mod(vUv.x * 90.0, stepRes);",
                "float htest = 0.1;",
                "if ((pixelSkip >= 0.0) && (pixelSkip <= htest)) {", 
                "float ypos = startAzimuth / vfov + (currvstep * vscale);",
                this.warping,
                "float depth = readDepth( tDepth, uv);",
                "gl_FragColor.rgb = texture2D( tColorMap, vec2(depth, 0.0) ).rgb;",
                "}",
			"}"
        ].join("\n")
    };   

    //var warpIdx = this.depthDisplay.fragmentShader.indexOf("<<<< INSERT WARPING >>>>");
    //console.log("Got Idx:", warpIdx);
    //Array.prototype.splice.apply(this.depthDisplay.fragmentShader, [warpIdx, 1].concat(this.warping));
    //this.depthDisplay.fragmentShader;

    this.params = JSON.parse( JSON.stringify(_params) );

    // TODO: Fix this - aspect calc is wrong
    // var vfov = Math.atan( (this.params.vertAzimuth/2.0) / ( (45/2.0) / Math.tan(Math.radians(45.0)) ) );
    // this.params.vfov = Math.degrees( 2.0 * vfov );
    var aspect = 90.0 / this.params.vertAzimuth;
    this.params.vfov = this.params.vertAzimuth;

    // Also need rendertarget for depth map (will be 4x camera wide)
    this.lidarWidth = width;
    this.lidarHeight = ((this.params.maximumAzimuth - this.params.minimumAzimuth) / this.params.angularResV) + 1;

    if( cameracount == undefined ) {
        this.cameracount = 4;
    } else {
        this.cameracount = cameracount;
    }

    this.lidarCamera = new THREE.PerspectiveCamera( this.params.vfov , aspect, this.params.cameraNear, this.params.cameraFar );

 	this.postCamera = new THREE.OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );
    this.postMaterial = new THREE.ShaderMaterial( this.depthDisplay );
    this.postScene = new THREE.Scene();


    this.rtargetWidth = this.cameracount * width;
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
 	this.quad.frustumCulled = false;
    this.postScene.add( this.quad );
};

THREE.LidarPassSALDO.prototype = Object.assign( Object.create( THREE.Pass.prototype ), {
	constructor: THREE.LidarPassSALDO,

	render: function ( renderer, writeBuffer, readBuffer, delta, maskActive ) {

        var top = 0;
        var camwidth = this.rtargetWidth/this.cameracount;
        var cam = 0;
        var rot = 0;

        this.lidarCamera.position.set( camera.position.x, camera.position.y, camera.position.z );
        this.renderTarget.scissorTest = true;
        this.lidarCamera.rotation.set( camera.rotation.x, camera.rotation.y, camera.rotation.z );

        for(var cc=0; cc<this.cameracount; cc++ ){
            this.lidarCamera.rotateY( rot );
            this.lidarCamera.updateProjectionMatrix();
            this.renderTarget.viewport.set(cam, 0, this.lidarWidth, this.rtargetHeight);
            this.renderTarget.scissor.set(cam, 0, this.lidarWidth, this.rtargetHeight);
            renderer.setRenderTarget(this.renderTarget);
            renderer.render( scene, this.lidarCamera );
            cam += camwidth;
            rot = -Math.PI * 0.5;  
        }

        this.renderTarget.scissorTest = false;

        // This is like the spinning rpm clock for the device.This time delta gives a "how much it has spun"
        //   with the last frame period (based on design specs)
        this.params.lastTime += simstate.deltat;

        // Rotation Rate determines hum much of a scanline is done in a frame. 20Hz = 20 times per second. 
        //  With 60 fps rendering, thats 1/3rd of a scanline per frame, for a 20Hz rotation.
        var startDegrees = ( this.params.lastTime % this.params.rotationRate ) / this.params.rotationRate;
        var endDegrees = startDegrees + (this.params.rotationRate / simstate.delta);

        this.postMaterial.uniforms['tColorMap'].value = this.params.colorMap;
        // Enable this to view normal color pixel view
        //this.postMaterial.uniforms['tDiffuse'].value = this.renderTarget.texture;
        this.postMaterial.uniforms['tDepth'].value = this.renderTarget.depthTexture;
        this.postMaterial.uniforms['cameraNear'].value = this.params.cameraNear;
        this.postMaterial.uniforms['cameraFar'].value = this.params.cameraFar;
        this.postMaterial.uniforms['stepRes'].value = this.params.angularResH;
        this.postMaterial.uniforms['startResH'].value = startDegrees;
        this.postMaterial.uniforms['endResH'].value = endDegrees;
        this.postMaterial.uniforms['timeLast'].value = this.params.lastTime;
        this.postMaterial.uniforms['startAzimuth'].value = this.params.vfov * 0.5 + this.params.minimumAzimuth  + 0.5;
        this.postMaterial.uniforms['stepAzimuth'].value = this.params.angularResV;
        this.postMaterial.uniforms['vfov'].value = this.params.vfov;
        this.postMaterial.uniforms['vertAzimuth'].value = this.params.vertAzimuth;

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

