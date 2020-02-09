
use <../animateSCAD/animateSCAD.scad>

module myModel() {
	color("blue") cube([10,14,18],center=true);
	color("green") translate([0,-30,40]) sphere(r=4,$fa=1,$fs=0.1);
}

$fps = 10;
$frameNo = undef;

$camera = camera(cpoints=[
	cpoint("p10",pos=[110,110,210]),
		cpoint("p20",move=[-50,-20,-175],speed=150),
		cpoint("p30",pos=[20,0,-60],speed=50),
		cpoint("p40",pos=[80,-80,0],speed=100),
//		cpoint("p50",move=[70,-20,140]),
		cpoint("p60",pos=[90,-90,95])
	],vpoints=[
		vpoint(["p20",0],standStill=true),
		vpoint(["p30",0],pos=[0,-30,40]),
		vpoint(["p30",0.3],pos=[0,-30,40]),
		vpoint(["p40",0.3],pos=[0,0,0])
	]);

$vpd = $camera[0];
$vpr = $camera[1];
$vpt = $camera[2];

animation(showPath=2) myModel();

//