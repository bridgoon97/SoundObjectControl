// Some useful synths
(
SynthDef(\tik,
	{var sig;
		// add a RLPF to sig may sound better
		sig = Impulse.ar(MouseX.kr(2, 18, 1)) * [1, 1];
		Out.ar(0,sig);
}).add;
)
(
SynthDef(\wind,
	{var sig,out;
		sig = PinkNoise.ar(MouseX.kr(0, 0.2) * [1, 1]);
		out = RLPF.ar(sig * 8, [1450, 1234], 0.2);
		Out.ar(0,out);
}).add;
)
