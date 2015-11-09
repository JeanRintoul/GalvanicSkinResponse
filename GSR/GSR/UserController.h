//
//  UserController.h
//  Biometer
//
//  Created by Jean Rintoul on 4/11/15.
//  Copyright (c) 2015 ibisbiofeedback. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSRangeGauge.h"


@interface UserController : UIViewController <UIAlertViewDelegate>

@property (strong, nonatomic) UIAlertView * alert;
@property (strong, nonatomic) UIWindow *window;

@property (weak, nonatomic) IBOutlet UILabel *bladderlevel;
@property (nonatomic) MSRangeGauge *exclusiveGauge;
@property (weak, nonatomic) IBOutlet UIButton *emptybutton;
@property (weak, nonatomic) IBOutlet UIButton *fullbutton;
@property (weak, nonatomic) IBOutlet UIButton *calibratebutton;

- (IBAction)empt:(id)sender;
- (IBAction)full:(id)sender;
- (IBAction)calibrate:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *fullLabel;
@property (weak, nonatomic) IBOutlet UILabel *emptyLabel;

@property (weak, nonatomic) IBOutlet UISwitch *alertswitch;

- (IBAction)alertswitched:(id)sender;



@end
