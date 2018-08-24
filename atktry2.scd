(
var decoder;
decoder = FoaDecoderMatrix.newStereo((131/2).degrad,0.5);
SynthDef(\foaEncode1,{
	var src,theta,phi,foa,out;

	src = PinkNoise.ar(-6.dbamp);
	// phi: azimuth theta: elevation
	phi = MouseX.kr(pi,-pi);
	theta=0;

	foa = FoaPanB.ar(src,phi,theta);

	out = FoaDecode.ar(foa,decoder);
	//out.numChannels.postln;
	Out.ar(0,out);
}).add;
)

(
var decoder,encoder;
decoder = FoaDecoderMatrix.newStereo((131/2).degrad,0.5);
encoder = FoaEncoderMatrix.newOmni;
SynthDef(\foaEncode2,{
	var src,angle,azim,foa,out;

	src = PinkNoise.ar(-6.dbamp);
	/*phi: azimuth theta: elevation
	phi = MouseX.kr(pi,-pi);
	theta=0;*/

	angle = MouseY.kr(pi/2,0);
	azim = MouseX.kr(pi,-pi);

	// foa = FoaPanB.ar(src,phi,theta);

	foa = FoaEncode.ar(src,encoder);
	foa = FoaTransform.ar(foa,'pushX',angle);
	foa = FoaTransform.ar(foa,'rotate',azim);

	out = FoaDecode.ar(foa,decoder);
	//out.numChannels.postln;
	Out.ar(0,out);
}).add;
)

a = Synth(\foaEncode2);

a.free;

(
var decoder;
decoder = FoaDecoderMatrix.newStereo((131/2).degrad,0.5);
a = Bus.audio(s,4);
SynthDef(\foaEncode3,{
	arg outBus,duration=0.05,theta,phi;
	var src,foa,env;
	src = PinkNoise.ar(-6.dbamp);
	env = EnvGen.kr(Env([0,1,0],[0.5,0.5],\sin),timeScale:duration,doneAction:2);
	foa = FoaPanB.ar(src,phi,theta,env);
	Out.ar(outBus,foa);
}).add;

SynthDef(\foaDecode,{arg inBus;
	var foa,out;
	foa = In.ar(inBus,4);
	out = FoaDecode.ar(foa,decoder);
	Out.ar(0,out);
}).add;
)
(
b = Synth(\foaDecode,[\inBus,a],1,\addToTail);
Routine.run({
	20.do({
		Synth(\foaEncode3,[\outBus,a,\theta,0,\phi,pi.rand2]);
		0.1.wait;
	})
});
b.free;
)

Routine{arg inval;
	inval.postln;
}.value("hello routine");
(
r = Routine{
	arg inval;
	inval.postln;
	inval = 123.yield;
	111.postln;
	inval.postln;
}
)
r.value("goodbyeroutine");
r.reset("reset");
r.stop("stop");

(
f = {"foo".postln };
g = {"bar".postln };
CmdPeriod.add(f);
CmdPeriod.add(g);
)


(
w = Window("close on cmd-.").front;
CmdPeriod.doOnce({w.close})
)

(
var score, bufnum, sndPath, duration, decoder, sampleRate, headerFormat, sampleFormat, numChannels;
var offset = 0.1;
score = Score.new;
bufnum = Server.default.bufferAllocator.alloc(1);
sndPath = Atk.userSoundsDir ++ "/b-format/Pampin-On_Space.wav";
SoundFile.use(
	sndPath,
	{arg soundFile;
		headerFormat = soundFile.headerFormat;
		sampleFormat = soundFile.sampleFormat;
		sampleRate = soundFile.sampleRate;
		numChannels = soundFile.numChannels;
		duration = soundFile.duration;
	}
);

decoder = FoaDecoderKernel.newUHJ(
	sampleRate:sampleRate,
	score:score
);
SynthDef(\kernelDecode,{arg buffer;
	var out,src;
	src = PlayBuf.ar(numChannels,buffer,BufRateScale.kr(buffer));
	out = FoaDecode.ar(src,decoder);
	Out.ar(0,out);
}).load;
score.add(
	[0.0,
		['b_allocRead',bufnum,sndPath,0,0],
		['s_new','kernelDecode',1001,0,1,'buffer',bufnum]
	],
);

score.add([duration,['n_free',1001]],);
score.add([duration+0.1,['b_free',bufnum]],);

// free the kernel buffers
decoder.kernel.do({arg bufs;
    bufs.do({arg buf;
        offset = offset + 0.1;
        score.add([ duration  + offset, [ 'b_free', buf.bufnum ]])
    });
});

// add the needed dummy command to stop NRT
score.add([offset + duration + 0.2, [0]] );


// render our score to a sound file
o=ServerOptions.new.numOutputBusChannels=decoder.numChannels;
score.recordNRT("~/Desktop/abc.osc".standardizePath,
	    "~/Desktop/myDecode.wav".standardizePath,
	sampleRate: sampleRate,
	headerFormat: headerFormat,
	sampleFormat: sampleFormat,
	options: o
	);

)

s.quit
