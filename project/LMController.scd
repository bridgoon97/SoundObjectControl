LMController {

	var <leftPresent;
	var <leftPosition;
	var <leftDistance;
	var <leftRotation;
	var <leftOpen;

	var <rightPresent;
	var <rightPosition;
	var <rightDistance;
	var <rightRotation;
	var <rightOpen;

	var <addr;

	*new{|addr|
		^super.new.init(addr);
	}

	init{|myAddr|

		addr = myAddr ?? NetAddr.localAddr;

		leftPresent = false;
		leftPosition = Array.new;
		leftDistance = Array.new;
		leftRotation = Array.new;
		leftOpen = false;
		rightPresent = false;
		rightPosition = Array.new;
		rightDistance = Array.new;
		rightRotation = Array.new;
		rightOpen = false;

}
	receive{|type=\GECO|

	OSCdef(\leftPresent,{|msg|
			leftPresent = msg[1];
			msg.postln;
		},'left/open/present',addr);

	OSCdef(\rightPresent,{|msg|
			rightPresent = msg[1];
			msg.postln;
		},'left/open/present',addr);

	OSCdef(\leftPosition,{|msg|
			leftPresent = msg[1];
			msg.postln;
		},'left/open/present',addr);
	}

		