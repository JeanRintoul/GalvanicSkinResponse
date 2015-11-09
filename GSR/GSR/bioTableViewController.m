//
//  bioTableViewController.m
//  BioimpedanceSpectrometer
//
//  Created by Jean Rintoul on 8/24/14.
//  Copyright (c) 2014 ibisbiofeedback. All rights reserved.
//

#import "bioTableViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "audiohandling.h"

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define kGlassColor [UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1.0]
//#define kRedColor [UIColor colorWithRed:0.3888 green:0.915 blue:0.976 alpha:1.0]  //actually blue
#define kRedColor [UIColor colorWithRed:0.9 green:0.01 blue:0.01 alpha:1.0]

#define kGrayColor [UIColor colorWithRed:0.396 green:0.396 blue:0.396 alpha:1.0]
#define kWhiteColor [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]
#define kBlackColor [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.5]

const UInt32 FFTLEN = 44100;

@interface SystemVolumeView : MPVolumeView

@end

@implementation SystemVolumeView
- (CGRect)volumeSliderRectForBounds:(CGRect)bounds
{
    return bounds;
}

- (CGRect) routeButtonRectForBounds:(CGRect)bounds {
    
    CGRect newBounds=[super routeButtonRectForBounds:bounds];
    newBounds.origin.y=bounds.origin.y;
    
    newBounds.size.height=bounds.size.height;
    
    return newBounds;
}

@end


@interface bioTableViewController ()

//@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation bioTableViewController {
    
    NSTimer *UITimer;
    //    NSThread* writeThread;
    NSThread* uiThread;
    //
    double frequency;
    double modgap;
    int toneon;
    BOOL isdatawriting; 
    float lastamp;
    NSString *playbuttontext;

    COMPLEX_SPLIT _A;
    FFTSetup      _FFTSetup;
    BOOL          _isFFTSetup;
    vDSP_Length   _log2n;
    
    // NSMutableArray* lastfftamps;
    // NSMutableArray* frequencies;
    
    float _fftBuf[FFTLEN];
    int _fftBufIndex;
    int _samplesRemaining;
    float dmagnitude;
    float dphase;
    NSMutableArray* dlastfftamps;
    NSDate *dtimestamp;
    float scalefactor;
    float rawscalefactor;
    float frequencyvalue;
    float Fs;
//    BOOL calibrating;
//    NSMutableArray *cmagnitudes;
//    float increment;

}

@synthesize tableView;
@synthesize audioPlot;
@synthesize audioPlotFreq;
@synthesize microphone;
@synthesize volumeView;
@synthesize volumeiconimage;
@synthesize frequencySlider;
@synthesize gapslider;
@synthesize playButton;
@synthesize frequencyLabel;
@synthesize calibratebutton;
@synthesize exportbutton;
@synthesize mag;
@synthesize phase;
@synthesize ampslid;
@synthesize graphscale;
@synthesize rawscale;
@synthesize sinebutton;
@synthesize rampbutton;
@synthesize audioplayback;
@synthesize recordaudio;
@synthesize volumedisplaylabel;
@synthesize connectiontextfield;
@synthesize samplerate;
@synthesize maggraphscaleslider;
@synthesize inportlabel;
@synthesize outportlabel;
@synthesize mpvolume;
@synthesize blueswitch;
@synthesize modlabel;
@synthesize filesize;
@synthesize scrollview;
@synthesize frequencytextfield;
//
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self centerScrollViewContents];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate     = self;
    self.tableView.dataSource   = self;
//    calibrating = NO;
//    //calibrationmarker   = [NSDate date];
//    cmagnitudes         = [[NSMutableArray alloc]init];
    //calibrateamplitude  = 0.99;
    //
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.navigationController.navigationBar setBarTintColor:[UIColor redColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                                      shadow, NSShadowAttributeName,
                                                                      [UIFont fontWithName:@"AmericanTypewriter" size:20.0], NSFontAttributeName, nil]];

    

    [mpvolume setRouteButtonImage:[UIImage imageNamed:@"route"]forState:UIControlStateNormal];
    
    toneon = [[audiohandling sharedManager] gettoneon];
    isdatawriting = [[audiohandling sharedManager] isdatawriting];
    //lastfftamps  = [[NSMutableArray alloc]init];
    //frequencies  = [[NSMutableArray alloc]init];
    _fftBufIndex = 0;
    _samplesRemaining = FFTLEN;
    //
    //
    // How to set up zoom control?
    //
    // 
    // Setup frequency domain audio plot
    self.magnitudePlot.backgroundColor = kWhiteColor;
    self.magnitudePlot.color           = [UIColor redColor];
    self.magnitudePlot.shouldFill      = NO;
    self.magnitudePlot.plotType        = EZPlotTypeRolling;
    self.magnitudePlot.shouldMirror    = NO;
    [self.magnitudePlot setRollingHistoryLength:2000];
    [self.magnitudePlot setGain:1]; // y scaling // 20Hz per bin,
    
    // Background color
    self.audioPlot.backgroundColor = kWhiteColor;     // Waveform color
    self.audioPlot.color           = [UIColor redColor];
    self.audioPlot.alpha           = 1.0; //0.2;
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeRolling;
    // Fill
    self.audioPlot.shouldFill      = NO;
    // Mirror
    self.audioPlot.shouldMirror    = NO;
    // History length
    [self.audioPlot setRollingHistoryLength:2000];
    [self.audioPlot setGain:1];  // y scaling
    //
    // Setup frequency domain audio plot
    self.audioPlotFreq.backgroundColor = kWhiteColor;
    // self.audioPlotFreq.alpha           = 0.2;
    self.audioPlotFreq.color           = [UIColor redColor];
    self.audioPlotFreq.shouldFill      = YES;
    self.audioPlotFreq.plotType        = EZPlotTypeBuffer;
    self.audioPlotFreq.shouldMirror    = NO;
    [self.audioPlotFreq setGain:1]; // y scaling // 20Hz per bin,
    //
    NSLog(@"called view did load again");
    // This ensures the session is listening to background events, so that it keeps active when Iphone is locked or app goes into the background.
    //[self configureAVAudioSession:@"speaker"];
    self.scrollview.minimumZoomScale = 0.5;
    self.scrollview.maximumZoomScale = 6.0;
    // self.scrollview.contentSize = self.magnitudePlot.sizeToFit;
    self.scrollview.delegate = self;
    
    //self.scrollView.contentSize=CGSizeMake(1280, 960);
    self.scrollview.scrollEnabled = true;
    self.scrollview.userInteractionEnabled = true;
    
    //setup notifications and backgrounding
    //[self setupNotifications];
    
    //set the audioSession category.
    BOOL success;
    NSError* error;
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:&error];
    //
    //
    [self gapchanged:gapslider];
    //
    [self sliderChanged:frequencySlider];
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    [self.microphone startFetchingAudio];
    dmagnitude  = 0.0;
    dphase      = 0.0;
    dtimestamp  = [NSDate date];
    lastamp     = 0.8;
    graphscale.delegate = self;
    [graphscale addTarget:self
                   action:@selector(scaleentered:)
         forControlEvents:UIControlEventEditingDidEnd];
    scalefactor = 0.5;
    
    rawscale.delegate = self;
    [rawscale addTarget:self
                   action:@selector(rawscaledentered:)
         forControlEvents:UIControlEventEditingDidEnd];
    rawscalefactor = 1.0;
    
    frequencytextfield.delegate = self;
    [frequencytextfield addTarget:self
                 action:@selector(frequencyvaluentered:)
       forControlEvents:UIControlEventEditingDidEnd];

    playbuttontext = [[audiohandling sharedManager] getplaybuttontext];
    playButton.titleLabel.text = playbuttontext;
    
    [tableView reloadData];
    
    // initialize.
    [[audiohandling sharedManager] initialize];

    [uiThread cancel];
    uiThread = nil;
    uiThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(userithread)
                                            object:nil];
    [uiThread start];  // Actually create the thread

    frequency = 1500.0;
    frequencyLabel.text = [NSString stringWithFormat:@"%4.1f Hz", frequency];
    // Send the frequency value through to the audiohandler.
    NSNumber *freq = [[NSNumber alloc] initWithDouble:frequency];
    [[audiohandling sharedManager] setfrequency:freq];
    
}


// what if it can't be changed through the audio route button?
- (void) configureAVAudioSession: (NSString *) output
{
    //get your app's audioSession singleton object
    //AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    
    //error handling
    BOOL success;
    NSError* error;
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:&error];
    
    [[AVAudioSession sharedInstance] setActive:NO error:&error];
    

    if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set the audioSession override
    if ([output isEqualToString:@"receiver"]) {
        NSLog(@"speakerPhoneButton pressed: switching to receiver");
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                                           error:&error];
        
        [self.microphone stopFetchingAudio];
        lastamp = 0.8;
        _isFFTSetup = NO;
        //self.microphone = nil;
        _fftBufIndex = 0;
        _samplesRemaining = 44100;
        Fs = [[audiohandling sharedManager] logSampleRate];
//        self.microphone = nil;
//        self.microphone = [EZMicrophone microphoneWithDelegate:self];
        [self.microphone startFetchingAudio];
       // bluetooth  = YES;
       // sampleRate = 16000;
        //
    }
    else{
        NSLog(@"speakerPhoneButton pressed: switching to speaker");
        //
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                           error:&error];
        
        //[[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone
        //                                                   error:&error];
        [self.microphone stopFetchingAudio];
        lastamp = 0.8;
        _isFFTSetup = NO;
        
        //self.microphone = nil;
        _fftBufIndex = 0;
        _samplesRemaining = 44100;
        
        Fs = [[audiohandling sharedManager] logSampleRate];
        
        //self.microphone = [EZMicrophone microphoneWithDelegate:self];
        [self.microphone startFetchingAudio];
        lastamp = 0.8;
        _isFFTSetup = NO;
//        bluetooth   = NO;
//        sampleRate  = 44100;
    }
    
    if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    
    //activate the audio session
    [[AVAudioSession sharedInstance] setActive: YES error: nil];

    if (!success) NSLog(@"AVAudioSession error activating: %@",error);
    else NSLog(@"audioSession active");
    
    

}


-(void)userithread
{
    @autoreleasepool
    {
        NSRunLoop *TimerRunLoop = [NSRunLoop currentRunLoop];
        UITimer =  [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(uiMethod) userInfo:nil repeats:YES];
        [TimerRunLoop run];
    }
    
}

- (void)uiMethod {

    //
    BOOL playingtrue = [[audiohandling sharedManager] isPlaying];
    if (!playingtrue )
    {
        //[[audiohandling sharedManager] playOn];
        [audioplayback setTitle:NSLocalizedString(@"Playback", nil) forState:0];
        toneon = 0;
    }
    else
    {
        //[[audiohandling sharedManager] playStop];
        [audioplayback setTitle:NSLocalizedString(@"Stop", nil) forState:0];
    }
    
    BOOL audiojack = [[audiohandling sharedManager] audiojackconnected];
    if (!audiojack )
    {
        [connectiontextfield setTitle:NSLocalizedString(@"No Headset", nil) forState:0];

    }
    else
    {
        [connectiontextfield setTitle:NSLocalizedString(@"Headset Connected", nil) forState:0];
    }
    //
    // Display the current volume.
    float volume = [[audiohandling sharedManager] getvolume];
    NSString *v = [NSString stringWithFormat:@"%f", volume];
    volumedisplaylabel.text = v;
    //
    float sr = [[audiohandling sharedManager] logSampleRate];
    NSString *Fsa = [NSString stringWithFormat:@"%.1f", sr];
    //
    //
    Fs = sr;
    [samplerate setTitle:NSLocalizedString(Fsa, nil) forState:0];
    //
    //
    //NSString *in = [[audiohandling sharedManager] getinport];
    //NSLog(@"%@",in);
    inportlabel.text  = [[audiohandling sharedManager] getinport];
    outportlabel.text = [[audiohandling sharedManager] getoutport];
    
    // get and display the filesize. 
    filesize.text = [[audiohandling sharedManager] getfilesize];
    
    // 
    NSString *title = [[audiohandling sharedManager] returncalibrationtitle];
    [calibratebutton setTitle:title forState:UIControlStateNormal];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    
    if ([view isKindOfClass: [UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView* castView = (UITableViewHeaderFooterView*) view;
        [castView.textLabel setTextColor:kGrayColor];
        [castView.detailTextLabel setTextColor:kGrayColor];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if ([self tableView:self.tableView titleForHeaderInSection:section] != nil) {
        return 40;
    }
    else {
        // If no section header title, no section header needed
        return 0;
    }
}


//
// 25 second calibration at the start of a run. Control the output volume,
// 1/3 of the scale of the average measure.
// Find the median of all the values.
//


- (IBAction)ampslider:(UISlider *)sender {
    
    NSLog(@"change the output amplitude");
    float val = ampslid.value;
    // NSLog(@"val %f",val);
    NSNumber *amp = [[NSNumber alloc] initWithFloat:val];
    [[audiohandling sharedManager] setamplitude:amp];
    NSLog(@"val %f",val);

}

- (IBAction)blueswitchaction:(id)sender {
    
    if ([blueswitch isOn]) {
        //self.myTextField.text = @"The Switch is Off";
        [[audiohandling sharedManager] changeAudioOutput];
        NSLog(@"Switch is on");
        [self configureAVAudioSession:@"receiver"];

//        _isFFTSetup = NO;
//        [self.microphone stopFetchingAudio];
//        self.microphone = nil;
//        _fftBufIndex = 0;
//        lastamp = 0.8;
//        
//        self.microphone = [EZMicrophone microphoneWithDelegate:self];
//        [self.microphone startFetchingAudio];

    } else {
        //self.myTextField.text = @"The Switch is On";
        [[audiohandling sharedManager] changeAudioOutput];
        [self configureAVAudioSession:@"speaker"];
//        lastamp = 0.8;
//        [self.microphone stopFetchingAudio];
//        self.microphone = nil;
//        _fftBufIndex = 0;
//        _samplesRemaining = 44100;
//        _isFFTSetup = NO;
//        self.microphone = [EZMicrophone microphoneWithDelegate:self];
//        [self.microphone startFetchingAudio];

    }
    
}

- (IBAction)sliderChanged:(UISlider *)slider
{
    NSLog(@"slider changed");
    
	frequency = slider.value;
	frequencyLabel.text = [NSString stringWithFormat:@"%4.1f Hz", frequency];
    // Send the frequency value through to the audiohandler.
    NSNumber *freq = [[NSNumber alloc] initWithDouble:frequency];
    [[audiohandling sharedManager] setfrequency:freq];
}

- (IBAction)gapchanged:(UISlider *)slider {
    // NSLog(@"slider changed");
    modgap = slider.value;
    modlabel.text = [NSString stringWithFormat:@"%4.1f *1024 samps", modgap];
    // Send the frequency value through to the audiohandler.
    NSNumber *thismodgap = [[NSNumber alloc] initWithDouble:modgap];
    [[audiohandling sharedManager] setmodgap:thismodgap];

}


- (IBAction)togglePlay:(UIButton *)selectedButton
{
    NSLog(@"toggle play");
    // is this updating correctly? 
    isdatawriting = [[audiohandling sharedManager] isdatawriting];
    // something is around the wrong way here.
	if (isdatawriting)
	{
        NSLog(@"recording data");
        [[audiohandling sharedManager] toggleStop] ;
        playbuttontext = [[audiohandling sharedManager] getplaybuttontext];
        [selectedButton setTitle:NSLocalizedString(@"Start", nil) forState:0];
//        [UITimer invalidate];
//        [writeThread cancel];
	}
	else
	{
        NSLog(@"not recording data");
        [[audiohandling sharedManager] toggleStart] ;
        playbuttontext = [[audiohandling sharedManager] getplaybuttontext];
        [selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        NSLog(@"Restarting UI Thread view did appear");
        //


	}
}


- (IBAction)toggleDelete:(UIButton *)selectedButton {
    
    if (isdatawriting)
	{
        NSLog(@"only deletes when not saving");
        // if this is triggered it means that the write thread never stopped.
        [[audiohandling sharedManager] toggleStop] ;
        [[audiohandling sharedManager] deletealltabledata] ;
    }
    else {
        NSLog(@"clear the table");
        // this should call this from audiohandling...
        [[audiohandling sharedManager] deletealltabledata] ;
        NSLog(@"clear the table");
    }
}

- (IBAction)toggleExport:(UIButton *)selectedButton {
    
    if (isdatawriting)
    {
        NSLog(@"only exports when not saving");
    }
    else {
        NSLog(@"sending the data");
        //[[audiohandling sharedManager] sendthedata];
        [self senddataemail];
        NSLog(@"sending the data");
    }
}

- (void)stop
{
    isdatawriting = [[audiohandling sharedManager] isdatawriting];
	if (isdatawriting)
	{
        [[audiohandling sharedManager] toggleStop];
	}
    
}

- (void)viewDidUnload {

}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    // Remove the mail view
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void) senddataemail {
    
    if ([MFMailComposeViewController canSendMail])
    {
        // make the csv
        //
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"Data"];
        
        NSArray *toRecipients = nil; //[NSArray arrayWithObjects:@"info@ibisbiofeedback.com", nil];
        [mailer setToRecipients:toRecipients];
        
        //NSError* error = nil;
        NSString *emailBody = @" ";
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *txtPath = [documentsDirectory stringByAppendingPathComponent:@"Bioimpedance.sqlite"];
        NSData *Data = [NSData dataWithContentsOfFile:txtPath];
        
        //
        //
        //[[audiohandling sharedManager] makecsv];
        
        
        // Get the path of the database and attach to the email.
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString *txtPath = [documentsDirectory stringByAppendingPathComponent:@"data.csv"];
//        NSData *Data = [NSData dataWithContentsOfFile:txtPath];
//        NSData *Data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"data.csv", docsDir]];
 //       NSLog(@"%@", Data);
        
        if (Data.length) {
            [mailer addAttachmentData:Data mimeType:@"application/x-sqlite3" fileName:@"Bioimpedance.sqlite"];
            //[mailer addAttachmentData:Data mimeType:@"text/csv" fileName:@"data.csv"];
        }
        else {
            emailBody = @"The data is an sqlite database. You can easily read it with many programs ";
        }
        [mailer setMessageBody:emailBody isHTML:NO];
        [self presentModalViewController:mailer animated:YES];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
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
//
//
// this happens once per fft frame.
-(void)updateFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
    
    //NSLog(@"bufferSize %f",bufferSize); // 1024
    
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
    // NSLog(@"Fs %f",Fs);
    float binspacing = (float)(Fs)/(float)bufferSize;
    float tiny = 0.1; //1.0; // was 0.1
    float mavamp  = 0.01;
    float f = 0.0;
    //float currentphase    = 0.0f;
    float currentmagnitude  = 0.0f;
    int ivalue =0;
    int cc = 0;
    float scale = 1.0;
    
    //NSLog(@"nOver2 %i",nOver2);
    
    for(int i=0; i<nOver2; i++) {
        // Calculate the magnitude
        float magn = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
        // Bind the value to be less than 1.0 to fit in the graph
        amp[i] = [EZAudio MAP:magn leftMin:0.0 leftMax:maxMag rightMin:0.0 rightMax:1.0];
        
        f = i*binspacing;
        if ( (f < frequency+binspacing) && (f > frequency-binspacing)) {
            //
            // NSLog(@"here");
            cc = cc+1;
            // It should only get in here once.
            if (cc == 1) {
                //
                // i wonder how many times in a loop it gets in here.
                // remember the i value.
                //
                ivalue = i;
                // currentmagnitude = log10(amp[ivalue]);
                //currentmagnitude = log10(amp[ivalue]);
                currentmagnitude = magn; //amp[ivalue];
                //
                // why does dmag equal nan sometimes.
                // currentmagnitude = -20*log10(sqrt(amp[ivalue]));
                // currentmagnitude = sqrt(amp[ivalue]);
                //
                //mavamp      = (((1.0 - tiny)*lastamp) + tiny*currentmagnitude);
                //lastamp     = mavamp;
                //dmagnitude =  mavamp;
                //
                dmagnitude = currentmagnitude;
                //
                if (scalefactor != abs(INFINITY)) {
                    //dmagnitude = mavamp/scalefactor;
                    dmagnitude = currentmagnitude/scalefactor;
                }
                //
                // save for route switch nan's /
                if (isnan(dmagnitude)) {
                    NSLog(@"resetting");
                    NSLog(@"amp %f",amp[2]);
                    dmagnitude = 0.1;
                    mavamp = 0.01;
                    lastamp = 0.01;
                
                }
                //
                // dmagnitude = currentmagnitude;
                //NSLog(@"dmag %f",dmagnitude);
            }
            // NSLog(@"mavamp %f %f %f",magn,dmagnitude,scalefactor);
        }
        
    }
    //
    // NSLog(@"f m:%f,%f",frequency,dmagnitude);
    //
    NSString *magtext;
    // The unscaled version.
    magtext   = [NSString stringWithFormat:@"%.2f",dmagnitude];
    mag.text   = magtext;
    //
    // copy from one array to the next.
    //dlastfftamps = [[NSMutableArray alloc] initWithArray:lastfftamps copyItems:YES];
    
    // update the magnitude plot as well.
    float magvalue = dmagnitude;
    [self.magnitudePlot updateBuffer:&magvalue withBufferSize:1.0];
    //
    // Update the frequency domain plot
    [self.audioPlotFreq updateBuffer:amp
                      withBufferSize:nOver2];
    
}
//
//#pragma mark - EZMicrophoneDelegate
-(void)    microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Update time domain plot
        if (rawscalefactor != 1.0) {

            for (int i =0; i<bufferSize;i++) {
                buffer[0][i] = buffer[0][i]/rawscalefactor;
             }
              [self.audioPlot updateBuffer:buffer[0]
                              withBufferSize:bufferSize];

            }
        else {
            [self.audioPlot updateBuffer:buffer[0]
                          withBufferSize:bufferSize];
        }
        //
        // Setup the FFT if it's not already setup
        if( !_isFFTSetup ){
            NSLog(@"refreshFFT");
            [self createFFTWithBufferSize:bufferSize withAudioData:buffer[0]];
            _isFFTSetup = YES;
        }
        
        // Get the FFT data
        [self updateFFTWithBufferSize:bufferSize withAudioData:buffer[0]];
        
    });
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"You entered %@",graphscale.text);
    
    [graphscale resignFirstResponder];
    
    [rawscale resignFirstResponder];
    
    NSLog(@"frequency entered");
    [frequencytextfield resignFirstResponder];
    
    return NO;
}

- (IBAction)rawscaledentered:(id)sender {
    NSLog(@"%@",rawscale.text);
    CGFloat strFloat = (CGFloat)[rawscale.text floatValue];
    rawscalefactor = strFloat;
}

- (IBAction)scaleentered:(id)sender {
    
    NSLog(@"%@",graphscale.text);
    CGFloat strFloat = (CGFloat)[graphscale.text floatValue];
    scalefactor = strFloat;
}
//
//
- (IBAction)frequencyvaluentered:(id)sender {
    //
    NSLog(@"%@",frequencytextfield.text);
    CGFloat strFloat = (CGFloat)[frequencytextfield.text floatValue];
    // change it.
    frequency = strFloat;
    frequencyLabel.text = [NSString stringWithFormat:@"%4.1f Hz", frequency];
}


- (IBAction)audiosave:(id)sender {
    
    BOOL recordingtrue = [[audiohandling sharedManager] isRecording];
    if (!recordingtrue )
    {
        [[audiohandling sharedManager] recordingOn];
        [recordaudio setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        toneon = 0;
    }
    else
    {
        NSLog(@"start recording");
        [[audiohandling sharedManager] recordingStop];
        [recordaudio setTitle:NSLocalizedString(@"Record", nil) forState:0];
    }
    
}

- (IBAction)audiodelete:(id)sender {
    
    // delete all wave files.
    NSLog(@"delete the stored file");
    [[audiohandling sharedManager] deletewavefile];
    
}

- (IBAction)playback:(id)sender {
    
    BOOL playingtrue = [[audiohandling sharedManager] isPlaying];
    if (!playingtrue )
    {
        [[audiohandling sharedManager] playOn];
        [audioplayback setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        toneon = 0;
    }
    else
    {
        [[audiohandling sharedManager] playStop];
        [audioplayback setTitle:NSLocalizedString(@"PlayBack", nil) forState:0];
    }

}

- (IBAction)signaltoggle:(UIButton *)selectedButton {
    
    // This button should change name to signal stop, after it is pressed. So it is a toggle switch.
    toneon = [[audiohandling sharedManager] gettoneon];

    if (toneon)
    {
        NSLog(@"turn the signal off");
        [[audiohandling sharedManager] toggletoneStop] ;
        //playbuttontext = [[audiohandling sharedManager] getplaybuttontext];
        //NSLog(@"%@",playbuttontext);
        [selectedButton setTitle:NSLocalizedString(@"Start", nil) forState:0];
        toneon = 0;
    }
    else
    {
        NSLog(@"turn the signal on");
        [[audiohandling sharedManager] toggletoneStart] ;
        //playbuttontext = [[audiohandling sharedManager] getplaybuttontext];
        [selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        toneon = 1;
    }
    
}

// Select the type of signal sine wave is the default type.
- (IBAction)sinewaveselect:(id)sender {
    [[audiohandling sharedManager] moddisabled];
    [[audiohandling sharedManager] rampdisabled];


}

- (IBAction)sweepselect:(id)sender {
    [[audiohandling sharedManager] rampenabled];
}

- (IBAction)modgapselect:(id)sender {
    [[audiohandling sharedManager] rampdisabled];
    [[audiohandling sharedManager] modenabled];
    
}


- (IBAction)maggraphsliderslid:(id)sender {
    
    // NSLog(@"slider slid");
    scalefactor = maggraphscaleslider.value;
    
}

- (void)centerScrollViewContents {
    
    CGSize boundsSize = self.scrollview.bounds.size;
    CGRect contentsFrame = self.magnitudePlot.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    self.magnitudePlot.frame = contentsFrame;
}
//
//
// Zoom works, need panning.
// I need to be able to pan it about. so it doesn't shrink into the corner.
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.magnitudePlot;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents];
}

- (IBAction)calibratepressed:(id)sender {
    NSLog(@"c button pressed");
    // we need to have smaller increments.
    [[audiohandling sharedManager] calibrationstarted];
    NSLog(@" Calibrate start! ");
}



- (IBAction)exportpressed:(id)sender {
    
    NSLog(@"e button pressed");
    //
    if (toneon)
    {
        [self togglePlay:playButton];
    }
    NSLog(@"sending the data");
    [self senddataemail];
//    NSLog(@"sending the data");
//    [self togglePlay:playButton];
// 
}

@end
