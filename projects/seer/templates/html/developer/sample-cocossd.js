

//let objectDetector;
boxcount = 0;
function makebox(text, x, y, w, h) {
    $(".box_cocossd").remove();
    $(".text_cocossd").remove();
    var results_box = '<div id="res_box'+boxcount+'" class="box_cocossd" ></div>';
    var results_text = '<div id="res_text'+boxcount+'" class="text_cocossd" >'+text+'</div>';
    $('body').append(results_box);
    $('body').append(results_text);
    $("#res_box"+boxcount).css( {width:w+'px', height:h+'px',left:x+'px', top:y+'px'} );
    $("#res_text"+boxcount).css( {left:x+20+'px', top:y+'px'} );
  boxcount ++;
}

function startDetecting(){
    console.log('model ready')
}

function runtensor() {
    const img = document.getElementById('container0');
    objectDetector.detect(img, function(err, results) {
        if(err){
            console.log(err);
            return
        }
        if(results) {
            for (var i = 0; i < results.length; i++) {
                var object = results[i];
                makebox(object.label, object.x, object.y, object.width, object.height);      
            }
        }
        console.log(results);
    });
}

$(document).ready( function() {
    objectDetector = ml5.objectDetector('cocossd', startDetecting);
    var $button = $('<button class="btn_refresh" style="z-index: 101;position:absolute;">Run Tensorflow</button>');
    $('body').append($button);
    $button.on('click',function(){
        runtensor();
    });
});
