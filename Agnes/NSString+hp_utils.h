//
//  NSString+hp_utils.h
//  Agnes
//
//  Created by Hermes on 27/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (hp_utils)

- (void)hp_enumerateOccurrencesOfString:(NSString*)target options:(NSStringCompareOptions)opts usingBlock:(void (^)(NSRange matchRange, BOOL *stop))block;

- (NSInteger)hp_linesWithFont:(UIFont*)font width:(CGFloat)width lineHeight:(CGFloat*)lineHeight;

@end
