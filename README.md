Multi touch module Appcelerator Titanium iPhone 1.7.2
===========================================

Handle multi touch event on your iPhone.

This module for Titanium Mobile 1.7.2


INSTALL
--------------

	./build.py && rm -Rf /Library/Application\ Support/Titanium/modules/iphone/multitouch/ && unzip multitouch-iphone-0.1.zip -d /Library/Application\ Support/Titanium/

If you have another Titanium Mobile SDK version, please change the value of the "TITANIUM_SDK_VERSION" property in titanium.xcconfig to match your desired version.

HOW TO USE IT
-------------
1. Add the multitouch module to your tiapp.xml: inside the `modules` tag add the following line:
	`<module version="1.0">multitouch</module>`
2. Add the following code in the beginning of your app.js:
	`require("multitouch");`
3. To enable multitouch for a window or a view, add an empty event listener to the 'singletap' event 
	(see example below).
4. Now your touchstart/touchmove/touchend/touchcancel events will contain a new field: "points". 
	This field is a dictionary with information about the active touches: the key is the id of the touch, 
	and the value is an object with the following properties: 'x', 'y' and 'globalPoint'.

CODE EXAMPLE
--------------

	require("multitouch");
	
	win.addEventListener('singletap', function(event) {
		// DON'T REMOVE THIS LISTENER!!
		// hack for multi touch module
	});
	
	win.addEventListener("touchstart", function(event) {
		Ti.API.info("Touches started, points: " + event.points);
	});

	win.addEventListener("touchmove", function(event) {
		Ti.API.info("Touches moved, points: " + event.points);
	});
	
	win.addEventListener("touchend", function(event) {
		Ti.API.info("Touches ended, points: " + event.points);
	});
	
	win.addEventListener("touchcanceled", function(event) {
		Ti.API.info("Touches canceled, points: " + event.points);
	});

For more info, Please check [app.js](examples/app.js)


LICENSE
--------------
MIT License


COPYRIGHT
--------------
* 2011 Uri Shaked ([urish](https://github.com/urish))
* 2011 Jose Fernandez (magec) github.com/magec (small change and tested in 1.6.2)
* 2010 Yuchiro MASUI (masuidrive) <masui@masuidrive.jp>
