(
var score, sndbuf, sndPath, encoder, decoder, synth, duration, sampleRate, headerFormat, sampleFormat, numChannels;

// define our CtkScore
score = CtkScore.new;

// the path to our B-Format sound file
sndPath = Atk.userSoundsDir ++  "/uhj/Palestrina-O_Bone.wav";

// get some info about the soundfile we are decoding for the Score requirements
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

// define a CtkBuffer and add it to our score
sndbuf = CtkBuffer.playbuf(sndPath).addTo(score);

// define the UHJ encoder
// the decoder takes a score argument so that it will add the kernels to the score for you
encoder = FoaEncoderKernel.newUHJ(
    sampleRate: sampleRate,
    score: score
);

// define a decoder of your choosing
// the decoder takes a score argument so that it will add the kernels to the score for you
decoder = FoaDecoderKernel.newListen(
    subjectID: 1013,
    sampleRate: sampleRate,
    score: score
);

// define a CtkSynthDef
synth = CtkSynthDef(\kernelEncodeDecode, {arg buffer;
    var out, encoded, src;

    // play a sound file from a buffer
    src = PlayBuf.ar(numChannels, buffer, BufRateScale.kr(buffer));

    // encode our UHJ sound file
    encoded = FoaEncode.ar(src, encoder);

    // decode our B-format sound file
    out = FoaDecode.ar(encoded, decoder);

    Out.ar(0, out);
});

// create a synth note and add it to the score
score.add(
    synth.note(0.0, duration).buffer_(sndbuf)
);

// write our score to disk
score.write("~/Desktop/myDecode1.wav".standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(decoder.numChannels)
);
)