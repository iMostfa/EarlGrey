//
// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AnimationViewController.h"

typedef NS_ENUM(NSUInteger, AnimationStatus) {
  kAnimationStopped = 0,
  kAnimationStarted,
  kAnimationPaused,
};

@interface AnimationViewController ()
@property(nonatomic, assign) AnimationStatus animationStatus;
@end

@implementation AnimationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  _animationStatus = kAnimationStopped;
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.delayedExecutionStatusLabel.accessibilityIdentifier = @"delayedLabelStatus";
  [self.toggleRedSquareButton addTarget:self
                                 action:@selector(toggleRedSquareDisappear)
                       forControlEvents:UIControlEventTouchUpInside];
}

- (void)toggleRedSquareDisappear {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   if ([self.viewToToggle isDescendantOfView:self.view]) {
                     [self.viewToToggle removeFromSuperview];
                   }
                 });
}

- (void)setDelayedExecutionStatusTextToExecutedTwice {
  self.delayedExecutionStatusLabel.text = @"Executed Twice!";
}

- (void)setDelayedExecutionStatusText:(NSString *)text {
  self.delayedExecutionStatusLabel.text = text;
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(setDelayedExecutionStatusText:)
                                             object:@"ShouldNotExecute"];
}

- (IBAction)delayedAnimationButtonClicked:(id)sender {
  [self performSelector:@selector(setDelayedExecutionStatusText:)
             withObject:@"Executed Once!"
             afterDelay:0.1];
  [self performSelector:@selector(setDelayedExecutionStatusTextToExecutedTwice)
             withObject:nil
             afterDelay:1.0];
  [self performSelector:@selector(setDelayedExecutionStatusText:)
             withObject:@"ShouldNotExecute"
             afterDelay:1.2];
}

- (IBAction)UIViewAnimationControlClicked:(id)sender {
  self.UIViewAnimationControlButton.enabled = NO;
  [self.UIViewAnimationControlButton setTitle:@"Started" forState:UIControlStateDisabled];
  [UIView animateWithDuration:1.0f
      animations:^{
        // Move view 50 units to the right.
        CGRect frame = self.viewToAnimate.frame;
        frame.origin.x = frame.origin.x + 50;
        self.viewToAnimate.frame = frame;

        // Move the view 100 units below.
        CGRect nestedFrame = self.viewToAnimate.frame;
        nestedFrame.origin.y = nestedFrame.origin.y + 100;
        self.viewToAnimate.frame = nestedFrame;

        // Resize the view to 1/2 its size.
        CGRect nestedResizeFrame = self.viewToAnimate.frame;
        nestedResizeFrame.size.width = nestedResizeFrame.size.width / 2;
        nestedResizeFrame.size.height = nestedResizeFrame.size.height / 2;
        self.viewToAnimate.frame = nestedResizeFrame;
      }
      completion:^(BOOL finished) {
        self.animationStatusLabel.text = @"UIView animation finished";
      }];
}

- (IBAction)startUIViewChainedAnimation:(id)sender {
  [UIView animateWithDuration:3
      animations:^{
        self.viewToAnimate.transform =
            CGAffineTransformRotate(self.viewToAnimate.transform, M_PI_2);
      }
      completion:^(BOOL finished) {
        [UIView animateWithDuration:3
                         animations:^{
                           // Test so that completion block is tracked for the extended sleep time.
                           CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, NO);
                           // viewToAnimate should cover viewToToggle view.
                           self.viewToAnimate.center = self.viewToToggle.center;
                         }];
      }];
}

- (IBAction)CAAnimationControlClicked:(id)sender {
  if (_animationStatus == kAnimationStopped) {
    CABasicAnimation *currentAnimation =
        [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    currentAnimation.fromValue = @(0);
    currentAnimation.toValue = @(350.0f);
    currentAnimation.duration = 5.0;
    currentAnimation.removedOnCompletion = NO;
    currentAnimation.fillMode = kCAFillModeForwards;
    [self.viewToAnimate.layer addAnimation:currentAnimation forKey:@"moveView"];

    self.CAAnimationControlButton.enabled = NO;
    self.animationStatusLabel.text = @"Started";

    __weak AnimationViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      AnimationViewController *strongSelf = weakSelf;
      if (strongSelf) {
        CFTimeInterval pausedTime =
            [strongSelf.viewToAnimate.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        strongSelf.viewToAnimate.layer.timeOffset = pausedTime;
        strongSelf.viewToAnimate.layer.speed = 0;
        strongSelf.animationStatus = kAnimationPaused;

        strongSelf.CAAnimationControlButton.enabled = YES;
        [strongSelf.CAAnimationControlButton setTitle:@"Resume Animation"
                                             forState:UIControlStateNormal];
        strongSelf.animationStatusLabel.text = @"Paused";
      }
    });
  } else if (_animationStatus == kAnimationPaused) {
    self.CAAnimationControlButton.enabled = NO;
    self.animationStatusLabel.hidden = YES;

    CFTimeInterval pausedTime = self.viewToAnimate.layer.timeOffset;
    self.viewToAnimate.layer.speed = 1;
    self.viewToAnimate.layer.beginTime = 0;
    self.viewToAnimate.layer.timeOffset = 0;

    CFTimeInterval timeSincePause =
        [self.viewToAnimate.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.viewToAnimate.layer.beginTime = timeSincePause;
  }
}

- (IBAction)beginIgnoringEventsClicked:(id)sender {
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                   self.animationStatusLabel.text = @"EndIgnoringEvents";
                 });
}

@end
