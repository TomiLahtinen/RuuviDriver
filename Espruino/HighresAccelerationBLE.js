var Ruuvitag = require("Ruuvitag");
var shaken = false;
var on = false;
var highresMode = false;

function onInit() {
  console.log("Start services");
  var services = NRF.setServices({
    0xBCDE:{
      0xABCD:{
        value: new Uint8Array([0,0]),
        notify: true,
        indicate: true
      },
      0xBCDE:{
        value: new Uint8Array([0,0]),
        notify: true,
        indicate: true
      },
      0xCDEF:{
        value: new Uint8Array([0,0]),
        notify: true,
        indicate: true
      }
    }
  });
  console.log("Power up accelerometer");
  Ruuvitag.setAccelOn(true, function(data) {
    console.log("update values", data);
    var x = hexToBytes(dec2hex(data.x));
    var y = hexToBytes(dec2hex(data.y));
    var z = hexToBytes(dec2hex(data.z));
    console.log("x", x, "y", y, "z", z);
    NRF.updateServices({
      0xBCDE:{
        0xABCD:{
          value: x,
          notify: true
        },
        0xBCDE:{
          value: y,
          notify: true
        },
        0xCDEF:{
          value: z,
          notify: true
        }
      }
    });
  });
  Ruuvitag.accel.setPowerMode("low");
  LED2.write(!highresMode);
}

setWatch(function() {
  console.log("Button clicked");
  highresMode = !highresMode;
  LED2.write(!highresMode);
  Ruuvitag.accel.setPowerMode(highresMode ? "highres" : "low");
}, BTN, { repeat:true, edge:'rising', debounce: 50 });

function dec2hex(i) {
   return (Math.floor(i)+0x10000).toString(16).substr(-4);
}

// Convert a hex string to a byte array
function hexToBytes(h) {
    for (var ret = [], c = 0; c < h.length; c += 2)
    ret.push(parseInt(h.substr(c, 2), 16));
    return ret;
}