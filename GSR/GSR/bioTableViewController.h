//
//  bioTableViewController.h
//  BioimpedanceSpectrometer
//
//  Created by Jean Rintoul on 8/24/14.
//  Copyright (c) 2014 ibisbiofeedback. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EZAudio.h"
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import <MessageUI/MessageUI.h>

@interface bioTableViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource,EZMicrophoneDelegate,MFMailComposeViewControllerDelegate,UITextFieldDelegate,UIScrollViewDelegate>
{

}

/**
 Use a OpenGL based plot to visualize the data coming in
 */

@property (weak, nonatomic) IBOutlet MPVolumeView *mpvolume;

@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (weak, nonatomic) IBOutlet EZAudioPlotGL *magnitudePlot;
@property (weak, nonatomic) IBOutlet EZAudioPlot *audioPlotFreq;
@property (nonatomic,strong) EZMicrophone *microphone;
@property (nonatomic,strong) EZRecorder *recorder;
@property (nonatomic,strong) EZOutput *output;
@property (strong,nonatomic) MPVolumeView *volumeView;
@property (strong, nonatomic) IBOutlet UIImageView *volumeiconimage;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
- (IBAction)togglePlay:(UIButton *)selectedButton;
- (IBAction)toggleDelete:(UIButton *)selectedButton;
- (IBAction)toggleExport:(UIButton *)selectedButton;
@property (weak, nonatomic) IBOutlet UILabel *inportlabel;
@property (weak, nonatomic) IBOutlet UILabel *outportlabel;

// start
@property (weak, nonatomic) IBOutlet UIButton *recordaudio;
@property (weak, nonatomic) IBOutlet UIButton *deleteaudio;

@property (weak, nonatomic) IBOutlet UIButton *startsignal;
- (IBAction)audiosave:(id)sender;
- (IBAction)audiodelete:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *audioplayback;

- (IBAction)playback:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *connectiontextfield;

- (IBAction)signaltoggle:(UIButton *)selectedButton; 

//
// signal selection
//

- (IBAction)sinewaveselect:(id)sender;
- (IBAction)sweepselect:(id)sender;
- (IBAction)modgapselect:(id)sender;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;



@property (weak, nonatomic) IBOutlet UIButton *gapbutton;
@property (weak, nonatomic) IBOutlet UIButton *sinebutton;
@property (weak, nonatomic) IBOutlet UIButton *rampbutton;
@property (weak, nonatomic) IBOutlet UIButton *samplerate;
@property (weak, nonatomic) IBOutlet UISlider *maggraphscaleslider;
- (IBAction)maggraphsliderslid:(id)sender;
//
@property (weak, nonatomic) IBOutlet UILabel *modlabel;
//
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
//@property (weak, nonatomic) IBOutlet UIButton *calibratebutton;
@property (weak, nonatomic) IBOutlet UILabel *phase;
@property (weak, nonatomic) IBOutlet UILabel *mag;
@property (weak, nonatomic) IBOutlet UISlider *ampslid;
@property (weak, nonatomic) IBOutlet UITextField *graphscale;
@property (weak, nonatomic) IBOutlet UITextField *rawscale;
@property (weak, nonatomic) IBOutlet UILabel *volumedisplaylabel;
@property (weak, nonatomic) IBOutlet UISwitch *blueswitch;

- (IBAction)blueswitchaction:(id)sender;
- (IBAction)sliderChanged:(UISlider *)frequencySlider;
- (IBAction)gapchanged:(UISlider *)gapslider;

@property (weak, nonatomic) IBOutlet UISlider *gapslider;
@property (weak, nonatomic) IBOutlet UITextField *frequencytextfield;
@property (weak, nonatomic) IBOutlet UILabel *filesize;

- (IBAction)ampslider:(UISlider *)sender;
- (IBAction)rawscaledentered:(id)sender;
- (IBAction)scaleentered:(id)sender;
- (IBAction)frequencyvaluentered:(id)sender;
- (void)senddataemail;
- (void)stop;

@property (weak, nonatomic) IBOutlet UIButton *calibratebutton;
- (IBAction)calibratepressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *exportbutton;
- (IBAction)exportpressed:(id)sender;


@end
