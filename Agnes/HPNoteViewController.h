//
//  HPNoteViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPNote;
@class HPIndexItem;

@interface HPNoteViewController : UIViewController

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, copy) HPIndexItem *indexItem;
@property (nonatomic, strong) NSMutableArray *notes;

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;

+ (HPNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes indexItem:(HPIndexItem*)indexItem;


@end
