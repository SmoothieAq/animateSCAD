
use <../animateSCAD/animateSCAD.scad>

module myModel() {
	color("blue") cube([10,14,18],center=true);
	color("green") translate([0,-30,40]) sphere(r=4,$fa=1,$fs=0.1);
}

$fps = 30;
$frameNo = undef;

$camera = camera(cpoints=[
	cpoint("p10",pos=[110,110,210]),
		cpoint("p20",move=[-50,-50,-175],speed=150),
		cpoint("p30",pos=[20,-20,-40],speed=50),
		cpoint("p40",pos=[40,-40,0]),
//		cpoint("p50",move=[70,-20,140]),
		cpoint("p60",pos=[-45,65,95])
	],vpoints=[
		vpoint(["p20",0],standStill=true),
		vpoint(["p30",0],pos=[0,-30,40]),
		vpoint(["p30",0.5],pos=[0,-30,40]),
		vpoint(["p40",1],pos=[0,0,0])
	]);

$vpd = $camera[0];
$vpr = $camera[1];
$vpt = $camera[2];

animation(showPath=2) myModel();

//