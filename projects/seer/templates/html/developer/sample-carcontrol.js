function speedup() {

    var car1 = SceneGraph.findByName("models551");
    var speed = car1.mover.speed();
    console.log(speed);
    if(speed < 10.0) speed += 1.0;
    car1.mover.setSpeed(speed);
}

function startcar() {

    var car1 = SceneGraph.findByName("models551");
    console.log(car1);
    car1.mover.setSpeed (0.0);         // speed along Forward direction.
    car1.mover.setMaxForce (7000.7);      // steering force is clipped to this magnitude
    car1.mover.setMaxSpeed (20);         // velocity is clipped to this magnitude
    car1.mover.setRadius(1.25);
    car1.mover.setHeading( 0.3);
}

$(document).ready( function() {
    var startbutton = $('<button class="btn_refresh" style="z-index: 101;position:absolute;">Start Car</button>');
    $('body').append(startbutton);
    startbutton.on('click',function(){
        startcar();
        // Start car updating...
    });
    var speedbutton = $('<button class="btn_refresh" style="z-index: 102; top: 30px; position:absolute;">Speed Up</button>');
    $('body').append(speedbutton);
    speedbutton.on('click',function(){
        speedup();
        // Start car updating...
    });

});