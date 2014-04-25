//
//  AGNUIMetrics.h
//  Agnes
//
//  Created by Hermes on 04/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const AGNIndexWidthPad;

@interface AGNUIMetrics : NSObject

+ (CGFloat)sideMarginForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation width:(CGFloat)width;

@end
