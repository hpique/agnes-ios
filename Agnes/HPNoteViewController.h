//
//  HPNoteViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPDataActionViewController.h"
#import "HPNoteNavigationController.h"
@class HPNote;
@class HPIndexItem;

@protocol HPNoteViewControllerDelegate;

@interface HPNoteViewController : HPDataActionViewController<HPNoteTransitionViewController>

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, weak) id<HPNoteViewControllerDelegate> delegate;
@property (nonatomic, copy) HPIndexItem *indexItem;
@property (nonatomic, strong) NSMutableArray *notes;
@property (nonatomic, strong) UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;

+ (HPNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;

- (BOOL)saveNote:(BOOL)animated;

@end

@protocol HPNoteViewControllerDelegate<NSObject>

- (void)noteViewController:(HPNoteViewController*)viewController shouldReturnToIndexItem:(HPIndexItem*)indexItem;

@end
