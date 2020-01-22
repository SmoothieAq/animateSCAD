
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADutil.scad>

/*
The full animation is specified as a vector of cpoints - that is what you give as argument to the camera() function.
A cpoint specifies both a point on the full camera travel, and it specifies some properties of the path between the previous
point and this point.
As a preperation we transform the original cpoints to first cxpoints (xps for short) and then cxxpoints (xxps for short).
However all are held in an increasingly rich cpointx vector - we index this vector with the _constant_ indexes below.
*/
_cameraAbsolute_ = 0;
_cameraTranslate_ = 1;
_cameraRotate_ = 2;
_viewAtAbsolute_ = 3;
_viewAtTranslate_ = 4;
_viewAtRotate_ = 5;
_zoom_ = 6;
_speed_ = 7;
_time_ = 8;
_pname_ = 9;
_splineM_ = 10;
_startTime_ = 11;
_viewAtSplineM_ = 12;
_accel_ = 13;
_leng_ = 14;
_startSpeed_ = 15;
function cpointx(cpoint,cameraAbsolute,cameraTranslate,cameraRotate,viewAtAbsolute,viewAtTranslate,viewAtRotate,zoom,speed,time,pname,splineM,startTime,viewAtSplineM,accel) =
	[nnv(cameraAbsolute,cpoint[_cameraAbsolute_]),nnv(cameraTranslate,cpoint[_cameraTranslate_]),nnv(cameraRotate,cpoint[_cameraRotate_]),
	 nnv(viewAtAbsolute,cpoint[_viewAtAbsolute_]),nnv(viewAtTranslate,cpoint[_viewAtTranslate_]),nnv(viewAtRotate,cpoint[_viewAtRotate_]),
	 nnv(zoom,cpoint[_zoom_]),nnv(speed,cpoint[_speed_]),nnv(time,cpoint[_time_]),nnv(cpoint[_pname_],pname),
	 nnv(splineM,cpoint[_splineM_]),nnv(startTime,cpoint[_startTime_]),nnv(viewAtSplineM,cpoint[_viewAtSplineM_]),nnv(accel,cpoint[_accel_])];

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
function _camera(cpoints,fps,t,frameNo) =
	assert(is_list(cpoints) && len(cpoints) > 1, "The cpoints argument should be a list of cpoint()")
	assert(cpoints[0][_cameraAbsolute_] != undef || cpoints[0][_viewAtAbsolute_] != undef, "The first cpoint should have an absolute camera position or an absolute viewAt position")
	let (
		sfps = nnv(fps,$fps),
		xps = cxpoints(cpoints),
		xxps = cxxpoints(xps),
		totTime = totTime(xxps),,
		sframeNo = $frameNo,
		frameTime0 = sframeNo != undef ? sframeNo/sfps : nnv(t, frameNo != undef ? frameNo/sfps : totTime*$t ),
		frameTime = frameTime0 < 0.001 ? 0.001 : frameTime0,
		cvPos = findCvz(xxps,frameTime),
		drtx = cvz2vpdrtx([cvPos[0],cvPos[1],1])
	)
		echo("animateSCAD:",total_time=totTime,frames_per_second=sfps,total_frames=totTime*sfps)
		echo(frameTime=frameTime,$t=$t,frameNo=nnv(sframeNo,frameNo),camPos=cvPos[0],viewAtPos=cvPos[1],zoom=cvPos[2],deltaTime=cvPos[3],delta=cvPos[4],towards=cvPos[5])
		concat((sframeNo != undef ? [100,[0,0,0],[0,0,0],drtx[3]] : drtx),[xps,xxps],drtx);


// Show the children (=the model) for a specific frame that was specified in $camera from the previous camera() function call
// If $frameNo != undef we asume a fixed camera and move the world - this is usually only for scripted call to openscap
// else we asume the camera has already been moved and we can just show the model
module _animation(showPath) {
	assert($camera != undef,"You must set $camera with: $camera = camera(cpoints);");
	if ($frameNo != undef)
		vpdrt2transform($camera[6], $camera[7], $camera[8]) showWithPath(showPath) children();
	else
		showWithPath(showPath) children();
}


// Find the the camera pos, viewAt pos and zoom for a given frameTime
function findCvz(xxps,frameTime) = let (
		p = findP(xxps,frameTime), // the path where the frame are in
		deltaTime = frameTime-p[_startTime_], // time from beginning of the path
		delta = deltaTime/p[_time_], // fraction into to path with respect to time
		camPos = crSplineT(p[_splineM_],delta),
		viewAtPos = crSplineT(p[_viewAtSplineM_],delta),
		pname = p[_pname_],
		zoom = 1
	) [camPos,viewAtPos,zoom,deltaTime,delta,pname];


// Show children, possibly illustrate the camera path
// showPath = 0 -> no illustration
// showPath = 1 -> show camera path only
// showPath = 2 -> also show view lines
module showWithPath(showPath) {
	module viewLine(t) { cvPos = findCvz($camera[5],t); line(cvPos[0],cvPos[1]); }
	if (showPath > 0) {
		crLines( [for (p = $camera[4]) p[0]] );
		if (showPath > 1) {
			totTime = totTime($camera[5]);
			for (t = [0:0.2:totTime]) color( t-floor(t+0.01) < 0.01 ? "blue" : "lightblue", 0.05) viewLine(t+0.001);
		}
	}
	children();
}

// Find the path containing a given frame
function findP(xxps,frameTime) = [ for (p = xxps) if ( frameTime >= p[_startTime_] && frameTime <= p[_startTime_]+p[_time_]) p ][0];

// Total duration of the animation
function totTime(xxps) = sum( [ for (p = xxps) p[_time_] ] );

/*
This is the fist transformation from the cpoints vector to the cxpoints vector.
We make sure each point has absolute positions for camera and viewAt.
We make sure each point has a name.
We cary forward speed and accel when they are not set.
 */
function cxpoints(cpoints) = [ for (
		i = 0,
		cp = cpoints[i],
		cpos = nnv(cp[_cameraAbsolute_],[100,100,100]),
		vpos = nnv(cp[_viewAtAbsolute_],[0,0,0]),
		speed = nnv(cp[_speed_],50),
		accel = nnv(cp[_accel_],100);
	i < len(cpoints);
		i = i+1,
		cp = cpoints[i],
		cpos = move(cpos,cp,_cameraAbsolute_,_cameraTranslate_),
		vpos = move(vpos,cp,_viewAtAbsolute_,_viewAtTranslate_),
		speed = nnv(cp[_speed_],speed),
		accel = nnv(cp[_accel_],accel)
	) cpointx(cp,cameraAbsolute=cpos,viewAtAbsolute=vpos,speed=speed,accel=accel,pname=nnv(cp[_pname_],str("point",i))) ];

function move(curPos,cpoint,absidx,transidx) =
	cpoint[absidx] != undef ? cpoint[absidx] :
		cpoint[transidx] != undef ? curPos + cpoint[transidx] :
			curPos;


/*
This is the second transformation from the cxpoints vector to the cxxpoints vector.
We make sure the following are now set: splineM, viewAtSpineM, time, startSpeed, speed, startTime and time
 */
function cxxpoints(cxpoints) = let (
	ms = crSplineMs([ for (p = cxpoints) p[_cameraAbsolute_] ]),
	vms = crSplineMs([ for (p = cxpoints) p[_viewAtAbsolute_] ])
) [ for (
		i = 0,
		p = undef,
		m = undef,
		time = undef,
		fromTime = undef,
		toTime = 0;
	i < len(cxpoints);
		i = i+1,
		p = cxpoints[i],
		m = ms[i-1],
		vm = vms[i-1],
		time = time(p,m),
		fromTime = toTime,
		toTime = fromTime+time,
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(cxpoints) ) ? echo(p[_pname_],startTime=fromTime,time=time) 1 : 0
) if (i > 0) cpointx(p,splineM=m,viewAtSplineM=vm,time=time,startTime=fromTime) ];

function time(p,m) = p[_time_] != undef ? p[_time_] : crLeng(m) / p[_speed_];

/*
Speed and time of a path

When calculating xxpoint, we will always know:
	s0	start speed
	a	accelearation
	l	length of path

And we will know either
	s1	end speed
or
	tt	time to travel path

A path travel consist of an (possible empty and possible negative) acceleration segment and then a segment crusing
at s1 speed. For the full path travel, the following is then true:
	l = ta * s0 + ta * ta * a / 2 + (tt - ta) * s1
where ta is the time the acceleration segment ends, and
	ta * a = s1 - s0

With some help from wolframalpha.com, we can deduce the following.

If we know tt, we can find s1:
	s1 = sqrt(a) * sqrt(a * tt * tt - 2 * l + 2 * s0 * tt) + a * tt + s0
if that was negative, we need a decelaration and we do:
	s1 = -sqrt(a) * sqrt(a * tt * tt - 2 * l + 2 * s0 * tt) + a * tt + s0
if that was also negative, then a is not large enough; we then change a to be just large enough:
	s1 = 2 * l * tt - s0
	a = abs(s1 - s0) / tt

If we know s1, we can find tt:
	tt = (2 * a * l + (s1 - s0) * (s1 - s0)) / (2 * a * s1)
if that was negative, then a is not large enough; we then change a to be just large enough:
	tt = 2 * l / (s0 + s1)
	a = abs(s1 - s0) / tt

We can then calculate how far (f = fraction [0-1]) we are along the path at time t:
	f = ta * s0 + ta * ta * a / 2 + tb * s1
where
	ta = max(t, (s1 - s0)/a)
	tb = min(0, t - (s1 - s0)/a)
*/

function s1tta(p,s0,l) = let (
		a = p[_accel_]
	)
	p[_time_] != undef ?
		let (
			tt = p[_time_],
			s1_1 = sqrt(a) * sqrt(a * tt * tt - 2 * l + 2 * s0 * tt),
			s1_2 = a * tt + s0,
			s1_a = s1_1 + s1_2,
			s1_b = s1_a > 0 ? s1_a : -s1_1 + s1_2,
			s1 = s1_b > 0 ? s1_b : 2 * l * tt - s0,
			a_ = s1_b > 0 ? a : abs(s1 - s0) / tt
		) [s1,tt,a_] :
		let (
			s1 = p[_speed_],
			tt_a = (2 * a * l + (s1 - s0) * (s1 - s0)) / (2 * a * s1),
			tt = tt_a > 0 ? tt_a : 2 * l / (s0 + s1),
			a_ = tt_a > 0 ? a : abs(s1 - s0) / tt
		)  [s1,tt,a_];

function f(p,t) = let (
		s0 = p[_startSpeed_],
		s1 = p[_speed_],
		a = p[_accel_],
		ta = max(t, (s1 - s0)/a),
		tb = min(0, t - (s1 - s0)/a)
	) ta * s0 + ta * ta * a / 2 + tb * s1;