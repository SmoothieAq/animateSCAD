
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADutil.scad>
include <animateSCADcamera.scad>

spacing = 30;

// Show children, possibly illustrate the camera path
// $showPath = -1 -> no model, only speed graphs
// $showPath = 0 -> no illustration
// $showPath = 1 -> show camera path only
// $showPath = 2 -> also show view lines
module showWithPath() {

	if ($showPath > 0 && $frameNo == undef) {
		xxcrLines( [for (p = $camera[4]) p[_pos_]], $camera[5], dotColor="SpringGreen", color="green" );
		xxcrLines( [for (p = $camera[10]) p[_pos_]], $camera[11], dotColor="DeepPink", color="pink" );
		if ($showPath > 1) {
			totTime = totTime($camera[5]);
			for (t = [0:0.2:totTime]) {
				color(t - floor(t + 0.01) < 0.01 ? "blue" : "lightblue", 0.05) viewLine(t + 0.001);
//				color("red") viewVector(t + 0.001);
			}
		}
	}
	if ($showPath < 0 && $frameNo == undef) {
		barChart($camera[5],undef,0,"darkgreen","lightgreen","springgreen");
		barChart($camera[11],$camera[5],spacing,"palevioletred","pink","deeppink");
		if ($showPath < -1) children();
	} else {
		children();
	}
}

module showPartWithPath(partName,mxps,mxxps) {
	if ($showPath > 0 && $frameNo == undef) {
		xxcrLines( [for (p = mxps) p[_pos_]],mxxps, dotColor="Brown", color="Orange" );
	}
	if ($showPath < 0 && $frameNo == undef) {
		if ($showPath < -1) {
			barChart(mxxps, undef, 2 * spacing, "pink", "pink", "pink");
			children();
		}
	} else {
		children();
	}
}

module viewLine(t) {
	cvPos = findCvz($camera[5],$camera[11],t);
	line(cvPos[0],cvPos[1]);
	echo(t=t,cpos=cvPos[0],vpos=cvPos[1]);
}

module viewVector(t) {
	t0 = t > 0.1 ? t-0.1 : 0.01;
	t1 = t > 0.1 ? t : 0.11;
	cp = findPos($camera[5],undef,t)[0];
	cp1 = findPos($camera[5],undef,t1)[0];
	cp0 = findPos($camera[5],undef,t0)[0];
	dir = unit(cp1-cp0);
	posx = cp + dir * 100;
	line(cp,posx); echo(t=t,cp=cp,posx=posx,dir=dir);
}

module barChart(xxps,cxxps,y,c1,c2,c3) {
	totTime = totTime(xxps);
	for ( t = [0:0.1:totTime-0.06]) {
		p1 = findPos(xxps,cxxps,t+0.01)[0];
		p0 = findPos(xxps,cxxps,t+0.06)[0];
		speed = norm(p1-p0)/0.05;
//		echo("speed",y=y,t=t,p0=p0,p1=p1,speed=speed);
		translate([t*10,y,0]) color( t-floor(t+0.01) < 0.01 ? c1 : c2) cylinder(r=0.5,h=speed/10);
	}
	for (p = xxps) translate([p[_startTime_] * 10,y,0]) color(c3) cube(1, center = true);
	translate([totTime * 10,y,0]) color(c3) cube(1, center = true);
}

module xxcrLines(ps,xxps,nsegments=20, color="green", dotColor="red") {
	color(dotColor) for (p = ps) translate(p) cube(1,center=true);
	ms = [ for (p=xxps) p[_splineM_] ];
	for (i = [1:len(ms)]) if (norm(ps[i]-ps[i-1]) > 0.05) crLine(crPoints(ms[i-1],nsegments),color=color);
}

