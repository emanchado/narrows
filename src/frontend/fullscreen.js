function inFullscreen() {
    return [
        "fullScreenElement",
        "mozFullScreenElement"
    ].some(function(attribute) {
        return document[attribute];
    });
}

function enterFullscreen() {
    const element = document.body;

    ["requestFullscreen",
     "mozRequestFullscreen",
     "msRequestFullscreen",
     "webkitRequestFullscreen"].forEach(function(method) {
         if (element[method]) {
             element[method]();
             return false;
         }
         return true;
     });
}

function exitFullscreen() {
    ["exitFullscreen",
     "mozCancelFullScreen",
     "msExitFullscreen",
     "webkitExitFullscreen"].forEach(function(method) {
         if (document[method]) {
             document[method]();
             return false;
         }
         return true;
     });
}

module.exports.inFullscreen = inFullscreen;
module.exports.enterFullscreen = enterFullscreen;
module.exports.exitFullscreen = exitFullscreen;
