
var lsheading;

var sub = {
    ship: null,
    heading: 0.0,
    tween: null
};

function moveships() {
    var littleship = SceneGraph.findByName("models390");
    littleship.mover.setForward( Vec3Set( Math.cos(lsheading), 0.0, Math.sin(lsheading) ));
    lsheading += 0.001;

    sub.tween = new TWEEN.Tween(sub)
    .to({ heading: sub.heading + 0.001, }, 200)
    .easing(TWEEN.Easing.Quadratic.In)
    .onUpdate(function(d) {
        sub.ship.mover.setForward( Vec3Set( -Math.cos(sub.heading), 0.0, -Math.sin(sub.heading) ));
    });
    sub.tween.start();
}

function startships() {

    var bigship = SceneGraph.findByName("models549");
    bigship.mover.setSpeed(15.0);         // speed along Forward direction.
    bigship.mover.setMaxForce(7000.7);      // steering force is clipped to this magnitude
    bigship.mover.setMaxSpeed(40);         // velocity is clipped to this magnitude

    var littleship = SceneGraph.findByName("models390");
    littleship.mover.setSpeed(2.0);         // speed along Forward direction.
    littleship.mover.setMaxForce(1000.7);      // steering force is clipped to this magnitude
    littleship.mover.setMaxSpeed(20);         // velocity is clipped to this magnitude
    lsheading = 0.0;

    sub.ship = SceneGraph.findByName("models387");
    sub.ship.mover.setSpeed(5.0);         // speed along Forward direction.
    sub.ship.mover.setMaxForce(1000.7);      // steering force is clipped to this magnitude
    sub.ship.mover.setMaxSpeed(10);         // velocity is clipped to this magnitude
    sub.heading = 290.0;

    setInterval( moveships, 200 );
}
