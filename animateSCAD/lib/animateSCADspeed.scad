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

If we know tt, we can find s:
	let v = sqrt( a * a * tt * tt - 2 * a * l - 1 * a * s0)
then a solution is a positive one off
	s = -v - a * tt + s0
	s = v - a * tt + s0
	s = -v + a * tt + s0
	s = v + a * tt + s0
if all was negative, then a is not large enough; we then change a to be just large enough:
 	s = 2 * l * tt - s0
	a = abs(s - s0) / tt

If we know s, we can find tt:
	tt = (2 * l - s0 * ta + s * ta) / (2 * s), where ta = abs(s - s0) / a
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
			v = sqrt( a * a * tt * tt - 2 * a * l - 1 * a * s0),
			s_a = -v - a * tt + s0,
			s_b = s_a > 0 ? s_a : -v + a * tt + s0,
			s_c = s_b > 0 ? s_b : v - a * tt + s0,
			s_d = s_c > 0 ? s_c : v + a * tt + s0,
			s_ = s_d > 0 ? s_d : 2 * l * tt - s0,
			a_ = s_d > 0 ? a : abs(s_ - s0) / tt
		) /*echo("find s",s0=s0,l=l,tt=tt,v=v,s_a=s_a,s_b=s_b,s_c=s_c,s_d=s_d,s=s_,a=a,a_=a_)*/[s_,tt,a_] :
		let (
			ta = abs(s - s0) / a,
			tt_a = (2 * l - s0 * ta + s * ta) / (2 * s),
			tt_ = tt_a > 0 ? tt_a : 2 * l / (s0 + s),
			a_ = tt_a > 0 ? a : abs(s - s0) / tt_
		)  /*echo("find tt",s0=s0,l=l,s=s,ta=ta,tt_a=tt_a,tt=tt_,a=a,a_=a_)*/ [s,tt_,a_];

function lt(t,s0,s,a) = s == 0 ? 0 : let (
		ta = min(t, abs(s - s0)/a),
		tb = max(0, t - abs(s - s0)/a)
	) /*echo(s0=s0,s1=s,a=a,ta=ta,tb=tb,a1=ta * s0,a2=ta * (s-s0) / 2,a=ta * s0 + ta * (s-s0) / 2,b=tb * s)*/ ta * s0 + ta * sign(s - s0) * ta * a / 2 + tb * s;