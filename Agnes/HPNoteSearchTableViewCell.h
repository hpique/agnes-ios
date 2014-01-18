//
//  HPNoteSearchTableViewCell.h
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPNote;

@interface HPNoteSearchTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, strong) HPNote *note;

@end