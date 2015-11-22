//
//  QISCaptureManager.m
//  QRCodeDemo
//
//  Created by xiexianyu on 11/11/15.
//  Copyright © 2015 QIS. All rights reserved.
//

#import "QISCaptureManager.h"
#import <UIKit/UIKit.h>

@interface QISCaptureManager () <AVCaptureMetadataOutputObjectsDelegate>
//
@property (nonatomic, assign) CGRect cropRect;
@property (assign, nonatomic) BOOL isReading;
@property (assign, nonatomic) BOOL isOnlyQRCode; //one meta type: QR code.
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic, readwrite) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@end

@implementation QISCaptureManager

- (instancetype)initWithCropRect:(CGRect)cropRect
{
    self = [super init];
    if (self) {
        _cropRect = cropRect;
        [self authCapture];
    }
    return self;
}

- (void)dealloc
{
    [self clearCapture];
}

#pragma mark - AVFoundation

- (void)authCapture
{
    NSString *mediaType = AVMediaTypeVideo;
    
    // verifying authorization
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted) { // ok
                [self setupCapture];
                [self startReader];
            }
            else { // denied
                [self notifyFailedToAccessCamera];
            }
        }];
    }
    else if (authStatus == AVAuthorizationStatusAuthorized) {
        [self setupCapture];
    }
    else { // denied or restricted
        [self notifyFailedToAccessCamera];
    }
}

- (void)setupCapture
{
    NSString *mediaType = AVMediaTypeVideo;
    
    // AVCaptureDevice
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:mediaType];
    // configure capture device
    [captureDevice lockForConfiguration:nil];
    // set focus modes
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        // reset default
        CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
        [captureDevice setFocusPointOfInterest:autofocusPoint];
        [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
    // set torch mode
    if ([captureDevice hasTorch] && [captureDevice isTorchModeSupported:AVCaptureTorchModeAuto]) {
        captureDevice.torchMode = AVCaptureTorchModeAuto;
    }
    // no download scale occur.
    captureDevice.videoZoomFactor = captureDevice.activeFormat.videoZoomFactorUpscaleThreshold;
    //
    [captureDevice unlockForConfiguration];
    
    // AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    // Configure the session to produce lower resolution video frames, if your
    // processing algorithm can cope.
    // Note: if change present size then it need change below method 'rectOfInterest'
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    }
    
    // AVCaptureDeviceInput
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!captureInput) { // error
        NSLog(@"AVCaptureDeviceInput error %@", error.localizedDescription);
        return ;
    }
    if ([_captureSession canAddInput:captureInput]) {
        [_captureSession addInput:captureInput];
    }
    
    // AVCaptureMetadataOutput
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    // call addOutput: must before call setMetadataObjectTypes:, or else exception unsupported type found.
    if ([_captureSession canAddOutput:captureOutput]) {
        [_captureSession addOutput:captureOutput];
    }
    // configure output
    // create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("captureOutputQueue", NULL);
    [captureOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    //
    if (self.isOnlyQRCode) {
        [captureOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    }
    else {
        [captureOutput setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode, nil]];
    }
    // crop rect
    captureOutput.rectOfInterest = [self rectOfInterest];
    
    // for UI
    // AVCaptureVideoPreviewLayer
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //[_videoPreviewLayer setFrame:self.view.layer.bounds];
    //[self.view.layer addSublayer:_videoPreviewLayer];
}

- (void)startReader
{
    self.isReading = YES;
    if (_captureSession && !_captureSession.isRunning) {
        // start the session running to start the flow of data
        [self.captureSession startRunning];
    }
    
}

- (void)stopReader
{
    self.isReading = NO;
    if (_captureSession && _captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (void)clearCapture
{
    self.isReading = NO;
    
    // clear capture
    
    [_captureSession stopRunning];
    //
    AVCaptureInput* input = [_captureSession.inputs objectAtIndex:0];
    [_captureSession removeInput:input];
    //
    AVCaptureVideoDataOutput* output = (AVCaptureVideoDataOutput*)[_captureSession.outputs objectAtIndex:0];
    [_captureSession removeOutput:output];
    //
    [_videoPreviewLayer removeFromSuperlayer];
    //
    self.videoPreviewLayer = nil;
    self.captureSession = nil;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    if (!_isReading) return;
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *stringValue = metadataObj.stringValue;
        
        // notify delegate if not nil.
        if (stringValue != nil && _delegate != nil && [_delegate respondsToSelector:@selector(didOutputDecodeStringValue:)]) {
            NSString *decodeText = [NSString stringWithString:stringValue];
            [_delegate didOutputDecodeStringValue:decodeText];
        }
        
#ifdef DEBUG
        [self rectOfInterest];
        NSLog(@"didOutputMetadataObjects %@\n", metadataObjects);
#endif
        
        /**
         didOutputMetadataObjects (
         "<AVMetadataMachineReadableCodeObject: 0x155e24860, type=\"org.gs1.EAN-13\", bounds={ 0.5,0.3 0.0x0.5 }>corners { 0.5,0.8 0.5,0.8 0.5,0.3 0.5,0.3 }, time 445706141214958, stringValue \"6901236341599\""
         */
    }
}

#pragma mark - helper

- (CGRect)rectOfInterest
{
    // default, scan the whole photo zone.
    CGRect rectOfInterest = CGRectMake(0.0, 0.0, 1.0, 1.0);
    
    // rotate 90 for photo is horizontal, but iphone is vertical.
    // interest with photo size, not screen size. preview layer is aspect fill.
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGSize photoSize = CGSizeMake(1920.0, 1080.0); //AVCaptureSessionPreset1920x1080
   
    // it need fix for iphone4s/4 or ipad.
    BOOL isFixScale = NO;
    UIUserInterfaceIdiom idiom = [UIDevice currentDevice].userInterfaceIdiom;
    if (idiom == UIUserInterfaceIdiomPad) { // ipad
        isFixScale = YES;
    }
    else if (screenSize.height < 480.0+1.0) { // iphone4s/4
        isFixScale = YES;
    }
    
    if (isFixScale) {
        CGFloat p1 = screenSize.height/screenSize.width;
        CGFloat p2 = photoSize.width/photoSize.height;
        if (p1 < p2) {
            // hide sides of photo width in screen, for aspect fill.
            // scale base on photo height.
            CGFloat fixHeight = ceilf(screenSize.width * photoSize.width / photoSize.height); //extend
            CGFloat fixPadding = ceilf((fixHeight - screenSize.height)/2);
            rectOfInterest = CGRectMake((_cropRect.origin.y + fixPadding)/fixHeight,
                                        _cropRect.origin.x/screenSize.width,
                                        _cropRect.size.height/fixHeight,
                                        _cropRect.size.width/screenSize.width);
        }
        else { //
            CGFloat fixWidth = ceilf(screenSize.height * photoSize.height / photoSize.width);
            CGFloat fixPadding = ceilf((fixWidth - screenSize.width)/2);
            rectOfInterest = CGRectMake(_cropRect.origin.y/screenSize.height,
                                        (_cropRect.origin.x + fixPadding)/fixWidth,
                                        _cropRect.size.height/screenSize.height,
                                        _cropRect.size.width/fixWidth);
            
        }
    }
    else { // same scale
        rectOfInterest = CGRectMake(_cropRect.origin.y/screenSize.height,
                                    _cropRect.origin.x/screenSize.width,
                                    _cropRect.size.height/screenSize.height,
                                    _cropRect.size.width/screenSize.width);
    }

#ifdef DEBUG
    NSLog(@"rectOfInterest %f %f %f %f\n", rectOfInterest.origin.x, rectOfInterest.origin.y, rectOfInterest.size.width, rectOfInterest.size.height);
#endif
    return rectOfInterest;
}

- (void)notifyFailedToAccessCamera
{
#ifdef DEBUG
    NSLog(@"AVCaptureDevice auth state for video is denied or restricted\n");
#endif
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(didFailToAccessCamera)]) {
        [_delegate didFailToAccessCamera];
    }
}

@end
