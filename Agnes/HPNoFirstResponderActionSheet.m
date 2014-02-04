//
//  HPNoFirstResponderActionSheet.m
//  Agnes
//
//  Created by Hermes on 04/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoFirstResponderActionSheet.h"

@implementation HPNoFirstResponderActionSheet

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

@end
