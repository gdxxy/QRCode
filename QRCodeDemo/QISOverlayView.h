//
//  QISOverlayView.h
//  QRCodeDemo
//
//  Created by xiexianyu on 11/12/15.
//  Copyright © 2015 QIS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QISOverlayView : UIView

+ (CGRect)cropRect;

// update result tip
- (void)updateResultTip:(NSString*)tip hide:(BOOL)isHide;

@end
