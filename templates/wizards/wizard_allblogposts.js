<script>
    $(document).ready( function(){
    var windowheight = $(window).height();
    var adminbannerheight =  $('.admin-banner').height();
    
    $('.admin-panel').css('min-height', windowheight - adminbannerheight ); 
        
        $('#blogpostnew').click(function(e){
            e.preventDefault();
            $.post('/functions/blognew',
                   function(data, status, xhr){
                // do something here with response;
                document.location = data;
            });
        });
    
            $('.edit-blogpost').click(function(e){
            e.preventDefault();
            $.post('/functions/blogedit', { href: $(this).text() },
                   function(data, status, xhr){
                // do something here with response;
                document.location = data;
            });
        });
    });
</script>
