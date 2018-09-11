//
//  MCAnimationView.m
//  Copyright (c) 2013, Mirego
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//  - Neither the name of the Mirego nor the names of its contributors may
//    be used to endorse or promote products derived from this software without
//    specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "MCAnimationView.h"
#import <MCUIImageAdvanced/UIImage+MCRetina.h>

@interface MCAnimationView ()
@property (nonatomic) UIImageView* imageView;
@property (nonatomic) NSMutableArray* animationFramesName;
@property (nonatomic) NSMutableArray* animationFramesTime;
@property (nonatomic) NSMutableArray* animationFramesCallback;
@end

@implementation MCAnimationView

//////////////////////////////////////////////////////////////
#pragma mark constructors and destructor
//////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.contentMode = UIViewContentModeCenter;
        self.userInteractionEnabled = NO;
        _animationFramesName = [[NSMutableArray alloc] init];
        _animationFramesTime = [[NSMutableArray alloc] init];
        _animationFramesCallback = [[NSMutableArray alloc] init];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.userInteractionEnabled = NO;
        [self addSubview:self.imageView];
    }
    
    return self;
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    [self stopAnimations];
}

- (void)dealloc
{
    [self stopAnimations];
}

//////////////////////////////////////////////////////////////
#pragma mark layout
//////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.contentMode != UIViewContentModeCenter)
        self.imageView.frame = self.bounds;
}

//////////////////////////////////////////////////////////////
#pragma mark custom drawing
//////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////
#pragma mark public methods
//////////////////////////////////////////////////////////////
- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self.imageView setContentMode:contentMode];
}

- (void)setAnimation:(NSArray *)animation
{
    if ([_animation isEqualToArray:animation] == NO) {
        _animation = [animation copy];
        
        if ([_animation count] > 0) {
            self.imageView.image = [UIImage imageNamedRetina:[_animation objectAtIndex:0]];
            if (CGSizeEqualToSize(self.bounds.size, self.imageView.image.size) == NO) {
                CGPoint center = self.center;
                self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.imageView.image.size.width, self.imageView.image.size.height);
                if (self.contentMode == UIViewContentModeCenter)
                    self.center = center;
                self.imageView.frame = self.bounds;
            }
        } else {
            self.imageView.image = nil;
        }
        
        [self setNeedsDisplay];
    }
}

- (BOOL)isAnimationPlaying
{
    return ([_animationFramesName count] > 0 &&
            [_animationFramesName count] == [_animationFramesTime count] &&
            [_animationFramesName count] == [_animationFramesCallback count]);
}

- (NSTimeInterval)playAnimationRepeatCount:(NSUInteger)repeatCount
{
    return [self playAnimationRepeatCount:repeatCount willPlayBlock:NULL didPlayBlock:NULL];
}

- (NSTimeInterval)playAnimationRepeatCount:(NSUInteger)repeatCount willPlayBlock:(void (^)(NSUInteger))willPlayBlock didPlayBlock:(void (^)(NSUInteger))didPlayBlock
{
    repeatCount = MAX(1, repeatCount);
    
    if ([_animation count] > 0) {
        
        for (NSUInteger ii = 0; ii < repeatCount; ++ii) {
            [_animationFramesName addObjectsFromArray:_animation];
            
            NSNumber* time = [NSNumber numberWithDouble:(_animationDuration / [_animation count])];
            for (NSUInteger ii = 0, ii_count = [_animation count]; ii < ii_count; ++ii) {
                [_animationFramesTime addObject:time];
            }
            
            [_animationFramesCallback insertObject:^(double delay){
                if (willPlayBlock)
                    willPlayBlock(ii);
            } atIndex:0];
            
            for (NSUInteger ii = 1, index = 1, ii_count = [_animation count] - 1; ii < ii_count; ++ii, ++index) {
                [_animationFramesCallback insertObject:^(double delay){} atIndex:index];
            }
            
            [_animationFramesCallback insertObject:^(double delay){
                if (didPlayBlock) {
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (delay * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^() {
                        didPlayBlock(ii);
                    });
                }
            } atIndex:[_animation count] - 1];
        }

        [self animationTimerFired];
    }
    
    NSTimeInterval animationLength = _animationDuration * repeatCount;
    return animationLength;
}

- (void)stopAnimations
{
    [_animationFramesName removeAllObjects];
    [_animationFramesTime removeAllObjects];
    [_animationFramesCallback removeAllObjects];
}

- (void)animationTimerFired
{
    if ([_animationFramesName count] > 0 &&
        [_animationFramesName count] == [_animationFramesTime count] &&
        [_animationFramesName count] == [_animationFramesCallback count]) {
        
        NSTimeInterval timeElapsed = [NSDate timeIntervalSinceReferenceDate];
        NSString* name = [_animationFramesName objectAtIndex:0];
        NSTimeInterval time = [[_animationFramesTime objectAtIndex:0] doubleValue];
        self.imageView.image = [UIImage imageNamedRetina:name];
        if (CGSizeEqualToSize(self.bounds.size, self.imageView.image.size) == NO) {
            CGPoint center = self.center;
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.imageView.image.size.width, self.imageView.image.size.height);
            if (self.contentMode == UIViewContentModeCenter)
                self.center = center;
            self.imageView.frame = self.bounds;
        }
        
        void (^callback)(double) = [_animationFramesCallback objectAtIndex:0];
        [_animationFramesName removeObjectAtIndex:0];
        [_animationFramesTime removeObjectAtIndex:0];
        [_animationFramesCallback removeObjectAtIndex:0];
        
        // Schedule next frame in time - time elapsed to play this frame
        timeElapsed = ([NSDate timeIntervalSinceReferenceDate] - timeElapsed);
        double delayInSeconds = (time - timeElapsed);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self animationTimerFired];
        });
        
        if (callback) {
            callback((time - timeElapsed) + 0.1);
        }
        
    } else {
        if ([_animation count] > 0) {
            NSString* name = self.animationEndsOnLastFrame ? [_animation lastObject] : [_animation objectAtIndex:0];
            self.imageView.image = [UIImage imageNamedRetina:name];
            if (CGSizeEqualToSize(self.bounds.size, self.imageView.image.size) == NO) {
                CGPoint center = self.center;
                self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.imageView.image.size.width, self.imageView.image.size.height);
                if (self.contentMode == UIViewContentModeCenter)
                    self.center = center;
                self.imageView.frame = self.bounds;
            }
        } else {
            self.imageView.image = nil;
        }
        
        [self stopAnimations];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

@end
