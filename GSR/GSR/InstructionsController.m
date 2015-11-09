//
//  InstructionsController.m
//  GSR
//
//  Created by Jean Rintoul on 11/3/15.
//  Copyright © 2015 Lir. All rights reserved.
//

#import "InstructionsController.h"

@interface InstructionsController ()

@end

@implementation InstructionsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // default webview.
    CGRect parentRect = CGRectMake(10, 70, 300, 500);
    // This is to determine whether it is retina 3.5 or 4 inch display.
    // NSInteger screenheight = [UIScreen mainScreen].bounds.size.height;
    NSURL *url;
    // parentRect = CGRectMake(50, 0, 300, 356);
    url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"instructions" ofType:@"html" inDirectory:@"www"]];
    // Do any additional setup after loading the view.
    UIWebView *webView = [[UIWebView alloc] initWithFrame:parentRect];
    [webView setSuppressesIncrementalRendering:NO];
    webView.suppressesIncrementalRendering = NO;
    //webView.scalesPageToFit = YES; // change this to yes, when i have a proper html page ready.
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    webView.userInteractionEnabled = NO;
    [self.view addSubview:webView];
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

@end
