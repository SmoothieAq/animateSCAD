
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADpath.scad>
use <animateSCADspeed.scad>
use <animateSCADutil.scad>
use <animateSCADcameraUtil.scad>
use <animateSCADviewAt.scad>

include <animateSCADpointx.scad>

// This is the main function that initiates all the hard work.
// The caller must set the returned vector to $camera, and should set $vpd, $vpr and $vpt from the first three elements in $camera
// $camera[0] 	vpd (but if $frameNo != undef it will be 100)
// $camera[1] 	vpr (but if $frameNo != undef it will be [0,0,0])
// $camera[2] 	vpt (but if $frameNo != undef it will be [0,0,0])
// $camera[3] 	x, transformation matrix for zoom
// $camera[4] 	cxpoints
// $camera[5] 	cxxpoints
// $camera[6] 	vpd (the real one)
// $camera[7] 	vpr (the real one)
// $camera[8] 	vpt (the real one)
// $camera[9] 	x, transformation matrix for zoom (the real one)
// $camera[10] 	vxpoints
// $camera[11] 	vxxpoints
// $camera[12]	frameTime
// $camera[13]	total time
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
		concat((sframeNo != undef ? [100,[0,0,0],[0,0,0],drtx[3]] : drtx),[cxps,cxxps],drtx,[vxps,vxxps],frameTime,totTime);

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
	) cpointx(p,pos=pos,speed=speed,accel=accel,pname=nnv(p[_pname_],str("p",i))) ];

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

