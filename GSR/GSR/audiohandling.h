//
// 
//
//
#import <Foundation/Foundation.h>
//#import <MediaPlayer/MediaPlayer.h>
// Import EZAudio header
#import "EZAudio.h"

#import <Accelerate/Accelerate.h>
// Import AVFoundation to play the file (will save EZAudioFile and EZOutput for separate example)
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

// By default this will record a file to the application's documents directory (within the application's sandbox)
//#define kAudioFilePath @"audiofile.wav"
#define kAudioFilePath @"audiofile.m4a"
#define regularAudioFilePath @"audiofile.wave"

@interface audiohandling : NSObject <EZMicrophoneDelegate,AVAudioRecorderDelegate, AVAudioPlayerDelegate, EZAudioFileDelegate, EZOutputDataSource,MFMailComposeViewControllerDelegate>
{
    AudioComponentInstance toneUnit;
    @public
        double frequency;
        double sampleRate;
        double theta;
        double calibrateamplitude;
        double buffercount;
        double modgap;
    
}
+ (audiohandling *) sharedManager;
//
//
- (void)stop;
- (void)rampenabled;
- (void)rampdisabled;
- (void)modenabled;
- (void)moddisabled;

- (float)logSampleRate;

//
//
@property (nonatomic, retain) NSDate *calibrationmarker;
/**
 Use a OpenGL based plot to visualize the data coming in
 */
@property (atomic,strong) AVAudioSession    *session;
@property (atomic,strong) AVAudioPlayer     *audioplayer;
@property (nonatomic,strong) EZMicrophone *microphone;
@property (nonatomic,strong) EZRecorder *recorder;
@property (nonatomic,strong) EZOutput *output;

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 A flag indicating whether we are recording or not
 */
@property (nonatomic,assign) BOOL isRecording;
@property (nonatomic,assign) BOOL isPlaying;
@property (nonatomic,assign) BOOL audiojackconnected;
- (void) recordingOn;
- (void) recordingStop;
- (void) playOn;
- (void) playStop;
//
//
- (void)setUpCoreDataStack;
- (void)writingthread;
- (void)writeMethod;
- (void) makecsv;
- (BOOL)clearEntity:(NSString *)entity;
- (BOOL)saveData;
- (float)getdbValue;
- (float)getvolume;
- (void)setfrequency: (NSNumber *)freq;
- (void)settonestop;
- (int) gettoneon;
- (void) deletealltabledata; 
- (NSString *) getplaybuttontext;
- (void)setamplitude:(NSNumber *)val;
- (void)setmodgap: (NSNumber *)modg;
- (NSString *) getoutport;
- (NSString *) getinport;
- (NSMutableArray *) getmags; 
- (NSMutableArray *) gettimes;
- (void) toggleStop;
- (void) toggleStart;
- (void) toggletoneStop;
- (void) toggletoneStart;
- (BOOL) isdatawriting;
- (void) initialize;
- (void)changeAudioOutput;
// wave file recordings.
-(void) deletewavefile;
- (void) calibrationstarted;
- (void) calculatecalibration;


- (NSString *) getfilesize;
- (NSString *) returncalibrationtitle;

@end
