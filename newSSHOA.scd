~encoder = ObjEncoder.new(s,3);
w = SSWorld(damping:0).showView;
w.dim
o = SSObject.new(w,~encoder);
~encoder.encoders
o.sourceNode
s.plotTree

o.gravity_(true)
w.damping_(0)
w.gravity_([0,0,-980]);
w.gravity
o.vel_([10,20,0])
o.loc

HOADecLebedev26.loadHrirFilters(s);
~dec = NodeProxy.new(s,\audio,16); ~dec.fadeTime = 1;
~dec.source = {HOADecLebedev26.ar(3,In.ar(~encoder.masterBus,16),hrir_Filters:1)};
In.ar(~encoder.masterBus,16)

~encoder.masterBus
~dec.play;
~dec.isPlaying
~encoder.encoders.at(\0).isPlaying;
~dec.bus
SynthDef(\sinTest,
	{arg out;
		Out.ar(out,SinOsc.ar());
}).add;

o.source_(\sinTest);

p = ProxySubmix.new(\ke);
p.addMix(~dec);

o.nodeID
~encoder.encoders.at(\0).nodeID
~encoder.masterBus
o.sourceNode.snodeID

a = NodeProxy.new(s,\audio,16);
b = NodeProxy.new(s,\control,15);
o.sourceNode.nodeID
a.source = {};
a = {HOAEncoder.ar(3,SinOsc.ar())}.play;
a.free

~freq = 50;
f = {~freq=~freq*2;~freq.value.postln;};
f.value