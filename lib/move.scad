
use <transformations.scad>
use <splines.scad>
use <path.scad>
use <speed.scad>
use <util.scad>
use <cameraUtil.scad>
use <pointx.scad>


module _move(partName,mpoints) {
	mxps = mxpoints(partName,mpoints);
	mxxps = mxxpoints(mxps,$camera[4],$camera[5]);
	frameTime = $camera[12];
	p = findPos(mxxps,undef,frameTime);
	showPartWithPath(partName,mxps,mxxps) mmove(p,mxps,mxxps) mcolor(p) mrotate(p) children();
}

module mmove(p,mxps,mxxps) {
	if ( p[0] )
		translate(p[0]) children();
	else if ( $showPath )
		translate(cp_pos(mxps[0])) children();
}

module mcolor(p) {
	function mid(a, b, i) = nnv(a[i], 1) + (nnv(b[i], 1) - nnv(a[i], 1)) * p[2];
	c1 = cp_color(p[4]);
	if (!c1) {
		children();
	} else {
		c0 = nnv(cp_prevColor(p[4]),c1);
		c = [ for (i=[0:3]) mid(c0,c1,i) ];
		echo(c0=c0,c1=c1,c=c);
		color(c) children();
	}
}

module mrotate(p) {
	function mid(a,b,i) = nnv(a[i],0) + (nnv(b[i],0)-nnv(a[i],0))*p[2];
	r1 = cp_rotate(p[4]);
	if (!r1) {
		children();
	} else {
		r0 = nnv(cp_rotate(p[4]),r1);
		r = [ for (i=[0:5]) mid(r0,r1,i) ];
		echo(r0=r0,r1=r1,r=r);
		if (r[3] || r[4] || r[5])
			translate([-r[3],-r[4],-r[5]]) rotate([r[0],r[1],r[2]]) translate([r[3],r[4],r[5]]) children();
		else
			rotate([r[0],r[1],r[2]]) children();
	}
}


/*
This is the fist transformation from the mpoints vector to the mxpoints vector.
We cary forward speed and accel, color and rotate when they are not set, and we set prevColor and prevRotate.
 */
function mxpoints(partName,mpoints) = [ for (
		i = 0,
		p = mpoints[i],
		pos = cmove([0,0,0],p),
		speed = nnv(cp_speed(p),50),
		accel = nnv(cp_accel(p),100),
		color = nnv(cp_color(p),[]),
		rotate = nnv(cp_rotate(p),[]),
		previousColor = color,
		previousRotate = rotate,
		prevColor = color,
		prevRotate = rotate;
	i < len(mpoints);
		i = i+1,
		p = mpoints[i],
		pos = cmove(pos,p),
		speed = nnv(cp_speed(p),speed),
		accel = nnv(cp_accel(p),accel),
		color = nnv(cp_color(p),color),
		rotate = nnv(cp_rotate(p),rotate),
		prevColor = previousColor,
		prevRotate = previousRotate,
		previousColor = color,
		previousRotate = rotate
)
	/*echo("mxpoint",pos=pos,speed=speed,accel=accel,color=color,prevColor=prevColor,rotate=rotate,prevRotate=prevRotate,pname=nnv(cp_pname(p),str(partName,"-",i)))*/
	cpointx(p,pos=pos,speed=speed,accel=accel,color=color,prevColor=prevColor,rotate=rotate,prevRotate=prevRotate,pname=nnv(cp_pname(p),str(partName,"-",i))) ];


/*
This is the second transformation from the mxpoints vector to the mxxpoints vector.
We make sure the following are now set: splineM, startSpeed, speed, startTime and time
 */
function mxxpoints(mxpoints,cxpoints,cxxpoints) = let (
	ms = crSplineMs([ for (p = mxpoints) cp_pos(p) ],s=0.4)
) [ for (
		i = 0,
		p = mxpoints[i],
		m = undef,
		time = undef,
		fromTime = undef,
		toTime = cp_cRel(p) ? mptime(cp_cRel(p),0,cxpoints,cxxpoints) : 0,
		endSpeed = cp_speed(mxpoints[1]),
		prevPos = cp_pos(cxpoints[0]);
	i < len(mxpoints);
		i = i+1,
		p = mxpoints[i],
		m = ms[i-1],
		leng = prevPos == cp_pos(p) ? 0 : crLeng(m),
		prevPos = cp_pos(p),
		startSpeed = endSpeed,
		nextStop = i + 1 < len(mxpoints) && norm(cp_pos(p) - cp_pos(mxpoints[i+1])) < 0.1,
		ptime = nnv(cp_time(p), cp_cRel(p) ? mptime(cp_cRel(p), toTime, cxpoints, cxxpoints) : undef),
		stta = i < len(mxpoints) ? stta(nnv(startSpeed, 0), leng, cp_accel(p), ptime, cp_speed(p), nextStop) : [],
		endSpeed = stta[0],
		time = stta[1],
		fromTime = toTime,
		toTime = fromTime+time,
		dummy = (($frameNo == undef || $frameNo < 1) && i > 0 && i < len(mxpoints) ) ? echo(cp_pname(p),startTime=fromTime,time=time,leng=leng,cpos=cp_pos(p),color=cp_color(p),rotate=cp_rotate(p)) 1 : 0
) if (i > 0) cpointx(p,splineM=m,time=time,startTime=fromTime,leng=leng,startSpeed=startSpeed,speed=stta[0],accel=stta[2],nextStop=nextStop) ];

function mptime(cRel,fromTime,cxpoints,cxxpoints) = let (
	cp0 = findcxx(cRel[0],cxxpoints),
	cp = cp0 ? cp0 : findcxx(cRel[0],cxpoints)
) cp_startTime(cp) + cp_time(cp) + cRel[1] - fromTime;
