//
//  HPRootViewController.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPRootViewController.h"
#import "HPNoteManager.h"
#import <CoreData/CoreData.h>

@implementation HPRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSUndoManager*)undoManager
{
    return [HPNoteManager sharedManager].context.undoManager;
}

@end
