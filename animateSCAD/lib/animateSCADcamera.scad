
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADutil.scad>

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
function cpointx(cpoint,cameraAbsolute,cameraTranslate,cameraRotate,viewAtAbsolute,viewAtTranslate,viewAtRotate,zoom,speed,time,pname,splineM,startTime,viewAtSplineM) =
	[nnv(cameraAbsolute,cpoint[_cameraAbsolute_]),nnv(cameraTranslate,cpoint[_cameraTranslate_]),nnv(cameraRotate,cpoint[_cameraRotate_]),
	 nnv(viewAtAbsolute,cpoint[_viewAtAbsolute_]),nnv(viewAtTranslate,cpoint[_viewAtTranslate_]),nnv(viewAtRotate,cpoint[_viewAtRotate_]),
	 nnv(zoom,cpoint[_zoom_]),nnv(speed,cpoint[_speed_]),nnv(time,cpoint[_time_]),nnv(cpoint[_pname_],pname),
	 nnv(splineM,cpoint[_splineM_]),nnv(startTime,cpoint[_startTime_]),nnv(viewAtSplineM,cpoint[_viewAtSplineM_])];

function _camera(cpoints,fps,t,frameNo) =
	assert(is_list(cpoints) && len(cpoints) > 1, "The cpoints argument should be a list of cpoint()")
	assert(cpoints[0][_cameraAbsolute_] != undef || cpoints[0][_viewAtAbsolute_] != undef, "The first cpoint should have an absolute camera position or an absolute viewAt position")
	let (
		sfps = nnv(fps,$fps),
		xps = cxpoints(cpoints),
		xxps = cxxpoints(xps),
		totTime = totTime(xxps),//sum( [ for (p = xxps) p[_time_] ] ),
		sframeNo = $frameNo,
		frameTime0 = sframeNo != undef ? sframeNo/sfps : nnv(t, frameNo != undef ? frameNo/sfps : totTime*$t ),
		frameTime = frameTime0 < 0.001 ? 0.001 : frameTime0,
		cvPos = findPos(xxps,frameTime),
		drtx = cvz2vpdrtx([cvPos[0],cvPos[1],1])
	)
		echo("animateSCAD:",total_time=totTime,frames_per_second=sfps,total_frames=totTime*sfps)
		echo(frameTime=frameTime,$t=$t,frameNo=nnv(sframeNo,frameNo),deltaTime=cvPos[2],delta=cvPos[3],camPos=cvPos[0],viewAtPos=cvPos[1],towards=cvPos[4])
		concat((sframeNo != undef ? [100,[0,0,0],[0,0,0],drtx[3]] : drtx),[xps,xxps],drtx);

function findPos(xxps,frameTime) = let (
		p = findP(xxps,frameTime),
		deltaTime = frameTime-p[_startTime_],
		delta = deltaTime/p[_time_],
		camPos = crSplineT(p[_splineM_],delta),
		viewAtPos = crSplineT(p[_viewAtSplineM_],delta),
		pname = p[_pname_]
	) [camPos,viewAtPos,deltaTime,delta,pname];

module _animation(showPath=0) {
	assert($camera != undef,"You must set $camera with: $camera = camera(cpoints);");
	module model() {
		module viewLine(t) { cvPos = findPos($camera[5],t); line(cvPos[0],cvPos[1]); }
		if (showPath > 0) {
			crLines( [for (p = $camera[4]) p[0]] );
			totTime = totTime($camera[5]);
			if (showPath > 1) {
				for (t = [0.001:totTime]) color("blue", 0.05) viewLine(t);
				for (t = [0.001:0.2:totTime]) color("lightblue", 0.05) viewLine(t);
			}
			*for (v =[ for( t = 0, cvPos1 = [0,0,0], cvPos2 = findPos($camera[5],t)[0], d1=0,d2= findPos($camera[5],t)[3]; t < totTime; t = t+0.2, cvPos1 = cvPos2, cvPos2 = findPos($camera[5],t)[0], d1=d2,d2= findPos($camera[5],t)[3]) [t,cvPos1,cvPos2,norm(cvPos1-cvPos2),d2-d1]]) echo(v);
		}
		children();
	}
	if ($frameNo != undef)
		translate([-$camera[8].x,-$camera[8].y,-$camera[8].z-$camera[6]+100])
			rotate([-$camera[7].x,0,0]) rotate([0,-$camera[7].y,0]) rotate([0,0,-$camera[7].z])
				model() children();
	else
		model() children();
}

function findP(ps,frameTime) = [ for (p = ps) if ( frameTime >= p[_startTime_] && frameTime <= p[_startTime_]+p[_time_]) p ][0];

function totTime(xccpoints) = sum( [ for (p = xccpoints) p[_time_] ] );

function cxpoints(cpoints) = [ for (
		i = 0,
		cp = cpoints[i],
		cpos = nnv(cp[_cameraAbsolute_],[100,100,100]),
		vpos = nnv(cp[_viewAtAbsolute_],[0,0,0]),
		speed = nnv(cp[_speed_],50);
	i < len(cpoints);
		i = i+1,
		cp = cpoints[i],
		cpos = move(cpos,cp,_cameraAbsolute_,_cameraTranslate_),
		vpos = move(vpos,cp,_viewAtAbsolute_,_viewAtTranslate_),
		speed = nnv(cp[_speed_],speed)
	) cpointx(cp,cameraAbsolute=cpos,viewAtAbsolute=vpos,speed=speed,pname=nnv(cp[_pname_],str("point",i))) ];

function move(curPos,cpoint,absidx,transidx) =
	cpoint[absidx] != undef ? cpoint[absidx] :
		cpoint[transidx] != undef ? curPos + cpoint[transidx] :
			curPos;

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

