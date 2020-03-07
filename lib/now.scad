
/*
After camera() has been called, these function can be used to access the current view etc...
 */

function now_vpd() 		= $camera[0]; // 	vpd (but if $frameNo != undef it will be 100)
function now_vpr() 		= $camera[1]; // 	vpr (but if $frameNo != undef it will be [0,0,0])
function now_vpt() 		= $camera[2]; // 	vpt (but if $frameNo != undef it will be [0,0,0])
function now_x() 		= $camera[3]; // 	x, transformation matrix for zoom
function now_cxpoints() = $camera[4]; // 	cxpoints
function now_cxxpoints()= $camera[5]; // 	cxxpoints
function now_rvpd() 	= $camera[6]; // 	vpd (the real one)
function now_rvpr() 	= $camera[7]; // 	vpr (the real one)
function now_rvpt() 	= $camera[8]; // 	vpt (the real one)
function now_rx() 		= $camera[9]; // 	x, transformation matrix for zoom (the real one)
function now_vxpoints() = $camera[10]; // 	vxpoints
function now_vxxpoints()= $camera[11]; // 	vxxpoints
function now_frameTime()= $camera[12]; //	frameTime
function now_totalTime()= $camera[13]; //	total time
