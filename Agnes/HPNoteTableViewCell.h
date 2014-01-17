//
//  HPNoteTableViewCell.h
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPNoteManager.h"
@class HPNote;

@interface HPNoteTableViewCell : UITableViewCell

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, assign) HPNoteDisplayCriteria displayCriteria;

@end
