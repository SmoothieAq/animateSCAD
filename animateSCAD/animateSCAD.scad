
use <lib/animateSCADcamera.scad>
use <lib/animateSCADpath.scad>

function cpoint(pname,pos,move,cameraAndView,standStill,speed,time,accel) =
	cpointx([],pos=pos,move=move,cameraAndView=cameraAndView,standStill=standStill,speed=speed,time=time,accel=accel,pname=pname);

function vpoint(cRel,pos,move,cameraAndView,straightAhead,standStill,zoom,accel) =
	cpointx([],cRel=cRel,pos=pos,move=move,cameraAndView=cameraAndView,straightAhead=straightAhead,standStill=standStill,zoom=zoom,accel=accel);

function camera(cpoints,vpoints=[],fps,t,frameNo) = _camera(cpoints,vpoints,fps=fps,t=t,frameNo=frameNo);

module animation(showPath=0) { _animation() showWithPath(showPath) children(); }
