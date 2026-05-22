<script src="/scripts/fullscreenForm.js"></script>
<script src="/scripts/selectFx.js"></script>

<script>
    var featurescounter = 0;    
    var pagecounter = 3;
    var referencecounter = 0;
    var competitorcounter = 0;
    

$(document).ready( function(){

    function initFormWrap() {
        var formWrap = document.getElementById( 'fs-form-wrap' );

        [].slice.call( document.querySelectorAll( 'select.cs-select' ) ).forEach( function(el) {	
            new SelectFx( el, {
                stickyPlaceholder: false,
                onChange: function(val){
                    document.querySelector('span.cs-placeholder').style.backgroundColor = val;
                }
            });
        } );

        new FForm( formWrap, {
            onReview : function() {
                classie.add( document.body, 'overview' ); // for demo purposes only
            }
        } );

        $('#webdesignplan_submit').click(function(e){
            e.preventDefault();
            var json = ConvertFormToJSON();
            json['userpassword'] = "**********";
            //console.log(json);
            var jsonString = JSON.stringify(json);
            //console.log(jsonString);
            $.post('/functions/submit', jsonString, formCompleteSuccess );
        });
    };

    $(".redesign-yes").hide();
    $(".current-domain-yes").hide();
    $(".content-designerprovided-yes").hide();
    $(".deadline-yes").hide();
    $(".maintenance-yes").hide();
    $(".content-pages-yes").hide();

    $('#redesign').click(function(){
    if($(this).is(':checked')) {
        $(".redesign-yes").slideDown();
    } else {
        $(".redesign-yes").slideUp();
    };
    });


    $('#visualidentity-brandingguide').click(function(){
    if($(this).is(':checked')) {
        $(".visualidentity-brandingguide-no").slideUp();
    } else {
        $(".visualidentity-brandingguide-no").slideDown();
    };
    });

    $('#current-domain').click(function(){
    if($(this).is(':checked')) {
        $(".current-domain-yes").slideDown();
        $(".current-domain-no").slideUp();
    } else {
        $(".current-domain-yes").slideUp();
        $(".current-domain-no").slideDown();
    };
    });

    $('#deadline').click(function(){
    if($(this).is(':checked')) {
        $(".deadline-yes").slideDown();
    } else {
        $(".deadline-yes").slideUp();
    };
    }); 

    $('#content-designerprovided').click(function(){
    if($(this).is(':checked')) {
        $(".content-designerprovided-yes").slideDown();
    } else {
        $(".content-designerprovided-yes").slideUp();
    };
    }); 

    $('#maintenance').click(function(){
    if($(this).is(':checked')) {
        $(".maintenance-yes").slideDown();
    } else {
        $(".maintenance-yes").slideUp();
    };
    });
      $('.content-pages').sortable({
        items: ".page"
    });              
    $('#content-pages').click(function(){
    if($(this).is(':checked')) {
        $(".content-pages-yes").slideDown();
    } else {
        $(".content-pages-yes").slideUp();
    };
    });  

    $('#newpage').on('click', function(){
        var newpagename = $('#newpagename').val();
        if( newpagename ) {
            pagecounter = pagecounter + 1;
        $('.content-pages').append(`<div class="page"><div class="delete-reference"><span class="icon-x"></span></div>
            <input id="page-` + pagecounter +`" name="page-` + pagecounter +`" value="` + newpagename + `" />
        </div>`);
        $('#newpagename').val('');
            $('.content-pages').sortable('refresh');
        }
    });

    $( ".slider" ).slider({
        value:3,
        min: 0,
        max: 6,
        step: 1
    });

    $('#add-reference').on('click', function(){
        var newreference = $('#reference').val();
        if( newreference ) {
            referencecounter = referencecounter + 1;
        $('.website-references').append(`<div class="reference">
            <div class="delete-reference"><span class="icon-x"></span></div>
            <input id="reference-` + referencecounter + `" name="reference-` + referencecounter + `" value="` + newreference + `" />
            <label>What do you like about this site?</label>
            <textarea id="reference-` + referencecounter + `-text" name="reference-` + referencecounter + `-text"rows="5" placeholder="I like....."></textarea>
        </div><hr />`);
        $('#reference').val('');
        }
    });
    
    $('.website-references').on('click',".delete-reference", function(){
        $(this).parent().remove();
    });
    
    $('.content-pages').on('click',".delete-reference", function(){
        $(this).parent().remove();
    });

    $('#add-competitor').on('click', function(){
      var newcompetitor = $('#competitor').val();
        if( newcompetitor ) {
            competitorcounter =  competitorcounter + 1;
            $('.website-competitors').append(`<div class="competitor">
                <div class="delete-competitor"><span class="icon-x"></span></div>
                <input id="competitor-` + competitorcounter + `" name="competitor-` + competitorcounter + `" value="` + newcompetitor + `" />
            </div>`);
            $('#competitor').val('');

        }
    });

    $('.website-competitors').on('click',".delete-competitor", function(){
        $(this).parent().remove();
    });
    
    $('#addmultiple-features').on('click', function(){
        $('#FeaturesModal').modal('show');
    });

    $('#featureslist-add').on('click', function(){
        $('#FeaturesModal input').each(function(){
          if( $(this).is(':checked')){
              featurescounter = featurescounter + 1;
              var thisinputid = $(this).val();
              $('#requirementslist').append(`<li><div class="delete-requirement"><span class="icon-x"></span></div>
<input id="feature-` + featurescounter + `" name="feature-` + featurescounter + `" value="` + thisinputid + `" /></li>`);
              $('#requirementslist').sortable('refresh');
          }
        }); 
        $('#FeaturesModal').modal('hide');
    });

    $('#requirementslist').sortable({
        items: "li:not(.ui-state-disabled)"
    });
    $('#newrequirement').click( function(){
        var newrequirementtext = $('#newrequirementtext').val();
        if ( newrequirementtext ){
            featurescounter = featurescounter + 1;
        $('#requirementslist').append(`<li>
            <div class="delete-requirement"><span class="icon-x"></span>
            </div><input id="feature-` + featurescounter + `" name="feature-` + featurescounter + `" value="` + newrequirementtext + `" /></li>`);
        $('#requirementslist').sortable('refresh');
        $('#newrequirementtext').val('');
        }
    });

    $('#requirementslist').on('click',".delete-requirement", function(){
        $(this).parent().remove();
    });

    checkUser(initFormWrap);
});
</script>