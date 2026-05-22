<script>
    
var userCheckCB = null;

function savedSuccess() {
    $('body').prepend(
               '<div class="alert alert-success alert-icon alert-dismissible" role="alert">' +
                    '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
                        '<span aria-hidden="true">&times;</span>' +
                    '</button>' +
                    '<strong>Page has been saved successfully </strong>'
    );
    setTimeout(function() {
        $('.alert').remove();
    }, 4000);
}

function savedFailed() {
    $('body').prepend(
               '<div class="alert alert-danger alert-icon alert-dismissible" role="alert">' +
                    '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
                        '<span aria-hidden="true">&times;</span>' +
                    '</button>' +
                    '<strong>Login failed. Try again.</strong>'
    );
    setTimeout(function() {
        $('.alert').remove();
    }, 4000); 
}

function userCheckSuccess() {
    $('body').prepend(
               '<div class="alert alert-success alert-icon alert-dismissible" role="alert">' +
                    '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
                        '<span aria-hidden="true">&times;</span>' +
                    '</button>' +
                    '<strong>User successfully identified.</strong>'
    );
    setTimeout(function() {
        $('.alert').remove();
    }, 4000);
}

function formCompleteSuccess() {
    $('body').prepend(
               '<div class="alert alert-success alert-icon alert-dismissible" role="alert">' +
                    '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
                        '<span aria-hidden="true">&times;</span>' +
                    '</button>' +
                    '<strong>Form Completed Successfully.</strong>'
    );
    setTimeout(function() {
        $('.alert').remove();
    }, 4000);
}

// Send the update content to the server to be saved
function onStateChange(body, code, ev) {
    //console.log($(this), ev, code)
    if(ev.status == 200) {
        // Save was successful, notify the user with a flash
        //console.log("user logged in.");
        savedSuccess();
    } else {
        // Save failed, notify the user with a flash
        //console.log("user not logged in.");
        $('#wizard_login').modal ({
            backdrop: 'static',
            keyboard: 'false',
            show: 'true'
        });
    }
}

// Send the update content to the server to be saved
function onLoginCheck(body, code, ev) {
    //console.log( window.location.pathname)
    if(ev.status == 200) {
      $.ajax({
          url: window.location.pathname + "/save",
          data: payload,
          processData: false,
          contentType: false,
          type: 'POST',
          success: onStateChange
      });
    }
    else if(ev.status == 201) {
        //console.log("Console login... ");
        $('#wizard_login').modal ({
            backdrop: 'static',
            keyboard: 'false',
            show: 'true'
        });
    }
}

function onSavedComplete(data, status, xhr) {

    // do something here with response;
    if(xhr.status == 200) {
        // Insert Login success
        $("#wizard_login").modal('hide');
        setCookie('userId', data, 1);
        savedSuccess();
        return;
    }
    // Can potentially end up here forever!
    else {
        //console.log("Something has gone wrong");
        // Insert Login Failed info here!!!
        savedFailed();
    }
}

// Include id with module name
function saveModule(indata) {
    
    $('#wizard_login_submit').click(function(e){
        e.preventDefault();

        var json = $('#userlogin_info').serialize();
        json = json+"&website=" + window.location.pathname;
        $.post('/functions/userlogin', json, onSavedComplete );
    });

    $('#wizard_login').on('hidden.bs.modal', function(e) {
        // If we get here, then a password and login has been accepted. Call the save
        // The save function still checks for valid user as well - no save if invlaid user
        $.ajax({
            url: window.location.pathname + "/save",
            data: payload,
            processData: false,
            contentType: false,
            type: 'POST',
            success: onStateChange
        });
        
    });
    
    payload = indata;
    $.ajax({
        url: window.location.pathname + "/check",
        data: payload,
        processData: false,
        contentType: false,
        type: 'POST',
        success: onLoginCheck
    });
}

// Send the update content to the server to be saved
function onLoginUserCheck(body, code, ev) {
    //console.log( window.location.pathname)
    if(ev.status == 200) {
        userCheckSuccess();
        if(userCheckCB != null) userCheckCB();
    }
    else if(ev.status == 201) {
        //console.log("Console login... ");
        $('#wizard_login').modal ({
            backdrop: 'static',
            keyboard: 'false',
            show: 'true'
        });
    }
}



function onUserCheckComplete(data, status, xhr) {

    // do something here with response;
    if(xhr.status == 200) {
        // Insert Login success
        $("#wizard_login").modal('hide');
        userCheckSuccess();
        // Write the cookie - this should be returned, otherwise user will have
        //   to login everytime!!!
        setCookie('userId', data, 1);
        if( userCheckCB != null ) userCheckCB(data);
        return;
    }
    // Can potentially end up here forever!
    else if(xhr.status == 201) {
        //console.log("Something has gone wrong");
        // Insert Login Failed info here!!!
        savedFailed();
    } 
    else if(xhr.status == 202) {
        // Not allowed to login anymore.. five tries.. and you are out.
    }
}

// Include id with module name
function checkUser(okfuncCB) {
        
    userCheckCB = okfuncCB;
    $('#wizard_login_submit').click(function(e){
        e.preventDefault();

        var json = $('#userlogin_info').serialize();
        json = json+"&website=" + window.location.pathname;
        $.post('/functions/userlogin', json, onUserCheckComplete );
    });
    
    $.ajax({
        url: window.location.pathname + "/check",
        data: "",
        processData: false,
        contentType: false,
        type: 'POST',
        success: onLoginUserCheck
    });
}

function checkCookie() {
    var username = getCookie("username");
    if (username != "") {
        alert("Welcome again " + username);
    } else {
        username = prompt("Please enter your name:", "");
        if (username != "" && username != null) {
            setCookie("username", username, 365);
        }
    }
}
</script>