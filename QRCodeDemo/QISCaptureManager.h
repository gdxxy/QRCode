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
- (void)didFailToAccessCamera; // auth state, show alert
- (void)didOutputDecodeStringValue:(NSString*)stringValue;


@end

@interface QISCaptureManager : NSObject

@property (weak, nonatomic) id<QISCaptureManagerDelegate> delegate;
@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

// crop rect as overlay view
- (instancetype)initWithCropRect:(CGRect)cropRect;
//
- (void)startReader;
- (void)stopReader;
- (void)clearCapture;

@end
