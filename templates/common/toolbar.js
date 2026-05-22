<script>
var current_image_selected;
var current_selected_object;
var current_selected_module;
var wall;


function InitModuleeditpanel() {
    $('div[class*="module-"]:not(.module-add)').append(
        '<div class="module-edit">' +
            '<div class="module-edit--item fullwidthmodule btn-icon btn-sm btn-rounded"><span class="icon-enlarge2"></span></div>' +
            '<div class="module-edit--item deletemodule btn-icon btn-sm btn-rounded"><span class="icon-bin"></span></div>' +
            '<div class="module-edit--item movemodule btn-icon btn-sm btn-rounded"><span class="icon-move"></span></div>' +
        '</div>');

    $('.deletemodule').on('click', function(){
        $(this).parent().parent('div[class*="module-"]').remove()
    });

    $('.fullwidthmodule').on('click', function(){
        $(this).parent().parent('div[class*="module-"]').children(".container").toggleClass("fullwidth");
        var $grid = $('.image-masonry').masonry({
              itemSelector: '.image-container',
              columnWidth: '.grid-sizer',
              percentPosition: true
          });
          $grid.masonry('reloadItems');
          $('.image-carousel').slick('setPosition');
    });

    $( ".page__main" ).sortable({
        items: '> div[class*="module-"]:not(.module-add)',
        containment: "body",
        handle: ".movemodule"
    });

    $( 'div[class*="module-"]:not(.module-add):not(.module-edit)' ).draggable({
        connectToSortable: ".page__main",
        containment: "body",
        handle: ".movemodule",
        scroll: true,
        start  : function(event, ui){
            $(ui.helper).addClass("ui-helper");
        }
    });
}

InitModuleeditpanel();

function getCurrentSelection() {
var html = '', sel;
if (typeof window.getSelection != 'undefined') {
   sel = window.getSelection();
   if (sel.rangeCount) {
       var container = document.createElement('div');
       for (var i = 0, len = sel.rangeCount; i < len; ++i) {
           container.appendChild(sel.getRangeAt(i).cloneContents());
       }
       html = container.innerHTML;
   }
} else if (typeof document.selection != 'undefined') {
   if (document.selection.type == 'Text') {
       html = document.selection.createRange().htmlText;
   }
}
return html;
}

function striptag(txt) {
    var regex = /(<([^>]+)>)/ig
    return txt.replace(regex, "");
}

function replaceHtml(options)
{
    // Get Current Value
    var html = getCurrentSelection(), sel = window.getSelection();
    //console.log(html);
    //Modify Content
    var mark = true;
    if( options.matchstart === "*" ) {
        html = $(html).text();
        html = options.start + html + options.end;
    } else {

    var ms = html.match( options.matchstart );
    var me = html.match( options.matchend );
    var matched = ms != null && me != null;

    if (options.start === undefined || matched == false) {
        if(options.action != undefined) html = options.action(html, true);
        html = options.start + html + options.end;
    } else { //clean old
        if(options.action != undefined) html = options.action(html, false);
        // html = String(html).split(options.matchstart).join('');
        // html = String(html).split(options.matchend).join('');

        // Remove front matching element section
        if(ms != null) html = html.replace(ms ,"");
        if(me != null) html = html.replace(me ,"");
        html = options.start + html + options.end;
    }
}

var range;
var fragment;


var menu_texteditor;
var menu_imageeditor;
var menu_iconeditor;

//Set new Content
if (sel.getRangeAt && sel.rangeCount) {
    range = window.getSelection().getRangeAt(0);
    range.deleteContents();

    // Create a DocumentFragment to insert and populate it with HTML
    // Need to test for the existence of range.createContextualFragment
    // because it's non-standard and IE 9 does not support it
    if (range.createContextualFragment) {
        fragment = range.createContextualFragment(html);
    } else {
        var div = document.createElement('div');
        div.innerHTML = html;
        fragment = document.createDocumentFragment();
        while ((child = div.firstChild)) {
            fragment.appendChild(child);
        }
    }

    var firstInsertedNode = fragment.firstChild;
    var lastInsertedNode = fragment.lastChild;
    range.insertNode(fragment);
    if (firstInsertedNode) {
        range.setStartBefore(firstInsertedNode);
        range.setEndAfter(lastInsertedNode);
    }
    sel.removeAllRanges();
    sel.addRange(range);
  }
};

function InitMediumToolbarObjects()
{
    var TextalignButton = MediumEditor.Extension.extend({
        name: 'textalign',

        init: function () {
          this.button = this.document.createElement('button');
          this.button.classList.add('medium-editor-action');
          this.button.uid = $('select').uniqueId().attr('id');
          this.button.innerHTML = '<select id="alignselect'+this.button.uid+
              '" class="selectpicker" data-style="btn">' +
              '<option value="left" data-content="<span class=\"icon-align-left\"></span>"></option>' +
              '<option value="center" data-content="<span class=\"icon-align-center\"></span>"></option>' +
              '<option value="right" data-content="<span class=\"icon-align-right\"></span>"></option>' +
              '<option value="justify" data-content="<span class=\"icon-align-justify\"></span>"></option>' +
              '</select>';
          this.button.title = 'Textalign';
          this.on(this.button, 'change', this.handleSelect.bind(this));
        },

        getButton: function () {
          return this.button;
        },

        handleSelect: function (event) {
            console.log(event);
            // Replace selected html
            options = [];
            var newalign = $( "#alignselect" + this.button.uid).val();

            options.start = "<span style=\"text-align:"+ newalign +";\">";
            options.end = "</span>";
            options.matchstart = "<span style=\"text-align:.*;\">";
            options.matchend = "</span>";
            replaceHtml(options);

            // Ensure the editor knows about an html change so watchers are notified
            // ie: <textarea> elements depend on the editableInput event to stay synchronized
            this.base.checkContentChanged();
        }
    });


    var FontfamilyButton = MediumEditor.Extension.extend({
        name: 'fontfamily',

        init: function () {

          this.button = this.document.createElement('button');
          this.button.classList.add('medium-editor-action');
          this.button.uid = $('select').uniqueId().attr('id');
          this.button.innerHTML = '<select id="fontselect'+this.button.uid+
              '" class="selectpicker" value="Raleway"  data-style="btn">' +
                  '<optgroup label="San Serif">' +
                  '    <option value="Arial">Arial</option>' +
                  '    <option value="Oswald">Oswald</option>' +
                  '    <option value="Raleway">Raleway</option>' +
                  '    <option value="Montserrat">Montserrat</option>' +
                  '    <option value="Lato">Lato</option>' +
                  '    <option value="Questrial">Questrial</option>' +
                  '    <option value="Open Sans">Open Sans</option>' +
                  '    <option value="Anton">Anton</option>' +
                  '    <option value="Quicksand">Quicksand</option>' +
                  '</optgroup>' +
                  '<optgroup label="Serif">' +
                  '    <option value="Playfair Display">Playfair Display</option>' +
                  '    <option value="Times New Roman">Times New Roman</option>' +
                  '    <option value="Merriweather">Merriweather</option>' +
                  '    <option value="Roboto Slab">Roboto Slab</option>' +
                  '    <option value="Lora">Lora</option>' +
                  '    <option value="Droid Serif">Droid Serif</option>' +
                  '</optgroup>' +
                  '<optgroup label="Script">' +
                  '    <option value="Pacifico">Pacifico</option>' +
                  '    <option value="Sacramento">Sacramento</option>' +
                  '</optgroup>' +
            '</select>';
          this.button.title = 'Fontfamily';
          this.on(this.button, 'change', this.handleSelect.bind(this));
        },

        getButton: function () {
          return this.button;
        },

        handleSelect: function (event) {

            // Replace selected html
            options = [];
            var newfont = $( "#fontselect" + this.button.uid ).val();

            options.start = "<span style=\"font-family:'"+ newfont +"';\">";
            options.end = "</span>";
            options.matchstart = "<span style=\"font-family:.*;\">";
            options.matchend = "</span>";
            replaceHtml(options);

            $("<link href='https://fonts.googleapis.com/css?family=" + newfont.split(" ").join('+') + "' rel='stylesheet' type='text/css'>").appendTo("head");

            // Ensure the editor knows about an html change so watchers are notified
            // ie: <textarea> elements depend on the editableInput event to stay synchronized
            this.base.checkContentChanged();
        }
    });

    var HeadingButton = MediumEditor.Extension.extend({
        name: 'heading',

        init: function () {
          this.button = this.document.createElement('button');
          this.button.classList.add('medium-editor-action');
          this.button.uid = $('select').uniqueId().attr('id');
          this.button.innerHTML = '<select id="headingselect' + this.button.uid+'" class="selectpicker" value="Heading 1"  data-style="btn">' +
                      '<option value="h1">Heading 1</option>' +
                      '<option value="h2">Heading 2</option>' +
                      '<option value="h3">Heading 3</option>' +
                      '<option value="h4">Heading 4</option>' +
                      '<option value="h5">Heading 5</option>' +
                      '<option value="h6">Heading 6</option>' +
                      '<option value="p">Normal</option>' +
                      '<option value="q">Quote</option>' +
                      '<option value="k">Clear All</option>' +
                      '</select>';
          this.button.title = 'heading';
          this.on(this.button, 'change', this.handleSelect.bind(this));
        },

        getButton: function () {
          return this.button;
        },

        handleSelect: function (event) {

            // Replace selected html
            options = [];
            var quote = $( "#headingselect" + this.button.uid ).val();

            if(quote == "q")  {
              options.start = '<span style="content:"&#34";></span>';
              options.end = '<span style="content:"&#34";></span>';
              options.matchstart = '<span style="content:.*;>';
              options.matchend = "</span";
            } else if(quote == "k") {
              options.start = "";
              options.end = "";
              options.matchstart = "*";
              options.matchend = "";
            } else {
              options.start = "<"+ quote +">";
              options.end = "</"+ quote +">";
              options.matchstart = "<h\\d>";
              options.matchend = "</h\\d>";
            }
            replaceHtml(options);

            // Ensure the editor knows about an html change so watchers are notified
            // ie: <textarea> elements depend on the editableInput event to stay synchronized
            this.base.checkContentChanged();
        }
    });
    
    var Button = MediumEditor.Extension.extend({
      name: 'button',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-hand-pointer-o').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-hand-pointer-o"></span>';
        this.button.title = 'button';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {
          
        return this.button;
      },
    
      handleSelect: function (event) {
            options = [];

            // Check parent (if already in a button.. no more!!!)
            html = getCurrentSelection()
            console.log(html);
            if( html.indexOf('btn') >= 0 )
                return;
            
            options.start = "<span class='btn btn-primary'>";
            options.end = "</span>";
            options.matchstart = "<span class='btn btn-primary'>";
            options.matchend = "</span>";
            replaceHtml(options);

            // Ensure the editor knows about an html change so watchers are notified
            // ie: <textarea> elements depend on the editableInput event to stay synchronized
            this.base.checkContentChanged();
      }
    });
    
    var Imagedisplay = MediumEditor.Extension.extend({
      name: 'imagedisplay',

      init: function () {
          this.button = this.document.createElement('button');
          this.button.classList.add('medium-editor-action');
          this.button.uid = $('select').uniqueId().attr('id');
          this.button.innerHTML = '<select id="displayselect'+this.button.uid+'" class="selectpicker" data-style="btn">' +
                    '<option value="grid" data-content="<span class=\"icon-img-grid\"></span>"></option>' +
                    '<option value="carousel" data-content="<span class=\"icon-img-carousel\"></span>"></option>' +
                    '<option value="masonry" data-content="<span class=\"icon-img-masonry\"></span>"></option>' +
                    '</select>';
          this.button.title = 'imagedisplay';
          this.on(this.button, 'change', this.handleSelect.bind(this));
      },

      getButton: function () {
        return this.button;
      },

      handleSelect: function (event) {

          var viewer = $(window.getSelection().anchorNode ).closest(".container");
          var displaysel = $( "#displayselect" + this.button.uid ).val();

          if(displaysel == "grid") {
              $(".image-carousel").slick('unslick');
              $('.image-masonry').masonry('destroy');

              viewer.children("div").removeClass("image-carousel");
              viewer.children("div").removeClass("image-masonry");
              viewer.children("div").addClass("image-grid");
              viewer.find(".grid-sizer").remove();

              $('.medium-editor-action[title="imagecarouselarrows"]').hide();
              $('.medium-editor-action[title="imagescale"]').show();

              viewer.find(".image-container").css("width","");
              viewer.children("div").children("div").addClass("col-md-4");

              $(".image-carousel").slick();

          } else if(displaysel == "carousel"){
              $(".image-carousel").slick('unslick');
              $('.image-masonry').masonry('destroy');

              viewer.children("div").removeClass("image-grid");
              viewer.children("div").removeClass("image-masonry");
              viewer.children("div").addClass("image-carousel");
              viewer.find(".grid-sizer").remove();

              viewer.children("div").children("div").removeClass().addClass("image-container");

              $('.medium-editor-action[title="imagecarouselarrows"]').show();
              $('.medium-editor-action[title="imagescale"]').hide();

              viewer.find(".image-container").css("height","");

              $(".image-carousel").slick();

          } else if (displaysel == "masonry"){
              $(".image-carousel").slick('unslick');

              viewer.children("div").removeClass("image-grid");
              viewer.children("div").removeClass("image-carousel");
              viewer.children("div").addClass("image-masonry");

              viewer.children("div").children("div").removeClass().addClass("image-container");

              viewer.find(".image-container").css("height","");

              $('.medium-editor-action[title="imagecarouselarrows"]').hide();
              $('.medium-editor-action[title="imagescale"]').show();

              viewer.children("div").prepend('<div class="grid-sizer"></div>');

              var $grid = $('.image-masonry').imagesLoaded( function() {
                  $('.image-masonry').masonry({
                      itemSelector: '.image-container',
                      columnWidth: '.grid-sizer',
                      percentPosition: true
                  });
              });

              $(".image-carousel").slick();
          }
      }
    });

    var Link = MediumEditor.Extension.extend({
      name: 'link',

      init: function () {
        this.button = this.document.createElement('button');  
        this.button.classList.add('medium-editor-action');
        this.button.classList.add('nopanel');
        this.button.innerHTML = '<div id="linkdropdown" class="btn-group dropdown-static" style="padding: 0 5px;margin: 0 -15px;">' +
            '<button type="button" class="dropdown-toggle"><span class="icon-link"></span></button>' +
            '<div class="dropdown-menu">' +
                '<div>' +
                    '<ul class="nav nav-pills">' +
                        '<li class="active"><a href="#link-url" data-toggle="tab">URL</a></li>' +
                        '<li class =""><a href="#link-blog" data-toggle="tab">Blog</a></li>' +
                        '<li class =""><a href="#link-page" data-toggle="tab">Page</a></li>' +
                    '</ul>' +
                    '<div class="link-icon-wrapper"><span class="icon-link"></span></div>' +
                    '<div class="tab-content clearfix">' +
                        '<div class="tab-pane active" id="link-url">' +
                            '<input type="text" placeholder="Insert URL" />' +
                        '</div>' +
                        '<div class="tab-pane" id="link-blog">' +
                            '<select id="link-blog_select" class="selectpicker" placeholder="Select blogpost" title="Choose blog post..." data-style="btn" data-live-search="true">' +
{% 
    local allblogs = _G.HTMLBLOGS.getallblogs()
    for k,v in pairs(allblogs) do
        local blogdata = _G.HTMLBLOGS.getblogdata(k)
%}
                        '<option value="{* k *}">{* blogdata.name *}</option>' +
{% end %}
                        '</select>' +
                    '</div>' +
                    '<div class="tab-pane" id="link-page">' +
                        '<select id="link-page_select" class="selectpicker" value="Select page" title="Choose page..." data-style="btn" data-live-search="true">' +
{% 
    local allpages = _G.HTMLPAGES.getallpages()
    for k,v in pairs(allpages) do
        local pagedata = _G.HTMLPAGES.getpagedata(k)
%}
                    '<option value="{* k *}">{* pagedata.name *}</option>' +
{% end %}
                        '</select>' +
                        '</div>' +
                    '</div>' +
                    '<div class="link-save"><span class="icon-checkmark"></span></div>' +
                '</div>' +
            '</div>' +
        '</div>';
        this.button.title = 'link';
        this.on( $(this.button).on( 'click', this.handleSelect.bind(this) ));
        this.on( $(this.button).find('.link-save').on( 'click' , this.handleClose.bind(this) ));
        this.on( $(this.button).find('ul.nav li').on( 'click', this.handleTabSelect.bind(this) ));
        },

        getButton: function () {
            return this.button;
        },
        
        handleTabSelect: function(event) {
            var oldtab = $(this).find('ul.nav li .active');
            var newtab = $(event.target);
            
            $(this.button).find('.tab-content .tab-pane').each( function() {
                $(this).removeClass('active');
                if('#' + $(this).attr('id') == newtab.attr('href'))
                    $(this).addClass('active');
            });
            
            newtab.addClass('active');     
        },

        handleSelect: function (event) {
            
            var thistool = $(this.button).find(".dropdown-static");

            if( !thistool.hasClass('open') && !thistool.hasClass('delay-reopen')) {
                current_selected_object = window.getSelection().getRangeAt(0);
                
                thistool.addClass("open");
            } 
            
            else if(thistool.hasClass('delay-reopen')) {
                thistool.removeClass('delay-reopen');      
            }
        },
        
        handleClose: function(event) {
            var thistool = $(this.button).find(".dropdown-static");
            var pageset = $(this.button).find("ul.nav li.active").text();
            var linkval = "undefined";
               
            if( pageset.localeCompare("Page") == 0 ) {
                linkval = "/" + thistool.find('#link-page div.btn-group button').attr('title');
            }
            if( pageset.localeCompare("Blog" ) == 0 ) {
                linkval = "/" + thistool.find('#link-blog div.btn-group button').attr('title');
            }
            if( pageset.localeCompare("URL") == 0 ) {
                linkval = "http://" + $('#link-url input').val();
            }
            
            console.log(pageset, linkval);
            if( linkval.localeCompare("undefined") != 0 ) {
                var newNode = "<a href =" + linkval + "></a>";
                var imgobj = $(current_selected_object.startContainer).find('img');
                console.log("Images:", imgobj);
                if(imgobj.length > 0)
                    $(imgobj).attr('onclick', "loadHtml('"+ linkval +"')");
                else
                    $(current_selected_object.startContainer).wrap(newNode);
            }

            if( thistool.hasClass('open')) {
                thistool.removeClass("open");
                thistool.addClass("delay-reopen");
            } 
        }
    });

    var Imagecolumns = MediumEditor.Extension.extend({
      name: 'imagecolumns',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.uid = $('select').uniqueId().attr('id');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<select id="imagecolumns'+this.button.uid+'" class="selectpicker" data-style="btn">' +
                    '<option value="1">1</option>' +
                    '<option value="2">2</option>' +
                    '<option value="3">3</option>' +
                    '<option value="4">4</option>' +
                    '<option value="6">6</option>' +
                    '</select>';
        this.button.title = 'imagecolumns';
        this.on(this.button, 'change', this.handleSelect.bind(this));
      },

      getButton: function () {
        return this.button;
      },

        handleSelect: function (event) {

            // Replace selected html
            var noofcolumns = $( "#imagecolumns" + this.button.uid ).val();

            if($(current_image_selected).closest(".container").children().hasClass('image-grid')) {
                if(noofcolumns == "1")  {
                    $(current_image_selected).closest(".container").children().children().removeClass();
                    $(current_image_selected).closest(".container").children().children().addClass("image-container").addClass('col-md-12');
                } else if(noofcolumns == "2") {
                    $(current_image_selected).closest(".container").children().children().removeClass();
                    $(current_image_selected).closest(".container").children().children().addClass("image-container").addClass('col-md-6');
                } else if(noofcolumns == "3"){
                    $(current_image_selected).closest(".container").children().children().removeClass();
                    $(current_image_selected).closest(".container").children().children().addClass("image-container").addClass('col-md-4');
                } else if(noofcolumns == "4"){
                    $(current_image_selected).closest(".container").children().children().removeClass();
                    $(current_image_selected).closest(".container").children().children().addClass("image-container").addClass('col-md-3');
                } else if(noofcolumns == "6"){
                    $(current_image_selected).closest(".container").children().children().removeClass();
                    $(current_image_selected).closest(".container").children().children().addClass("image-container").addClass('col-md-2');
                }
            } else if($(current_image_selected).closest(".container").children().hasClass('image-carousel')){
                var imagecarouselselected = $(current_image_selected).closest(".container").children('.image-carousel');
               if(noofcolumns == "1")  {
                  $(imagecarouselselected).slick('slickSetOption', {
                      infinite: true,
                      slidesToShow: 1,
                      slidesToScroll: 1
                  });
                } else if(noofcolumns == "2") {
                  $(imagecarouselselected).slick('slickSetOption', {
                      infinite: true,
                      slidesToShow: 2,
                      slidesToScroll: 1
                  });
                } else if(noofcolumns == "3"){
                  $(imagecarouselselected).slick('slickSetOption', {
                      infinite: true,
                      slidesToShow: 3,
                      slidesToScroll: 1
                  });
                } else if(noofcolumns == "4"){
                  $(imagecarouselselected).slick('slickSetOption', {
                      infinite: true,
                      slidesToShow: 4,
                      slidesToScroll: 1
                  });
                } else if(noofcolumns == "6"){
                  $(imagecarouselselected).slick('slickSetOption', {
                      infinite: true,
                      slidesToShow: 6,
                      slidesToScroll: 1
                  });
                }

                $(imagecarouselselected).slick('setPosition');


            } else if($(current_image_selected).closest(".container").children().hasClass('image-masonry')){
                if(noofcolumns == "1")  {
                    $(current_image_selected).closest(".container").find(".grid-sizer").css("width","100%");
                    $(current_image_selected).closest(".container").find(".image-container").css("width","100%");
                } else if(noofcolumns == "2") {
                    $(current_image_selected).closest(".container").find(".grid-sizer").css("width","50%");
                    $(current_image_selected).closest(".container").find(".image-container").css("width","50%");
                } else if(noofcolumns == "3"){
                    $(current_image_selected).closest(".container").find(".grid-sizer").css("width","33.33%");
                    $(current_image_selected).closest(".container").find(".image-container").css("width","33.33%");
                } else if(noofcolumns == "4"){
                    $(current_image_selected).closest(".container").find(".grid-sizer").css("width","25%");
                    $(current_image_selected).closest(".container").find(".image-container").css("width","25%");
                } else if(noofcolumns == "6"){
                    $(current_image_selected).closest(".container").find(".grid-sizer").css("width","16.66%");
                    $(current_image_selected).closest(".container").find(".image-container").css("width","16.66%");
                }
                var $grid = $('.image-masonry').imagesLoaded( function() {
                  $('.image-masonry').masonry({
                      itemSelector: '.image-container',
                      columnWidth: '.grid-sizer',
                      percentPosition: true
                  });
              });
            }

            this.base.checkContentChanged();
        }
    });

    var Imagetag = MediumEditor.Extension.extend({
      name: 'imagetag',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-tag').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-tag"></span>';
        this.button.title = 'imagetag';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          $(current_image_selected).addClass('image-shoptag');
          $(current_image_selected).find('img').addClass('image-shoptag-img');
            pinInit(); 
            pinDocClickClose(); 
      }
    });

    var Imageupload = MediumEditor.Extension.extend({
      name: 'imageupload',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('select').uniqueId().attr('id');
        this.button.innerHTML= '<span id="imageuploadbtn"'+this.button.uid +' class="icon-image"></span>';
        this.button.title = 'imageupload';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {
        return this.button;
      },

      handleSelect: function (event) {
          current_selected_module = $(window.getSelection().anchorNode );
          //console.log($('#wizard_assets'));
          //var displaysel = $( "#imageuploadbtn" + this.button.uid );
          $('#wizard_assets').modal('show');
          
          var $container = $("#assets-images, #assets-videos, #assets-icons");
          $container.imagesLoaded(function () {
              $container.masonry({
                  itemSelector: '.image-container',
                  columnWidth: '.grid-sizer',
                  percentPosition: true
              });
          });
      }
    });
    

    var ImageCarouselPagination = MediumEditor.Extension.extend({
      name: 'imagecarouselpagination',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<span class="icon-dots-three-horizontal"></span>';
        this.button.title = 'imagecarouselpagination';
      },

      getButton: function () {
        return this.button;
      }
    });


    var ImageCarouselArrows = MediumEditor.Extension.extend({
      name: 'imagecarouselarrows',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-arrows').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-arrows"></span>';
        this.button.title = 'imagecarouselarrows';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {
        return this.button;
      },

      handleSelect: function (event) {
          $(current_image_selected).closest(".container").find(".slick-next").toggleClass("hide");
          $(current_image_selected).closest(".container").find(".slick-prev").toggleClass("hide");
      }
    });


    var Feedaccounts = MediumEditor.Extension.extend({
      name: 'feedaccounts',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<div class="btn-group" style="padding: 0 5px;margin: 0 -15px;"><button type="button" class="dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><span class="icon-share"></span></button><ul class="dropdown-menu"><li><a><span class="icon-rss pull-left"></span><span class="pull-right label label-info">ADD BLOG FEED</span></a><a><span class="icon-facebook pull-left"></span><span class="pull-right label label-info">CONNECT</span></a><a><span class="pull-left icon-tumblr"></span><span class="pull-right label label-info">CONNECT</span></a><a><span class="pull-left icon-twitter"></span><span class="pull-right label label-info">CONNECT</span></a><a><span class="pull-left icon-instagram"></span><span class="pull-right label label-info">CONNECT</span></a></li></div>';
        this.button.title = 'feedaccounts';
      },

      getButton: function () {
        return this.button;
      }
    });

    var Imageadd = MediumEditor.Extension.extend({
      name: 'imageadd',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-cop').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-copy"></span>';
        this.button.title = 'imageadd';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {

          if($(current_image_selected).closest(".container").children().hasClass("image-grid")) {
              var newimage = $(current_image_selected).closest(".container").find( ".image-container" ).first().clone();
              $(current_image_selected).parent().append(newimage);
          } else if($(current_image_selected).closest(".container").children().hasClass("image-carousel")) {
              var carouselcontainer = $(current_image_selected).closest(".container").children(".image-carousel");
              var newimage = $(current_image_selected).closest(".container").find( ".image-container" ).first().clone();
              $(carouselcontainer).slick('slickAdd', newimage);
          } else if($(current_image_selected).closest(".container").children().hasClass("image-masonry")) {
              var newimage = $(current_image_selected).closest(".container").find( ".image-container" ).first().clone();

              var masonrycontainer = $(current_image_selected).closest(".container").children(".image-masonry");
              $(masonrycontainer).append( newimage ).masonry( 'appended', newimage );
          }
          ApplyMediumEditor();
      }
    });

    var Imagescale = MediumEditor.Extension.extend({
      name: 'imagescale',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-photo_size_select_large').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-photo_size_select_large"></span>';
        this.button.title = 'imagescale';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          $(current_image_selected).toggleClass("img-fullwidth");
          var $grid = $('.image-masonry').masonry({
              itemSelector: '.image-container',
              columnWidth: '.grid-sizer',
              percentPosition: true
          });
          $grid.masonry('reloadItems');
          $('.image-carousel').slick('setPosition');

      }
    });

    var Padding = MediumEditor.Extension.extend({
      name: 'padding',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-enlarge2').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-checkbox-unchecked"></span>';
        this.button.title = 'padding';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          $(current_image_selected).closest(".container").find(".image-container").toggleClass('padding');
          var $grid = $('.image-masonry').masonry({
          itemSelector: '.image-container',
          columnWidth: '.grid-sizer',
          percentPosition: true
        });
        $grid.masonry('reloadItems');
      }
    });

    var Imagedelete = MediumEditor.Extension.extend({
      name: 'imagedelete',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-bin').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-bin"></span>';
        this.button.title = 'imagedelete';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {

          if($(current_image_selected).closest(".container").children().hasClass("image-grid")) {

              $(current_image_selected).remove();

          } else if($(current_image_selected).closest(".container").children().hasClass("image-carousel")) {

              var carouselcontainer = $(current_image_selected).closest(".container").children(".image-carousel");
              var deleteimagecarousel = $(current_image_selected);

              $(carouselcontainer).slick('slickRemove',deleteimagecarousel);

          } else if($(current_image_selected).closest(".container").children().hasClass("image-masonry")) {

              var deleteimagemasonry = $(current_image_selected);
              var masonrycontainer = $(current_image_selected).closest(".container").children(".image-masonry");

              $(masonrycontainer).masonry( 'remove', deleteimagemasonry );

          }

          $(current_image_selected).remove();
          $('.image-masonry').masonry('layout');

      }
    });

    var Iconsize = MediumEditor.Extension.extend({
      name: 'iconsize',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('select').uniqueId().attr('id');
        this.button.innerHTML = '<select id="iconsize'+this.button.uid+'" class="selectpicker" data-style="btn">' +
                    '<option value="small" data-content="<span class=\"icon-icon-small\"></span>"></option>' +
                    '<option value="medium" data-content="<span class=\"icon-icon-medium\"></span>"></option>' +
                    '<option value="large" data-content="<span class=\"icon-icon-large\"></span>"></option>' +
                    '</select>';
        this.button.title = 'iconsize';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          var iconsizeselected = $( "#iconsize" + this.button.uid ).val();

          if(iconsizeselected == "small")  {
            $(current_image_selected).find("img").removeClass("img-md").removeClass("img-lg");
            $(current_image_selected).find("img").addClass("img-sm");
          } else if(iconsizeselected == "medium") {
            $(current_image_selected).find("img").removeClass("img-sm").removeClass("img-lg");
            $(current_image_selected).find("img").addClass("img-md");
          } else if(iconsizeselected == "large") {
            $(current_image_selected).find("img").removeClass("img-sm").removeClass("img-md");
            $(current_image_selected).find("img").addClass("img-lg");
          }
      }
    });

var Iconshape = MediumEditor.Extension.extend({
      name: 'iconshape',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('select').uniqueId().attr('id');
        this.button.innerHTML = '<select id="iconshape'+this.button.uid+'" class="selectpicker" data-style="btn">' +
                    '<option value="square" data-content="<span class=\"icon-icon-square\"></span>"></option>' +
                    '<option value="circle" data-content="<span class=\"icon-icon-circle\"></span>"></option>' +
                    '</select>';
        this.button.title = 'iconshape';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          var iconshapeselected = $( "#iconshape" + this.button.uid ).val();

          if(iconshapeselected == "square")  {
            $(current_image_selected).closest("li").removeClass("img-circle");
            $(current_image_selected).closest("li").addClass("img-square");
          } else if(iconshapeselected == "circle") {
            $(current_image_selected).closest("li").removeClass("img-square");
            $(current_image_selected).closest("li").addClass("img-circle");
          }
      }
    });

var Iconstyle = MediumEditor.Extension.extend({
      name: 'iconstyle',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('select').uniqueId().attr('id');
        this.button.innerHTML = '<select id="iconstyle'+this.button.uid+'" class="selectpicker" data-style="btn">' +
                    '<option value="fill" data-content="<span class=\"icon-stop2\"></span>"></option>' +
                    '<option value="border" data-content="<span class=\"icon-checkbox-unchecked\"></span>"></option>' +
                    '<option value="none" data-content="<span class=\"icon-x\"></span>"></option>' +
                    '</select>';
        this.button.title = 'iconstyle';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          var iconstyleselected = $( "#iconstyle" + this.button.uid ).val();

          if(iconstyleselected == "fill")  {
            $(current_image_selected).closest("li").removeClass("img-border");
            $(current_image_selected).closest("li").addClass("img-fill");
          } else if(iconstyleselected == "border") {
            $(current_image_selected).closest("li").removeClass("img-fill");
            $(current_image_selected).closest("li").addClass("img-border");
          } else if(iconstyleselected == "none") {
            $(current_image_selected).closest("li").removeClass("img-fill").removeClass("img-border");
          }
      }
    });

var Icondelete = MediumEditor.Extension.extend({
      name: 'icondelete',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<span class="icon-bin"></span>';
        this.button.title = 'icondelete';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          $(current_image_selected).closest("li").remove();
      }
    });

var Iconadd = MediumEditor.Extension.extend({
      name: 'iconadd',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<span class="icon-copy"></span>';
        this.button.title = 'iconadd';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          var newicon = $(current_image_selected).closest(".container").find( "li" ).first().clone();
          $(current_image_selected).closest("ul").append(newicon);

          ApplyMediumEditor();
      }
    });

    var Iconselect = MediumEditor.Extension.extend({
      name: 'iconselect',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.uid = $('.icon-icons').uniqueId().attr('id');
        this.button.innerHTML = '<span class="icon-icons"></span>';
        this.button.title = 'iconselect';
        this.on(this.button, 'click', this.handleSelect.bind(this));
      },

      getButton: function () {

        return this.button;
      },

      handleSelect: function (event) {
          $('#wizard_assets').modal('show');
      }
    });

    var Featuredposts = MediumEditor.Extension.extend({
      name: 'featuredposts',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<div class="btn-group" style="padding: 0 5px;margin: 0 -15px;"><button type="button" class="dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><span class="icon-cog"></span></button><ul class="dropdown-menu"><li>Sort by</li><li><span class="pull-left">Filter</span><span class="pull-right label label-info">ADD</span></li><li><span class="pull-left">Rule</span><span class="pull-right label label-info">ADD</span></li></div>';
        this.button.title = 'featuredposts';
      },

      getButton: function () {
        return this.button;
      }
    });

    var Infinteposts = MediumEditor.Extension.extend({
      name: 'infinteposts',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<div class="btn-group" style="padding: 0 5px;margin: 0 -15px;"><button type="button" class="dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Infinite posts/no.of posts</button><ul class="dropdown-menu"><input class="spinner" name="value" value="2"></div>';
        this.button.title = 'infinteposts';
      },

      getButton: function () {
        return this.button;
      }
    });

    var Feedsettings = MediumEditor.Extension.extend({
      name: 'feedsettings',

      init: function () {
        this.button = this.document.createElement('button');
        this.button.classList.add('medium-editor-action');
        this.button.innerHTML = '<div class="btn-group" style="padding: 0 5px;margin: 0 -15px;"><button type="button" class="dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><span class="icon-cogs"></span></button><ul class="dropdown-menu"></div>';
        this.button.title = 'feedsettings';
      },

      getButton: function () {
        return this.button;
      }
    });

    //$(".module-mediagrid img").wrap("<figure contenteditable=\"false\"></figure>");

    menu_texteditor = new MediumEditor('.editable', {
        toolbar: {
            buttons: ['fontfamily', 'heading', 'bold', 'italic', 'textalign', 'link', 'button'  ]
        },
        extensions: {
            'textalign': new TextalignButton(),
            'fontfamily': new FontfamilyButton(),
            'heading': new HeadingButton(),
            'button': new Button(),
            'link': new Link()
        }

    });

    menu_feed = new MediumEditor('.module-feed', {
        toolbar: {
          buttons: ['feedaccounts', 'featuredposts', 'infinteposts', 'feedsettings' ]
        },
        extensions: {
            'feedacounts': new Feedaccounts(),
            'featuredposts': new Featuredposts(),
            'infinteposts': new Infinteposts(),
            'feedsettings': new Feedsettings()
        }
    });


    menu_imageeditor = new MediumEditor('.image-editor', {
        toolbar: {
          buttons: ['imagedisplay', 'imagecolumns', 'imagecarouselarrows', 'padding', 'imageupload', 'imagetag', 'link', 'imagescale', 'imageadd', 'imagedelete' ]
        },
        extensions: {
            'imagedisplay': new Imagedisplay(),
            'imagecolumns': new Imagecolumns(),
            'imageupload': new Imageupload(),
            'imagetag': new Imagetag(),
            'imagecarouselarrows': new ImageCarouselArrows(),
            'link': new Link(),
            'imageadd': new Imageadd(),
            'imagedelete': new Imagedelete(),
            'padding': new Padding(),
            'imagescale': new Imagescale()
        }

    });

    menu_iconeditor = new MediumEditor('.icon-editor', {
        toolbar: {
          buttons: ['iconselect', 'iconsize', 'iconshape', 'iconstyle', 'link', 'iconadd', 'icondelete' ]
        },
        extensions: {
            'iconselect': new Iconselect(),
            'iconsize': new Iconsize(),
            'iconshape': new Iconshape(),
            'iconstyle': new Iconstyle(),
            'link': new Link(),
            'iconadd': new Iconadd(),
            'icondelete': new Icondelete()
        },
    });
    
    $('.selectpicker').selectpicker();
}

function ApplyMediumEditor(element)
{
    if(element) {
        //console.log(element);
        // Check element if it needs to be added to any of the editors
        var child;
        child = null;
        if( $(element).hasClass("editable") ) child = element;
        if(!child) child = $(element).find(".editable");
        if(child) menu_texteditor.addElements(child);
        child = null;
        if( $(element).hasClass("image-editor") ) child = element;
        if(!child) child = $(element).find(".image-editor");
        if(child) {
            //console.log("adding Child:", child);
            menu_imageeditor.addElements(child);
        }
        child = null;
        if( $(element).hasClass("icon-editor") ) child = element;
        if(!child) child = $(element).find(".icon-editor");
        if(child) {
            //console.log("adding Child:", child);
            menu_imageeditor.addElements(child);
        }
        child = null;
        InitModuleeditpanel();

    }

    $('.page__main img').click( function(event){
        var pelement = $(this).parent();
        current_image_selected = pelement[0];
        window.getSelection().selectAllChildren(pelement[0]);
    });

}

function ApplyHolder()
{
    $("img:not([src])").each( function() {
      Holder.run({ images: this });
    });
}
</script>