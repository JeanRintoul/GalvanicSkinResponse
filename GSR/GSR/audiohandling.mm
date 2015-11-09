//
// audio and thread handling for the whole app.
// It must be a singleton class.
//
//
// The only data that gets sent through is the view controller -
//
//
#import "audiohandling.h"
#import <AudioToolbox/AudioToolbox.h>
#import "Data.h"

const UInt32 FFTLEN = 44100;

OSStatus RenderModulated(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
    // Get the tone parameters out of the view controller
    audiohandling *viewController =
    (__bridge audiohandling *)inRefCon;
    
    // Fixed amplitude is good enough for our purposes
    const double amplitude = viewController->calibrateamplitude; // 0.9;
    double theta = viewController->theta;
    
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    //
    // RAMP 128
//    float ramptype = 2; // two values only.
//    float rampgap  = (int)1000; //(int)(viewController->sampleRate/2)/ramptype;  // aprox 172.
    //
    // Now we have some logic to determin the frequency.
    // the logic is based on if the buffercount variable >=3.
    // if the buffercount variable >=3, then we shift up one frequency.
    // if the frequency is f > (22050-172) we make the frequency 0 again.
    //
    if (viewController->buffercount >= viewController->modgap) {
        //
        // shift up a frequency
        // viewController->frequency = viewController->frequency + rampgap;
        //
        if (viewController->frequency > 1000) {
            viewController->frequency = 1000;
        }
        else {
            viewController->frequency = 3000;
        }
        // reset the buffercount.
        viewController->buffercount = 0;
    }
    viewController->buffercount = viewController->buffercount + 1;
    //
    double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    //
    // How big is the buffer?
    // buff is 1024
    // NSLog(@"buff %d",inNumberFrames);
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * amplitude;
        theta += theta_increment;
        
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the theta back in the view controller
    viewController->theta = theta;
    return noErr;
}


OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)
{
    // NSLog(@"rendering tone");
    // Get the tone parameters out of the view controller
    audiohandling *viewController =
    (__bridge audiohandling *)inRefCon;
    
    // Fixed amplitude is good enough for our purposes
    const double amplitude = viewController->calibrateamplitude; // 0.9;
    
    double theta = viewController->theta;
    double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * amplitude;
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the theta back in the view controller
    viewController->theta = theta;
  
    
    return noErr;
}


OSStatus RenderRamp(
                     void *inRefCon,
                     AudioUnitRenderActionFlags 	*ioActionFlags,
                     const AudioTimeStamp 		*inTimeStamp,
                     UInt32 						inBusNumber,
                     UInt32 						inNumberFrames,
                     AudioBufferList 			*ioData)

{
    // Get the tone parameters out of the view controller
    audiohandling *viewController =
    (__bridge audiohandling *)inRefCon;
    
    // Fixed amplitude is good enough for our purposes
    const double amplitude = viewController->calibrateamplitude; // 0.9;
    double theta = viewController->theta;

    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    //
    // RAMP 128
    float ramptype      = 128;
    float rampgap = (int)(viewController->sampleRate/2)/ramptype;  // aprox 172.
    //
    // Now we have some logic to determin the frequency.
    // the logic is based on if the buffercount variable >=3.
    // if the buffercount variable >=3, then we shift up one frequency.
    // if the frequency is f > (22050-172) we make the frequency 0 again.
    //
    if (viewController->buffercount >= 3) {
        // shift up a frequency
        viewController->frequency = viewController->frequency + rampgap;
        if (viewController->frequency > ((viewController->sampleRate/2)- rampgap)) {
            viewController->frequency = 0;
        }
        // reset the buffercount.
        viewController->buffercount = 0;
    }
    viewController->buffercount = viewController->buffercount + 1;
    //
    //
    double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    //
    // How bug is the buffer?
    // buff is 1024
    // NSLog(@"buff %d",inNumberFrames);
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * amplitude;
        theta += theta_increment;
        
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the theta back in the view controller
    viewController->theta = theta;
    return noErr;
}


void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    audiohandling *viewController =
    (__bridge audiohandling *)inClientData;
    
    [viewController stop];
}



@interface audiohandling ()

// Using AVPlayer for example
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation audiohandling {
    
    float dbValue;
    float lastdbValue;
    float lastlastdbValue;
    float lastamp;
    NSTimer *UITimer;
    NSThread* writeThread;
    COMPLEX_SPLIT _A;
    FFTSetup      _FFTSetup;
    BOOL          _isFFTSetup;
    vDSP_Length   _log2n;
    NSMutableArray* lastfftamps;
    NSMutableArray* frequencies;
    float _fftBuf[FFTLEN];
    int _fftBufIndex;
    int _samplesRemaining;
    float dmagnitude;
    float dphase;
    NSMutableArray* dlastfftamps;
    NSDate *dtimestamp;
    float lasttheta;
    float frequencycalclimit;
    BOOL rampstate;
    BOOL modstate;
    NSMutableArray *cmagnitudes;
    float increment;
    float scalefactor;
    float rawscalefactor;
    NSDate *onesecondintervaldate;
    float magnitudeinterval;
    NSString *playbuttontext;
    NSMutableArray* times;
    NSMutableArray* mags;
    float mpvolumevalue;
    NSString *inport;
    NSString *outport;
    NSString *filesize;
    float Fs;
    BOOL bluetooth;
    NSString *lastsource;
    AVAudioRecorder *avrecorder;
    AVAudioPlayer *avplayer;
    BOOL calibrating;
    NSString *calibratebuttonTitle;
}

static audiohandling *sharedManager = nil;

@synthesize microphone;
@synthesize calibrationmarker;
@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;
@synthesize isRecording;
@synthesize isPlaying;
@synthesize recorder;
@synthesize audiojackconnected;
@synthesize output;
@synthesize audioplayer;
@synthesize session;
@synthesize audioPlayer;


//notification center access
NSNotificationCenter *notifications;

#pragma mark Singleton Methods

// singleton class foro audiohandling.
+ (audiohandling *) sharedManager {
    
    @synchronized(self)
    {
        if (sharedManager == nil)
        {
            // sharedManager = [[audiohandling alloc] init];
            sharedManager = [[super allocWithZone:NULL]init];
        }
        
    }
    return sharedManager;

}


- (id)init {
    
    if (self = [super init]) {
        //
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        [self configureAVAudioSession:@"speaker"];

        
        self.microphone = [EZMicrophone microphoneWithDelegate:self];
        [self.microphone startFetchingAudio];
        
        //setup notifications and backgrounding
        [self setupNotifications];
        
        calibratebuttonTitle = @"Calibrate";
        Fs = [self logSampleRate];
        //sampleRate = 44100;
        lastfftamps  = [[NSMutableArray alloc]init];
        frequencies  = [[NSMutableArray alloc]init];
        _fftBufIndex = 0;
        _samplesRemaining = FFTLEN;
        dmagnitude = 0.0;
        dphase = 0.0;
        dtimestamp = [NSDate date];
        frequencycalclimit = 2000;
        rampstate = NO;
        modstate  = NO;
        lastamp = 0.0;
        calibrationmarker = [NSDate date];
        cmagnitudes       = [[NSMutableArray alloc]init];
        increment         = 0.05;
        dbValue           = 0.0f;
        lastdbValue       = 0.5;
        _fftBufIndex      = 0;
        _samplesRemaining   = FFTLEN;
        playbuttontext      = @"Start";
        scalefactor         = 1.0;
        rawscalefactor      = 1.0;
        frequency           = 100.0;
        buffercount         = 0;
        modgap              = 3;
        calibrateamplitude  = 0.99;
        calibrating         = NO;
//  
//        filesize =
//        NSURL * pathToMp3File = ...
//        NSError *error = nil;
//        AVAudioPlayer* avAudioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:pathToMp3File error:&error];
//        
//        double duration = avAudioPlayer.duration;
//        avAudioPlayer = nil;
//        
        
        [self setupBackgrounding];
        
    }
    NSLog(@"finished init");

    return self;
}

-(void)setupNotifications
{
    notifications       = [NSNotificationCenter defaultCenter];
    
    [notifications addObserver:self
                      selector:@selector(audioSessionInterrupted:)
                          name:AVAudioSessionInterruptionNotification
                        object:nil];
    
    [notifications addObserver:self
                      selector:@selector(audioRouteChangeListenerCallback:)
                          name:AVAudioSessionRouteChangeNotification
                        object:nil];
    
    [notifications addObserver:self
                       selector:@selector(volumeChanged:)
                        name:@"AVSystemController_SystemVolumeDidChangeNotification"
                        object:nil];
    
    #ifdef TEST
        CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, CFNotificationListener, NULL, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    #endif
    
//    [notifications addObserver:self selector:@selector(bluetoothConnected:) name:@"BluetoothDeviceConnectSuccessNotification" object:nil];
    
}


- (void)changeAudioOutput
{
    if (bluetooth == YES) {
        [self configureAVAudioSession:@"speaker"];
        Fs = [self logSampleRate];
    }
    else{
        [self configureAVAudioSession:@"receiver"];
        Fs = [self logSampleRate];
    }
    
}


// what if it can't be changed through the audio route button?
- (void) configureAVAudioSession: (NSString *) output
{
    //get your app's audioSession singleton object
    //AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    
    //error handling
    BOOL success;
    NSError* error;
    
    session             = [AVAudioSession sharedInstance];
    [session setActive:NO error:&error];
    
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride:
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                             error:&error];
//    success = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
//                                  error:&error];
  //  success = [session setCategory:AVAudioSessionPortBluetoothHFP
               //                             error:&error];
    
    if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set the audioSession override
    if ([output isEqualToString:@"receiver"]) {
        NSLog(@"speakerPhoneButton pressed: switching to receiver");
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                                  error:&error];
        bluetooth  = YES;
        sampleRate = 16000;
        
    }
    else{
        
        
        NSLog(@"headphones in there");
        //success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone
        //                                     error:&error];
        bluetooth   = NO;
        sampleRate  = 44100;
        // sdfdsf
        AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
        NSArray *inputsForRoute = currentRoute.inputs;
        NSArray *outputsForRoute = currentRoute.outputs;
        AVAudioSessionPortDescription *outPortDesc = [outputsForRoute objectAtIndex:0];
        // NSLog(@"current outport type %@", outPortDesc.portType);
        AVAudioSessionPortDescription *inPortDesc = [inputsForRoute objectAtIndex:0];
        // NSLog(@"current inPort type %@", inPortDesc.portType);
        //
        // Not sure if this is correct. It should only reset the audio session
        // when changing between bluetooth and something else. Everything else has the same settings.
        //
        NSLog(@"audio route listener callback");
        
        if ([inPortDesc.portType isEqualToString:@"MicrophoneWired"])
        {
            NSLog(@"headphones in there");
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                                 error:&error];

        }
        else {
            NSLog(@"speakerPhoneButton pressed: switching to speaker");
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                 error:&error];
            
        }
        bluetooth   = NO;
        sampleRate  = 44100;
        
    }

    
    if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    
    //activate the audio session
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"AVAudioSession error activating: %@",error);
    else NSLog(@"audioSession active");
    
    //Initialiaze recorder.
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    if (bluetooth) {
        [recordSetting setValue:[NSNumber numberWithFloat:16000] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    }
    else {
        [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    }

    // Initiate and prepare the recorder
    avrecorder = [[AVAudioRecorder alloc] initWithURL:[self testFilePathURL] settings:recordSetting error:nil];
    avrecorder.delegate = self;
    avrecorder.meteringEnabled = YES;
    [avrecorder prepareToRecord];
    
}



//audio format settings
-(AudioStreamBasicDescription)bluestreamFormat
{
    // Describe format
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate         = 16000.00;
    streamFormat.mFormatID           = kAudioFormatLinearPCM;
//    streamFormat.mFormatFlags        =  kAudioFormatFlagIsSignedInteger |
//    kAudioFormatFlagsNativeEndian |
//    kAudioFormatFlagIsPacked;
    streamFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    streamFormat.mFramesPerPacket    = 1;
    streamFormat.mChannelsPerFrame   = 1;
    streamFormat.mBitsPerChannel     = 16;
    streamFormat.mBytesPerPacket     = 2;
    streamFormat.mBytesPerFrame      = 2;
    
    return streamFormat;
}

//audio format settings
-(AudioStreamBasicDescription)streamFormat
{
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate        = 44100;
    streamFormat.mFormatID          = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags       = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket    = 4;
    streamFormat.mFramesPerPacket   = 1;
    streamFormat.mBytesPerFrame     = 4;
    streamFormat.mChannelsPerFrame  = 2; //CHANNELS;
    streamFormat.mBitsPerChannel    = 32;
    return streamFormat;
}


-(void)setUpCoreDataStack
{

    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    managedObjectContext  = [appDelegate managedObjectContext];
    
}

- (void) toggletoneStart {
    
    if (!toneUnit) {
        
        [self createToneUnit];
        // playbuttontext = @"Stop";
        // Stop changing parameters on the unit
        OSErr err = AudioUnitInitialize(toneUnit);
        // NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
        // Start playback
        err = AudioOutputUnitStart(toneUnit);
        // NSAssert1(err == noErr, @"Error starting unit: %ld", err);
        [writeThread cancel];
        writeThread = nil;
        //
        writeThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(writingthread)
                                                object:nil];
        [writeThread start];  // Actually create the thread
    }
    
}

- (void) toggletoneStop {
    
    if (toneUnit)
    {
        NSLog(@"tone stop");
        // This part seems to take over the EZAudio mic ...
        AudioOutputUnitStop(toneUnit);
        AudioUnitUninitialize(toneUnit);
        AudioComponentInstanceDispose(toneUnit);
        toneUnit = nil;
        if (!self.microphone.microphoneOn) {
            self.microphone = [EZMicrophone microphoneWithDelegate:self];
            [self.microphone startFetchingAudio];
        }
        [writeThread cancel];
        writeThread = nil;
    }
    
}


//- (void) toggleStart
//{
//        NSLog(@"start data recording data toggled - hehehehe");
//        playbuttontext = @"Stop";
//        [writeThread cancel];
//        writeThread = nil;
//        //
//        writeThread = [[NSThread alloc] initWithTarget:self
//                                              selector:@selector(writingthread)
//                                                object:nil];
//        [writeThread start];  // Actually create the thread
//    
//}
//
//- (void) toggleStop
//{
//    NSLog(@"stop data recording toggled");
//    playbuttontext = @"Start";
//
//    [writeThread cancel];
//    writeThread = nil;
//}



- (BOOL)clearEntity:(NSString *)entity {
    
    __block NSError *saveError = nil;

    NSManagedObjectContext *myContext = managedObjectContext;
    NSFetchRequest *fetchAllObjects = [[NSFetchRequest alloc] init];
    [fetchAllObjects setEntity:[NSEntityDescription entityForName:entity inManagedObjectContext:myContext]];
    [fetchAllObjects setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSError *error = nil;
    NSArray *allObjects = [myContext executeFetchRequest:fetchAllObjects error:&error];
    if (error) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    NSLog(@"count is %d",[allObjects count]);
    int i = 0;
    for (NSManagedObject *object in allObjects) {
        [myContext deleteObject:object];
        i = i+1;
    }
    // NSLog(@"stuff");
    if (![myContext save:&saveError]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }

    return (saveError == nil);
    
}
//
//
- (BOOL)saveData {
    
   // dispatch_sync(dispatch_get_main_queue(), ^{
        
        dtimestamp      = [NSDate date];
        NSString *magtext;
        NSString *phasetext;
        // This is updating too often...
        //magtext   = [NSString stringWithFormat:@"%.2f",dmagnitude];
        //phasetext = [NSString stringWithFormat:@"%.1f", RADIANS_TO_DEGREES(dphase)];
        //mag.text   = magtext;
        //phase.text = phasetext;
        // Actually this just puts something in the database.
        NSManagedObjectContext *context = managedObjectContext;
    
        Data *newData = [NSEntityDescription insertNewObjectForEntityForName:@"Data" inManagedObjectContext:context];
        newData.phase       = [NSNumber numberWithFloat:dphase];
        newData.magnitude   = [NSNumber numberWithFloat:dmagnitude];
        newData.timestamp   = dtimestamp;
        [context save:nil];
        
        if (calibrating == YES) {
            [cmagnitudes addObject:[NSNumber numberWithFloat:dmagnitude]];
            NSLog(@"calibr");
        }
        return YES;

   // });
   //return YES;
}



- (void)createToneUnit
{
    //
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
    // NSAssert1(toneUnit, @"Error creating unit: %ld", err);
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    
    // Render Sine Wave:
    input.inputProc = nil;
    if (rampstate == YES) {
        // Render Chirp:
        NSLog(@"rendering ramp");
        input.inputProc = RenderRamp;
        modstate = NO;
    }
    else { // Render a sine wave.
        
        if (modstate) {
            NSLog(@"rendering modgap");
            input.inputProc = RenderModulated;
        }
        else {
            NSLog(@"rendering sine wave");
            input.inputProc = RenderTone;
        }

    }
    input.inputProcRefCon = (__bridge void *)(self);
    err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    //
    // NSAssert1(err == noErr, @"Error setting callback: %ld", err);
    // Apply audio formats dependent on bluetooth mode or not.
    //
    if (bluetooth) {
        // just made it the same. 
        AudioStreamBasicDescription streamFormat = [self streamFormat];
        err = AudioUnitSetProperty (toneUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &streamFormat,
                                    sizeof(AudioStreamBasicDescription));
        
    }
    else {
            AudioStreamBasicDescription streamFormat = [self streamFormat];
            err = AudioUnitSetProperty (toneUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &streamFormat,
                                    sizeof(AudioStreamBasicDescription));
    }

    
}


-(void)createFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
    
    // Setup the length
    _log2n = log2f(bufferSize);
    
    // Calculate the weights array. This is a one-off operation.
    _FFTSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);
    
    // For an FFT, numSamples must be a power of 2, i.e. is always even
    int nOver2 = bufferSize/2;
    
    // Populate *window with the values for a hamming window function
    float *window = (float *)malloc(sizeof(float)*bufferSize);
    vDSP_hamm_window(window, bufferSize, 0);
    // Window the samples
    vDSP_vmul(data, 1, window, 1, data, 1, bufferSize);
    free(window);
    
    // Define complex buffer
    _A.realp = (float *) malloc(nOver2*sizeof(float));
    _A.imagp = (float *) malloc(nOver2*sizeof(float));
    
}

-(void)updateFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
    
    // For an FFT, numSamples must be a power of 2, i.e. is always even
    int nOver2 = bufferSize/2;
    
    // Pack samples:
    // C(re) -> A[n], C(im) -> A[n+1]
    vDSP_ctoz((COMPLEX*)data, 2, &_A, 1, nOver2);
    
    // Perform a forward FFT using fftSetup and A
    // Results are returned in A
    vDSP_fft_zrip(_FFTSetup, &_A, 1, _log2n, FFT_FORWARD);
    // Convert COMPLEX_SPLIT A result to magnitudes
    float amp[nOver2];
    float maxMag = 0;
    for(int i=0; i<nOver2; i++) {
        // Calculate the magnitude
        float mag = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
        maxMag = mag > maxMag ? mag : maxMag;
    }
    //
    float binspacing = (float)(Fs)/(float)bufferSize;
    float tiny      = 0.1; //1.0; // was 0.1
    float mavamp    = 0.01;
    float f         = 0.0;
    //float currentphase    = 0.0f;
    float currentmagnitude  = 0.0f;
    int ivalue =0;
    int cc = 0;
    // float scale = 1.0;
    for(int i=0; i<nOver2; i++) {
        // Calculate the magnitude
        float magn = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
        // Bind the value to be less than 1.0 to fit in the graph
        amp[i] = [EZAudio MAP:magn leftMin:0.0 leftMax:maxMag rightMin:0.0 rightMax:1.0];
        f = i*binspacing;
        frequencies[i] = [NSNumber numberWithFloat:i*binspacing];
        lastfftamps[i] = [NSNumber numberWithFloat:magn];
        if ( (f < frequency+binspacing) && (f > frequency-binspacing)) {
            //
            // NSLog(@"here");
            cc = cc+1;
            //
            // It should only get in here once.
            if (cc == 1) {
                // i wonder how many times in a loop it gets in here.
                // remember the i value.
                ivalue = i;
                //currentmagnitude = log10(amp[ivalue]);
                currentmagnitude    = magn; //amp[ivalue];
                //currentmagnitude = -20*log10(sqrt(amp[ivalue]));
                //currentmagnitude = sqrt(amp[ivalue]);
                //
                //mavamp    = (((1.0 - tiny)*lastamp) + tiny*currentmagnitude);
                //lastamp     = mavamp;
                //dmagnitude  = mavamp;
                //
                dmagnitude = currentmagnitude;
                // 
                if (scalefactor != abs(INFINITY)) {
                    //dmagnitude = mavamp/scalefactor;
                    dmagnitude = currentmagnitude/scalefactor;
                }
                // NSLog(@"dmag %f",dmagnitude);
            }
            // NSLog(@"mavamp %f %f %f",magn,dmagnitude,scalefactor);
        }
        
    }

    // copy from one array to the next.
    dlastfftamps = [[NSMutableArray alloc] initWithArray:lastfftamps copyItems:YES];
    //
//    dvfdg
//    // For an FFT, numSamples must be a power of 2, i.e. is always even
//    int nOver2 = bufferSize/2;
//    // Pack samples:
//    // C(re) -> A[n], C(im) -> A[n+1]
//    vDSP_ctoz((COMPLEX*)data, 2, &_A, 1, nOver2);
//    // Perform a forward FFT using fftSetup and A
//    // Results are returned in A
//    vDSP_fft_zrip(_FFTSetup, &_A, 1, _log2n, FFT_FORWARD);
//    float binspacing = (float)(22050)/(float)bufferSize;
//    // NSLog(@"binspacing %f",binspacing); //20nm.
//    // Convert COMPLEX_SPLIT A result to magnitudes
//    float amp[nOver2];
//    float maxMag = 0;
//    for(int i=0; i<nOver2; i++) {
//        // Calculate the magnitude
//        float magn = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
//        maxMag = magn > maxMag ? magn : maxMag;
//    }
//    //
//    float tiny = 0.1; //1.0; // was 0.1
//    float mavamp;
//    float f = 0.0;
//    float currentphase      = 0.0f;
//    float currentmagnitude  = 0.0f;
//    //
//    for(int i=0; i<nOver2; i++) {
//        //
//        // float magn =1+ 10*log10( _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i])/100;
//        // Calculate the magnitude
//        float magn = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
//        // Bind the value to be less than 1.0 to fit in the graph
//        amp[i] = [EZAudio MAP:magn leftMin:0.0 leftMax:maxMag rightMin:0.0 rightMax:1.0];
//        f = i*binspacing;
//        frequencies[i] = [NSNumber numberWithFloat:i*binspacing];
//        lastfftamps[i] = [NSNumber numberWithFloat:magn];
//        //
//        if ( (f < frequency+binspacing) && (f > frequency-binspacing)) {
//            //
//            float phasecalc  = atan2f(_A.imagp[i],_A.realp[i]);
//            currentphase     = phasecalc; // - theta; // phase difference between input and output.
//            currentmagnitude = magn; //magnitudeinterval;
//            // Actually this just puts something in the database.
//            if (currentphase > 0.0 & currentphase < 3.0) {
//                //
//                mavamp      = (((1.0 - tiny)*lastamp) + tiny*currentmagnitude  );
//                lastamp     = mavamp;
//                currentmagnitude = mavamp;
//                dphase      = currentphase;
//                
//                if (currentmagnitude == 0 ) {
//                    currentmagnitude = dmagnitude;
//                }
//                if (scalefactor != abs(INFINITY)) {
//                    dmagnitude = currentmagnitude/scalefactor;
//                }
//                
//            }
//            
//        }
//    }
//    
//    // copy from one array to the next.
//    dlastfftamps = [[NSMutableArray alloc] initWithArray:lastfftamps copyItems:YES];

}


//microphone delegate - receives audiosystem updates
-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels
{
    if(isRecording)
    {
        [recorder appendDataFromBufferList:bufferList
                            withBufferSize:bufferSize];
    }
}


//-(void)           output:(EZOutput *)output
// callbackWithActionFlags:(AudioUnitRenderActionFlags *)ioActionFlags
//             inTimeStamp:(const AudioTimeStamp *)inTimeStamp
//             inBusNumber:(UInt32)inBusNumber
//          inNumberFrames:(UInt32)inNumberFrames
//                  ioData:(AudioBufferList *)ioData
//{
//
//// Nothing here yet.
//}

#pragma mark - EZMicrophoneDelegate
-(void)    microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Calculate Decibels.
        // Decibel Calculation.
//        float one       = 1.0;
//        float meanVal   = 0.0;
//        float tiny      = 0.1;
//        vDSP_vsq(buffer[0], 1, buffer[0], 1, bufferSize);
//        vDSP_meanv(buffer[0], 1, &meanVal, bufferSize);
//        vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
//        //
//        // Exponential moving average to dB level to only get continous sounds.
//        float currentdb = 1.0 - (fabs(meanVal)/100);
//        if (lastdbValue == INFINITY || lastdbValue == -INFINITY || isnan(lastdbValue)) {
//            lastdbValue = 0.0;
//        }
//        //dbValue =   ((1.0 - tiny)*lastdbValue) + tiny*currentdb;
//        currentdb = 2*(currentdb-0.35);
//        dbValue =   ((1.0 - tiny)*lastdbValue) + tiny*currentdb;
//        lastdbValue = dbValue;
        //
        
        
        // Update time domain plot
        if (rawscalefactor != 1.0) {
            
            for (int i =0; i<bufferSize;i++) {
                buffer[0][i] = buffer[0][i]/rawscalefactor;
            }

        }
        else {

        }

        // Setup the FFT if it's not already setup
        if( !_isFFTSetup ){
            [self createFFTWithBufferSize:bufferSize withAudioData:buffer[0]];
            _isFFTSetup = YES;
        }
        
        // Get the FFT data
        [self updateFFTWithBufferSize:bufferSize withAudioData:buffer[0]];
        
    });
}

- (void) applicationDidEnterBackground: (UIApplication *) application {
    
    NSLog(@"applicationDidEnterBackground:");
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
}

// If the user pulls out he headphone jack, stop playing.
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    //NSLog(@"audio jack not connected");
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *inputsForRoute = currentRoute.inputs;
    NSArray *outputsForRoute = currentRoute.outputs;
    AVAudioSessionPortDescription *outPortDesc = [outputsForRoute objectAtIndex:0];
    // NSLog(@"current outport type %@", outPortDesc.portType);
    AVAudioSessionPortDescription *inPortDesc = [inputsForRoute objectAtIndex:0];
    // NSLog(@"current inPort type %@", inPortDesc.portType);
    //
    // Not sure if this is correct. It should only reset the audio session
    // when changing between bluetooth and something else. Everything else has the same settings.
    //
    NSLog(@"audio route listener callback");
    
    if ([inPortDesc.portType isEqualToString:@"MicrophoneWired"])
    {
        audiojackconnected = YES;
    }
    
    else {
        audiojackconnected = NO;
    }
    outport = inPortDesc.portType;
    inport  = outPortDesc.portType;
    
}



- (NSString *) getoutport {
    
    return outport;
}


- (NSString *) getinport {
    
    return inport;
    
}

- (NSString *) getfilesize {
    float duration = (float)avplayer.duration;
    // NSLog(@"duration:%f",duration);
    filesize = [[NSNumber numberWithFloat:duration] stringValue];
    
    return filesize;
    
}

//
//
// Volume Level Display.
//
- (void)volumeChanged:(NSNotification*)notification {
    
    float vol = [[AVAudioSession sharedInstance] outputVolume];
    mpvolumevalue = vol; //20.f*log10f(vol+FLT_MIN);
    NSLog(@"output volume: %1.2f dB", mpvolumevalue);
}

- (float)getvolume {
    
    return mpvolumevalue;
}


- (void)audioSessionInterrupted:(NSNotification*)notification {
    NSDictionary *interruptionDictionary = [notification userInfo];
    NSNumber *interruptionType = (NSNumber *)[interruptionDictionary valueForKey:AVAudioSessionInterruptionTypeKey];
    if ([interruptionType intValue] == AVAudioSessionInterruptionTypeBegan) {
        NSLog(@"Interruption started");
    } else if ([interruptionType intValue] == AVAudioSessionInterruptionTypeEnded){
        NSLog(@"Interruption ended");
    } else {
        NSLog(@"Something else happened");
    }
}



- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupBackgrounding {
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appBackgrounding:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appForegrounding:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
}


- (void)appBackgrounding: (NSNotification *)notification {
    NSLog(@"appBackgrounding!");
    [self keepAlive];
}

- (void) keepAlive {
    self.backgroundTask = [ [UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
        [self keepAlive];
    }];
}

- (void)appForegrounding: (NSNotification *)notification {
    
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)rampenabled {
    rampstate = YES;
}


- (void)rampdisabled {
    rampstate = NO;
}
//
// modgap needs to come through from somewhere as well
// Otherwise default it to 3.
//
- (void)modenabled {
    modstate = YES;
}

- (void)moddisabled {
    modstate = NO;
}


+ (NSNumber *)meanOf:(NSArray *)array
{
    double runningTotal = 0.0;
    for(NSNumber *number in array)
    {
        runningTotal += [number doubleValue];
    }
    return [NSNumber numberWithDouble:(runningTotal / [array count])];
}



-(void)writingthread
{
    @autoreleasepool
    {
        NSRunLoop *TimerRunLoop = [NSRunLoop currentRunLoop];
        UITimer =  [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(writeMethod) userInfo:nil repeats:YES];
        [TimerRunLoop run];
    }
    
}

- (void)writeMethod {
    
    if (managedObjectContext == nil) {
        NSLog(@"NSManagedObjectContext is nil");
        [self setUpCoreDataStack];
    }
    //
    // NSLog(@"write thread is doing it.");
    NSString *magtext;
    NSString *phasetext;
    // This is updating too often...
    magtext   = [NSString stringWithFormat:@"%.2f",dmagnitude];
    //phasetext = [NSString stringWithFormat:@"%.1f", RADIANS_TO_DEGREES(dphase)];
    //mag.text   = magtext;
    //phase.text = phasetext;
    //NSLog(@"mag phase %@ %@",magtext,phasetext);
    //
    if (calibrating == YES) {
        NSDate *currenttime = [NSDate date];
        NSTimeInterval secs = [currenttime timeIntervalSinceDate:calibrationmarker];
        NSLog(@"secs %d",secs);
        if (secs > 15) {
            NSLog(@"Calibration finished.");
            [self calculatecalibration];
            calibrationmarker = currenttime;
            calibrating       = NO;
            [cmagnitudes removeAllObjects];
            calibratebuttonTitle = @"Calibrate";
        }
        else {
            //NSLog(@"Calibration right now");
            int seconds = (int)secs;
            [self calculatecalibration];
            NSString *counttext   = [NSString stringWithFormat:@"%d",seconds];
            calibratebuttonTitle = counttext;
        }
    }
    else {
        calibratebuttonTitle = @"Calibrate";
        // NSLog(@"data saving");
        //[calibratebutton setTitle:@"Calibrate" forState:UIControlStateNormal];
        [self saveData];
    }
    //  session.
    //  # output.audioStreamBasicDescription.mFormatID
    //  When stop thread, not closing down object model context properly...

    
}


- (void)stop
{
    [self toggleStop];
    NSLog(@"write thread stopped");
}

- (NSString *) getplaybuttontext {
 
    return playbuttontext;
}

- (float) getdbValue {

    return dmagnitude;
}


//- (float) getdbValue {
//    
//    return dmagnitude;
//}

// We need things to be passed between the biotableviewcontroller, and the audiohandling controller.
- (void)setfrequency: (NSNumber *)freq {
    frequency = [freq doubleValue];
}


- (void)setmodgap: (NSNumber *)modg {
    modgap = [modg doubleValue];
}

- (void)settonestart {
    NSLog(@"tone starts, start saving? ");
    [self toggletoneStart];
    [UITimer invalidate];
    [writeThread cancel];
}

- (void)settonestop {

    [self toggletoneStop];
    
    [UITimer invalidate];
    [writeThread cancel];
    
    writeThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(writingthread)
                                            object:nil];
    [writeThread start];  // Actually create the thread
    
}


- (void)setamplitude: (NSNumber *)val {
    
    calibrateamplitude = [val doubleValue];
}

- (void)deletealltabledata {
 
    NSLog(@"deleting data");
    BOOL thing = [self clearEntity:@"Data"];
    NSLog(@"cleared entity");
    
}

- (int) gettoneon {
    
    if (toneUnit) {
        return 1;
    }
    return 0;
}

- (BOOL) isdatawriting {
    
    if ([writeThread isExecuting] && (writeThread != nil)) {
        NSLog(@"it's executing");
        return YES;
    }
    // return whether or not we are writing to core data, or not.
    return NO;

}


- (void) makecsv {
    
    NSString *outputString = @"";
    NSManagedObjectContext *myContext = managedObjectContext;
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName:@"Data"
                                               inManagedObjectContext:myContext];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [myContext executeFetchRequest:fetchRequest error:&error];
    NSString *magtext;
    NSString *phasetext;
    NSString *timetext;
    // Write the header into the file.
    outputString = [outputString stringByAppendingFormat:@"Time,Magnitude,Phase\n"];
    int i = 0;
    for (Data *object in fetchedObjects) {
        // NSLog(@"yo %d",i);
        magtext      = [NSString stringWithFormat:@"%.15f", [object.magnitude floatValue]];
        phasetext    = [NSString stringWithFormat:@"%.15f", [object.phase floatValue]];
        timetext     = [NSString stringWithFormat:@"%@", object.timestamp];
        outputString = [outputString stringByAppendingFormat:@"%@,%@,%@\n", timetext, magtext, phasetext];
        i = i+1;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    NSString *outputFileName = [docDirectory stringByAppendingPathComponent:@"data.csv"];
    //Create an error incase something goes wrong
    NSError *csvError = NULL;
    //We write the string to a file and assign it's return to a boolean
    BOOL written = [outputString writeToFile:outputFileName atomically:YES encoding:NSUTF8StringEncoding error:&csvError];
    //If there was a problem saving we show the error if not show success and file path
    if (!written) {
        NSLog(@"write failed, error=%@", csvError);
    }
    else {
        NSLog(@"Saved! File path = %@", outputFileName);
    }
}
//
//
// get the magnitudes and get the times for the history plot
//
//
- (NSMutableArray *) getmags {
    
    times = [[NSMutableArray alloc]init];
    mags  = [[NSMutableArray alloc]init];
    NSManagedObjectContext *myContext = managedObjectContext;
    
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName:@"Data"
                                               inManagedObjectContext:myContext];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [myContext executeFetchRequest:fetchRequest error:&error];
    NSMutableArray *timeslong = [[NSMutableArray alloc]init];
    for (Data *object in fetchedObjects) {
        int timestamp = [object.timestamp timeIntervalSince1970];
        [timeslong addObject:[NSNumber numberWithInt:timestamp]];
        [mags addObject:object.magnitude];
    }
    
    int xxmin = [[timeslong valueForKeyPath:@"@min.self"] intValue];
    NSLog(@"min is : %D",xxmin);
    for (NSInteger j = 0; j < [timeslong count]; j ++) {
        int timenow = [[timeslong objectAtIndex:j] intValue];
        int diff    = timenow; // - xxmin;
        [times addObject:[NSNumber numberWithInt:diff]];
    }
    //
    // NSLog(@"history date %@",mags);
    //
    return mags;
}

- (NSMutableArray *) gettimes {
    // NSLog(@"history scores %@",historyscores);
    return times;
}
//
// don't need raw scale factor or scale factor because we don't want to alter the real recorded data. 

- (void) initialize {

    [self setUpCoreDataStack];
    //[self init];
    //sharedManager = [[super allocWithZone:NULL]init];
}
//
//
//
- (void) recordingOn {
//
    NSLog(@"recording on");
//    if( audioPlayer )
//    {
//        if( audioPlayer.playing )
//        {
//            [audioPlayer stop];
//        }
//        audioPlayer = nil;
//    }
    
    
    // Stop the audio player before recording
    if (avplayer.playing) {
        [avplayer stop];
    }
//
    if (!avrecorder.recording) {
//        AVAudioSession *session = [AVAudioSession sharedInstance];
//        [session setActive:YES error:nil];
        
        // Start recording
        [avrecorder record];
        //[recordPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        
    }


    // New create the recorder without EZAudio
    
    /*
     Create the recorder
     */
//    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted)
//     {
//         //
//         //
//         if ( bluetooth == NO) {
//             recorder = nil;
//             recorder = [EZRecorder recorderWithDestinationURL:[self testFilePathURL]
//                                                  sourceFormat:[self streamFormat]
//                                           destinationFileType:EZRecorderFileTypeWAV];
//         }
//         else {
//             recorder = nil;
//             recorder = [EZRecorder recorderWithDestinationURL:[self testFilePathURL]
//                                                  sourceFormat:[self bluestreamFormat]
//                                           destinationFileType:EZRecorderFileTypeWAV];
//         }
//
//     }];
    
    NSLog(@"recording");
    isRecording = YES;
}

- (void) recordingStop {
    NSLog(@"stop recording");
    [avrecorder stop];
    
//    if(recorder != nil)
//    {
//        [recorder closeAudioFile];
//        recorder = nil;
//    }
     isRecording = NO;
}

- (void) playOn {
    
    NSLog(@"play on");
    // av audio recorder
    if (!avrecorder.recording){
        avplayer = [[AVAudioPlayer alloc] initWithContentsOfURL:avrecorder.url error:nil];
        [avplayer setDelegate:self];
        [avplayer play];
        isRecording = NO;
    }
    
    float duration = (float)avplayer.duration;
    NSLog(@"duration:%f",duration);
    filesize = [[NSNumber numberWithFloat:duration] stringValue];
    
    // Update microphone state
//   [self.microphone stopFetchingAudio];
//    
//    // Update recording state
    
//    
//    // Create Audio Player
//    if( audioPlayer )
//    {
//        if( audioPlayer.playing )
//        {
//            [audioPlayer stop];
//        }
//        audioPlayer = nil;
//    }
//    
//    // Close the audio file
//    if( recorder )
//    {
//        [recorder closeAudioFile];
//    }
//    
//    NSError *err;
//    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self testFilePathURL]
//                                                              error:&err];
//    [audioPlayer play];
//    audioPlayer.delegate = self;
    
    isPlaying = YES;
    //self.playingTextField.text = @"Playing";

    
}
- (void) playStop {
    
    NSLog(@"Play Stop");
    if( avplayer.playing ) {
        [avplayer stop];
    }
//    if( audioPlayer.playing )
//    {
//        [audioPlayer stop];
//    }
//    audioPlayer = nil;
    isPlaying = NO;
}

-(void) deletewavefile {
    
    // Get the waves in the documents directory.
    //
    NSFileManager  *manager = [NSFileManager defaultManager];
    
    // the preferred way to get the apps documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // grab all the files in the documents dir
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // filter the array for only sqlite files
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.m4a'"];
    NSArray *sqliteFiles = [allFiles filteredArrayUsingPredicate:fltr];
    
    // use fast enumeration to iterate the array and delete the files
    for (NSString *sqliteFile in sqliteFiles)
    {
        NSError *error = nil;
        [manager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:sqliteFile] error:&error];
        NSAssert(!error, @"Assertion: wavefile deletion shall never throw an error.");
    }
    
    
}


#pragma mark - AVAudioPlayerDelegate
/*
 Occurs when the audio player instance completes playback
 */
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
//    
    if( avplayer.playing ) {
        [avplayer stop];
    }
//
//    if( audioPlayer.playing )
//    {
//        [audioPlayer stop];
//    }
//    audioPlayer = nil;

    NSLog(@"Play Stop");
//    if( audioPlayer.playing )
//    {
//        [audioPlayer stop];
//    }
//    audioPlayer = nil;
    isPlaying = NO;
  
}


#pragma mark - Utility
-(NSArray*)applicationDocuments {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
}

-(NSString*)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(NSURL*)testFilePathURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   kAudioFilePath]];
}


- (float)logSampleRate {
    Float64 sampleRate;
    UInt32 srSize = sizeof (sampleRate);
    OSStatus error =
    AudioSessionGetProperty(
                            kAudioSessionProperty_CurrentHardwareSampleRate,
                            &srSize,
                            &sampleRate);
    if (error == noErr) {
    //    NSLog (@"CurrentHardwareSampleRate = %f", sampleRate);
    }
    return sampleRate;
}


- (void) calibrationstarted {
    NSLog(@"calibrate button");
    calibrating = YES;
    calibrationmarker = [NSDate date];
}

- (void) calculatecalibration {

    // we need to have smaller increments.
    //
    NSNumber *mean  = [audiohandling meanOf:cmagnitudes];
    // now adjust graph things...
    if ([mean floatValue] < 0.3) { // amplitude should increase
        if (fabs(calibrateamplitude) < 1 && calibrateamplitude > 0) {
            calibrateamplitude = calibrateamplitude + increment;
        }
    }
    else { // amplitude should decrease
        
        if (calibrateamplitude < increment) {
            increment = increment/2;
            if (calibrateamplitude <= 0.0) {
                calibrateamplitude = calibrateamplitude + increment;
            }
            //
        }
        else {
            calibrateamplitude = calibrateamplitude - increment;
        }
        
    }
    NSLog(@"calibrate amplitude %.2f",calibrateamplitude);
    //ampslid.value = calibrateamplitude;
    
}

- (NSString *) returncalibrationtitle {
    return calibratebuttonTitle;
}

@end
