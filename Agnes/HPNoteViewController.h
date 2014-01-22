//
//  HPNoteViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPDataActionViewController.h"
@class HPNote;
@class HPIndexItem;

@interface HPNoteViewController : HPDataActionViewController

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, copy) HPIndexItem *indexItem;
@property (nonatomic, strong) NSMutableArray *notes;
@property (nonatomic, strong) UITextView *noteTextView;

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;

+ (HPNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;


@end
