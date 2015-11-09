//
//  UserController.m
//  Biometer
//
//  Created by Jean Rintoul on 4/11/15.
//  Copyright (c) 2015 ibisbiofeedback. All rights reserved.
//
//#import "MSSimpleGauge.h"
#import "UserController.h"
#import "SFGaugeView.h"
#import "audiohandling.h"

//#define kBlueColor [UIColor colorWithRed:0.5 green:0.915 blue:1.0 alpha:1.0]
#define kBlueColor [UIColor lightGrayColor] //[UIColor colorWithRed:0.5 green:0.815 blue:1.0 alpha:1.0]
#define kGrayColor [UIColor redColor] // [UIColor colorWithRed:0.396 green:0.396 blue:0.396 alpha:1.0]
#define kGlassColor [UIColor grayColor ] //[UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1.0]

@interface UserController ()


@end

@implementation UserController {
    NSTimer *UITimer;
    NSThread* uiThread;
    float maxvalue;
    float minvalue;
    float gaugemaxvalue;
    float gaugeminvalue;
    float gvalue;
    int n;
    BOOL switchstate;
    
    
}

@synthesize bladderlevel;
@synthesize emptybutton;
@synthesize fullbutton;
@synthesize calibratebutton;
@synthesize fullLabel;
@synthesize emptyLabel;
@synthesize alert;
@synthesize alertswitch;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    bladderlevel.text = @"33%";
    
    [[UIDevice currentDevice] setValue:
     [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                forKey:@"orientation"];

    emptybutton.layer.cornerRadius = 10;
    emptybutton.layer.borderWidth  = 1.0f;
    emptybutton.layer.borderColor  = kGrayColor.CGColor;
    [emptybutton setTitleColor:kGrayColor forState:UIControlStateNormal];
    emptybutton.layer.backgroundColor = kBlueColor.CGColor;
    [emptybutton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [emptybutton setTintColor:kGrayColor];
    
    fullbutton.layer.cornerRadius = 10;
    fullbutton.layer.borderWidth  = 1.0f;
    fullbutton.layer.borderColor  = kGrayColor.CGColor;
    [fullbutton setTitleColor:kGrayColor forState:UIControlStateNormal];
    fullbutton.layer.backgroundColor = kBlueColor.CGColor;
    [fullbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [fullbutton setTintColor:kBlueColor];
    
    
    calibratebutton.layer.cornerRadius = 10;
    calibratebutton.layer.borderWidth  = 1.0f;
    calibratebutton.layer.borderColor  = kGrayColor.CGColor;
    [calibratebutton setTitleColor:kGrayColor forState:UIControlStateNormal];
    calibratebutton.layer.backgroundColor = kBlueColor.CGColor;
    [calibratebutton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [calibratebutton setTintColor:kBlueColor];
    
    self.exclusiveGauge = [[MSRangeGauge alloc] initWithFrame:CGRectMake(20, 120, 300, 200)];
    self.exclusiveGauge.minValue = 0;
    self.exclusiveGauge.maxValue = 100;
    self.exclusiveGauge.upperRangeValue = 80;
    self.exclusiveGauge.lowerRangeValue = 20;
    self.exclusiveGauge.value = 30;
    
    self.exclusiveGauge.backgroundArcFillColor = [UIColor redColor]; //[UIColor colorWithRed:.41 green:.76 blue:.73 alpha:1];
    self.exclusiveGauge.backgroundArcStrokeColor = [UIColor redColor]; //[UIColor colorWithRed:.41 green:.76 blue:.73 alpha:1];
    self.exclusiveGauge.rangeFillColor = [UIColor colorWithRed:.82 green:.82 blue:.82 alpha:1];
    [self.view addSubview:self.exclusiveGauge];
    //
    // Now make a thread between 0-1.
    //
    [self.view bringSubviewToFront:emptyLabel];
    [self.view bringSubviewToFront:fullLabel];
    //
    // Get the stored data before the view loads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    gaugeminvalue = [[defaults objectForKey:@"minvalue"] floatValue];
    gaugemaxvalue = [[defaults objectForKey:@"maxvalue"] floatValue];
    
    NSLog(@"gaugeminvalue %f",gaugeminvalue);
    NSLog(@"gaugemaxvalue %f",gaugemaxvalue);
    
    if (gaugemaxvalue == 0 ) {
        gaugemaxvalue = 10.0;
    }
    //
    n = 0;
    //
    minvalue = 0.0;
    maxvalue = 1.0;
    
    [uiThread cancel];
    uiThread = nil;
    uiThread = [[NSThread alloc] initWithTarget:self
                                       selector:@selector(userithread)
                                         object:nil];
    [uiThread start];  // Actually create the thread
    
    
    switchstate = NO;
}

-(void)userithread
{
    @autoreleasepool
    {
        NSRunLoop *TimerRunLoop = [NSRunLoop currentRunLoop];
        UITimer =  [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(uiMethod) userInfo:nil repeats:YES];
        [TimerRunLoop run];
    }
    
}

- (void)uiMethod {
    
    float currentvalue          = fabs([[audiohandling sharedManager] getdbValue]);
    NSLog(@"%f,%f,%f",currentvalue,gaugeminvalue,gaugemaxvalue);
    float gaugevalue            = (currentvalue - gaugeminvalue)/fabs(gaugemaxvalue - gaugeminvalue);
    //
//    n = n + 10;
//    float d = n;
//    NSLog(@"%f",d);
//    gvalue      = gvalue + d/1000;
//    if (n == 2)  {
//        n = 0;
//    }
//    gaugevalue  = gvalue;
//    //
    // Set limits.
    // NSLog(@"%f",gaugevalue);
    //
    if (gaugevalue < 0) {
        gaugevalue = 0.0;
    }
    if (gaugevalue > 1) {
        gaugevalue = 1.0;
    }
    
    NSString *btext   = [NSString stringWithFormat:@"%.0f",100*gaugevalue];
    bladderlevel.text = btext;
    self.exclusiveGauge.value   = 100*gaugevalue;
    // 
    // Alert should only be activated
    //
    // Alert Code.
    if (switchstate) {
    //
    //
        if (100*gaugevalue > 80) {
            
            if (!self.alert.visible) {
                
                NSString *msg= [NSString stringWithFormat:@"Lie Detected!"];
                
                self.alert = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                self.alert.alertViewStyle = UIAlertViewStyleDefault;
                NSLog(@"showing alert");
                [self.alert show];
            }
            return;
            }

    }  // end of if switch is on.
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.alertswitch setOn:NO animated:YES];
    switchstate = NO;
}

- (void)dealloc
{
    [alert dismissWithClickedButtonIndex:0 animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)empt:(id)sender {
    // save min value into temporary memory.
    //get current magnitude, save it locally.
    minvalue = fabs([[audiohandling sharedManager] getdbValue]);
    NSLog(@"empty %f",minvalue);
    //minvalue = 0;
}

- (IBAction)full:(id)sender {
    //
    maxvalue = fabs([[audiohandling sharedManager] getdbValue]);
    NSLog(@"full %f", maxvalue);
    //maxvalue = 1.0;
}

- (IBAction)calibrate:(id)sender {
    //
    // Save min and max into the user defaults so it's remembered when the app shuts down and restarts.
    //
    NSLog(@"min,max %f,%f",minvalue,maxvalue);
    // minvalue = fullvalue;
    // maxvalue = emptyvalue;
    //[NSNumber numberWithFloat: myfloatvalue];
    NSNumber *min = [NSNumber numberWithFloat:minvalue];
    NSNumber *max = [NSNumber numberWithFloat:maxvalue];
    // Store the data
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:min forKey:@"minvalue"];
    [defaults setObject:max forKey:@"maxvalue"];
    [defaults synchronize];
    // 
    gaugeminvalue = minvalue;
    gaugemaxvalue = maxvalue;
    // NSLog(@"gauge mins %f,%f",gaugemaxvalue);
    NSLog(@"%f,%f",gaugeminvalue,gaugemaxvalue);
}
- (IBAction)alertswitched:(id)sender {
    
    
    if(alertswitch.on) {
        // lights on
        switchstate = YES;
    }
    
    else {
        // lights off
        switchstate = NO;
    }
    
}


@end
