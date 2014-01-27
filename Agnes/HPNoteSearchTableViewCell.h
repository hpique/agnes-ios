//
//  HPNoteSearchTableViewCell.h
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPNoteTableViewCell.h"

@interface HPNoteSearchTableViewCell : HPNoteTableViewCell

@property (nonatomic, copy) NSString *searchText;

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width searchText:(NSString*)searchText;

@end
