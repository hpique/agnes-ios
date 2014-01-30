//
//  HPFontManager.h
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPNote;

extern NSString* const HPFontManagerDidChangeFontsNotification;

@interface HPFontManager : NSObject

+ (HPFontManager*)sharedManager;

- (UIFont*)fontForDetail;
- (UIFont*)fontForNoteTitle;
- (UIFont*)fontForNoteBody;
- (UIFont*)fontForArchivedNoteTitle;
- (UIFont*)fontForArchivedNoteBody;

- (UIFont*)fontForTitleOfNote:(HPNote*)note;
- (UIFont*)fontForBodyOfNote:(HPNote*)note;

@property (nonatomic, assign) BOOL dinamicType;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, assign) CGFloat fontSize;

@end
