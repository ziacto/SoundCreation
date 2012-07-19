#import "ViewController.h"

OSStatus RenderTone(void *inRefCon,
                    AudioUnitRenderActionFlags *ioActionFlags,
                    const AudioTimeStamp *inTimeStamp,
                    UInt32 inBusNumber,
                    UInt32 inNumberFrames,
                    AudioBufferList *ioData)
{
    const double amplitude = 0.25;
    const double theta_increment = ((M_PI_X_2 * 880) / 44100);
    
    double theta = 0;
    
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
        buffer[frame] = amplitude * sin(theta);
        theta += theta_increment;
        if (theta >= M_PI_X_2)
            theta = 0;
        
    }
    
    ViewController *viewController = (__bridge ViewController *)inRefCon;
    viewController.theta = theta;
    
    return noErr;
}

@implementation ViewController {
    AudioComponentInstance _toneUnit;
    double _sampleRate;
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sampleRate = 44100;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
- (IBAction)togglePlay:(id)sender {
    if (!_toneUnit) {
        [self createAudioUnit];
        
        OSErr err = AudioUnitInitialize(_toneUnit);
        NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
        
        err = AudioOutputUnitStart(_toneUnit);
        NSAssert1(err == noErr, @"Error starting unit: %hd", err);
    } else {
        AudioOutputUnitStart(_toneUnit);
        AudioUnitUninitialize(_toneUnit);
        AudioComponentInstanceDispose(_toneUnit);
        _toneUnit = nil;
    }
}

#pragma mark - Audio Unit
- (void)createAudioUnit {
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    OSErr err = AudioComponentInstanceNew(defaultOutput, &_toneUnit);
    NSAssert1(_toneUnit, @"Error creating unint: %hd", err);
    
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void *)(self);
    err = AudioUnitSetProperty(_toneUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, sizeof(input));
    NSAssert1(err == noErr, @"Error setting callbackL %hd", err);
    
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte  = 8;
    
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = _sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = (kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved);
    streamFormat.mBytesPerPacket = four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty(_toneUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat,
                               sizeof(AudioStreamBasicDescription));
    NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
}
@end








