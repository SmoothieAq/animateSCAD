
use <util.scad>

/*
A full path is specified as a vector of .points. We use such full paths for camera position, viewAt position, and part position.
A cpoint specifies both a point on the full travel, and it specifies some properties of the path between the previous
point and this point.
As a preperation we transform the original .points to first .xpoints (xps for short) and then .xxpoints (xxps for short).
However all are held in an increasingly rich cpointx vector - we index this vector with the _constant_ indexes below.
*/
_pname_ = 0; // name of (sub)path - only for c..points
_pos_ = 1; // absolute position - always set in .xpoints
_move_ = 2; // relative move - not used after .xpoints
_cameraAndView_ = 3; // in cpoints: [vpr, vpt, vpd] from OpenSCAD viewer; in vpoints: if true read from cpoints; not used after .xpoints
_standStill_ = 4; // no move; not used after .xpoints
_speed_ = 5; // crusing speed, only for cpoints
_time_ = 6; // time to travel path, initially only for cpoints
_accel_ = 7; // acceletartion

_cRel_ = 8; // [pname,relTime], start time relative to cpoint start time - only for v..points
_straightAhead_ = 9; // a distance, keep viewAt straight ahead of camera move with that distance
_zoom_ = 10; // camera zoom (but specified on vpoints)

// the following are set in .xxpoints
_splineM_ = 11; // spline matrix for path
_startTime_ = 12; // start time for path
_leng_ = 13; // length of path
_startSpeed_ = 14;
_endSpeed_ = 15;
_endTime_ = 16; // only for vxpoints
_nextStop_ = 17; // next (sub)path is not moving

// for move only
_color_ = 18; // [r,g,b,a] color inclusive alpha, if [] then no color([r,g,b,a]) is used
_rotate_ = 19; // [xr,yr,zr,x,y,z] where x, y, z defaluts to [0,0,0] does a rotate([xr,yr,zr]) translate([x,y,z]) before moveing, if [] then no rotate is done
_prevColor_ = 20;
_prevRotate_ = 21;


function cpointx(cpoint,pname,pos,move,cameraAndView,standStill,speed,time,accel,cRel,straightAhead,zoom,splineM,startTime,leng,startSpeed,endSpeed,endTime,nextStop,color,rotate,prevColor,prevRotate) =
	[nnv(cpoint[0],pname),nnv(pos,cpoint[1]),nnv(move,cpoint[2]),nnv(cameraAndView,cpoint[3]),nnv(standStill,cpoint[4]),
	 nnv(speed,cpoint[5]),nnv(time,cpoint[6]),nnv(accel,cpoint[7]),
	 nnv(cRel,cpoint[8]),nnv(straightAhead,cpoint[9]),nnv(zoom,cpoint[10]),
	 nnv(splineM,cpoint[11]),nnv(startTime,cpoint[12]),
	 nnv(leng,cpoint[13]),nnv(startSpeed,cpoint[14]),nnv(endSpeed,cpoint[15]),nnv(endTime,cpoint[16]),nnv(nextStop,cpoint[17]),
	 nnv(color,cpoint[18]),nnv(rotate,cpoint[19]),nnv(prevColor,cpoint[20]),nnv(prevRotate,cpoint[21])];

function cp_pname(cp) = cp[0]; // name of (sub)path - only for c..points
function cp_pos(cp) = cp[1]; // absolute position - always set in .xpoints
function cp_move(cp) = cp[2]; // relative move - not used after .xpoints
function cp_cameraAndView(cp) = cp[3]; // in cpoints: [vpr, vpt, vpd] from OpenSCAD viewer]; in vpoints: if true read from cpoints]; not used after .xpoints
function cp_standStill(cp) = cp[4]; // no move]; not used after .xpoints
function cp_speed(cp) = cp[5]; // crusing speed, only for cpoints
function cp_time(cp) = cp[6]; // time to travel path, initially only for cpoints
function cp_accel(cp) = cp[7]; // acceletartion

function cp_cRel(cp) = cp[8]; // [pname,relTime], start time relative to cpoint start time - only for v..points
function cp_straightAhead(cp) = cp[9]; // a distance, keep viewAt straight ahead of camera move with that distance
function cp_zoom(cp) = cp[10]; // camera zoom (but specified on vpoints)

// the following are set in .xxpoints
function cp_splineM(cp) = cp[11]; // spline matrix for path
function cp_startTime(cp) = cp[12]; // start time for path
function cp_leng(cp) = cp[13]; // length of path
function cp_startSpeed(cp) = cp[14];
function cp_endSpeed(cp) = cp[15];
function cp_endTime(cp) = cp[16]; // only for vxpoints
function cp_nextStop(cp) = cp[17]; // next (sub)path is not moving

// for move only
function cp_color(cp) = cp[18]; // [r,g,b,a] color inclusive alpha, if [] then no color([r,g,b,a]) is used
function cp_rotate(cp) = cp[19]; // [xr,yr,zr,x,y,z] where x, y, z defaluts to [0,0,0] does a rotate([xr,yr,zr]) translate([x,y,z]) before moveing, if [] then no rotate is done
function cp_prevColor(cp) = cp[20];
function cp_prevRotate(cp) = cp[21];
