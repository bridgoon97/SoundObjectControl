
s.quit;
(
Server.supernova;
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
)
s.plotTree;
(
~order = 2;
~hoaNumChannels = (~order+1).pow(2);
~hoa = NodeProxy.new(s,\audio,~hoaNumChannels); ~hoa.fadeTime = 1;
~buffer = Buffer.readChannel(s,"D:/research/summer research/sound/jack-hammer.wav",channels:[0]);
~hoa.source = {|az=0,el=0,rad=2|HOAEncoder.ar(~order,WhiteNoise.ar(mul:0.2),az,el,plane_spherical:1,radius:rad)};

~dec = NodeProxy.new(s,\audio,~hoaNumChannels); ~dec.fadeTime = 1;
~decOrder = 2;
~decNumChannels = (~decOrder+1).pow(2);
HOADecLebedev26.loadHrirFilters(s);
~dec.source = {var in; in = \in.ar(0!~decNumChannels);HOADecLebedev26.ar(~decOrder,in,hrir_Filters:1)};
~hoa<>>~dec;
)
~dec.stop;
~hoa.free;~dec.free;
(
w = SSWorld(damping:0,timeStep:60).showView;
o = SSObject(w);
// w.viewDiff_(false);
// w.gravity_([0,0,9.8*100]);
o.gravity_(true);

n = w.renderAddresses[0];
OSCFunc.new(
	{	|msg,time,addr,port|
		// msg.postln;
		~hoa.set(\az,(msg[1]/180*pi),\el,(msg[2]/180*pi),\rad,msg[3].linlin(0,150,0.5,1.5));
},"/spatdif/source/"++o.name++"/position",srcID:n);

)

w.dim
o.loc_([20,0,120]);
o.vel_([0,0,10]);
w.gravity_([0,100,100]);


		