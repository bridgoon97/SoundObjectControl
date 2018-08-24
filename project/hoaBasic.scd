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


//select HOA order
(
~order = 4;
~hoaNumChannels = (~order+1).pow(2);
s.scope(~hoaNumChannels);
)
//HOA encoding
//---------------------------------------------------------------------

//HOA encode node
(
~hoaSignal = NodeProxy.new(s,\audio,~hoaNumChannels);
~hoaSignal.source = {HOAEncoder.ar(~order,WhiteNoise.ar(0.3),MouseX.kr(pi,-pi),MouseY.kr(-pi*0.5,pi*0.5))};
~hoaSignal.fadeTime = 1;
)

//other encode sources
~hoaSignal.source = {HOAEncoder.ar(~order, WhiteNoise.ar(1), MouseX.kr(pi,-pi), elev:0, gain:0, plane_spherical:1, radius: MouseY.kr(0.1, 4 ) )};

~hoaSignal.source = {HOAConvert.ar(~order,  HOAEncoder.ar(~order, WhiteNoise.ar(1), pi* 0.25, pi* 0.25 ), ~inFormat, ~outFormat)};

//recorded sounds
~buffer = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
Platform.resourceDir.openOS;
(
~hoaSignal.source = {HOAEncoder.ar(~order,
     PlayBuf.ar(1, ~buffer, BufRateScale.kr(~buffer) , loop:1),
	    az:MouseX.kr(pi,-pi), elev:0, gain:2, plane_spherical:1, radius: MouseY.kr(0.1,5) )};
)
~hoaSignal.play(0,~hoaNumChannels,vol:0.1,fadeTime:1.0);
~hoaSignal.stop;

//read HOA B signals
~hoaSoundFile = Buffer.read(s, HOA.userSoundsDir++"/eigen_O4_ACN_N3D_cicadas.wav");
~hoaSoundFile = Buffer.read(s, HOA.userSoundsDir++"/eigen_O3_ACN_N3D_080717_josh.wav");

~hoaSoundFile.numChannels;
~order = ~hoaSoundFile.numChannels.sqrt -1;
(
~hoaSignal = NodeProxy.new(s,\audio,~hoaSoundFile.numChannels);
~hoaSignal.source = {PlayBuf.ar(~hoaSoundFile.numChannels,~hoaSoundFile,loop:1)};
~hoaSignal.fadeTime = 1;
)


HOA.userSoundsDir.openOS
//HOA format convertion
//--------------------------------------------------------------------

~inFormat = \ACN_N3D;

~outFormat = \ACN_SN3D;
~outFormat = \ACN_N3D;
~outFormat = \FuMa;

//Sound field transformation
//--------------------------------------------------------------------

(
~hoaTransformer = NodeProxy.new(s,\audio,~hoaNumChannels);
~hoaTransformer.fadeTime = 1;
)
//mirror
~hoaTransformer.source = {|front_back = 1,left_right = 0,up_down = 0|var in; in = \in.ar(0!~hoaNumChannels); HOATransMirror.ar(~order,in,front_back,left_right,up_down)};
~hoaTransformer.set(\left_right,1);
~hoaTransformer.set(\front_back,0);

//rotate xyz
(
~hoaTransformer = {var in; in = \in.ar(0!~hoaNumChannels);
	HOATransRotateXYZ.ar(~order,in,
		LFTri.ar(0.02,0,pi),
		LFTri.ar(0.02,0,pi),
		LFTri.ar(0.02,0,pi)
)};
)


//HOA decoding (binaural)
//--------------------------------------------------------------------


//create decoder node
(
~decoder = NodeProxy.new(s,\audio,26);
~decoderOrder = 3; // let's reduce the order
~decoderNumChannels = (~decoderOrder+1).pow(2);
HOADecLebedev26.loadHrirFilters(s);
~decoder.source = {var in; in = \in.ar(0!~decoderNumChannels); HOADecLebedev26.ar(~decoderOrder, in, hrir_Filters:1) };
~decoder.fadeTime = 1;
~decoder.play(0,vol:0.5,fadeTime:1.0);
)
~decoder.stop;

//connect encoder and decoder (and transformer)
~hoaSignal<>>~decoder;
~hoaSignal<>>~hoaTransformer<>>~decoder;

//other decode sources
s.scope(26); // To see all channels we add one more to the oscilloscope
~decoder.source = {var in; in = \in.ar(0!~hoaNumChannels); HOADecLebedev26.ar(3, in, output_gains: 24) };

//mix decoded signals
(
~mix = ProxySubmix(\mixer); ~mix.ar(5);
~mix.addMix(~decoder1).addMix(~decoder2).addMix(~decoder3);
)

HOADecLebedev06.hrirFilters.size;


