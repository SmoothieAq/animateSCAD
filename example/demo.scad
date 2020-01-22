
use <../animateSCAD/animateSCAD.scad>

module myModel() {
	color("blue") cube([10,14,18],center=true);
	color("green") translate([0,-20,0]) sphere(r=4,$fa=1,$fs=0.1);
}

$fps = 30;
$frameNo = undef;

$camera = camera(cpoints=[
	cpoint(cameraAbsolute=[110,110,210]),
	cpoint(cameraTranslate=[-50,-50,-175],speed=150),
	cpoint(cameraAbsolute=[-20,-20,-40],speed=50),
	cpoint(cameraAbsolute=[0,-40,0],viewAtAbsolute=[0,-20,0]),
	cpoint(cameraTranslate=[70,-20,140]),
	cpoint(cameraAbsolute=[-45,65,95])
]);

$vpd = $camera[0];
$vpr = $camera[1];
$vpt = $camera[2];

animation(showPath=0) myModel();

//