/*

Model(or model), World and View spaces: http://www.codinglabs.net/article_world_view_projection_matrix.aspx
Transformation to View space: https://www.3dgep.com/understanding-the-view-matrix/

We use a "Look At Camera" with Eye position, up vector and target point (and zoom)
*/


use <animateSCADutil.scad>

// from [camPos,viewAtPos,zoom] to [vpd,vpr,vpt,compress/expand]
function cvz2vpdrtx(cvz) = let (
		camPos = cvz[0],
		viewAtPos = cvz[1],
		zoom = cvz[2],
		camTop = [0,0,1],
		camDir = unit(viewAtPos-camPos),
		camDist = norm(camPos-viewAtPos),
		rot = camRot(camDir,camTop),
		irot = transpose(rot),
		vpd = zoom*camDist,
		vpr = RM2EAxyz(camRot(camDir,camTop)),
		vpt = viewAtPos,
		vpx = irot*mscale([1,1,zoom])*rot
	) //echo(camPos=camPos,viewAtPos=viewAtPos,zoom=zoom,camTop=camTop,camDir=camDir,camDist=camDist,vpd=vpd,vpr=vpr,vpt=vpt,vpx=vpx)
	[ vpd, vpr, vpt, vpx ];

// from OpenSCAD vpd, vpr, vpt to [campPos,viewAtPos,zoom]
function vpdr2cvz(vpd, vpr, vpt) = let (
		camDir = EAxyz2CamDir(vpr),
		camPos = vpt-camDir*vpd,
		viewAtPos = vpt,
		zoom = 1
	) //echo(vpr=vpr,camDir=camDir,camPos=camPos,viewAtPos=viewAtPos)
	[camPos,viewAtPos,zoom];

module asView(x) multmatrix(x) children();

// converts a rotation matrix into the Euler angles
// with the order Rx.Ry.Rz
// adapted from http://forum.openscad.org/How-to-set-camera-angle-td22497.html by Ronaldo
function RM2EAxyz(M) =
	let( sy = norm([M[0][0],M[0][1]]) )
	sy > 1e-6 ?
		[   atan2(M[1][2], M[2][2]),
			atan2(-M[0][2], sy),
			atan2(M[0][1], M[0][0]) ] :
		[   atan2(-M[2][1], M[1][1]),
			atan2(-M[0][2], sy),
			0 ];

// the rotation matrix of a camera local system
// adapted from http://forum.openscad.org/How-to-set-camera-angle-td22497.html by Ronaldo
function camRot(dir,top) =
	let(	dx = cross(dir,top),
			dy = -cross(dir,dx) )
	[unit(dx), unit(dy), -unit(dir)];

// from Euler angles to camera direction
// adapted from https://stackoverflow.com/questions/1568568/how-to-convert-euler-angles-to-directional-vector by Adisak (third column of the ORDER_XYZ)
function EAxyz2CamDir(vpr) = [-sin(vpr.x)*sin(vpr.z),sin(vpr.x)*cos(vpr.z),-cos(vpr.x)];

