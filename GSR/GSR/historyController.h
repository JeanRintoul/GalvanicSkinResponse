//
//  historyController.h
//  BioimpedanceSpectrometer
//
//  Created by Jean Rintoul on 8/24/14.
//  Copyright (c) 2014 ibisbiofeedback. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface historyController : UIViewController <CPTPlotDataSource,UITextViewDelegate,UIAlertViewDelegate>

@property (strong, nonatomic) UIAlertView * alert;

@property (nonatomic, strong) CPTScatterPlot *fftPlot;
@property (nonatomic, strong) CPTGraph *graph;
@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTTheme *selectedTheme;

-(void)initPlot;
-(void)initPlotLandscape;
-(void)configureGraph;
-(void)configurePlots;
-(void)configureAxes;
-(void)configureHost2;

@property (weak, nonatomic) IBOutlet UIView *dataview;
@property (retain, nonatomic) NSMutableArray *mags;
@property (retain, nonatomic) NSMutableArray *times;
//
//
//@property (strong, nonatomic) UIAlertView * alert;
//@property (strong, nonatomic) UIWindow *window;


@end
