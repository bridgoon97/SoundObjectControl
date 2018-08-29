(
//1. server settings
s = Server.local;
s.options.device_(
	"ASIO4ALL v2"
	// "JackRouter"
	// "MOTU Pro Audio"
);
Server.supernova;
s.options.numInputBusChannels = 36;
s.options.numOutputBusChannels = 36;
s.options.numAudioBusChannels = 1024*2;
s.options.blockSize = 512;
s.options.numWireBufs = 64*16;
s.options.memSize = 2.pow(16);
s.options.sampleRate = 48000;
s.newBusAllocators;
/*ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;*/

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

// create a single ObjEncoder to hold HOAEncoder for sound objects
~makeEncoder = {
	~encoder = ObjEncoder.new(s,~encOrder);
	"encoder created".postln;
};


//binaural decoder
~makeDecoder = {
	s.bind({
		HOADecLebedev26.loadHrirFilters(s);
		~decoder = NodeProxy.new(s,\audio,~decNumChannels);
		// ~decoder.fadeTime = 2;
		~decoder.source = {HOADecLebedev26.ar(~decOrder,
			\in.ar(0!~decNumChannels.asInteger),
			hrir_Filters:1)};
	});
	"binarul decoder created".postln;
};


// (Optional: for grouping use only)
// choose either makeEncoder or makeMasterEncoder (plus AddEncoder), cannot have both!!!
// one master encoder and one encoder dictionary to contain all sub encoders (an ObjEncoder)

// ~makeMasterEncoder = {
// 	~encoders = Dictionary.new;
// 	~masterEncoder = NodeProxy.new(s,\audio,~encNumChannels);
// 	if(~encoders.at(\default).isNil) {
// 		~encoders.add(\default->ObjEncoder.new(s,~encOrder));
// 		~masterEncoder.source = {Out.ar(~masterEncoder.bus,In.ar(~encoders.at(\default).encodeBus,~encNumChannels.asInteger))};
// 		"\default ObjEncoder in ~encoders".postln;
// 	};
// 	"masterEncoder created".postln;
// };

// (Optional: for grouping use only)
// add an ObjEncoder to encoders and route to masterEncoder

// ~addEncoder = {arg name;
// 	if(~encoder.at(name).isNil) {
// 		~encoder.add(name->ObjEncoder.new(s,~encOrder));
// 		~masterEncoder.add = {Out.ar(~masterEncoder.bus,In.ar(~encoder.at(name).encodeBus,~encNumChannels.asInteger))};
// 	};
// 	("ObjEncoder "++name++" created in ~encoders dictionary").postln;
// };


// sound field transformer
~makeTransformer = {
	~transformer = NodeProxy.new(s,\audio,~encNumChannels);
	~transformer.fadeTime = 1;
	"transformer created".postln;
};

// connect between encoder, transformer, (convertor), decoder (binaural only)
~routing = {
	"routing begins".postln;
	"//////////////////////".postln;
	if(~masterEncoder.isNil.not) {
		"grouping mode".postln;
		~transformer.source = {
			arg pitch=0,yaw=0,roll=0; var in=\in.ar(0!~encNumChannels);
			HOATransRotateXYZ.ar(~encOrder,in,pitch,roll,yaw);
		};
		~masterEncoder<>>~transformer;
		"masterEncoder->transformer".postln;
	} {
		"single encoder mode".postln;
		// Ndef(\encoder,{In.ar(~encoder.encodeBus,~encNumChannels.asInteger)});
		~transformer.source = {
			arg pitch=0,yaw=0,roll=0;
		HOATransRotateXYZ.ar(~encOrder,In.ar(~encoder.encodeBus,~encNumChannels.asInteger),pitch,roll,yaw);
		};
		"encoder->transformer".postln;
	};
	if(~convertor.isNil.not) {
		~transformer<>>~convertor;
		"transformer->convertor".postln;
		if(~decoder.isNil.not) {
			~convertor<>>~decoder;
			"convertor->decoder, ready to output".postln;
		} {
			"no decoder, convertor is ready to output".postln;
		};
	} {
		"no convertor".postln;
		if(~decoder.isNil.not) {
			~transformer<>>~decoder;
			"transformer->decoder, ready to output".postln;
		} {
			"no decoder, transformer is ready to output".postln;
		};
	};
	"//////////////////////".postln;
	"routing finished".postln;
};


//
~makeReverb = {};

~makeConnect = Routine {
	s.newBusAllocators;
	0.1.wait;
	~makeEncoder.value;
	0.1.wait;
	~makeTransformer.value;
	0.1.wait;
	if(s.options.device=="ASIO4ALL v2") {
		~makeDecoder.value;
		0.1.wait;
		~routing.value;
		0.1.wait;
		~decoder.play;
	};
	if(s.options.device=="MOTU Pro Audio"){
		~makeConvertor.value;
		0.1.wait;
		~routing.value;
		0.1.wait;
		~convertor.play;
	};
};

~makeWorld = {
	~world = SSWorld.new;
	~world.showView;
	"world created".postln;
};

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
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
			OSCdef(\setxGrab).enable;
			OSCdef(\setyGrab).enable;
			OSCdef(\setzGrab).enable;
		} {
			OSCdef(\setxGrab).disable;
			OSCdef(\setyGrab).disable;
			OSCdef(\setzGrab).disable;
		}
	},'/switch/grab');
};

~attract = {|world|
	var dist_x,dist_y,dist_z;
	OSCdef(\getxAttract,{|msg|
		dist_x = msg[1].linlin(-1,1,world.dim.x.neg,world.dim.x);
	},'right/closed/posz').disable;
	OSCdef(\getyAttract,{|msg|
		dist_y = msg[1].linlin(-1,1,world.dim.y,world.dim.y.neg);
	},'right/closed/posx').disable;
	OSCdef(\getzAttract,{|msg|
		dist_z = msg[1].linlin(-1,1,world.dim.z.neg,world.dim.z);
	},'right/closed/posy').disable;
	OSCdef(\switchAttract,{|msg|
		var switch = msg[1];
		if(switch!=0) {
			OSCdef(\getxAttract).enable;
			OSCdef(\getyAttract).enable;
			OSCdef(\getzAttract).enable;
			world.objects.do{|obj|
				var dir = [dist_x,dist_y,dist_z] - obj.loc.asArray;
				var dist = dir.sum(_.pow(2)).sqrt;
				obj.extForce_(dir*(world.gravity.asArray.sum(_.pow(2)).sqrt*obj.mass/dist/dist));
			};
		} {
			OSCdef(\getxAttract).disable;
			OSCdef(\getyAttract).disable;
			OSCdef(\getzAttract).disable;
			world.objects.do{|obj|
				obj.extForce_([0,0,0]);
			};
		};
	},'/switch/attract');
};

~repulse = {|world|
	var dist_x,dist_y,dist_z;
	OSCdef(\getxRepulse,{|msg|
		dist_x = msg[1].linlin(-1,1,world.dim.x.neg,world.dim.x);
	},'right/closed/posz').disable;
	OSCdef(\getyRepulse,{|msg|
		dist_y = msg[1].linlin(-1,1,world.dim.y,world.dim.y.neg);
	},'right/closed/posx').disable;
	OSCdef(\getzRepulse,{|msg|
		dist_z = msg[1].linlin(-1,1,world.dim.z.neg,world.dim.z);
	},'right/closed/posy').disable;
	OSCdef(\switchRepulse,{|msg|
		var switch = msg[1];
		if(switch!=0) {
			OSCdef(\getxRepulse).enable;
			OSCdef(\getyRepulse).enable;
			OSCdef(\getzRepulse).enable;
			world.objects.do{|obj|
				var dir = obj.loc.asArray - [dist_x,dist_y,dist_z];
				var dist = dir.sum(_.pow(2)).sqrt;
				obj.extForce_(dir*(world.gravity.asArray.sum(_.pow(2)).sqrt*obj.mass/dist/dist));
			};
		} {
			OSCdef(\getxRepulse).disable;
			OSCdef(\getyRepulse).disable;
			OSCdef(\getzRepulse).disable;
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
	var new_gravity = [0,0,-9.8];
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
			OSCdef(\getxGravity).disable;
			OSCdef(\getyGravity).disable;
			OSCdef(\getzGravity).disable;
			OSCdef(\getpitchGravity).disable;
			OSCdef(\getrollGravity).disable;
			world.gravity_([0,0,-980]);
		};
	},'/switch/gravity');
};

~rotate = {|transformer|
	var pitch=0, yaw=0, roll=0;
	OSCdef(\getpitchRotate,{|msg|
		pitch = msg[1].linlin(-1,1,pi/2,-pi/2);
	},'/right/open/pitch').disable;
	OSCdef(\getyawRotate,{|msg|
		yaw = msg[1].linlin(-1,1,pi/2,-pi/2);
	},'/right/open/yaw').disable;
	OSCdef(\getrollRotate,{|msg|
		roll = msg[1].linlin(-1,1,-pi,pi);
	},'/right/open/roll').disable;
	OSCdef(\switchRotate,{|msg|
		var switch = msg[1];
		if(switch!=0) {//on
			OSCdef(\getpitchRotate).enable;
			OSCdef(\getyawRotate).enable;
			OSCdef(\getrollRotate).enable;
			transformer.set(
				\pitch, pitch,
				\yaw, yaw,
				\roll, roll
		);} {//off
			OSCdef(\getpitchRotate).disable;
			OSCdef(\getyawRotate).disable;
			OSCdef(\getrollRotate).disable;
			transformer.set(
				\pitch,0,
				\yaw,0,
				\roll,0
		);}
	},'/switch/rotate');
};
//~spread
//~contract
//~removeObjects


//4. register functions with ServerBoot/Quit/Tree
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeWorld);
ServerQuit.add({
	if(~world.isNil.not) {
		~world.objects.do{|obj|
			obj.sourceNode.clear;
			~world.remove(obj);
		};
	};
	if(~encoder.isNil.not){
		~encoder.encoders.do{|enc|
			enc.clear;
		};
		~encoder.encodeBus.free;
		~encoder.encodeGroup.free;
	};
	if(~transformer.isNil.not){
		~transformer.clear;
	};
	if(~decoder.isNil.not){
		~decoder.clear;
	};
	if(~convertor.isNil.not){
		~convertor.clear;
	};
});
ServerQuit.add(~cleanup);


//5. boot server
s.waitForBoot({
	s.sync;

	//6. register remaining functions
	ServerTree.add({
	~world.updateView;
});

	s.freeAll;

	s.sync;

	~makeConnect.reset.play;

});



)