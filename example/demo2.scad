
use <../animateSCAD/animateSCAD.scad>

module part1()
	difference() {
		cube(80, center = true);
		sphere(r=50,$fa=1,$fs=0.1);
	}

module part2()
//	translate([-40,-190,90])
		intersection()
			for(i = [ [ 0, 0, 0], [ 10, 20, 300], [200, 40, 57], [ 20, 88, 57] ])
			rotate(i) cube([100, 20, 20], center = true);

module myModel() {
	color("cornflowerblue") part1();
	color("olive") move("part2",[
		mpoint(pos=[-840,-190,90]),
		mpoint(cRel=["p20",-0.6],pos=[-110,-190,90]),
		mpoint(cRel=["p20",0],pos=[-40,-190,90]),
		mpoint(cRel=["p40",0],pos=[-40,-250,90]),
		mpoint(move=[0,-100,0],speed=30)
	]) part2();
}

$fps = 5;
$frameNo = undef;
$showPath = -2;

$camera = camera(cpoints=[
		cpoint("p10",cameraAndView=[1900,[73,0,145],[45,-70,85]],speed=400),
		cpoint("p20",pos=[350, 120, 40]),
//		cpoint("p25",pos=[140, -5, 0]),
		cpoint("p30",pos=[50,0,0],speed=40),
		cpoint("p40",pos=[15,-50,10]),
		cpoint("p50",pos=[120, -200, 50],speed=200),
		cpoint("p60",cameraAndView=[1300,[77,0,40],[-47,-30,90]]),
	],vpoints=[
		vpoint(["p10",0],cameraAndView=true),
		vpoint(["p20",0],pos=[0,0,0]),
		vpoint(["p30",-0.1],straightAhead=100),
		vpoint(["p30",0],straightAhead=100),
		vpoint(["p40",-0.8],pos=[-40,-190,90]),
		vpoint(["p60",-2]),
		vpoint(["p60",0],pos=[100,0,0])
	]);

$vpd = $camera[0];
$vpr = $camera[1];
$vpt = $camera[2];

animation() myModel();

//