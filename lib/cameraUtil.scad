
use <transformations.scad>
use <splines.scad>
use <path.scad>
use <speed.scad>
use <util.scad>
use <pointx.scad>

function findcxx(pname,cxxs) = let ( i = search([pname],cxxs) ) cxxs[i[0]];

// Find the the camera pos, viewAt pos and zoom for a given frameTime
function findCvz(cxxps,vxxps,frameTime) = let (
		cpos = findPos(cxxps,undef,frameTime),
		vpos = findPos(vxxps,cxxps,frameTime),
		zoom = 1
	) [cpos[0],vpos[0],zoom,cpos[1],cpos[2],cpos[3]];

// Find the the pos for a given frameTime
function findPos(xxps,cxxps,frameTime) = let (
	p = findP(xxps,frameTime), // the path where the frame are in
	pname = cp_pname(p),
	deltaTime = frameTime-cp_startTime(p) // time from beginning of the path
) !p ? p : cp_straightAhead(p) ?
	let (
		straightAhead = cp_straightAhead(p),
		pos = vStraightAheadPos(frameTime,straightAhead,cxxps)
	) /*echo("findPos",pname,frameTime=frameTime,deltaTime=deltaTime,straightAhead=straightAhead,pos=pos)*/ [pos,deltaTime,undef,pname,p] :
	let (
		deltaLeng = lt(deltaTime,cp_startTime(p),cp_speed(p),cp_accel(p),cp_time(p),cp_nextStop(p)),
		delta = cp_leng(p) < 0.01 || deltaLeng < 0.01 ? 0.01 :  cp_leng(p) - deltaLeng < 0.01 ? 1 : deltaLeng / cp_leng(p),
		pos = cp_leng(p) < 0.01 ? cp_pos(p) : crSplineT(cp_splineM(p),delta)
	) /*echo("findPos",pname,frameTime=frameTime,deltaTime=deltaTime,deltaLeng=deltaLeng,delta=delta,pos=pos)*/ [pos,deltaTime,delta,pname,p];


/// Find the path containing a given frame
function findP(xxps,frameTime) = let (
	p = [ for (p = xxps) if ( frameTime >= cp_startTime(p) && frameTime <= cp_startTime(p) + cp_time(p)) p ][0]
) p ? p : frameTime < cp_startTime(xxps[0]) ? undef : xxps[len(xxps)-1];

// Total duration of the animation
function totTime(xxps) = sum( [ for (p = xxps) cp_time(p) ] );


function cmove(curPos,p) =
	cp_pos(p) != undef ? cp_pos(p) :
		cp_move(p) != undef ? curPos + cp_move(p) :
			cp_cameraAndView(p) != undef ? let ( cv = cp_cameraAndView(p) ) vpdrt2cvz(cv[0], cv[1], cv[2])[0] :
				curPos;

function vStraightAheadPos(t,dist,cxxpoints) = let (
	t0 = t > 0.1 ? t-0.1 : 0.01,
	t1 = t > 0.1 ? t : 0.11,
	cp1 = findPos(cxxpoints,undef,t1)[0],
	cp0 = findPos(cxxpoints,undef,t0)[0],
	dir = unit(cp1-cp0),
	pos = cp1 + dir * dist
) /*echo("vStraightAheadPos>>",t=t,t0=t0,cp0=cp0,t1=t1,cp1=cp1,dist=dist,pos=pos)*/ pos;

