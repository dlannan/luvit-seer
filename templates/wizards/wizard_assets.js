<script>

    
function uploadFile(fileName, data) {
    $.ajax({
        url: '/admin/upload/' + fileName,
        data: data,
        processData: false,
        contentType: false,
        type: 'POST',
        success: function(data) {
            var newdata = '<div id="assets_view">' + data + '</div>';
            $("#assets_view").replaceWith(newdata);
            var grid = document.querySelector('#assets-images');
            var item = document.createElement('div');
            ApplyHolder();
        }
    });
}

function handlePaste(e) {
    for (var i = 0 ; i < e.clipboardData.items.length ; i++) {
        var item = e.clipboardData.items[i];
        console.log("Item: " + item.type);
        if (item.type.indexOf("image") != -1) {
            uploadFile("pastedFile" + Math.floor((Math.random() * 100000) + 1) + ".png", item.getAsFile());
        } else {
            console.log("Discardingimage paste data");
        }
    }
}

$( document ).ready(function() {
    var $grid = $('.image-masonry').masonry({
      itemSelector: '.image-container',
      columnWidth: '.grid-sizer',
      percentPosition: true
    });
    $grid.masonry('reloadItems');
    
    $('#assets_view img').each( function() {
        $(this).on( 'click', function(event) {
            $('#assets_view img').removeClass("active");
            $(this).addClass("active");
            $('#assets_view').attr('data-selected', $(this).attr('src'));
        });
    });

    $('#wizard_assets_submit').click( function(event) {
        var selectedimage = $('#assets_view').attr('data-selected');
        if(selectedimage && current_image_selected) {
            console.log(selectedimage, current_image_selected);
            $(current_image_selected).find('img').attr('src', selectedimage);
        }

        //if($(current_image_selected).parent().hasClass("image-grid")) {
        //var smallestheight = 999999;
        //current_selected_module.parent().find('img').each(function () {
        //    var thisheight = $(this).height();
        //    if (smallestheight === 999999 || thisheight < smallestheight) {
        //        smallestheight = thisheight;
        //    }
        //});

        //current_selected_module.parent().find('img').each(function () {
        //    var imgheight = $(this).height();
        //    var imgdif = -((imgheight - smallestheight) / 2);
        //    $(this).css({top:imgdif});

        //    $(this).parent().css({height:smallestheight, overflow:'hidden'});
        //});
        //} else if($(current_image_selected).parent().hasClass("image-masonry")) {
        //    $grid.imagesLoaded().progress( function() {
        //        $grid.masonry('layout');
        //    });
        //}
    });

    $('#wizard_assets').modal('hide');
    
    $('#wizard_assets').on('shown.bs.modal', function() {
        window.dispatchEvent(new Event('resize'));
    })

    $('#uploadFile').change(function (event){

        files = event.target.files;
        var fileName = $(this).val().split('\\').pop();
        //console.log(fileName);

        uploadFile(fileName, files[0]);
    });

    // NOTE: This works, but it creates havok.
    //document.getElementById("pasteTarget").addEventListener("paste", handlePaste);
});
</script>