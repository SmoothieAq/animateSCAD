
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADpath.scad>
use <animateSCADspeed.scad>
use <animateSCADutil.scad>
use <animateSCADcameraUtil.scad>

include <animateSCADpointx.scad>


module _move(partName,mpoints) {
	mxps = mxpoints(partName,mpoints);
	mxxps = mxxpoints(mxps,$camera[4],$camera[5]);
	frameTime = $camera[12];
	p = findPos(mxxps,undef,frameTime);
	showPartWithPath(partName,mxps,mxxps) mmove(p,mxps,mxxps) mcolor(p) mrotate(p) children();
}

module mmove(p,mxps,mxxps) {
	if ( p[0] )
		translate(p[0]) children();
	else if ( $showPath )
		translate(mxps[0][_pos_]) children();
}

module mcolor(p) {
	children();
}

module mrotate(p) {
	children();
}


/*
This is the fist transformation from the mpoints vector to the mxpoints vector.
We cary forward speed and accel, color and rotate when they are not set, and we set prevColor and prevRotate.
 */
function mxpoints(partName,mpoints) = [ for (
		i = 0,
		p = mpoints[i],
		pos = cmove([0,0,0],p),
		speed = nnv(p[_speed_],50),
		accel = nnv(p[_accel_],100),
		color = nnv(p[_color_],[]),
		rotate = nnv(p[_rotate_],[]),
		previousColor = [],
		previousRotate = [],
		prevColor = [],
		prevRotate = [];
	i < len(mpoints);
		i = i+1,
		p = mpoints[i],
		pos = cmove(pos,p),
		speed = nnv(p[_speed_],speed),
		accel = nnv(p[_accel_],accel),
		color = nnv(p[_color_],color),
		rotate = nnv(p[_rotate_],rotate),
		prevColor = previousColor,
		prevRotate = previousRotate,
		previousColor = color,
		previousRotate = rotate
)
	/*echo("mxpoint",pos=pos,speed=speed,accel=accel,color=color,prevColor=prevColor,rotate=rotate,prevRotate=prevRotate,pname=nnv(p[_pname_],str(partName,"-",i)))*/
	cpointx(p,pos=pos,speed=speed,accel=accel,color=color,prevColor=prevColor,rotate=rotate,prevRotate=prevRotate,pname=nnv(p[_pname_],str(partName,"-",i))) ];


/*
This is the second transformation from the mxpoints vector to the mxxpoints vector.
We make sure the following are now set: splineM, startSpeed, speed, startTime and time
 */
function mxxpoints(mxpoints,cxpoints,cxxpoints) = let (
	ms = crSplineMs([ for (p = mxpoints) p[_pos_] ],s=0.4)
) [ for (
		i = 0,
		p = mxpoints[i],
		m = undef,
		time = undef,
		fromTime = undef,
		toTime = p[_cRel_] ? mptime(p[_cRel_],0,cxpoints,cxxpoints) : 0,
		endSpeed = mxpoints[1][_speed_],
		prevPos = cxpoints[0][_pos_];
	i < len(mxpoints);
		i = i+1,
		p = mxpoints[i],
		m = ms[i-1],
		leng = prevPos == p[_pos_] ? 0 : crLeng(m),
		prevPos = p[_pos_],
		startSpeed = endSpeed,
		nextStop = i + 1 < len(mxpoints) && norm(p[_pos_]-mxpoints[i+1][_pos_]) < 0.1,
		ptime = nnv(p[_time_],p[_cRel_] ? mptime(p[_cRel_],toTime,cxpoints,cxxpoints) : undef),
		stta = i < len(mxpoints) ? stta(nnv(startSpeed,0),leng,p[_accel_],ptime,p[_speed_],nextStop) : [],
		endSpeed = stta[0],
		time = stta[1],
		fromTime = toTime,
		toTime = fromTime+time,
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(mxpoints) ) ? echo(p[_pname_],startTime=fromTime,time=time,leng=leng,cpos=p[_pos_],color=p[_color_],rotate=p[_rotate_]) 1 : 0
) if (i > 0) cpointx(p,splineM=m,time=time,startTime=fromTime,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2],nextStop=nextStop) ];

function mptime(cRel,fromTime,cxpoints,cxxpoints) = let (
	cp0 = findcxx(cRel[0],cxxpoints),
	cp = cp0 ? cp0 : findcxx(cRel[0],cxpoints)
) cp[_startTime_]+cp[_time_]+cRel[1]-fromTime;