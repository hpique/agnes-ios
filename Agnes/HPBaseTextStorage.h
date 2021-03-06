//
//  HPBaseTextStorage.h
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPBaseTextStorage : NSTextStorage

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *search;

- (void)beginAnimatingAttachmentAtIndex:(NSUInteger)index;
- (void)endAnimatingAttachmentAtIndex:(NSUInteger)index;
- (void)setAnimationProgress:(CGFloat)progress ofAttachmentAtIndex:(NSUInteger)index;

@end

