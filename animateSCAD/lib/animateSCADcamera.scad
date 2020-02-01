
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

function cpointx(cpoint,pname,pos,move,cameraAndView,standStill,speed,time,accel,cRel,straightAhead,zoom,splineM,startTime,leng,startSpeed,endSpeed,endTime) =
	[nnv(cpoint[_pname_],pname),nnv(pos,cpoint[_pos_]),nnv(move,cpoint[_move_]),nnv(cameraAndView,cpoint[_cameraAndView_]),nnv(standStill,cpoint[_standStill_]),
	 nnv(speed,cpoint[_speed_]),nnv(time,cpoint[_time_]),nnv(accel,cpoint[_accel_]),
	 nnv(cRel,cpoint[_cRel_]),nnv(straightAhead,cpoint[_straightAhead_]),nnv(zoom,cpoint[_zoom_]),
	 nnv(splineM,cpoint[_splineM_]),nnv(startTime,cpoint[_startTime_]),
	 nnv(leng,cpoint[_leng_]),nnv(startSpeed,cpoint[_startSpeed_]),nnv(endSpeed,cpoint[_endSpeed_]),nnv(endTime,cpoint[_endTime_])];

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
	assert(is_list(cpoints) && len(cpoints) > 1, "The cpoints argument should be a list of cpoint()")
	assert(cpoints[0][_pos_] != undef || cpoints[0][_viewAtAbsolute_] != undef, "The first cpoint should have an absolute camera position or an absolute viewAt position")
	let (
		sfps = nnv(fps,$fps),
		cxps = cxpoints(cpoints),
		cxxps = cxxpoints(cxps),
		vxps = vxpoints(fullVpoints(vpoints,cxxps),cxxps),
		vxxps = vxxpoints(vxps,cxxps),
		totTime = totTime(cxxps),
		sframeNo = $frameNo,
		frameTime0 = sframeNo != undef ? sframeNo/sfps : nnv(t, frameNo != undef ? frameNo/sfps : totTime*$t ),
		frameTime = frameTime0 < 0.001 ? 0.001 : frameTime0,
		cvPos = findCvz(cxxps,vxxps,frameTime),
		drtx = cvz2vpdrtx([cvPos[0],cvPos[1],1])
	)
		echo("animateSCAD:",total_time=totTime,frames_per_second=sfps,total_frames=totTime*sfps)
		echo(frameTime=frameTime,$t=$t,frameNo=nnv(sframeNo,frameNo),camPos=cvPos[0],viewAtPos=cvPos[1],zoom=cvPos[2],deltaTime=cvPos[3],delta=cvPos[4],towards=cvPos[5])
		concat((sframeNo != undef ? [100,[0,0,0],[0,0,0],drtx[3]] : drtx),[cxps,cxxps],drtx,[vxps,vxxps]);

function _fullVpoints(vr,cn,o) = (vr[0] == cn && abs(vr[1]-o) < 0.02) ? [] : [cpointx([],cRel=[cn,o])];
function fullVpoints(vps,cxxps) = concat(_fullVpoints(vps[0][_cRel_],cxxps[0][_pname_],-cxxps[0][_time_]),vps,_fullVpoints(vps[len(vps)-1][_cRel_],cxxps[len(cxxps)-1][_pname_],0));

// Show the children (=the model) for a specific frame that was specified in $camera from the previous camera() function call
// If $frameNo != undef we asume a fixed camera and move the world - this is usually only for scripted call to openscad
// else we asume the camera has already been moved and we can just show the model
module _animation() {
	assert($camera != undef,"You must set $camera with: $camera = camera(cpoints);");
	if ($frameNo != undef)
		vpdrt2transform($camera[6], $camera[7], $camera[8]) children();
	else
		children();
}


// Find the the camera pos, viewAt pos and zoom for a given frameTime
function findCvz(cxxps,vxxps,frameTime) = let (
		cpos = findPos(cxxps,frameTime),
		vpos = findPos(vxxps,frameTime),
		zoom = 1
	) [cpos[0],vpos[0],zoom,cpos[1],cpos[2],cpos[3]];

// Find the the pos for a given frameTime
function findPos(xxps,frameTime) = let (
	p = findP(xxps,frameTime), // the path where the frame are in
	deltaTime = frameTime-p[_startTime_], // time from beginning of the path
	deltaLeng = lt(deltaTime,p[_startSpeed_],p[_speed_],p[_accel_]),
	delta = p[_leng_] < 0.01 || deltaLeng < 0.01 ? 0.01 : deltaLeng / p[_leng_],
	pos = crSplineT(p[_splineM_],delta),
	pname = p[_pname_]
) /*echo(deltaTime=deltaTime,deltaLeng=deltaLeng,delta=delta,frameTime=frameTime,pos=pos,p[_pname_])*/ [pos,deltaTime,delta,pname];


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
	ms = crSplineMs([ for (p = cxpoints) p[_pos_] ])
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
		stta = i < len(cxpoints) ? stta(startSpeed,leng,p[_accel_],p[_time_],p[_speed_]) : [],
		endSpeed = stta[0],
		time = stta[1],
		fromTime = toTime,
		toTime = fromTime+time,
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(cxpoints) ) ? echo(p[_pname_],startTime=fromTime,time=time,leng=leng) 1 : 0
) if (i > 0) cpointx(p,splineM=m,time=time,startTime=fromTime,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2]) ];

function findcxx(pname,cxxs) = let ( i = search([pname],cxxs) ) cxxs[i[0]];

/*
This is the fist transformation from the vpoints vector to the vxpoints vector.
We make sure each point has absolute endTime positions. cRel is changed to be the referenced cxxp.
We cary forward zoom and accel when they are not set.
 */
function vxpoints(vpoints,cxxpoints) = let (
	ps = [ for (p = vpoints)
		let (
			cp = findcxx(p[_cRel_][0],cxxpoints)
		) cpointx(p,cRel=cp,endTime=cp[_startTime_]+cp[_time_]+p[_cRel_][1],pname=str("V",cp[_pname_],"/",p[_cRel_][1]))
	]
) [ for (
		i = 0,
		p = ps[i],
		pos = vmove([0,0,0],p,cxxpoints),
		zoom = nnv(p[_zoom_],50),
		accel = nnv(p[_accel_],100);
	i < len(vpoints);
		i = i+1,
		p = ps[i],
		pos = vmove(pos,p,cxxpoints),
		zoom = nnv(p[_zoom_],zoom),
		accel = nnv(p[_accel_],accel)
) cpointx(p,pos=pos,zoom=zoom,accel=accel) ];

function vmove(curPos,p,cxxpoints) =
	p[_pos_] != undef ? p[_pos_] :
		p[_move_] != undef ? curPos + p[_move_] :
			p[_cameraAndView_] != undef ? let ( cv = p[_cRel_][_cameraAndView_] ) vpdrt2cvz(cv[0], cv[1], cv[2])[1] :
				p[_straightAhead_] != undef ? vStraightAheadPos(p,cxxpoints) :
					curPos;

function vStraightAheadPos(p,cxxpoints) = let (
	vt0 = p[_startTime_],
	t0 = vt0 > 0.1 ? vt0-0.1 : 0.01,
	t1 = vt0 > 0.1 ? vt0 : vt0 + 0.01,
	cp1 = findPos(cxxpoints,t1),
	dir = unit(findPos(cxxpoints,t0)-cp1)
) cp1 + dir * p[_straightAhead_];

/*
This is the second transformation from the vxpoints vector to the vxxpoints vector.
We make sure the following are now set: startTime, time, splineM, startSpeed and speed
 */
function vxxpoints(vxpoints,cxxpoints) = let (
	ms = crSplineMs([ for (p = vxpoints) p[_pos_] ])
) [ for (
		i = 0,
		p = undef,
		m = undef,
		time = undef,
		startTime = 0,
		endTime = 0,
		endSpeed = 0,
		prevPos = vxpoints[0][_pos_];
	i < len(vxpoints);
		i = i+1,
		p = vxpoints[i],
		m = ms[i-1],
		leng = prevPos == p[_pos_] ? 0 : crLeng(m),
		prevPos = p[_pos_],
		startTime = endTime,
		endTime = p[_endTime_],
		time = endTime - startTime,
		startSpeed = endSpeed,
		stta = i >= len(vxpoints) ? [] : leng > 0 ? stta(startSpeed,leng,p[_accel_],time,undef) : [0,time,0],
		endSpeed = stta[0],
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(vxpoints) ) ? echo(p[_pname_],startTime=startTime,time=time,leng=leng) 1 : 0
) if (i > 0) cpointx(p,splineM=m,startTime=startTime,time=time,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2]) ];

