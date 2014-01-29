//
//  HPNoteListSearchBar.h
//  Agnes
//
//  Created by Hermes on 29/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPNoteListSearchBar : UISearchBar

@property (nonatomic, readonly) UIButton *actionButton;

- (void)setWillBeginSearch;

- (void)setWillEndSearch;

@end
