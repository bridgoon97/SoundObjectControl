(
//1. server settings
s = Server.local;
// s.options.device_("ASIO4ALL v2");
// s.options.device_("JackRouter");
Server.supernova;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 36;
s.options.numAudioBusChannels = 1024*2;
s.options.blockSize = 512;
s.options.numWireBufs = 64*16;
s.options.memSize = 2.pow(16);
s.options.sampleRate = 44100;
s.newBusAllocators;
// ServerBoot.removeAll;
// ServerTree.removeAll;
// ServerQuit.removeAll;

//2. init global variables & functions
~out = 0;
~path = PathName(thisProcess.nowExecutingPath).parentPath++"buffers";


//3. piece-specific functions

//3a. render settings
~makeBuffers = {
	b = Dictionary.new;
	PathName(~path).entries.do{
		arg subfolder;
		b.add(
			subfolder.folderName.asSymbol ->
			Array.fill(
				subfolder.entries.size,{
					arg i;
					Buffer.read(s,subfolder.entries[i].fullPath);
			})
		)
	}
};

~encOrder = 3; //encoder order
~encNumChannels = (~encOrder+1).pow(2);
~decOrder = 3; //decoder order
~decNumChannels = (~decOrder+1).pow(2);

//binaural decoder
~makeDecoder = {
	s.bind({
		~decGroup = ParGroup.new;
		HOADecLebedev26.loadHrirFilters(s);
		~decoder = NodeProxy.new(s,\audio,~decNumChannels);
		~decoder.fadeTime = 2;
		~decoder.source = {HOADecLebedev26.ar(~decOrder,
			\in.ar(0!~decNumChannels.asInteger),
			hrir_Filters:1)};
		~decoder.group.moveToHead(~decGroup); //Move decoder to a parallel group
		// ~masterEncoder<>>~decoder;

	});
};

// (Optional: for grouping use)
// one master encoder and one encoder dictionary to contain all sub encoders (an ObjEncoder)
~makeEncoder = {
	~encoder = Dictionary.new;
	~masterEncoder = NodeProxy.new(s,\audio,~encNumChannels);
	~masterEncoder.fadeTime = 2;
};

// (Optional: for grouping use)
// add an ObjEncoder to encoders and route to masterEncoder
// route masterEncoder bus (hoa) to decoder bus (hoa)
~addEncoder = {arg name;
	if(~encoder.at(name).isNil) {
		~encoder.add(name->ObjEncoder.new(s,~encOrder));
		~masterEncoder.source = {Out.ar(~masterEncoder.bus,In.ar(~encoder.at(name).encodeBus,~encNumChannels.asInteger))};
		};
};

// parallel group for source synths
~makeSourceGroup = {
	~srcGroup = ParGroup.new;
};

// sound field transformer
~makeTransformer = {
	~transformer = NodeProxy.new(s,\audio,~encNumChannels);
	~transformer.fadeTime = 1;
	~transformer.source = {var in,pitch=0,yaw=0,roll=0; in=\in.ar(0!~encNumChannels);
		HOATransRotateXYZ.ar(~order,in,pitch,roll,yaw);
	};
};

//
~makeReverb = {};

~cleanup = {
	s.newBusAllocators;
	// ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

//3b. controller settings (OSC receiving functions)

~removeOSC = {
	OSCdef.freeAll;
};

//physical actions

//move single object
~grab = {|obj|
	OSCdef.freeAll;
	OSCdef(\setxGrab,{|msg|
		obj.vel.x = msg[1].linlin(-1,1,obj.world.dim.x.neg,obj.world.dim.x);
		msg.postln;
	},'/right/closed/posz').disable;
	OSCdef(\setyGrab,{|msg|
		obj.vel.y = msg[1].linlin(-1,1,obj.world.dim.y,obj.world.dim.y.neg);
		msg.postln;
	},'/right/closed/posx').disable;
	OSCdef(\setzGrab,{|msg|
		obj.vel.z = msg[1].linlin(-1,1,obj.world.dim.z.neg,obj.world.dim.z);
		msg.postln;
	},'/right/closed/posy').disable;
	OSCdef(\switchGrab,{|msg|
		var switch = msg[1];
		if(switch!=0) {
			OSCdef(\setx).enable;
			OSCdef(\sety).enable;
			OSCdef(\setz).enable;
		} {
			OSCdef(\setx).disable;
			OSCdef(\sety).disable;
			OSCdef(\setz).disable;
		}
	},'/switch/grab');
};

~attract = {|world|
	var dist_x,dist_y,dist_z;
	OSCdef.freeAll;
	OSCdef(\getxAttract,{|msg|
		dist_x = msg[1].linlin(-1,1,world.dim.x.neg,world.dim.x);
	},'right/closed/posz');
	OSCdef(\getyAttract,{|msg|
		dist_y = msg[1].linlin(-1,1,world.dim.y,world.dim.y.neg);
	},'right/closed/posx');
	OSCdef(\getzAttract,{|msg|
		dist_z = msg[1].linlin(-1,1,world.dim.z.neg,world.dim.z);
	},'right/closed/posy');
	OSCdef(\switchAttract,{|msg|
		var switch = msg[1];
		if(switch!=0) {
			world.objects.do{|obj|
				var dir = [dist_x,dist_y,dist_z] - obj.loc.asArray;
				var dist = dir.sum(_.pow(2)).sqrt;
				obj.extForce_(dir*(world.gravity.asArray.sum(_.pow(2)).sqrt*obj.mass/dist/dist));
			};
		} {
			world.objects.do{|obj|
				obj.extForce_([0,0,0]);
			};
		};
	},'/switch/attract');
};

~repulse = {|world|
	var dist_x,dist_y,dist_z;
	OSCdef.freeAll;
	OSCdef(\getxRepulse,{|msg|
		dist_x = msg[1].linlin(-1,1,world.dim.x.neg,world.dim.x);
	},'right/closed/posz');
	OSCdef(\getyRepulse,{|msg|
		dist_y = msg[1].linlin(-1,1,world.dim.y,world.dim.y.neg);
	},'right/closed/posx');
	OSCdef(\getzRepulse,{|msg|
		dist_z = msg[1].linlin(-1,1,world.dim.z.neg,world.dim.z);
	},'right/closed/posy');
	OSCdef(\switchRepulse,{|msg|
		var switch = msg[1];
		if(switch!=0) {
			world.objects.do{|obj|
				var dir = obj.loc.asArray - [dist_x,dist_y,dist_z];
				var dist = dir.sum(_.pow(2)).sqrt;
				obj.extForce_(dir*(world.gravity.asArray.sum(_.pow(2)).sqrt*obj.mass/dist/dist));
			};
		} {
			world.objects.do{|obj|
				obj.extForce_([0,0,0]);
			};
		};
	},'/switch/repulse');
};

~gravity = {|world|
	//ref: http://planning.cs.uiuc.edu/node102.html
	var mul_x=1,mul_y=1,mul_z=1,pitch=0,roll=0;
	var orit_x=0,orit_y=0,orit_z=(-1); //initial gravity orientation
	var g_min=0.5,g_max=5;
	var new_gravity = [0,0,-980];
	// OSCdef.freeAll;
	OSCdef(\getxGravity,{|msg|
		mul_x = msg[1].linexp(-1,1,g_min,g_max);
	},'right/closed/posz').disable;
	OSCdef(\getyGravity,{|msg|
		mul_y = msg[1].linexp(-1,1,g_max,g_min);
	},'right/closed/posx').disable;
	OSCdef(\getzGravity,{|msg|
		mul_z = msg[1].linexp(-1,1,g_min,g_max);
	},'right/closed/posy').disable;
	OSCdef(\getpitchGravity,{|msg|
		pitch = msg[1]*pi/2; //transform to rad and counterclockwise
	},'right/open/pitch').disable;
	// yaw not necessary for gravity control
	/*OSCdef(\getyaw,{|msg|
		yaw = msg[1]*pi/2*(-1);//transform to rad and counterclockwise
	},'right/open/yaw');*/
	OSCdef(\getrollGravity,{|msg|
		roll = msg[1]*pi*(-1);//transform to rad and counterclockwise
	},'right/open/roll').disable;
	OSCdef(\switchGravity,{|msg|
		var switch = msg[1];
		if(switch!=0) {//on
			//turn on OSC funcs
			OSCdef(\getxGravity).enable;
			OSCdef(\getyGravity).enable;
			OSCdef(\getzGravity).enable;
			OSCdef(\getpitchGravity).enable;
			OSCdef(\getrollGravity).enable;
			//combine of rotation matrix and then compute (multiply [0,0,1])
			orit_x = sin(pitch)*cos(roll);
			orit_y = -1*sin(roll);
			orit_z = cos(pitch)*cos(roll);
			new_gravity = 980*[orit_x*mul_x,orit_y*mul_y,orit_z*mul_z];
			world.gravity_(new_gravity);
		} {//off
			world.gravity_([0,0,-980]);
			OSCdef(\getxGravity).disable;
			OSCdef(\getyGravity).disable;
			OSCdef(\getzGravity).disable;
			OSCdef(\getpitchGravity).disable;
			OSCdef(\getrollGravity).disable;
		};
	},'/switch/gravity');
};






//4. register functions with ServerBoot/Quit/Tree
ServerBoot.add(~makeBuffers);
ServerQuit.add(~cleanup);


//5. boot server
s.waitForBoot({

	//6a. SynthDefs
	SynthDef(\bpfMonoBuf,{
	arg out=0, startPos=0, buf=0, rate=1, atk=0, sus=0, rel=3,
	c1=1, c2=(-1),freq=261, bpfmix=1,rq=1,rqmin=0.01,rqmax=0.1,
	amp=1, pan=0;
	var sig, env;
	rq = {LFNoise1.kr(0.1).exprange(rqmin,rqmax)};
	env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
	sig = PlayBuf.ar(1,buf,rate*BufRateScale.ir(buf),startPos:startPos);
	sig = XFade2.ar(sig,BPF.ar(sig,freq,rq,1/rq.sqrt),bpfmix*2-1);
	sig = sig*env;
	sig = Pan2.ar(sig,pan,amp);
	Out.ar(out,sig);
}).add;
	SynthDef(\bpfStereoBuf,{
	arg out=0, startPos=0, buf=0, rate=1, atk=0, sus=0, rel=3,
	c1=1, c2=(-1),freq=261, bpfmix=1,rq=1,rqmin=0.01,rqmax=0.1,
	amp=1;
	var sig, env;
	rq = {LFNoise1.kr(0.1).exprange(rqmin,rqmax)};
	env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
	sig = PlayBuf.ar(2,buf,rate*BufRateScale.ir(buf),startPos:startPos);
	sig = XFade2.ar(sig,BPF.ar(sig,freq,rq,1/rq.sqrt),bpfmix*2-1);
	sig = sig*env*amp;
	Out.ar(out,sig);
}).add;


	s.sync;

	//6b. register remaining functions
	ServerTree.add(~makeEncoder);
	ServerTree.add(~makeDecoder);
	// ServerTree.add(~makeSourceGroup);
	ServerTree.add(~makeTransformer);
	ServerTree.add(~makeReverb);
	s.freeAll;

	s.sync;

	~masterEncoder<>>~decoder;

	"done".postln;

});


)
//7. piece
s.quit
(
s.plotTree;
~addEncoder.value(\grp1);
~grp1 = ~encoder.at(\grp1);
w = SSWorld(damping:0);
o = SSObject(w,~grp1);
o.gravity_(true);
o.setSource({BPF.ar(WhiteNoise.ar(0.1),440,MouseX.kr(0.5,2),mul:0.7)});
)
~moveObj.value(o);
~decoder.play
~decoder.group
~decoder.stop
w.showView
ServerTree.add({w.closeWindow});

o.setSource(\bpfStereoBuf);
o.sourceNode.set(\buf,b[\water][0]);

o.gravity_(false);
SynthDef(\haha,{arg out=0,freq=400,mul=0.4;var sig;
	sig = SinOsc.ar(freq:freq,mul:mul);
	Out.ar(out,sig);
}).add;

o.source_(~a);
~o2 = SSObject(w,~grp1);
~o2.source_(~a);
~o2.sourceNode.set(\freq,70.midicps,\amp,7);
o.sourceNode.stop;
o.vel_([0,50,0]);
(
~a = Pbind(
	\instrument, \bpfMonoBuf,
	\buf,b[\drop][0].bufnum,
	// \rel,3,
	\dur, Prand([0.25,0.5],inf),
	\amp,2,
	\freq, Prand(([0,4,7,11]+60).midicps,inf) * Prand([1,2,4],inf),
	// \bpfmix,1,
);
)

//8. send to decoder
// need an HOAConvertor
// from ACN/N3D to ACN/SN3D

//...