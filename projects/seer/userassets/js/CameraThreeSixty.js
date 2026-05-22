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

THREE.ThreeSixtySALDO = function ( width, height, _params ) {

    THREE.Pass.call( this );

    // Lidar RayCasting type rendering
    //    -- if this frag is a point needing a ray cast (is a valid scanline?)
    //    -- we cast from viewer pos, outwards to "depth". 
    //    -- return the depth "hit" or nothing.
    this.depthDisplay = {
        uniforms: THREE.UniformsUtils.merge( [
            {         

                "tColor": { value: null },
            }
        ] ),

        vertexShader: [   
            "varying vec2 vUv;",
            "void main() {",
                "vUv = uv;",
                "gl_Position = projectionMatrix * (modelViewMatrix * vec4(position, 1.0));",
            "}"
        ].join("\n"),
        
        fragmentShader: [
            'uniform sampler2D tColor;',
            'varying vec2 vUv;',

            'void main(void){',
                'vec2 uv = vec2( vUv.x, vUv.y );',
                'gl_FragColor.rgb = texture2D( tColor, uv ).rgb;',
            '}',
        ].join("\n")
    };   

    //var warpIdx = this.depthDisplay.fragmentShader.indexOf("<<<< INSERT WARPING >>>>");
    //console.log("Got Idx:", warpIdx);
    //Array.prototype.splice.apply(this.depthDisplay.fragmentShader, [warpIdx, 1].concat(this.warping));
    //this.depthDisplay.fragmentShader;

    this.cameracount = 4;
    this.params = JSON.parse( JSON.stringify(_params) );

    // Also need rendertarget for depth map (will be 4x camera wide)
    this.lidarWidth = width / this.cameracount;
    this.lidarHeight = height;

    this.aspect = ((width/this.cameracount) / height);
    var vfov = 2.0 * Math.atan( Math.tan( (Math.PI * 0.5) * 0.5 ) * this.aspect) * 180.0 / Math.PI;
    this.tsCamera = new THREE.PerspectiveCamera( vfov, 1.0/this.aspect, this.params.cameraNear, this.params.cameraFar );

 	this.postCamera = new THREE.OrthographicCamera( - 1, 1, 1, - 1, -1, 1);
    this.postMaterial = new THREE.ShaderMaterial( {
        fragmentShader: this.depthDisplay.fragmentShader,
        vertexShader: this.depthDisplay.vertexShader,
        uniforms: THREE.UniformsUtils.clone( this.depthDisplay.uniforms ),
    } );        

    //this.postMaterial.uniforms.height.value = new THREE.Vector2(width/this.cameracount, height);
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

    // this.postMaterial = new THREE.MeshStandardMaterial( { 
    //     color: 0xffffff, 
    //     map: this.renderTarget.texture,
    //     lights: true,        
    // });

    var postPlane = new THREE.PlaneGeometry( 2, 2, 20, 1 );
//    this.quad.scale.set( 1, 0.01, 1 );
    
// Can use this in the vert shader to warp image correctly.
    var vertsize = postPlane.vertices.length;
    for(var i=0; i<vertsize; i++) {
        var offset = Math.sin(( ((postPlane.vertices[i].x + 1.0) % 0.5) * 2.0 - 1.0) * Math.PI) * 1.0;
        postPlane.vertices[i].z = postPlane.vertices[i].z + offset;
    }
    this.quad = new THREE.Mesh( postPlane, this.postMaterial );

 	this.quad.frustumCulled = false;
    this.postScene.add( this.quad );
};

THREE.ThreeSixtySALDO.prototype = Object.assign( Object.create( THREE.Pass.prototype ), {
	constructor: THREE.ThreeSixtySALDO,

	render: function ( renderer, writeBuffer, readBuffer, delta, maskActive ) {

        var top = 0;
        var camwidth = this.rtargetWidth / this.cameracount;
        var cam = 0;
        var rot = 0;

        var gh = gridhelper.visible;
        var of = ocean.floor.visible;
        var brt = ocean.surface.material.uniforms.refractionSampler.value;
        gridhelper.visible = false;
        ocean.floor.visible = false;
        ocean.surface.material.uniforms.refractionSampler.value = null;

        renderer.clear();
        this.renderTarget.scissorTest = true;

        this.tsCamera.rotateY( rot );
        this.tsCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tsCamera );
        cam = camwidth;
        rot = -Math.PI / 2;

        this.tsCamera.rotateY( rot );
        this.tsCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tsCamera );
        cam = camwidth * 2;

        this.tsCamera.rotateY( rot );
        this.tsCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tsCamera );
        cam = camwidth * 3;

        this.tsCamera.rotateY( rot );
        this.tsCamera.updateProjectionMatrix();
        this.renderTarget.viewport.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        this.renderTarget.scissor.set(cam, 0, this.lidarWidth + 1, this.rtargetHeight);
        renderer.setRenderTarget(this.renderTarget);
        renderer.render( scene, this.tsCamera );

        this.renderTarget.scissorTest = false;
        gridhelper.visible = gh;
        ocean.floor.visible = of;
        ocean.surface.material.uniforms.refractionSampler.value = brt;

        // This is like the spinning rpm clock for the device.This time delta gives a "how much it has spun"
        //   with the last frame period (based on design specs)
        this.params.lastTime += simstate.deltat;
        
        // Enable this to view normal color pixel view
        //this.postMaterial.uniforms['tDiffuse'].value = this.renderTarget.texture;
        this.postMaterial.uniforms['tColor'].value = this.renderTarget.texture;

 		if ( this.renderToScreen == false ) {
            renderer.setRenderTarget(writeBuffer);
            renderer.clear();
		} else {
            renderer.setRenderTarget(null);
        }
        renderer.render( this.postScene, this.postCamera );
    },

 	setSize: function ( width, height ) {
 	}
});

