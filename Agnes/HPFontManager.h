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
extern NSString* const HPFontManagerSystemFontName;

@interface HPFontManager : NSObject

+ (HPFontManager*)sharedManager;

- (UIFont*)fontForArchivedNoteTitle;
- (UIFont*)fontForArchivedNoteBody;
- (UIFont*)fontForBarButtonTitle;
- (UIFont*)fontForDetail;
- (UIFont*)fontForIndexCellTitle;
- (UIFont*)fontForIndexCellDetail;
- (UIFont*)fontForNavigationBarTitle;
- (UIFont*)fontForNavigationBarDetail;
- (UIFont*)fontForNoteTitle;
- (UIFont*)fontForNoteBody;

- (UIFont*)fontForTitleOfNote:(HPNote*)note;
- (UIFont*)fontForBodyOfNote:(HPNote*)note;

@property (nonatomic, assign) BOOL dinamicType;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, readonly) CGFloat noteTitleLineHeight;
@property (nonatomic, readonly) CGFloat noteBodyLineHeight;

@end
