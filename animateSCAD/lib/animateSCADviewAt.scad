
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADpath.scad>
use <animateSCADspeed.scad>
use <animateSCADutil.scad>
use <animateSCADcameraUtil.scad>

include <animateSCADpointx.scad>


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
		) cpointx(p,cRel=cp,endTime=cp[_startTime_]+cp[_time_]+p[_cRel_][1],pname=nnv(p[_pname_],str(cp[_pname_],"/",p[_cRel_][1])))
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

