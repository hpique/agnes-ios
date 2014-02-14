//
//  HPNoteActivityItemSource.h
//  Agnes
//
//  Created by Hermes on 25/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPNote;

@interface HPNoteActivityItemSource : NSObject<UIActivityItemSource>

- (id)initWithNote:(HPNote*)note;

@property (nonatomic, assign) NSRange selectedRange;

@end
