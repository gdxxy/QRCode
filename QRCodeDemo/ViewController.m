//
//  ViewController.m
//  QRCodeDemo
//
//  Created by xiexianyu on 11/10/15.
//  Copyright © 2015 QIS. All rights reserved.
//

#import "ViewController.h"
#import "QISOverlayView.h"
#import "QISCaptureManager.h"

@interface ViewController () <QISCaptureManagerDelegate>
//
@property (strong, nonatomic) QISCaptureManager *captureManager;
//
@property (strong, nonatomic) QISOverlayView *overlayView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // add observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)dealloc
{
    // remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // stop capture video and clear
    [_captureManager clearCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // setup capture manager
    CGRect cropRect = [QISOverlayView cropRect];
    self.captureManager = [[QISCaptureManager alloc] initWithCropRect:cropRect];
    _captureManager.delegate = self;
    // add video preview layer
    [_captureManager.videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:_captureManager.videoPreviewLayer];
    //
    [self setupOverlayView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // start capture video
    [_captureManager startReader];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.overlayView removeFromSuperview];
    // stop capture video and clear
    [_captureManager clearCapture];
    //
    self.overlayView = nil;
}

- (void)setupOverlayView
{
    self.overlayView = [[[NSBundle mainBundle] loadNibNamed:@"QISOverlayView" owner:nil options:nil] firstObject];
    [self.view addSubview:_overlayView];
    
    _overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMutableArray *newConstraints = [NSMutableArray array];
    NSDictionary *views = @{@"overlayView":_overlayView};
    
    NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[overlayView]|" options:0 metrics:nil views:views];
    [newConstraints addObjectsFromArray:constraints1];
    NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[overlayView]|" options:0 metrics:nil views:views];
    [newConstraints addObjectsFromArray:constraints2];
    
    float versionNumber = floor(NSFoundationVersionNumber);
    if (versionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        // use iOS 7-style appearance
        [self.view addConstraints:newConstraints];
    } else {
        // use iOS 8-style appearance
        [NSLayoutConstraint activateConstraints:newConstraints];
    }
}

#pragma mark - QISCaptureManagerDelegate

- (void)didFailToAccessCamera
{
    // auth state, show alert
    [self alertCameraAuth];
}

- (void)didOutputDecodeStringValue:(NSString*)stringValue
{
    //TODO: handle decode result
    
    //[_captureManager stopReader];
    //[_overlayView updateResultTip:@"已扫描，处理中" hide:NO];
    
}

// helper
- (void)alertCameraAuth
{
    NSString *title = nil;
    NSString *message = @"请在“设置-隐私-相机”选项中，允许应用访问你的相机";
    NSString *cancelTitle = nil;
    NSString *otherTitle = @"好";
    
    float versionNumber = floor(NSFoundationVersionNumber);
    if (versionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        // alert view
        UIAlertView *tipAlert = [[UIAlertView alloc] initWithTitle:title
                                                           message:message
                                                          delegate:nil
                                                 cancelButtonTitle:cancelTitle
                                                 otherButtonTitles:otherTitle, nil];
        
        tipAlert.tag = 128;
        [tipAlert show];
    }
    else {
        // ios 8 and later, use alertController
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            //TODO nothing
        }];
        [alertController addAction:otherAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        // disable edge pan for root view controller
        alertController.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

#pragma mark - handle app notification

- (void)applicationWillEnterForeground:(NSNotification*)notification
{
    [_captureManager startReader];
}

- (void)applicationDidEnterBackground:(NSNotification*)notification
{
    [_captureManager stopReader];
}

@end
