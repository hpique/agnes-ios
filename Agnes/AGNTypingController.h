//
//  AGNTypingController.h
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AGNTypingControllerDelegate;

@interface AGNTypingController : NSObject

@property (nonatomic, weak) id<AGNTypingControllerDelegate> delegate;

@property (nonatomic, readonly) BOOL typing;

- (void)setTyping:(BOOL)typing animated:(BOOL)animated;

- (void)finishTyping;

@end

@protocol AGNTypingControllerDelegate<NSObject>

- (UINavigationController*)navigationControllerForTypingController:(AGNTypingController*)typingController;

- (void)typingController:(AGNTypingController*)typingController didShowBarsAnimated:(BOOL)animated;

@end
