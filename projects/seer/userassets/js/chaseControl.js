/**
 * @author dlannan 
 */

THREE.chaseControl = function ( object, domElement ) {

	this.object = object;
	this.target = undefined;

	this.domElement = ( domElement !== undefined ) ? domElement : document;

	this.enabled = true;
	this.ortho = false;
	this.lposition = new THREE.Vector3();

	this.distance = -5.0;
	this.height = 2.5;
	this.lookheight = 2.3;

	this.lookSpeed = 0.005;
	this.lookVertical = true;
	this.autoForward = false;

	this.activeLook = false;

	this.heightSpeed = false;
	this.constrainVertical = false;
	this.verticalMin = 0;
	this.verticalMax = Math.PI;

	this.autoSpeedFactor = 0.0;

	this.lat = 0;
	this.lon = 0;
	this.startlat = 0;
	this.startlon = 0;

	this.viewHalfX = 0;
	this.viewHalfY = 0;

	if ( this.domElement !== document ) {

		this.domElement.setAttribute( 'tabindex', - 1 );

	}

	//

	this.handleResize = function () {

		if ( this.domElement === document ) {

			this.viewHalfX = window.innerWidth / 2;
			this.viewHalfY = window.innerHeight / 2;
		} else {

			this.viewHalfX = this.domElement.offsetWidth / 2;
			this.viewHalfY = this.domElement.offsetHeight / 2;
		}
	};

	this.update = function( delta ) {

		if ( this.enabled === false ) return;
		if ( this.target === undefined ) return;
		var actualMoveSpeed = delta * this.movementSpeed;

		var fwd = new THREE.Vector3();
		this.target.getWorldDirection(fwd);		

		this.lposition = this.target.position.clone();
		var forwardOffset = fwd.clone().multiplyScalar(this.distance);
		var tpos = this.lposition.add( forwardOffset );

		var tview = new THREE.Vector3( tpos.x + fwd.x, tpos.y + this.lookheight + fwd.y, tpos.z + fwd.z);
		this.object.position.set( tpos.x, tpos.y + this.height, tpos.z );
		this.object.lookAt( tview );
	};

	function contextmenu( event ) {

		event.preventDefault();
	}

	this.dispose = function() {

		this.domElement.removeEventListener( 'contextmenu', contextmenu, false );
	};

	this.domElement.addEventListener( 'contextmenu', contextmenu, false );

	function bind( scope, fn ) {

		return function () {

			fn.apply( scope, arguments );
		};
	}

	this.handleResize();
};
