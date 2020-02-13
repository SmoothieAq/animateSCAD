
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADpath.scad>
use <animateSCADspeed.scad>
use <animateSCADutil.scad>

/*
The full animation is specified as a vector of cpoints - that is what you give as argument to the camera() function.
A cpoint specifies both a point on the full camera travel, and it specifies some properties of the path between the previous
point and this point.
As a preperation we transform the original cpoints to first cxpoints (xps for short) and then cxxpoints (xxps for short).
However all are held in an increasingly rich cpointx vector - we index this vector with the _constant_ indexes below.
*/
_pname_ = 0; // name of (sub)path - only for c..points
_pos_ = 1; // absolute position - always set in .xpoints
_move_ = 2; // relative move - not used after .xpoints
_cameraAndView_ = 3; // in cpoints: [vpr, vpt, vpd] from OpenSCAD viewer; in vpoints: if true read from cpoints; not used after .xpoints
_standStill_ = 4; // no move; not used after .xpoints
_speed_ = 5; // crusing speed, only for cpoints
_time_ = 6; // time to travel path, initially only for cpoints
_accel_ = 7; // acceletartion

_cRel_ = 8; // [pname,relTime], start time relative to cpoint start time - only for v..points
_straightAhead_ = 9; // a distance, keep viewAt straight ahead of camera move with that distance
_zoom_ = 10; // camera zoom (but specified on vpoints)

// the following are set in .xxpoints
_splineM_ = 11; // spline matrix for path
_startTime_ = 12; // start time for path
_leng_ = 13; // length of path
_startSpeed_ = 14;
_endSpeed_ = 15;
_endTime_ = 16; // only for vxpoints
_nextStop_ = 17; // next (sub)path is not moving

function cpointx(cpoint,pname,pos,move,cameraAndView,standStill,speed,time,accel,cRel,straightAhead,zoom,splineM,startTime,leng,startSpeed,endSpeed,endTime,nextStop) =
	[nnv(cpoint[_pname_],pname),nnv(pos,cpoint[_pos_]),nnv(move,cpoint[_move_]),nnv(cameraAndView,cpoint[_cameraAndView_]),nnv(standStill,cpoint[_standStill_]),
	 nnv(speed,cpoint[_speed_]),nnv(time,cpoint[_time_]),nnv(accel,cpoint[_accel_]),
	 nnv(cRel,cpoint[_cRel_]),nnv(straightAhead,cpoint[_straightAhead_]),nnv(zoom,cpoint[_zoom_]),
	 nnv(splineM,cpoint[_splineM_]),nnv(startTime,cpoint[_startTime_]),
	 nnv(leng,cpoint[_leng_]),nnv(startSpeed,cpoint[_startSpeed_]),nnv(endSpeed,cpoint[_endSpeed_]),nnv(endTime,cpoint[_endTime_]),nnv(nextStop,cpoint[_nextStop_])];

// This is the main function that initiates all the hard work.
// The caller must set the returned vector to $camera, and should set $vpd, $vpr and $vpt from the first three elements in $camera
// $camera[0] 	vpd (but if $frameNo != undef it will be 100)
// $camera[1] 	vpr (but if $frameNo != undef it will be [0,0,0])
// $camera[2] 	vpt (but if $frameNo != undef it will be [0,0,0])
// $camera[3] 	x, transformation matrix for zoom
// $camera[4] 	xpoints
// $camera[5] 	xxpoints
// $camera[6] 	vpd (the real on)
// $camera[7] 	vpr (the real on)
// $camera[8] 	vpt (the real on)
function _camera(cpoints,vpoints,fps,t,frameNo) =
//	assert(is_list(cpoints) && len(cpoints) > 1, "The cpoints argument should be a list of cpoint()")
//	assert(cpoints[0][_pos_] != undef || cpoints[0][_viewAtAbsolute_] != undef, "The first cpoint should have an absolute camera position or an absolute viewAt position")
	let (
		sfps = nnv(fps,$fps),
		cxps = cxpoints(cpoints),
		cxxps = cxxpoints(cxps),
		vxps = vxpoints(fullVpoints(vpoints,cxps),cxps,cxxps),
		vxxps = vxxpoints(vxps,cxxps),
		totTime = totTime(cxxps),
		sframeNo = $frameNo,
		frameTime0 = sframeNo != undef ? sframeNo/sfps : nnv(t, frameNo != undef ? frameNo/sfps : totTime*$t ),
		frameTime = frameTime0 < 0.001 ? 0.001 : frameTime0,
		cvPos = findCvz(cxxps,vxxps,frameTime),
		drtx = cvz2vpdrtx([cvPos[0],cvPos[1],1])
	)
		echo("animateSCAD:",total_time=totTime,frames_per_second=sfps,total_frames=totTime*sfps)
//		echo(frameTime=frameTime,$t=$t,frameNo=nnv(sframeNo,frameNo),camPos=cvPos[0],viewAtPos=cvPos[1],zoom=cvPos[2],deltaTime=cvPos[3],delta=cvPos[4],towards=cvPos[5])
		concat((sframeNo != undef ? [100,[0,0,0],[0,0,0],drtx[3]] : drtx),[cxps,cxxps],drtx,[vxps,vxxps]);

function _fullVpoints(vr,cn,o) = (vr[0] == cn && abs(vr[1]-o) < 0.02) ? [] : [cpointx([],cRel=[cn,o])];
function fullVpoints(vps,cxps) = concat(_fullVpoints(vps[0][_cRel_],cxps[0][_pname_],0),vps,_fullVpoints(vps[len(vps)-1][_cRel_],cxps[len(cxps)-1][_pname_],0));

// Show the children (=the model) for a specific frame that was specified in $camera from the previous camera() function call
// If $frameNo != undef we asume a fixed camera and move the world - this is usually only for scripted call to openscad
// else we asume the camera has already been moved and we can just show the model
module _animation() { 
	assert($camera != undef,"You must set $camera with: $camera = camera(cpoints);");
	if ($frameNo != undef)
		vpdrt2transform($camera[6], $camera[7], $camera[8]) multmatrix($camera[3]) children();
	else
		multmatrix($camera[3]) children();
}


// Find the the camera pos, viewAt pos and zoom for a given frameTime
function findCvz(cxxps,vxxps,frameTime) = let (
		cpos = findPos(cxxps,undef,frameTime),
		vpos = findPos(vxxps,cxxps,frameTime),
		zoom = 1
	) [cpos[0],vpos[0],zoom,cpos[1],cpos[2],cpos[3]];

// Find the the pos for a given frameTime
function findPos(xxps,cxxps,frameTime) = let (
	p = findP(xxps,frameTime), // the path where the frame are in
	pname = p[_pname_],
	deltaTime = frameTime-p[_startTime_] // time from beginning of the path
) p[_straightAhead_] ?
	let (
		straightAhead = p[_straightAhead_],
		pos = vStraightAheadPos(frameTime,p[_straightAhead_],cxxps)
	) /*echo(pname,frameTime=frameTime,deltaTime=deltaTime,straightAhead=straightAhead,pos=pos)*/ [pos,deltaTime,undef,pname] :
	let (
		deltaLeng = lt(deltaTime,p[_startSpeed_],p[_speed_],p[_accel_],p[_time_],p[_nextStop_]),
		delta = p[_leng_] < 0.01 || deltaLeng < 0.01 ? 0.01 :  p[_leng_]-deltaLeng < 0.01 ? 1 : deltaLeng / p[_leng_],
		pos = p[_leng_] < 0.01 ? p[_pos_] : crSplineT(p[_splineM_],delta)
	) /*echo(pname,frameTime=frameTime,deltaTime=deltaTime,deltaLeng=deltaLeng,delta=delta,pos=pos)*/ [pos,deltaTime,delta,pname];


/// Find the path containing a given frame
function findP(xxps,frameTime) = [ for (p = xxps) if ( frameTime >= p[_startTime_] && frameTime <= p[_startTime_]+p[_time_]) p ][0];

// Total duration of the animation
function totTime(xxps) = sum( [ for (p = xxps) p[_time_] ] );


/*
This is the fist transformation from the cpoints vector to the cxpoints vector.
We make sure each point has absolute positions.
We cary forward speed and accel when they are not set.
 */
function cxpoints(cpoints) = [ for (
		i = 0,
		p = cpoints[i],
		pos = cmove([100,100,100],p),
		speed = nnv(p[_speed_],50),
		accel = nnv(p[_accel_],100);
	i < len(cpoints);
		i = i+1,
		p = cpoints[i],
		pos = cmove(pos,p),
		speed = nnv(p[_speed_],speed),
		accel = nnv(p[_accel_],accel)
	) cpointx(p,pos=pos,speed=speed,accel=accel,pname=nnv(p[_pname_],str("_point",i))) ];

function cmove(curPos,p) =
	p[_pos_] != undef ? p[_pos_] :
		p[_move_] != undef ? curPos + p[_move_] :
			p[_cameraAndView_] != undef ? let ( cv = p[_cameraAndView_] ) vpdrt2cvz(cv[0], cv[1], cv[2])[0] :
				curPos;


/*
This is the second transformation from the cxpoints vector to the cxxpoints vector.
We make sure the following are now set: splineM, startSpeed, speed, startTime and time
 */
function cxxpoints(cxpoints) = let (
	ms = crSplineMs([ for (p = cxpoints) p[_pos_] ],s=0.4)
) [ for (
		i = 0,
		p = undef,
		m = undef,
		time = undef,
		fromTime = undef,
		toTime = 0,
		endSpeed = cxpoints[1][_speed_],
		prevPos = cxpoints[0][_pos_];
	i < len(cxpoints);
		i = i+1,
		p = cxpoints[i],
		m = ms[i-1],
		leng = prevPos == p[_pos_] ? 0 : crLeng(m),
		prevPos = p[_pos_],
		startSpeed = endSpeed,
		nextStop = i + 1 < len(cxpoints) && norm(p[_pos_]-cxpoints[i+1][_pos_]) < 0.1,
		stta = i < len(cxpoints) ? stta(startSpeed,leng,p[_accel_],p[_time_],p[_speed_],nextStop) : [],
		endSpeed = stta[0],
		time = stta[1],
		fromTime = toTime,
		toTime = fromTime+time,
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(cxpoints) ) ? echo(p[_pname_],startTime=fromTime,time=time,leng=leng,cpos=p[_pos_]) 1 : 0
) if (i > 0) cpointx(p,splineM=m,time=time,startTime=fromTime,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2],nextStop=nextStop) ];

function findcxx(pname,cxxs) = let ( i = search([pname],cxxs) ) cxxs[i[0]];

/*
This is the fist transformation from the vpoints vector to the vxpoints vector.
We make sure each point has absolute endTime positions. cRel is changed to be the referenced cxxp.
We cary forward zoom and accel when they are not set.
 */
function vxpoints(vpoints,cxpoints,cxxpoints) = let (
	ps = [ for (p = vpoints)
		let (
			cp0 = findcxx(p[_cRel_][0],cxxpoints),
			cp = cp0 == undef ? findcxx(p[_cRel_][0],cxpoints) : cp0
		) cpointx(p,cRel=cp,endTime=cp[_startTime_]+cp[_time_]+p[_cRel_][1],pname=str("V",cp[_pname_],"/",p[_cRel_][1]))
	]
) [ for (
		i = 0,
		p = ps[i],
		startTime = 0,
		endTime = 0,
		time = 0,
		pos = vmove([0,0,0],p,cxpoints),
		zoom = nnv(p[_zoom_],50),
		accel = nnv(p[_accel_],100),
		prevStraightAhead = p[_straightAhead_],
		straightAhead = false;
	i < len(vpoints);
		i = i+1,
		p = ps[i],
		startTime = endTime,
		endTime = p[_endTime_],
		time = endTime - startTime,
		pos = vmove(pos,p,cxxpoints,endTime),
		zoom = nnv(p[_zoom_],zoom),
		accel = nnv(p[_accel_],accel),
		straightAhead = prevStraightAhead && p[_straightAhead_] ? p[_straightAhead_] : false,
		prevStraightAhead = p[_straightAhead_]
) /*echo(i,startTime=startTime,time=time,endTime=endTime,prevStraightAhead,straightAhead,p[_straightAhead_])*/ cpointx(p,startTime=startTime,time=time,pos=pos,zoom=zoom,accel=accel,straightAhead=straightAhead) ];

function vmove(curPos,p,cxxpoints,startTime) =
	p[_pos_] != undef ? p[_pos_] :
		p[_move_] != undef ? curPos + p[_move_] :
			p[_cameraAndView_] != undef ? let ( cv = p[_cRel_][_cameraAndView_] ) vpdrt2cvz(cv[0], cv[1], cv[2])[1] :
				p[_straightAhead_] != undef ? vStraightAheadPos(startTime,p[_straightAhead_],cxxpoints) :
					curPos;

function vStraightAheadPos(t,dist,cxxpoints) = let (
	t0 = t > 0.1 ? t-0.1 : 0.01,
	t1 = t > 0.1 ? t : 0.11,
	cp1 = findPos(cxxpoints,undef,t1)[0],
	cp0 = findPos(cxxpoints,undef,t0)[0],
	dir = unit(cp1-cp0),
	pos = cp1 + dir * dist
) /*echo("vStraightAheadPos>>",t=t,t0=t0,cp0=cp0,t1=t1,cp1=cp1,dist=dist,pos=pos)*/ pos;

/*
This is the second transformation from the vxpoints vector to the vxxpoints vector.
We make sure the following are now set: startTime, time, splineM, startSpeed and speed
 */
function vxxpoints(vxpoints,cxxpoints) = let (
	ms = vcrSplineMs(vxpoints,s=0.2)
) [ for (
		i = 0,
		p = undef,
		m = undef,
		time = undef,
		endSpeed = 0,
		prevPos = vxpoints[0][_pos_];
	i < len(vxpoints);
		i = i+1,
		p = vxpoints[i],
		m = ms[i-1],
		leng = prevPos == p[_pos_] ? 0 : crLeng(m),
		prevPos = p[_pos_],
		startSpeed = endSpeed,
		nextStop = i + 1 < len(vxpoints) && norm(p[_pos_]-vxpoints[i+1][_pos_]) < 0.1,
		stta = i >= len(vxpoints) ? [] : leng > 0 ? stta(startSpeed,leng,p[_accel_],p[_time_],undef,nextStop) : [0,time,0],
		endSpeed = p[_straightAhead_] ? 50 : stta[0],
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(vxpoints) ) ? echo(p[_pname_],startTime=p[_startTime_],time=p[_time_],leng=leng,vpos=p[_pos_]) 1 : 0
) if (i > 0) cpointx(p,splineM=m,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2],nextStop=nextStop) ];

function vcrSplineMs(ps,s=0.3) = [ for (i = [0:len(ps)-2])
	let (
		p0 = (i == 0 || ps[i][_straightAhead_] || ps[i+1][_straightAhead_]) ? ps[i][_pos_] : ps[i-1][_pos_],
		p1 = ps[i][_pos_],
		p2 = ps[i+1][_pos_],
		p3 = (i == len(ps)-2 || ps[i+2][_straightAhead_] || ps[i+1][_straightAhead_]) ? ps[i+1][_pos_] : ps[i+2][_pos_]
	)
	/*echo(p0,p1,p2,p3,ps[i+2][_straightAhead_],ps[i+1][_straightAhead_])*/ crSplineM(p0,p1,p2,p3,s=s)
];
