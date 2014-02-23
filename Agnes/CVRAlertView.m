//
//  CVRAlertView.m
//  Agnes
//
//  Created by Hermes on 21/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "CVRAlertView.h"

@interface CVRAlertView()<UIAlertViewDelegate>

@end

@implementation CVRAlertView {
    __weak id _realDelegate;
    void(^_clickedButtonAtIndexBlock)(NSInteger buttonIndex);
}

#pragma mark Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initHelper];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initHelper];
    }
    return self;
}

- (void)initHelper
{
    _realDelegate = self.delegate;
    [super setDelegate:self];
}

#pragma mark Public

- (void)showWithClickBlock:(void(^)(NSInteger buttonIndex))clickBlock
{
    _clickedButtonAtIndexBlock = clickBlock;
    [self show];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([_realDelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
    {
        [_realDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
    }
    if (_clickedButtonAtIndexBlock)
    {
        _clickedButtonAtIndexBlock(buttonIndex);
    }
    _clickedButtonAtIndexBlock = nil;
}

#pragma mark Delegate forwarding

- (void)dealloc
{
    self.delegate = nil;
}

- (id)forwardingTargetForSelector:(SEL)s
{
    return [_realDelegate respondsToSelector:s] ? _realDelegate : [super forwardingTargetForSelector:s];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)s
{
    return [super methodSignatureForSelector:s] ?: [(id)_realDelegate methodSignatureForSelector:s];
}

- (BOOL)respondsToSelector:(SEL)s
{
    return [super respondsToSelector:s] || [_realDelegate respondsToSelector:s];
}

- (void)setDelegate:(id)delegate
{
    [super setDelegate:delegate ? self : nil];
    _realDelegate = delegate != self ? delegate : nil;
}

@end
