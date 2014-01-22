//
//  HPFontManager.h
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPNote;


@interface HPFontManager : NSObject

+ (HPFontManager*)sharedManager;

- (UIFont*)fontForNoteTitle;
- (UIFont*)fontForNoteBody;
- (UIFont*)fontForArchivedNoteTitle;
- (UIFont*)fontForArchivedNoteBody;

- (UIFont*)fontForTitleOfNote:(HPNote*)note;
- (UIFont*)fontForBodyOfNote:(HPNote*)note;

@end
