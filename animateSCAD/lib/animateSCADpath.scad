
use <animateSCADtransformations.scad>
use <animateSCADsplines.scad>
use <animateSCADutil.scad>
include <animateSCADcamera.scad>


// Show children, possibly illustrate the camera path
// showPath = -1 -> no model, only speed graphs
// showPath = 0 -> no illustration
// showPath = 1 -> show camera path only
// showPath = 2 -> also show view lines
module showWithPath(showPath) {
	module viewLine(t) { cvPos = findCvz($camera[5],$camera[11],t); line(cvPos[0],cvPos[1]); }
	module barChart(xxps,y,c1,c2) {
		totTime = totTime(xxps);
		for ( t = [0:0.1:totTime]) {
			speed = norm(findPos(xxps,t+0.01)[0]-findPos(xxps,t+0.06)[0])/0.05;
			translate([t*10,y,0]) color( t-floor(t+0.01) < 0.01 ? c1 : c2) cylinder(r=0.5,h=speed/10);
		}
		for (p = xxps) translate([p[_startTime_] * 10,y,0]) color("red") cube(1, center = true);
		translate([totTime * 10,y,0]) color("red") cube(1, center = true);
	}
	if (showPath > 0 && $frameNo == undef) {
		crLines( [for (p = $camera[4]) p[_pos_]] );
		if (showPath > 1) {
			totTime = totTime($camera[5]);
			for (t = [0:0.2:totTime]) color( t-floor(t+0.01) < 0.01 ? "blue" : "lightblue", 0.05) viewLine(t+0.001);
		}
	}
	if (showPath < 0 && $frameNo == undef) {
		barChart($camera[5],0,"blue","lightblue");
		barChart($camera[11],10,"green","lightgreen");
	} else {
		children();
	}
}

