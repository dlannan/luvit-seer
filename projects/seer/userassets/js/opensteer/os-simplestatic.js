var serialStaticNumberCounter = 0;

// SimpleVehicle adds concrete vehicle methods to SimpleVehicle_3
var SimpleStatic = function() {

    // maintain unique serial numbers
    this.serialNumber = serialStaticNumberCounter++;        

    this._mass = 0.0;       // mass (defaults to unity so acceleration=force)
    this._radius = 0.0;     // size of bounding sphere, for obstacle avoidance, etc.

    this._speed = 0.0;      // speed along Forward direction.  Because local space
                        // is velocity-aligned, velocity = Forward * Speed

    this._maxForce = 0.0;   // the maximum steering force this vehicle can apply
                        // (steering force is clipped to this magnitude)

    this._maxSpeed = 0.0;   // the maximum speed this vehicle is allowed to move
                        // (velocity is clipped to this magnitude)

    this._curvature = 0.0;
    this._lastForward = new Vec3();
    this._lastPosition = new Vec3();

    SteerLibrary(this);
    LocalSpace(this);

    // reset vehicle state
    this.reset = function() {
        // reset LocalSpace state
        this.resetLocalSpace(this.local);

        this.setMass(1.0);          // mass (defaults to 1 so acceleration=force)
        this.setSpeed(0.0);         // speed along Forward direction.

        this.setRadius(0.5);     // size of bounding sphere

        this.setMaxForce(0.0);   // steering force is clipped to this magnitude
        this.setMaxSpeed(0.0);   // velocity is clipped to this magnitude
    }

    // get/set mass
    this.mass = function() {return this._mass;}
    this.setMass = function(m) { return this._mass = m; }

    // get velocity of vehicle
    this.velocity = function() { return this.forward().mult(this._speed); }

    // get/set speed of vehicle  (may be faster than taking mag of velocity)
    this.speed = function() { return this._speed; }
    this.setSpeed = function(s) { return this._speed = s; }

    // size of bounding sphere, for obstacle avoidance, etc.
    this.radius = function() { return this._radius; }
    this.setRadius = function(m) { return this._radius = m; }

    // get/set maxForce
    this.maxForce = function() {return this._maxForce;}
    this.setMaxForce = function(mf) {return this._maxForce = mf;}

    // get/set maxSpeed
    this.maxSpeed = function()  {return this._maxSpeed;}
    this.setMaxSpeed = function(ms) {return this._maxSpeed = ms;}

    // ratio of speed to max possible speed (0 slowest, 1 fastest)
    this.relativeSpeed = function() { return this.speed() / this.maxSpeed(); }

}