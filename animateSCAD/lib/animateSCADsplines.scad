
use <animateSCADutil.scad>

// Catmull-Rom Spline after http://www.cs.cmu.edu/~jkh/462_s07/08_curves_splines_part2.pdf
s = 0.5;
crBasis = [
	[ -s, 2-s, s-2, s ],
	[ 2*s, s-3, 3-2*s, -s ],
	[ -s, 0, s, 0 ],
	[ 0, 1, 0, 0]
];
function crSplineM(p0,p1,p2,p3) = crBasis*[p0,p1,p2,p3];
function crSplineMs(ps) = [ for (i = [0:len(ps)-2])
	let (
		p0 = i == 0 ? ps[i] : ps[i-1],
		p3 = i == len(ps)-2 ? ps[i+1] : ps[i+2]
	)
		crSplineM(p0,ps[i],ps[i+1],p3)
];

function crSplineU(m,u) = [pow(u,3),pow(u,2),u,1]*m;

function crSplineT(m,t,nsegments=50) = let (
		ss = sSegments(m,0,1,0,nsegments),
		leng = ss[len(ss)-1][2],
		tLeng = leng*t-leng/100000,
		sf = sFindSegment(ss,tLeng,0,len(ss)-1),
		ss2 = sSegments(m,sf[0],sf[2],sf[1],nsegments/2),
		scl = sf[3]/(ss2[len(ss2)-1][2]-ss2[0][2]),
		ss2s = sScaleSegments(ss2,scl),
		sf2 = sFindSegment(ss2s,tLeng,0,len(ss2s)-1),
		u = sf2[0]+(sf2[2]-sf2[0])*(tLeng-sf2[1])/sf2[3]
	) crSplineU(m, leng == 0 ? 0 : u);

function sSegments(m,u0,u1,leng0,nsegments=30) =
	[ for (
			i = 0, u = u0, p1 = crSplineU(m,u), p2 = p1, l = 0, tot = leng0;
		i <= nsegments;
			i = i+1, u = u0+i*(u1-u0)/nsegments, p1 = p2, p2 = crSplineU(m,u), l = norm(p2-p1), tot = tot+l
	) [u,l,tot] ];

function sScaleSegments(ss,scl) =
	[ for (
			i = 0, l = ss[i][1]*scl, tot = ss[i][2];
		i < len(ss);
			i = i+1, l = ss[i][1]*scl, tot = tot+l
	) [ss[i][0],l,tot] ];

function sFindSegment(ss,tLeng,n,m) =
	n != m ?
		let ( i = n + floor((m-n)/2) ) ss[i][2] > tLeng ? sFindSegment(ss,tLeng,n,i) : sFindSegment(ss,tLeng,i+1,m) :
		[ss[m-1][0],ss[m-1][2],ss[m][0],ss[m][1]];

function crPoints(m,n) = [ for (i = [0:n]) crSplineU(m,i/n) ];
module crLine(crPoints) color("green",0.3) for (i = [0:len(crPoints)-2]) { *echo(i); line(crPoints[i],crPoints[i+1]); }

function crLeng(m,nsegments=30) = pathleng([ for (i = [0:nsegments]) crSplineU(m,i/nsegments) ]);
function pathleng(points,i=0) = sum( segmentLengths(points) );// i+1 >= len(points) ? 0 : norm(points[i]-points[i+1])+pathleng(points,i+1);

function segmentLengths(points) = [ for ( i = 0, p2 = points[i]; i < len(points); i = i+1, p1 = p2, p2 = points[i]) if (i > 0) norm(p2-p1) ];

module crLines(ps,nsegments=20) {
	color("red") for (p = ps) translate(p) cube(1,center=true);
	for (m = crSplineMs(ps)) crLine(crPoints(m,nsegments));
}

// after http://forum.openscad.org/Rods-between-3D-points-td13104.html
module line(p0,p1,r=0.3) {
	dir = p1-p0;
	h   = norm(dir);
	if(dir[0] == 0 && dir[1] == 0) {
		// no transformation necessary
		cylinder(r=r, h=h);
	} else {
		w  = dir / h; *echo(p0=p0,p1=p1,dir=dir,h=h,w=w);
		u0 = cross(w, [0,0,1]);
		u  = u0 / norm(u0);
		v0 = cross(w, u);
		v  = v0 / norm(v0);
		multmatrix(m=[
				[u[0], v[0], w[0], p0[0]],
				[u[1], v[1], w[1], p0[1]],
				[u[2], v[2], w[2], p0[2]],
				[0,    0,    0,    1]]
			)
				cylinder(r=r, h=h);
	}
}

