//
//  HPNoteTableViewCell.h
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSwipeTableViewCell.h"
@class HPNote;

@interface HPNoteTableViewCell : MCSwipeTableViewCell

@property (nonatomic, strong) HPNote *note;
@property (nonatomic, readonly) UIFontDescriptor *titleFontDescriptor;
@property (nonatomic, readonly) UIFontDescriptor *detailFontDescriptor;

- (void)displayNote;

@end
