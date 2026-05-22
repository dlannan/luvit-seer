<script>
var checkSimReq;

// TODO: Make this work withouth chrome errors! (might not be possible).
function CheckAlive() {

  var host = "https://sim.kakutai.com:3000/gr/data.json/simdata/";
  var userTimeout = 2000;

  if(checkSimReq == undefined) 
    checkSimReq = new XMLHttpRequest();         // this is the request we'll use to test the host

  if(checkSimReq.readyState != 0)
    return;

  checkSimReq.open('GET', host, true);            // async http GET from host
  checkSimReq.timeout = userTimeout;                        // Infinite timer - setTimeout() controls length

  checkSimReq.finished = function () { 
    globalSimUpdate.process = "none";
    console.log("finished", this.readyState );
  };
  checkSimReq.ontimeout = function (e) { 
    // console.log("timeout", this.readyState);
    this.abort();
    this.finished();
  };
  checkSimReq.onabort   = function (e) { 
    console.log("abort");
    this.finished();
  };
  checkSimReq.onerror   = function (e) { 
    // console.log("error");    
    this.abort();
    this.finished();
  };

  checkSimReq.onload = function() {
    if (this.readyState == 4 && this.status == 200) {
      runSimStatusUpdate(this.responseText);
    }
    else {
      //console.log("readyState " + req.readyState + ", statusText: " + req.statusText);
      this.abort();
      this.finished();
      console.log("not sent.");
    }
  };

  try { checkSimReq.send(); } catch( err ) {
    console.log( 'Error getting data: ' + err.message );
  }
}

var globalSimUpdate = {
  process: "none",
  connect: "not connected" 
};

function runSimStatusUpdate(data) {
console.log(data);
  if(data.length > 0){
    data.forEach(function(entry) {

      if(entry.status === "RESETING") {            
        $("#scenestatus_" + entry.sceneid).html('<i class="fas fa-circle-notch fa-spin" style="color: orange;"></i>');
      } else if(entry.status === "RUNNING") {            
        $("#scenestatus_" + entry.sceneid).html('<i class="fas fa-play" style="color: #0f0;"></i>');
      } else if(entry.status === "STOPPED") {            
        $("#scenestatus_" + entry.sceneid).html('<i class="fas fa-circle" style="color: #f00;"></i>');
      } else {            
        $("#scenestatus_" + entry.sceneid).html('<i class="fas fa-bolt" style="color: #f00;"></i>');
      }

      if(isNaN(entry.clients) === false) {            
        var clientperc = parseFloat(entry.clients) / 10.0;
        $("#scenestatus_clients_" + entry.sceneid).attr("data-value", clientperc.toString());   
        $("#scenestatus_clients_value_" + entry.sceneid).text( entry.clients );
      }

      if(entry.lasttime) {
        $("#scenestatus_lasttime_" + entry.sceneid).text(entry.lasttime);   
      }

      if(entry.runtime) {
        var monthrun = entry.runtime / ( 30.0 * 24.0 * 60.0 * 60.0 );
        $("#scenestatus_runtime_" + entry.sceneid).html("<strong>" + Number.parseFloat(monthrun).toFixed(0) + "%</strong>");  
      }
    });
  }
}

</script>
