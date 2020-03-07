
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
	[nnv(cpoint[_pname_],pname),nnv(pos,cpoint[_pos_]),nnv(move,cpoint[_move_]),nnv(cameraAndView,cpoint[_cameraAndView_]),nnv(standStill,cpoint[_standStill_]),
	 nnv(speed,cpoint[_speed_]),nnv(time,cpoint[_time_]),nnv(accel,cpoint[_accel_]),
	 nnv(cRel,cpoint[_cRel_]),nnv(straightAhead,cpoint[_straightAhead_]),nnv(zoom,cpoint[_zoom_]),
	 nnv(splineM,cpoint[_splineM_]),nnv(startTime,cpoint[_startTime_]),
	 nnv(leng,cpoint[_leng_]),nnv(startSpeed,cpoint[_startSpeed_]),nnv(endSpeed,cpoint[_endSpeed_]),nnv(endTime,cpoint[_endTime_]),nnv(nextStop,cpoint[_nextStop_]),
	 nnv(color,cpoint[_color_]),nnv(rotate,cpoint[_rotate_]),nnv(prevColor,cpoint[_prevColor_]),nnv(prevRotate,cpoint[_prevRotate_])];

