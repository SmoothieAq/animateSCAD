
use <transformations.scad>
use <splines.scad>
use <path.scad>
use <speed.scad>
use <util.scad>
use <cameraUtil.scad>
use <pointx.scad>


/*
This is the fist transformation from the vpoints vector to the vxpoints vector.
We make sure each point has absolute endTime positions. cRel is changed to be the referenced cxxp.
We cary forward zoom and accel when they are not set.
 */
function vxpoints(vpoints,cxpoints,cxxpoints) = let (
	ps = [ for (p = vpoints)
		let (
			cp0 = findcxx(cp_cRel(p)[0], cxxpoints),
			cp = cp0 == undef ? findcxx(cp_cRel(p)[0], cxpoints) : cp0
		) cpointx(p, cRel = cp, endTime = cp_startTime(cp) + cp_time(cp) + cp_cRel(p)[1], pname = nnv(cp_pname(p), str(cp_pname(cp), "/" , cp_cRel(p)[1])))
	]
) [ for (
		i = 0,
		p = ps[i],
		startTime = 0,
		endTime = 0,
		time = 0,
		pos = vmove([0,0,0],p,cxpoints),
		zoom = nnv(cp_zoom(p), 50),
		accel = nnv(cp_accel(p), 100),
		prevStraightAhead = cp_straightAhead(p),
		straightAhead = false;
	i < len(vpoints);
		i = i+1,
		p = ps[i],
		startTime = endTime,
		endTime = cp_endTime(p),
		time = endTime - startTime,
		pos = vmove(pos, p, cxxpoints, endTime),
		zoom = nnv(cp_zoom(p), zoom),
		accel = nnv(cp_accel(p), accel),
		straightAhead = prevStraightAhead && cp_straightAhead(p) ? cp_straightAhead(p) : false,
		prevStraightAhead = cp_straightAhead(p)
) /*echo(i,startTime=startTime,time=time,endTime=endTime,prevStraightAhead,straightAhead,cp_straightAhead(p))*/ cpointx(p,startTime=startTime,time=time,pos=pos,zoom=zoom,accel=accel,straightAhead=straightAhead) ];

function vmove(curPos,p,cxxpoints,startTime) =
	cp_pos(p) != undef ? cp_pos(p) :
		cp_move(p) != undef ? curPos + cp_move(p) :
			cp_cameraAndView(p) != undef ? let ( cv = cp_cameraAndView(cp_cRel(p)) ) vpdrt2cvz(cv[0], cv[1], cv[2])[1] :
				cp_straightAhead(p) != undef ? vStraightAheadPos(startTime, cp_straightAhead(p), cxxpoints) :
					curPos;

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
		prevPos = cp_pos(vxpoints[0]);
	i < len(vxpoints);
		i = i+1,
		p = vxpoints[i],
		m = ms[i-1],
		leng = prevPos == cp_pos(p) ? 0 : crLeng(m),
		prevPos = cp_pos(p),
		startSpeed = endSpeed,
		nextStop = i + 1 < len(vxpoints) && norm(cp_pos(p) - cp_pos(vxpoints[i+1])) < 0.1,
		stta = i >= len(vxpoints) ? [] : leng > 0 ? stta(startSpeed, leng, cp_accel(p), cp_time(p), undef, nextStop) : [0, time, 0],
		endSpeed = cp_straightAhead(p) ? 50 : stta[0],
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(vxpoints) ) ? echo(cp_pname(p), startTime = cp_startTime(p), time = cp_time(p), leng = leng, vpos = cp_pos(p)) 1 : 0
) if (i > 0) cpointx(p,splineM=m,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2],nextStop=nextStop) ];

function vcrSplineMs(ps,s=0.3) = [ for (i = [0:len(ps)-2])
	let (
		p0 = (i == 0 || cp_straightAhead(ps[i]) || cp_straightAhead(ps[i+1])) ? cp_pos(ps[i]) : cp_pos(ps[i-1]),
		p1 = cp_pos(ps[i]),
		p2 = cp_pos(ps[i+1]),
		p3 = (i == len(ps)-2 || cp_straightAhead(ps[i+2]) || cp_straightAhead(ps[i+1])) ? cp_pos(ps[i+1]) : cp_pos(ps[i+2])
	)
	/*echo(p0,p1,p2,p3,cp_straightAhead(ps[i+2]),cp_straightAhead(ps[i+1]))*/ crSplineM(p0,p1,p2,p3,s=s)
];

