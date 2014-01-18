//
//  HPNoteViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPNote;

@interface HPNoteViewController : UIViewController

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, strong) NSMutableArray *notes;

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes tag:(NSString*)tag;

+ (HPNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes tag:(NSString*)tag;


@end
