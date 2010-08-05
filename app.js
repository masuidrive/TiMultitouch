// this sets the background color of the master UIView (when there are no windows/tab groups on it)
Ti.UI.setBackgroundColor('#000');
require("multitouch");

var window = Ti.UI.createWindow({  
    backgroundColor:'#fff',
    fullscreen: true
});

var scale = 1.0;

function calcDistance(x1, y1, x2, y2) {
    return Math.sqrt(Math.pow(x2-x1,2)+Math.pow(y2-y1,2));
}

var imageView = Ti.UI.createImageView({
    image: "sample.jpg",
    transform: Ti.UI.create2DMatrix().scale(scale)
});

var start_scale = scale;
var distance = 0.0;
var touchstart_point = {x:0, y:0};
var touchstart_view = {left:0, top:0};
window.addEventListener('touchstart', function(ev) {
    Ti.API.info(ev);
    if(ev.points.length>1) {
	start_scale = scale;
	distance = calcDistance(ev.points[0].x, ev.points[0].y, ev.points[1].x, ev.points[1].y);
    }
    else {
	Ti.API.info(ev);
	touchstart_point.x = ev.x;
	touchstart_point.y = ev.y;
	touchstart_view.left = imageView.left || 0;
	touchstart_view.top = imageView.top || 0;
    }
});
window.addEventListener('touchmove', function(ev) {
    Ti.API.info(ev);
    if(ev.points.length>1) {
	scale = start_scale * (calcDistance(ev.points[0].x, ev.points[0].y, ev.points[1].x, ev.points[1].y) / distance);
	imageView.transform = Ti.UI.create2DMatrix().scale(scale);
    }
    else {
	imageView.left = touchstart_view.left + (ev.x - touchstart_point.x);
	imageView.top = touchstart_view.top + (ev.y - touchstart_point.y); 
    }
});

window.addEventListener('touchend', function(ev) {
    Ti.API.info(ev);
    // can't handle multi touch in 'touchend' and 'touchcancel' event.
});

window.addEventListener('singletap', function(ev) {
    // DON'T REMOVE THIS LISTENER!!
    // hack for multi touch module
});


window.open();