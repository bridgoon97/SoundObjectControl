
s.quit;
(
Server.scsynth;
Server.local=Server.default;
o = Server.local.options;
o.numInputBusChannels = 2;
o.numOutputBusChannels = 36;
o.numAudioBusChannels = 1024*2;
o.blockSize = 512;
o.numWireBufs = 64*16;
o.memSize = 2.pow(16);
o.sampleRate = 48000;
s.makeWindow;
s.boot;
s.plotTree;
)

(
~order = 3;
~hoaNumChannels = (~order+1).pow(2);
s.scope(~hoaNumChannels); // let's use only two channels as we will monitor it with headphones
)

(
SynthDef("HOASyn1",{arg freq=440,az=0,el=0,rad=1,dur=1,amp=1,outbus=0;
	var substrate,env,sgn,outsig;
	substrate = Resonz.ar(ClipNoise.ar(100),freq,0.0001);
	env = EnvGen.ar(Env.perc(0.01,freq.reciprocal*dur,1,-8),1,doneAction:2);
	sgn = substrate*env;
	outsig = HOAEncoder.ar(~order.asInteger,sgn,az,el,radius:rad);
	OffsetOut.ar(outbus,outsig);
}).load(s);
)

Synth("HOASyn1",[\freq,880*2,\dur,20,\amp,0.5]);

HOADecLebedev26.loadHrirFilters(s);

(
~decoderSynth = {Out.ar(0,HOADecLebedev26.ar(~order.asInteger,In.ar(2,~hoaNumChannels.asInteger),hrir_Filters:1))}.play;
)

Synth.before(~decoderSynth,\HOASyn1,[\freq,1000.rand+100,\dur,100,\az,pi.rand2,\el,(pi*0.5).rand2,\rad,1,\out,2]);

(
var numNotes, seconds;
numNotes = 1000;
seconds = 15;
~myScore = Score.new;
numNotes.do({|i|
	~myScore = ~myScore.add([i.explin(0.1,numNotes,0.1,seconds-5),
		[\s_new,\HOASyn1,1000+i,0,0,
			                                       \freq, i.linexp(0, numNotes, 500, 5000).rand, // mapping frequency
                                       \az, i.linlin(0,numNotes, -pi*1.5 , pi*1.5).mod(pi), // mapping  azimuth
                                       \el, i.linlin(0,numNotes, -pi, pi), // mapping elevation
                                       \dur, i.linexp(0.0, numNotes, 100, 800), // mapping duration
                                       \amp, i.linlin(0.0, numNotes, 0, -25).dbamp // mapping the amplitude
                                     ]
	])
});
~myScore.add([seconds,[\c_set,0,0]]);
)

~myScore.score.copyRange(0,20).do({|item,i| item.postln;  });

//set server
(
~nrtOptions = ServerOptions.new;
~nrtOptions.verbosity_(0);  // 0 to see the events as OSCPacket
~nrtOptions.numOutputBusChannels_(16); // we need 16 channels because it is B-format 3rd order
// ~nrtOptions.memSize_(8192 * 6400);
// ~nrtOptions.maxNodes_(1024 * 48);
// ~nrtOptions.maxSynthDefs_(1024 * 48);

Score.recordNRT(~myScore.score,
	            "D:/research/summer research/sound"++"/sonificationHOA-oscFile.txt",
	            "D:/research/summer research/sound"++"/sonificationHOA.wav",
                sampleRate: 44100,
                headerFormat: "WAV",
                sampleFormat: "float",
                options: ~nrtOptions,
                action: {"DONE".postln;

        SoundFile.normalize( "D:/research/summer research/sound"++"/sonificationHOA.wav",
                     "D:/research/summer research/sound"++"/sonificationHOA_norm.wav",
                    newHeaderFormat: "WAV",
                    newSampleFormat: "int16");

    }
);
)

~hoaSoundFile = Buffer.read(s, "D:/research/summer research/sound"++"/sonificationHOA_norm.wav");
(
~hoaSignal = NodeProxy.new(s, \audio, ~hoaNumChannels);
~hoaSignal.source = { HPF.ar(PlayBuf.ar( ~hoaSoundFile.numChannels,  ~hoaSoundFile, loop:1  ), 50)   };
~hoaSignal.fadeTime = 1;
)
HOADecLebedev26.loadHrirFilters(s);
(

~decoderOrder = 3; // let's reduce the order
~decoderNumChannels = (~decoderOrder+1).pow(2);

~decoder = NodeProxy.new(s, \audio, 2);
~decoder.source = {var in; in = \in.ar(0!~decoderNumChannels); HOADecLebedev26.ar(~decoderOrder, in, hrir_Filters:1) };
~decoder.fadeTime = 1;
~decoder.play(0, 2);

~hoaSignal <>>  ~decoder;
)
~decoder.stop;