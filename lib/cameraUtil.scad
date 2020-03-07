
use <transformations.scad>
use <splines.scad>
use <path.scad>
use <speed.scad>
use <util.scad>

include <pointx.scad>


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
) !p ? p : p[_straightAhead_] ?
	let (
		straightAhead = p[_straightAhead_],
		pos = vStraightAheadPos(frameTime,p[_straightAhead_],cxxps)
	) /*echo("findPos",pname,frameTime=frameTime,deltaTime=deltaTime,straightAhead=straightAhead,pos=pos)*/ [pos,deltaTime,undef,pname,p] :
	let (
		deltaLeng = lt(deltaTime,p[_startSpeed_],p[_speed_],p[_accel_],p[_time_],p[_nextStop_]),
		delta = p[_leng_] < 0.01 || deltaLeng < 0.01 ? 0.01 :  p[_leng_]-deltaLeng < 0.01 ? 1 : deltaLeng / p[_leng_],
		pos = p[_leng_] < 0.01 ? p[_pos_] : crSplineT(p[_splineM_],delta)
	) /*echo("findPos",pname,frameTime=frameTime,deltaTime=deltaTime,deltaLeng=deltaLeng,delta=delta,pos=pos)*/ [pos,deltaTime,delta,pname,p];


/// Find the path containing a given frame
function findP(xxps,frameTime) = let (
	p = [ for (p = xxps) if ( frameTime >= p[_startTime_] && frameTime <= p[_startTime_]+p[_time_]) p ][0]
) p ? p : frameTime < xxps[0][_startTime_] ? undef : xxps[len(xxps)-1];

// Total duration of the animation
function totTime(xxps) = sum( [ for (p = xxps) p[_time_] ] );


function cmove(curPos,p) =
	p[_pos_] != undef ? p[_pos_] :
		p[_move_] != undef ? curPos + p[_move_] :
			p[_cameraAndView_] != undef ? let ( cv = p[_cameraAndView_] ) vpdrt2cvz(cv[0], cv[1], cv[2])[0] :
				curPos;

function vStraightAheadPos(t,dist,cxxpoints) = let (
	t0 = t > 0.1 ? t-0.1 : 0.01,
	t1 = t > 0.1 ? t : 0.11,
	cp1 = findPos(cxxpoints,undef,t1)[0],
	cp0 = findPos(cxxpoints,undef,t0)[0],
	dir = unit(cp1-cp0),
	pos = cp1 + dir * dist
) /*echo("vStraightAheadPos>>",t=t,t0=t0,cp0=cp0,t1=t1,cp1=cp1,dist=dist,pos=pos)*/ pos;

