

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
function crSplineT(m,u) = [pow(u,3),pow(u,2),u,1]*m;

function crPoints(m,n) = [ for (i = [0:n]) crSplineT(m,i/n) ];
module crLine(crPoints) color("green",0.3) for (i = [0:len(crPoints)-2]) { *echo(i); line(crPoints[i],crPoints[i+1]); }

function crLeng(m,nsegments=20) = pathleng([ for (i = [0:nsegments]) crSplineT(m,i/nsegments) ]);
function pathleng(points,i=0) = i+1 >= len(points) ? 0 : norm(points[i]-points[i+1])+pathleng(points,i+1);

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

