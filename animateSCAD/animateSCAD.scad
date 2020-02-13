
use <lib/animateSCADcamera.scad>
use <lib/animateSCADpath.scad>

function cpoint(pname,pos,move,cameraAndView,standStill,speed,time,accel) =
	cpointx([],pos=pos,move=move,cameraAndView=cameraAndView,standStill=standStill,speed=speed,time=time,accel=accel,pname=pname);

function vpoint(cRel,pname,pos,move,cameraAndView,straightAhead,standStill,zoom,accel) =
	cpointx([],cRel=cRel,pos=pos,move=move,cameraAndView=cameraAndView,straightAhead=straightAhead,standStill=standStill,zoom=zoom,accel=accel,pname=pname);

function mpoint(pname,cRel,pos,move,standStill,speed,time,accel,color,rotate) =
	cpointx([],cRel=cRel,pos=pos,move=move,standStill=standStill,speed=speed,time=time,accel=accel,color=color,rotate=rotate,pname=pname);

function camera(cpoints,vpoints=[],fps,t,frameNo) = _camera(cpoints,vpoints,fps=fps,t=t,frameNo=frameNo);

module move(partName,mpoints) _move(partName,mpoints) children();

module animation() _animation() showWithPath() children();
