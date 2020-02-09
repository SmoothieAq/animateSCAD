/*
Speed and time of a path

When calculating xxpoint, we will always know:
	s0	start speed
	a	accelearation
	l	length of path

And we will know either
	s	cruse speed
or
	tt	time to travel path

A path travel consist of an (possible empty and possible negative) acceleration segment and then a segment crusing
at s speed. For the full path travel, the following is then true:
	l = ta * s0 + ta * (s - s0) / 2 + (tt - ta) * s
where ta is the time the acceleration segment ends, and
	ta * a = abs(s - s0)

With some help from wolframalpha.com, we can deduce the following.

If we know tt, then s is:
	let
		p1 = a * a * tt * tt
		p2 = 2 * a * l,
		p3 = 2 * a * s0 * tt
		px = p1 + p2 - p3
		py = p1 - p2 + p3
	if py <= 0 then a is not large enough; we then change a to be just large enough:
	 	s = 2 * l * tt - s0
		a = abs(s - s0) / tt
	else if py > px then s will be less than s0 and:
		sqrt( px ) - a * tt + s0
	else s will be larger than or equal s0 and:
		-sqrt( py ) + a * tt + s0

If we know s, we can find tt:
	tt = (2 * l - s0 * ta + s * ta) / (2 * s), where ta = abs(s - s0)
if that was negative, then a is not large enough; we then change a to be just large enough:
	tt = 2 * l / (s0 + s)
	a = abs(s - s0) / tt

We can then calculate how far lt we are along the path at time t:
	lt = ta * s0 + ta * sign(s - s0) * ta * a / 2 + tb * s
where
	ta = min(t, abs(s - s0)/a)
	tb = max(0, t - abs(s - s0)/a)
*/

function stta(s0,l,a,tt,s) =
	tt != undef ?
		let (
			p1 = a * a * tt * tt,
			p2 = 2 * a * l,
			p3 = 2 * a * s0 * tt,
			px = p1 + p2 - p3,
			py = p1 - p2 + p3,
			s_ = py <= 0 ? 2 * l * tt - s0 : py > px ? sqrt( px ) - a * tt + s0 : -sqrt( py ) + a * tt + s0,
			a_ = py <= 0 ? abs(s_ - s0) / tt : a
		) /*echo("find s",s0=s0,l=l,tt=tt,p1=p1,p2=p2,p3=p3,px=px,py=py,s=s_,a=a,a_=a_)*/ [s_,tt,a_] :
		let (
			ta = abs(s - s0) / a,
			tt_a = (2 * l - s0 * ta + s * ta) / (2 * s),
			tt_ = tt_a > 0 ? tt_a : 2 * l / (s0 + s),
			a_ = tt_a > 0 ? a : abs(s - s0) / tt_
		) /*echo("find tt",s0=s0,l=l,s=s,ta=ta,tt_a=tt_a,tt=tt_,a=a,a_=a_)*/ [s,tt_,a_];

function lt(t,s0,s,a) = s == 0 ? 0 : let (
		ta = min(t, abs(s - s0)/a),
		tb = max(0, t - abs(s - s0)/a),
		a1 = ta * s0,
		a2 = ta * sign(s - s0) * ta * a / 2,
		a = a1 + a2,
		b = tb * s,
		lt = a + b
	) /*echo("lt",s0=s0,s1=s,a=a,ta=ta,tb=tb,a1=a1,a2=a2,a=a,b=b,lt=lt)*/ lt;