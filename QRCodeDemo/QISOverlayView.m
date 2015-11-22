//
//  QISOverlayView.m
//  QRCodeDemo
//
//  Created by xiexianyu on 11/12/15.
//  Copyright © 2015 QIS. All rights reserved.
//

#import "QISOverlayView.h"
#import <AVFoundation/AVFoundation.h>

// const
static const CGFloat kQISOverlayPadding = 30.0;

@interface QISOverlayView ()
@property (nonatomic, assign) CGRect overlayCropRect;
//
@property (assign, nonatomic) BOOL isAnimating;
@property (weak, nonatomic) IBOutlet UIView *cropContainerView;
@property (strong, nonatomic) UIImageView *scrollImageView;
//
@property (weak, nonatomic) IBOutlet UIView *resultContainerView;
@property (weak, nonatomic) IBOutlet UILabel *resultTipLabel;
// crop size constraint
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cropWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cropHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollTopConstraint;
@end

@implementation QISOverlayView

+ (CGRect)cropRect
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat cropWidth = screenSize.width - kQISOverlayPadding - kQISOverlayPadding;
    CGFloat cropHeight = cropWidth;
    CGFloat cropX = kQISOverlayPadding;
    CGFloat cropY = ceilf((screenSize.height - cropHeight)/2);
    
    return CGRectMake(cropX, cropY, cropWidth, cropHeight);
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onVideoStart:)
                                                 name: AVCaptureSessionDidStartRunningNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onVideoStop:)
                                                 name: AVCaptureSessionDidStopRunningNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onVideoStop:)
                                                 name: AVCaptureSessionWasInterruptedNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onVideoStart:)
                                                 name: AVCaptureSessionInterruptionEndedNotification
                                               object: nil];
    
    // set up scroll image view.
    _scrollImageView.layer.shadowColor = [UIColor greenColor].CGColor;
    _scrollImageView.layer.shadowOffset = CGSizeMake(1, 1);
    _scrollImageView.layer.shadowOpacity = 0.5;
    _scrollImageView.layer.shadowRadius = 5;
    
    // set crop rect
    self.overlayCropRect = [QISOverlayView cropRect];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// override
- (void)updateConstraints
{
    _cropWidthConstraint.constant = _overlayCropRect.size.width;
    _cropHeightConstraint.constant = _overlayCropRect.size.height;
    
    [super updateConstraints];
}

- (void)updateResultTip:(NSString*)tip hide:(BOOL)isHide
{
    self.resultTipLabel.text = tip;
    self.resultContainerView.hidden = isHide;
}

#pragma mark - handle capture session notification

- (void)onVideoStart: (NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startScrollAnimate];
    });
}

- (void)onVideoStop: (NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopScrollAnimate];
    });
}

#pragma mark - start/stop scroll animate

- (void)startScrollAnimate
{
    if (_isAnimating) {
        return ;
    }
    
    self.scrollImageView.hidden = NO; //show
    self.isAnimating = YES;
    
    [self loopScrollAnimate];
}

- (void)stopScrollAnimate
{
    self.scrollImageView.hidden = YES; //hide
    self.isAnimating = NO;
}

// scroll animate
- (void)loopScrollAnimate
{
    if (!_isAnimating) {
        return ;
    }
    
    // move to bottom. minus height of scroll image view
    _scrollTopConstraint.constant = _overlayCropRect.size.height-8.0;
    [self setNeedsLayout];
    
    // animate
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        // move to top
        _scrollTopConstraint.constant = 0.0;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        [self loopScrollAnimate];
    }];
}

@end
