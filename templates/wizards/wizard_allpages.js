<script>
    $(document).ready( function(){
    var windowheight = $(window).height();
    var adminbannerheight =  $('.admin-banner').height();
    
    $('.admin-panel').css('min-height', windowheight - adminbannerheight ); 
        
        $('#pagenew').click(function(e){
            e.preventDefault();
            $.post('/functions/pagenew',
                   function(data, status, xhr){
                // do something here with response;
                document.location = data;
            });
        });
    
            $('.edit-page').click(function(e){
            console.log("clicked..");
            e.preventDefault();
            $.post('/functions/pageedit', { href: $(this).text() },
                   function(data, status, xhr){
                // do something here with response;
                document.location = data;
            });
        });
    });

</script>