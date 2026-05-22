function pinInit() {
    $('.image-container.image-shoptag img').on('click', function (e){     
    
        var $this = $(this);
        var offset = $this.offset();
        var width = $this.width();
        var height = $this.height();
        var posX = offset.left;
        var posY = offset.top;
        var x = e.pageX-posX;
        x = parseInt(x/width*100,10);
        x = x<0?0:x;
        x = x>100?100:x;
        var y = e.pageY-posY;
        y = parseInt(y/height*100,10);
        y = y<0?0:y;
        y = y>100?100:y;
        console.log(x+'% '+y+'%');
        var pin = $(
        '<div class="pin-wrapper open">' + 
        '  	<div class="pin">' + 
        '		<div class="pin-popover">' + 
        '  			<div class="pin-popover-close"></div>' + 
        '<div class="pin-popover--content">' + 
        '<a class="btn" style="padding: 10px 20px; text-align: left;">Add Text<span class="icon-plus" style="float: right;line-height: 20px;"></span></a></div>' + 
        '		</div>' + 
          '	</div>' + 
         ' 	<div class="pin-open">' + 
        '		<span class="icon-x"></span>' + 
          '	</div>' + 
        	'<div class="pin-delete"><span class="icon-trashcan"></span></div>' + 
          '</div>' ).css({top:y+'%', left:x+'%'});
        
        $this.parent().append(pin);
        
        PinToggle();
        
        $('.pin-delete').on('click', function() {
        $(this).closest('.pin-wrapper').remove();
        });
        
        $( ".pin-wrapper" ).draggable({
            containment: "parent",
            handle: ".pin-open",
            stop: function( event, ui ) {
              var $elm = $(this);
              var pos = $elm.position(),
                  parentSizes = {
                    height: $elm.parent().height(),
                    width: $elm.parent().width()
                  };
              $elm.css('top', (((pos.top/parentSizes.height) * 100).toFixed()) + '%').css('left', (((pos.left/parentSizes.width) * 100).toFixed()) + '%');
              
              pinnedimage = $('#Pin .image-container.image-shoptag').html();
                      $('#helper-dragpins').fadeOut();
        
            }
        });
    
        pinnedimage = $('#Pin .image-container.image-shoptag').html();
    });
}
  
function PinToggle() {    
    $('.pin-open').on('click', function() {
      $('.image-container.image-shoptag').find('.pin-wrapper').removeClass('open');
      $(this).closest('.pin-wrapper').toggleClass('open');
    });
}  


function pinDocClickClose() {
    $(document).on('mouseup', function (e){
        var container = $(".pin-popover");
        if (!container.is(e.target)
          && container.has(e.target).length === 0)
        {
            container.closest('.pin-wrapper').removeClass('open');
        }
    });
}

function setCookie(cname, cvalue, exdays) {
    var d = new Date();
    d.setTime(d.getTime() + (exdays*24*60*60*1000));
    var expires = ""; //expires="+ d.toUTCString();
    console.log(cname + "=" + cvalue + ";" + expires + ";path=/");
    document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
}

function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for(var i = 0; i <ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
            return c.substring(name.length, c.length);
        }
    }
    return "";
}

function ConvertFormToJSON( idname ){
    var $vals = {};
    if(idname == 'undefined') { idname = ' '; }
    //console.log("Idname:", idname);
    
    var selection = $('form' + idname +' input');
    selection = selection.add( $('form' + idname +' textarea') );
    selection = selection.add( $('form' + idname +' select') );
    selection = selection.add( $('form' + idname +' .slider') );
    
    selection.each(function(i){ 

        var input = $(this)[0];
        if( !input ) return true;
        if( $(this).attr('name') == '' ) return true;
        
        switch( input.tagName.toLowerCase() ) {
            case 'input' : 
                if( input.type === 'radio') {
                    if (!$vals[input.name])
                        $vals[input.name] = 'empty';
                    
                    if( input.checked == true ) {
                        $vals[input.name] = input.value;
                    }
                }
                else if( input.type === 'checkbox' )
                {
                    if( input.checked === true ) {
                        $vals[input.name] = 'true';
                    } 
                    else {
                        $vals[input.name] = 'false';
                    }
                }
                else
                {
                    if( input.value === '' ) {
                        $vals[input.name] = 'empty';
                    } 
                    else {
                        $vals[input.name] = input.value;
                    }
                }
                break;

            case 'select' : 
                // assuming here '' or '-1' only
                if( input.value === '' || input.value === '-1' ) {
                    $vals[input.name] = 'empty';
                } 
                else {
                    $vals[input.name] = input.value;
                }
                break;

            case 'textarea' :
                if( input.value === '' ) {
                    $vals[input.name] = 'empty';
                } 
                else {
                    $vals[input.name] = input.value;
                }
                break;
        }
        
        if($(this).hasClass('slider'))
        {
            //console.log($(this).attr('name'), $(this).slider( "value" ));
            $vals[$(this).attr('name')] = $(this).slider( "value" );
        }
    });
    return $vals;
}  

$( document ).ready(function() {
    $('[data-toggle="tooltip"]').tooltip();  

    PinToggle();
    pinDocClickClose();
    $('.admin-footer--horizontalscroll').slick({
        slide: '.admin-footer--item',
        slidesToShow: 5,
        slidesToScroll: 1,
        infinite: false,
        nextArrow: '<span class="slick-next icon-triangle-right"></span>',
        prevArrow: '<span class="slick-prev icon-triangle-left"></span>'
    }); 
    
{% if editing == true then %}
    $('main').attr("id", "panel");
    $('#panel').parent().append('<button class="adminmenu-toggle-button"><span class="icon-hamburger"></span></button>');

    var slideout = new Slideout({
        'panel': document.getElementById('panel'),
        'menu': document.getElementById('admin-menu'),
        'padding': 256,
        'tolerance': 70
    });
    
    // Toggle button
    document.querySelector('.adminmenu-toggle-button').addEventListener('click', function() {
        slideout.toggle();
    });
{% end %}
    
    var adminmenu = $('#admin-menu');
    var adminmenutoggle = $('#nav-toggle');
    
    function OpenAdminMenu() {
        adminmenu.addClass('active').focus();
        adminmenutoggle.addClass('drawer-active').focus();
        adminmenutoggle.find("span").removeClass("icon-hamburger").addClass("icon-x");
        $('body').addClass("drawer_left-open");
    }
    
    function CloseAdminMenu() {
        adminmenu.removeClass('active').focus();
        adminmenutoggle.removeClass('drawer-active').focus();
        adminmenutoggle.find("span").addClass("icon-hamburger").removeClass("icon-x");
        $('body').removeClass("drawer_left-open");
    }

    $('#nav-toggle').on('click', function () {
        if($(this).find("span").hasClass("icon-hamburger")){
            OpenAdminMenu();
        } else {
            CloseAdminMenu();
        }
    });

    $('#nav-toggle').on({
        focusout: function () {
            $(this.hash).data('timer', setTimeout(function () {
                CloseAdminMenu();
            }.bind(this), 0));
        },
        focusin: function () {
            clearTimeout($(this.hash).data('timer'));
        }
    });
    
    $('#admin-menu').on({
        focusout: function () {
            $(this).data('timer', setTimeout(function () {
                CloseAdminMenu();
            }.bind(this), 0));
        },
        focusin: function () {
            clearTimeout($(this).data('timer'));
        },
        keydown: function (a) {
            if (a.which === 27) {
                CloseAdminMenu();
                a.preventDefault();
            }
        }
    });
    
    
    $('#comments').comments({
        getComments: function(success, error) {
            var commentsArray = [{
                id: 1,
                created: '2015-10-01',
                content: 'Lorem ipsum dolort sit amet',
                fullname: 'Simon Powell test',
                upvote_count: 2,
                user_has_upvoted: false
            }];
            success(commentsArray);
        },
        enableNavigation: false,
        enableAttachments: false,
        sendText: 'Comment',
        textareaRows: 5
    });
    
    $('.image-carousel').not('.slick-initialized').slick({
        dots: true,
        infinite: true,
        slidesToShow: 1,
        slidesToScroll: 1,
        autoplay: true,
        autoplaySpeed: 1500,
        arrows: false,
        nextArrow: '<span class="slick-next icon-triangle-right"></span>',
        prevArrow: '<span class="slick-prev icon-triangle-left"></span>'
    });
    
    $('.image-carousel').not('.slick-initialized').slick('reInit');
    
    var $grid = $('.image-masonry').masonry({
        itemSelector: '.image-container',
        columnWidth: '.grid-sizer',
        percentPosition: true
    });
    $grid.imagesLoaded().progress( function() {
        $grid.masonry('layout');
    });
    $('.datepicker').timepicker({timeFormat:"hh:mm TT", timeOnly:true });
 
    $('.datepicker-inline').timepicker({timeFormat:"hh:mm TT", timeOnly:true });

    $(".tagsinput").select2({
        tags: true,
        tokenSeparators: [',', ' ']
    });

    var elems = Array.prototype.slice.call(document.querySelectorAll('.js-switch'));
    elems.forEach(function(html) {
        var switchery = new Switchery(html);
    });
    
    $('.logo-spin_wrapper').addClass('remove');
    
    $('input').filter(function() {
        return this.value;
    });
});

