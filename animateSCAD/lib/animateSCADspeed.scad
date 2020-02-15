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

We have two different cases.
===================
In the first case a path travel consist of an (possible empty and possible negative) acceleration segment and then a segment crusing
at s speed. At the end of the part, the speed will be equat to the crusing speed

For the full path travel, the following is then true:
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
	 	s = 2 * l / tt - s0
		a = abs(s - s0) / tt
	else if py > px then s will be less than s0 and:
		sqrt( px ) - a * tt + s0
	else s will be larger than or equal s0 and:
		-sqrt( py ) + a * tt + s0

If we know s, we can find tt:
	tt = (2 * a * l - s0 * ta + s * ta) / (2 * s), where ta = abs(s - s0)
if that was negative, then a is not large enough; we then change a to be just large enough:
	tt = 2 * l / (s0 + s)
	a = abs(s - s0) / tt


===================
In the second case a path travel consist of an (possible empty and possible negative) acceleration segment and then a segment crusing
at s speed, and finally a decceleration segment down to full stop.

For the full path travel, the following is then true:
	l = ta * s0 + ta * (s - s0) / 2 + (tt - ta - tc) * s + tc * s / 2
where ta is the time the acceleration segment ends and tc is the time of the decceleration to full stop, so
	ta * a = abs(s - s0)
	tc * a = s

With some help from wolframalpha.com, we can deduce the following.

If we know s, we can find tt:
	tt = (2 * s * l + s * ta - s0 * ta + s * s) / (2 * a * s) where ta = abs(s - s0)
if that was negative, then a is not large enough; we then change a to be just large enough
	a = (s * ta + s0 * ta + s * s) / (2 * l)
	tt = ta / a + s / a

If we know tt, then s is:
	let
		p1 = a * a * tt * tt
		p2 = 2 * a * l
		p3 = 2 * a * s0 * tt
		pa = (s0 * s0 - 2 * a * l) / (2 * s0 - 2 * a * tt)
		pb = p1 - 2 * p2 + p3 - s0 * s0
	if pb <= 0 then a is not large enough; we then change a to be just large enough
		there are two subcases
 			let
				pl = tt * s0 / 2
			if pl >= 1 then we only decelearate so
				s = 0
				a = s0 * s0 / l / 2
			else
				s = (sqrt(2) * sqrt( 2 * l * l - 2 * l * s0 * tt + s0 * s0 * tt * tt) + 2 * l)/(2 * tt)
				a = (2 * s_ - s0) / tt
	else we dont change a, we just need to find s
		if ps / s0 < 1 then
 			s = pa
 		else
 			s = 0.5 * (-sqrt( pb ) + a * tt + s0)

==================

We can then calculate how far lt we are along the path at time t:
	lt = ta * s0 + ta * sign(s - s0) * ta * a / 2 + tb * s - tc * tc * a /2
where
	stop = 1 if we should deccelerate to zero, else 0
 	ta = min(t, abs(s - s0)/a)
	tb = max(0, t - abs(s - s0)/a)
	tc = stop * max(0, t - (tt - s/a))

*/

function stta(s0,l,a,tt,s,stop) =
	tt != undef ?
		(stop ? stta_s_stop(s0,l,a,tt) : stta_s_no_stop(s0,l,a,tt) ) :
		(stop ? stta_tt_stop(s0,l,a,s) : stta_tt_no_stop(s0,l,a,s) );

function stta_tt_no_stop(s0,l,a,s) = let (
	ta = abs(s - s0),
	tt_a = (2 * a * l - s0 * ta + s * ta) / (2 * a * s),
	tt_ = tt_a > 0 ? tt_a : 2 * l / (s0 + s),
	a_ = tt_a > 0 ? a : abs(s - s0) / tt_
) /*echo("find tt, no stop",s0=s0,l=l,s=s,ta=ta,tt_a=tt_a,tt=tt_,a=a,a_=a_)*/ [s,tt_,a_];

function stta_tt_stop(s0,l,a,s) = let (
	ta = abs(s - s0),
	tt_a = (2 * a * l + s * ta - s0 * ta + s * s) / (2 * a * s),
	a_ = tt_a > 0 ? a : (s * ta + s0 * ta + s * s) / (2 * l),
	tt_ = tt_a > 0 ? tt_a : ta / _a + s / _a
) /*echo("find tt, stop",s0=s0,l=l,s=s,ta=ta,tt_a=tt_a,tt=tt_,a=a,a_=a_)*/ [s,tt_,a_];

function stta_s_no_stop(s0,l,a,tt) = let (
	p1 = a * a * tt * tt,
	p2 = 2 * a * l,
	p3 = 2 * a * s0 * tt,
	px = p1 + p2 - p3,
	py = p1 - p2 + p3,
	s_ = py <= 0 ? 2 * l / tt - s0 : px <= 0 ? 0 : py > px ? sqrt( px ) - a * tt + s0 : -sqrt( py ) + a * tt + s0,
	a_ = py <= 0 ? abs(s_ - s0) / tt : px <= 0 ? s0 * s0 / l / 2 : a
) /*echo("find s, no stop",s0=s0,l=l,tt=tt,p1=p1,p2=p2,p3=p3,px=px,py=py,s=s_,a=a,a_=a_)*/ [s_,tt,a_];

function stta_s_stop(s0,l,a,tt) = let (
	p1 = a * a * tt * tt,
	p2 = 2 * a * l,
	p3 = 2 * a * s0 * tt,
	pa = (s0 * s0 - 2 * a * l) / (2 * s0 - 2 * a * tt),
	pb = p1 - 2 * p2 + p3 - s0 * s0,
	pl = tt * s0 / 2,
	s_ = pb <= 0 ? (pl >= l ? 0 : (sqrt(2) * sqrt( 2 * l * l - 2 * l * s0 * tt + s0 * s0 * tt * tt) + 2 * l)/(2 * tt)) : pa / s0 < 1 ? pa : 0.5 * (-sqrt( pb ) + a * tt + s0),
	a_ = pb <= 0 ? (pl >= l ? s0 * s0 / l / 2 : (2 * s_ - s0) / tt ) : a
) /*echo("find s, stop",s0=s0,l=l,tt=tt,p1=p1,p2=p2,p3=p3,pa=pa,pb=pb,pl=pl,s=s_,a=a,a_=a_)*/ [s_,tt,a_];

function lt(t,s0,s,a,tt,stop) = s0 == 0 && s == 0 ? 0 : let (
		ta = min(t, abs(s - s0)/a),
		tb = max(0, t - abs(s - s0)/a),
		tc = stop ? max(0, t - (tt - s/a)) : 0,
		a1 = ta * s0,
		a2 = ta * sign(s - s0) * ta * a / 2,
		aa = a1 + a2,
		bb = tb * s,
		cc = -tc * tc * a / 2,
		lt = aa + bb + cc
) /*echo("lt",t=t,s0=s0,s1=s,a=a,tt=tt,stop=stop,ta=ta,tb=tb,tc=tc,a1=a1,a2=a2,aa=aa,bb=bb,cc=cc,lt=lt)*/ lt;