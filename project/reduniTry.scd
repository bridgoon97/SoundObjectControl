w = SSWorld([10,10,10]).showView;
o = SSObject(w,name:\1);

o.loc_([3,1,0]);
o.loc_(z:5);

o.locSph_([3,pi,0]);
o.locSph_(ele:pi/4);

w.gravity;
w.gravity_([3,0,0]);
o.gravity_(true);

w.friction_(0.5);
o.friction_(true);

w.damping_(0.5);

w.viewDiff_(true);

(
t=Task({
	inf.do{
		w.gravity_((3.0.dup(3).collect(_.rand2)).postln);
		w.friction_(1.0.rand);
		w.gravity_(1.0.rand);
		2.wait;
		w.gravity_([0,0,0]);
		5.wait;
	}
}); t.play;
)
t.stop;
o.stop;

w.closeWindow;

//==========================================

w = SSWorld([10,10,10]).showView;

o = SSObject(w,name:\object,loc:[1,2,3]);

SSObject(w);

w.getObject(\1).loc_([3,0,0])

w.removeByName(\1)

//==========================================

r = SpatialRender.new(s);

(
w = SSWorld([20,20,10]).showView;
o = SSObject(w,loc:[2,0,0],channel:0).setMotion(\orbit)
)

w.sweetSpotSize
r.verbose_(false)
o.channel
o.setChannel(1)