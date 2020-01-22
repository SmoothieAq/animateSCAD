
use <lib/animateSCADcamera.scad>

function cpoint(cameraAbsolute,cameraTranslate,cameraRotate,viewAtAbsolute,viewAtTranslate,viewAtRotate,zoom,speed,time,accel,pname) =
	cpointx([],cameraAbsolute=cameraAbsolute,cameraTranslate=cameraTranslate,cameraRotate=cameraRotate,
				viewAtAbsolute=viewAtAbsolute,viewAtTranslate=viewAtTranslate,viewAtRotate=viewAtRotate,
				zoom=zoom,speed=speed,time=time,accel=accel,pname=pname);

function camera(cpoints,fps,t,frameNo) = _camera(cpoints,fps,t,frameNo);

module animation(showPath=0) { _animation(showPath) children(); }
