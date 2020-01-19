
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
function cpointx(cpoint,cameraAbsolute,cameraTranslate,cameraRotate,viewAtAbsolute,viewAtTranslate,viewAtRotate,zoom,speed,time,pname,splineM,startTime) =
	[nnv(cameraAbsolute,cpoint[_cameraAbsolute_]),nnv(cameraTranslate,cpoint[_cameraTranslate_]),nnv(cameraRotate,cpoint[_cameraRotate_]),
	 nnv(viewAtAbsolute,cpoint[_viewAtAbsolute_]),nnv(viewAtTranslate,cpoint[_viewAtTranslate_]),nnv(viewAtRotate,cpoint[_viewAtRotate_]),
	 nnv(zoom,cpoint[_zoom_]),nnv(speed,cpoint[_speed_]),nnv(time,cpoint[_time_]),nnv(cpoint[_pname_],pname),
	 nnv(splineM,cpoint[_splineM_]),nnv(startTime,cpoint[_startTime_])];

function _camera(cpoints,fps=2,t,frameNo) =
	assert(is_list(cpoints) && len(cpoints) > 1, "The cpoints argument should be a list of cpoint()")
	assert(cpoints[0][_cameraAbsolute_] != undef || cpoints[0][_viewAtAbsolute_] != undef, "The first cpoint should have an absolute camera position or an absolute viewAt position")
	let (
		xps = cxpoints(cpoints),
		xxps = cxxpoints(xps),
		totTime = sum( [ for (p = xxps) p[_time_] ] ),
		frameTime = nnv(t, frameNo != undef ? frameNo/fps : totTime*$t ),
		p = findP(xxps,frameTime),
		deltaTime = frameTime-p[_startTime_],
		delta = deltaTime/p[_time_],
		camPos = crSplineT(p[_splineM_],delta),
		drtx = cvz2vpdrtx([camPos,p[_viewAtAbsolute_],1])
	)
		echo("animateSCAD:",total_time=totTime,frames_per_second=fps,total_frames=totTime*fps)
		echo(frameTime=frameTime,$t=$t,deltaTime=deltaTime,delta=delta,camPos=camPos,towards=p[_pname_])
		concat(drtx,[xps,xxps]);

module _animation(showPath=false) {
	assert($camera != undef,"You must set $camera with: $camera = camera(cpoints,fps);");
	if (showPath) crLines( [ for (p=$camera[4]) p[0] ] );
	children();
}

function findP(ps,frameTime) = [ for (p = ps) if ( frameTime >= p[_startTime_] && frameTime <= p[_startTime_]+p[_time_]) p ][0];


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
	ms = crSplineMs([ for (p = cxpoints) p[_cameraAbsolute_] ])
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
		time = time(p,m),
		fromTime = toTime,
		toTime = fromTime+time
	) if (i > 0) echo(p[_pname_],startTime=fromTime,time=time) cpointx(p,splineM=m,time=time,startTime=fromTime) ];

function time(p,m) = p[_time_] != undef ? p[_time_] : crLeng(m) / p[_speed_];

