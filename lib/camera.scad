
use <transformations.scad>
use <splines.scad>
use <path.scad>
use <speed.scad>
use <util.scad>
use <cameraUtil.scad>
use <viewAt.scad>
use <pointx.scad>
use <now.scad>

// This is the main function that initiates all the hard work.
// The caller must set the returned vector to $camera, and should set $vpd, $vpr and $vpt from the first three elements in $camera
// Use the functions in now.scad to access the elements of $camera
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
function fullVpoints(vps,cxps) = concat(_fullVpoints(cp_cRel(vps[0]),cp_pname(cxps[0]),0),vps,_fullVpoints(cp_cRel(vps[len(vps)-1]),cp_pname(cxps[len(cxps)-1]),0));

// Show the children (=the model) for a specific frame that was specified in $camera from the previous camera() function call
// If $frameNo != undef we asume a fixed camera and move the world - this is usually only for scripted call to openscad
// else we asume the camera has already been moved and we can just show the model
module _animation() {
	assert($camera != undef,"You must set $camera with: $camera = camera(cpoints);");
	if ($frameNo != undef)
		vpdrt2transform(now_rvpd(), now_rvpr(), now_rvpt()) multmatrix(now_rx()) children();
	else
		multmatrix(now_x()) children();
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
		speed = nnv(cp_speed(p),50),
		accel = nnv(cp_accel(p),100);
	i < len(cpoints);
		i = i+1,
		p = cpoints[i],
		pos = cmove(pos,p),
		speed = nnv(cp_speed(p),speed),
		accel = nnv(cp_accel(p),accel)
	) cpointx(p,pos=pos,speed=speed,accel=accel,pname=nnv(cp_pname(p),str("p",i))) ];

function cmove(curPos,p) =
	cp_pos(p) != undef ? cp_pos(p) :
		cp_move(p) != undef ? curPos + cp_move(p) :
			cp_cameraAndView(p) != undef ? let ( cv = cp_cameraAndView(p) ) vpdrt2cvz(cv[0], cv[1], cv[2])[0] :
				curPos;


/*
This is the second transformation from the cxpoints vector to the cxxpoints vector.
We make sure the following are now set: splineM, startSpeed, speed, startTime and time
 */
function cxxpoints(cxpoints) = let (
	ms = crSplineMs([ for (p = cxpoints) cp_pos(p) ], s = 0.4)
) [ for (
		i = 0,
		p = undef,
		m = undef,
		time = undef,
		fromTime = undef,
		toTime = 0,
		endSpeed = cp_speed(cxpoints[1]),
		prevPos = cp_pos(cxpoints[0]);
	i < len(cxpoints);
		i = i+1,
		p = cxpoints[i],
		m = ms[i-1],
		leng = prevPos == cp_pos(p) ? 0 : crLeng(m),
		prevPos = cp_pos(p),
		startSpeed = endSpeed,
		nextStop = i + 1 < len(cxpoints) && norm(cp_pos(p)-cp_pos(cxpoints[i+1])) < 0.1,
		stta = i < len(cxpoints) ? stta(startSpeed,leng,cp_accel(p),cp_time(p),cp_speed(p),nextStop) : [],
		endSpeed = stta[0],
		time = stta[1],
		fromTime = toTime,
		toTime = fromTime+time,
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(cxpoints) ) ? echo(cp_pname(p),startTime=fromTime,time=time,leng=leng,cpos=cp_pos(p)) 1 : 0
) if (i > 0) cpointx(p,splineM=m,time=time,startTime=fromTime,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2],nextStop=nextStop) ];


