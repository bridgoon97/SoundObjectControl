(

OSCdef.new(
	\amp1,
	{
		|msg, time, addr, port|
		x.set(\amp,msg[1].linexp(0,1,0.001,1));
		// x.get(\amp).postln;
		// msg[1].postln;
	},
	'/main/amp'
);


OSCdef.new(
	\cutoff,
	{
		|msg, time, addr, port|
		x.set(\cutoff,msg[1].linexp(0,1,2,200));
	},
	'/main/cutoff'
);


OSCdef.new(
	\pan,
	{
		|msg, time, addr, port|
		x.set(\pan,msg[1].linlin(0,1,-1,1));
	},
	'/main/pan'
);


OSCdef.new(
	\xy1,
	{
		|msg, time, addr, port|
		[msg[1],msg[2]].postln;
	},
	'/main/xy1'
);
)

(
SynthDef(\oscSin,{
	arg cutoff=100,amp=1,pan=0;
	{Out.ar(0,
		Pan2.ar(RLPF.ar(Saw.ar(5,0.1),cutoff.lag(0.02),0.25,mul:amp),pos:pan)).scope};
}).add;
)
(
SynthDef(\simple,
	{arg amp=1;
		Out.ar(0,SinOsc.ar(440,mul:amp));
}).add;
)

x = Synth.new(\oscSin,[\pan,0]);
x = Synth.new(\simple)