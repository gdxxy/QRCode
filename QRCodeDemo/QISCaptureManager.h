//
//  QISCaptureManager.h
//  QRCodeDemo
//
//  Created by xiexianyu on 11/11/15.
//  Copyright © 2015 QIS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVfoundation/AVfoundation.h>

@protocol QISCaptureManagerDelegate <NSObject>

@optional
- (void)didChangeAccessCameraState:(BOOL)isGranted;
- (void)didOutputDecodeStringValue:(NSString*)stringValue;
- (void)didDecodeUnmatchType:(NSString*)codeType;

@end

@interface QISCaptureManager : NSObject

@property (weak, nonatomic) id<QISCaptureManagerDelegate> delegate;
@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

// crop rect as overlay view
- (instancetype)initWithCropRect:(CGRect)cropRect;

// start/stop/clear
- (void)startReader;
- (void)stopReader;
- (void)clearCapture;

@end
