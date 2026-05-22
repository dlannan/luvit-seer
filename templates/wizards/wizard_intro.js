<script>
$( document ).ready(function() {

    $('#wizard_intro_submit').click(function(e){
          e.preventDefault();

//          $.post('/functions/website_demo',
//             $('#website_info').serialize(),
//             function(data, status, xhr){
//               // do something here with response;
//               document.location = data;
//             });
        window.location.href = "/admin/demo/index.html";
    });

    $('#wizard_intro').modal ({
        backdrop: 'static',
        keyboard: 'false',
        show: 'true'
    });
});
</script>