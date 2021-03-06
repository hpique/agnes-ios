//
//  HPKeyboardButton.h
//  Agnes
//
//  Created by Hermes on 21/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPKeyboardButton : UIButton

@property (nonatomic, copy) NSString *key;

+ (CGSize)sizeForOrientation:(UIInterfaceOrientation)interfaceOrientation;

+ (CGFloat)keySeparatorForOrientation:(UIInterfaceOrientation)interfaceOrientation;

+ (CGFloat)sideInsetForOrientation:(UIInterfaceOrientation)interfaceOrientation;

+ (CGFloat)topMarginForOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end
