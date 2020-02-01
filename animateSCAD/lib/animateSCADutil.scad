
function nnv(v,d) = v != undef ? v : d;

function sum(v,i=0) = i >= len(v) ? 0 : v[i] + sum(v,i+1);

// scale matrix
function mscale(s) = [ for (i = [0:2]) [ for (j = [0:2]) i == j ? s[i]: 0 ] ];

function unit(v) = v/norm(v);

function transpose(M) = [ for (j = [0:2]) [ for (i = [0:2]) M[i][j] ] ];

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

