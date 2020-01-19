
use <../animateSCAD/animateSCAD.scad>

module myModel() {
	color("blue") cube([10,14,18]);
}
/*
$camera = camera(fps=2, points= [
	cpoint( cameraAbsolute=[100,100,70], speed=50 ),
	cpoint( openScad=[5,[2,3,4],[5,6,7]]),
	cpoint( cameraUp=40, viewAtLeft=20, time=3 ),
]);

$vpd = $camera[0];
$vpr = $camera[1];
$vpt = $camera[2];

view($camera) myModel();
*/

$camera = camera(cpoints=[
	cpoint(cameraAbsolute=[110,110,210]),
	cpoint(cameraTranslate=[-50,-50,-175]),
	cpoint(cameraAbsolute=[0,30,-10]),
	cpoint(cameraTranslate=[70,35,140]),
	cpoint(cameraAbsolute=[45,65,95])
],fps=60);

$vpd = $camera[0];
$vpr = $camera[1];
$vpt = $camera[2];


animation(showPath=true) myModel();
