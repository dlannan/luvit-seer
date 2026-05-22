
console.log("Module Feeds Initialising...")
$('.feed-instagram').each(function (index) {
    var myhtml = $(this);
//    $.get( $(this).attr("data-src"), function(data) {
//        //console.log(data);
//        if(data.html != 'undefined') {
//            myhtml.html(data.html);
//            //console.log(data.html);
//        }
//    });
    myhtml.html('<img data-src="holder.js/700x450?auto=yes" />'); 
});

// Apply the like button capability
$('.module-feed .feed-like-button').on('click', function (index) {
 
    json = "key=feeds.thisfeed.likecount";
    $.post('/functions/likeblock', json,
        function(data, status, xhr){
            $('.module-feed .feed-like-data').text("Like: " + data);
    });
});


