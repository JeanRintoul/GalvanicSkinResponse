//
//  historyController.m
//  BioimpedanceSpectrometer
//
//  Created by Jean Rintoul on 8/24/14.
//  Copyright (c) 2014 ibisbiofeedback. All rights reserved.
//

#import "historyController.h"
#import "Data.h"
#import "audiohandling.h"

#define kBlueColor [UIColor colorWithRed:0.3888 green:0.815 blue:0.976 alpha:1.0]
#define kGrayColor [UIColor colorWithRed:0.396 green:0.396 blue:0.396 alpha:1.0]
#define kGlassColor [UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1.0]

static NSString *const kPlotIdentifier = @"historyplot";

@interface historyController ()

@end

@implementation historyController

@synthesize graph;
@synthesize hostView = hostView_;
@synthesize selectedTheme = selectedTheme_;
@synthesize fftPlot;
@synthesize dataview;
@synthesize alert;
@synthesize mags;
@synthesize times;

#pragma mark AlertView Delegate
- (void)alertView:(UIAlertView *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex{
    // 
    // This segue backsegue.
    [self performSegueWithIdentifier:@"bb" sender:self];
    NSLog(@"alert button on chart scene pressed");
}


-(void)viewWillAppear:(BOOL)animated {

    //    NSLog(@"viewDidAppear");
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    // We can only get the data, when we are not writing to core data.
    // so, check if write thread is running first.
    // if it isn't running, we can load the graph.
    //
    NSLog(@"loading");
    BOOL writethread = [[audiohandling sharedManager] isdatawriting];
    
    if (writethread) {
        NSLog(@"write thread is executing cannot show history!");
        if (!self.alert.visible) {
            self.alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Can't plot while saving data!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alert.alertViewStyle = UIAlertViewStyleDefault;
            [self.alert show];
        }
        
    }
    else {
        NSLog(@"write thread is not on");
        // 
        mags  = [[audiohandling sharedManager] getmags];
        times = [[audiohandling sharedManager] gettimes];
        
//        NSLog(@"%@",times);
//        NSLog(@"%@",mags);
        
         NSLog(@"%d",[times count]);
         NSLog(@"%d",[mags count]);
        //
        UIDeviceOrientation Orientation=[[UIDevice currentDevice]orientation];
        if(Orientation==UIDeviceOrientationLandscapeLeft || Orientation==UIDeviceOrientationLandscapeRight)
        {
            [self initPlotLandscape];
            NSLog(@"Landscape");
        }
        else if(Orientation==UIDeviceOrientationPortrait)
        {
            [self initPlot];
            NSLog(@"Portrait");
        }
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// Graphing code.
#pragma mark - Chart behavior

-(void)initPlot {
    //self.hostView.allowPinchScaling = NO;
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
    
}

-(void)initPlotLandscape {
    //self.hostView.allowPinchScaling = NO;
    [self configureHost2];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
    
}


-(void)configureHost {
    
    //CGRect parentRect = CGRectMake(0, 100, 320, 240);
    CGRect parentRect = CGRectMake(0, 0, 320, 500);
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:parentRect];
    self.hostView.allowPinchScaling = YES;
    [self.hostView setCollapsesLayers:NO];

    [dataview addSubview:self.hostView];
    
}

-(void)configureHost2 {
    
    //CGRect parentRect = CGRectMake(0, 100, 320, 240);
    CGRect parentRect = CGRectMake(0, 0, 600, 260);
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:parentRect];
    self.hostView.allowPinchScaling = YES;
    [self.hostView setCollapsesLayers:NO];
    
    [dataview addSubview:self.hostView];
    
}


#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    
    // NSLog(@"mags count here %d", [mags count]);
    return [mags count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    
    NSInteger valueCount = [mags count];
    //NSInteger valueCount = [samps count];
    //NSLog(@"val count: %d",valueCount);
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if (index < valueCount) {
                NSNumber *n = [NSNumber numberWithInt:index];
                return n;
                //return [times objectAtIndex:index];
                // samples axis.
                //return [NSNumber numberWithUnsignedInteger:index];
            }
            break;
            
        case CPTScatterPlotFieldY:
            if (index < valueCount) {
                return [mags objectAtIndex:index];
            }
            break;
    }
    return [NSDecimalNumber zero];
}

-(void)configureGraph {
    
    // 1 - Create the graph
    graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    //[graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    self.hostView.hostedGraph = graph;
    
    // 2 - Set graph title
    NSString *title = @"";
    graph.title = title;
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor blackColor];
    graph.plotAreaFrame.borderLineStyle = nil;
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    //graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    graph.titleDisplacement = CGPointMake(0.0f, 20.0f);
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:30.0f];
    [graph.plotAreaFrame setPaddingBottom:30.0f];
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    
}

-(void)configurePlots {
    
    graph = self.hostView.hostedGraph;
    [self.hostView setCollapsesLayers:NO];
    
    //[graph setCollapsesLayers:NO];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    
    // 2 - Create the plot
    fftPlot = [[CPTScatterPlot alloc] init];
    fftPlot.dataSource = self;
    fftPlot.identifier = kPlotIdentifier;
    //UIColor *clrbackground  = [UIColor colorWithRed:0.3888 green:0.815 blue:0.976 alpha:1.0];
    //CPTColor *fftColor = clrbackground;
    CPTColor *color = [CPTColor cyanColor];
    color = [[CPTColor alloc] initWithComponentRed:(0x00&0xff)/255.0 green:(0x95&0xFF)/255.0 blue:(0xD2&0xFF)/255.0   alpha:1.0];
    
    CPTColor *fftColor = color;
    // CPTColor *fftColor = [CPTColor redColor];
    [graph addPlot:fftPlot toPlotSpace:plotSpace];
    
    // 3 - Set up plot space
    [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:fftPlot, nil]];
    
    CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];
    
    plotSpace.xRange = xRange;
    CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
    [yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];
    plotSpace.yRange = yRange;
    
    // 4 - Create styles and symbols
    CPTMutableLineStyle *fftLineStyle = [fftPlot.dataLineStyle mutableCopy];
    fftLineStyle.lineWidth = 2.5;
    fftLineStyle.lineColor = fftColor;
    fftPlot.dataLineStyle = fftLineStyle;
    CPTMutableLineStyle *fftSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    fftSymbolLineStyle.lineColor = fftColor;
    CPTPlotSymbol *fftSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    fftSymbol.fill = [CPTFill fillWithColor:fftColor];
    fftSymbol.lineStyle = fftSymbolLineStyle;
    fftSymbol.size = CGSizeMake(1.0f, 1.0f);
    fftPlot.plotSymbol = fftSymbol;
    
}


-(void)configureAxes {
    
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor blackColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor whiteColor];
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor blackColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 11.0f;
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor blackColor];
    tickLineStyle.lineWidth = 2.0f;
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor blackColor];
    tickLineStyle.lineWidth = 1.0f;
    
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    // 3 - Configure x-axis
    CPTAxis *x = axisSet.xAxis;
    x.title = @"Time(seconds)";
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = -40.0f;
    x.axisLineStyle = axisLineStyle;
    x.majorGridLineStyle = gridLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.labelOffset = 16.0f;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.minorTickLength = 2.0f;
    x.tickDirection = CPTSignPositive;
    
    NSInteger majorIncrement = 500;
    NSInteger minorIncrement = 1;
    //CGFloat xMax = 22000.0;  // should determine dynamically based on max price
    CGFloat xMax = [times count]; //5000.0;
    
    //    NSInteger majorIncrement = 100;
    //    NSInteger minorIncrement = 50;
    //    //CGFloat xMax = 22000.0;  // should determine dynamically based on max price
    //    CGFloat xMax = 500.0;
    
    NSMutableSet *xLabels = [NSMutableSet set];
    NSMutableSet *xMajorLocations = [NSMutableSet set];
    NSMutableSet *xMinorLocations = [NSMutableSet set];
    for (NSInteger j = minorIncrement; j <= xMax; j += minorIncrement) {
        NSUInteger mod = j % majorIncrement;
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", j] textStyle:x.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger(j);
            label.tickLocation = location;
            label.offset = -x.majorTickLength - x.labelOffset;
            if (label) {
                [xLabels addObject:label];
            }
            [xMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        } else {
            [xMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    x.axisLabels = xLabels;
    x.majorTickLocations = xMajorLocations;
    x.minorTickLocations = xMinorLocations;
    
    // 4 - Configure y-axis
    CPTAxis *y = axisSet.yAxis;
    y.title = @"magnitude";
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = -40.0f;
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = 16.0f;
    y.majorTickLineStyle = axisLineStyle;
    y.majorTickLength = 4.0f;
    y.minorTickLength = 2.0f;
    y.tickDirection = CPTSignPositive;
    //
    NSNumber* max = [mags valueForKeyPath:@"@max.self"];
    // ymax is determined dynamically based on max snore history
    NSInteger majoryIncrement = [max floatValue]/10.0f; // 10;
    NSInteger minoryIncrement = 1;
    CGFloat yMax = [max floatValue] + 20.0f; // 100.0f;
    //
    if (majoryIncrement == 0) {
        majoryIncrement = 1;
    }
    //CGFloat yMin = 20.0f;
    // Then we should figure out how to subtract the mean before doing the FFT.
    //
    // Then we should figure out how to normalize and save the resulting audio signal to file, ready for playback.
    //
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    for (NSInteger k = minoryIncrement; k <= yMax; k += minoryIncrement) {
        NSUInteger mod = k % majoryIncrement;
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", k] textStyle:y.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger(k);
            label.tickLocation = location;
            label.offset = -y.majorTickLength - y.labelOffset;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        } else {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(k)]];
        }
    }
    y.axisLabels = yLabels;
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
    
}


-(void)OrientationDidChange:(NSNotification*)notification
{
    UIDeviceOrientation Orientation=[[UIDevice currentDevice]orientation];
    
    if(Orientation==UIDeviceOrientationLandscapeLeft || Orientation==UIDeviceOrientationLandscapeRight)
    {
        [self initPlotLandscape];
        NSLog(@"Landscape");
    }
    else if(Orientation==UIDeviceOrientationPortrait)
    {
        [self initPlot];
        NSLog(@"Portrait");
    }
}


@end
