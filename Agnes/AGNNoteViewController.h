//
//  AGNNoteViewController.h
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
@class PSPDFTextView;

@protocol AGNNoteViewControllerDelegate;

@interface AGNNoteViewController : HPDataActionViewController<HPNoteTransitionViewController>

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, weak) id<AGNNoteViewControllerDelegate> delegate;
@property (nonatomic, copy) HPIndexItem *indexItem;
@property (nonatomic, copy) NSArray *notes;
@property (nonatomic, strong) PSPDFTextView *noteTextView; // Needs to be PSPDFTextView for a hack in HPNoteListDetailTransitionAnimator
@property (nonatomic, copy) NSString *search;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

+ (AGNNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;

+ (CGFloat)minimumNoteWidth;

- (BOOL)saveNote:(BOOL)animated;

@end

@protocol AGNNoteViewControllerDelegate<NSObject>

- (void)noteViewController:(AGNNoteViewController*)viewController didSelectIndexItem:(HPIndexItem*)indexItem;

@end
