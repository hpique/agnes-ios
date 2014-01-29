//
//  HPFontManager.m
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPFontManager.h"
#import "HPPreferencesManager.h"
#import "HPNote.h"

@implementation HPFontManager {
    UIFont *_archivedNoteBodyFont;
    UIFont *_archivedNoteTitleFont;
    UIFont *_noteBodyFont;
    UIFont *_noteTitleFont;
}

- (id)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChangeNotification:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    return self;
}

+ (HPFontManager*)sharedManager
{
    static HPFontManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPFontManager alloc] init];
        instance.dinamicType = [HPPreferencesManager sharedManager].dynamicType;
        instance.fontName = [HPPreferencesManager sharedManager].fontName;
        instance.fontSize = [HPPreferencesManager sharedManager].fontSize;
    });
    return instance;
}

- (UIFont*)fontForNoteTitle
{
    if (!_noteTitleFont) _noteTitleFont = [self fontWithTextStyle:UIFontTextStyleBody addingTraits:UIFontDescriptorTraitBold];
    return _noteTitleFont;
}

- (UIFont*)fontForNoteBody
{
    if (!_noteBodyFont) _noteBodyFont = [self fontWithTextStyle:UIFontTextStyleBody addingTraits:kNilOptions];
    return _noteBodyFont;
}

- (UIFont*)fontForArchivedNoteTitle
{
    if (!_archivedNoteTitleFont) _archivedNoteTitleFont = [self fontWithTextStyle:UIFontTextStyleBody addingTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
    return _archivedNoteTitleFont;
}

- (UIFont*)fontForArchivedNoteBody
{
    if (!_archivedNoteBodyFont) _archivedNoteBodyFont = [self fontWithTextStyle:UIFontTextStyleBody addingTraits:UIFontDescriptorTraitItalic];
    return _archivedNoteBodyFont;
}

- (UIFont*)fontForTitleOfNote:(HPNote*)note
{
    return note.archived ? [self fontForArchivedNoteTitle] : [self fontForNoteTitle];
}

- (UIFont*)fontForBodyOfNote:(HPNote*)note
{
    return note.archived ? [self fontForArchivedNoteBody] : [self fontForNoteBody];
}

- (void)setDinamicType:(BOOL)dinamicType
{
    _dinamicType = dinamicType;
    [self invalidateFonts];
}

- (void)setFontName:(NSString *)fontName
{
    _fontName = fontName;
    [self invalidateFonts];
}

- (void)setFontSize:(CGFloat)fontSize
{
    _fontSize = fontSize;
    [self invalidateFonts];
}

#pragma mark - Actions

- (void)contentSizeCategoryDidChangeNotification:(NSNotification*)notification
{
    [self invalidateFonts];
}

#pragma mark - Private

- (UIFont*)fontWithTextStyle:(NSString*)textStyle addingTraits:(UIFontDescriptorSymbolicTraits)traits
{
    if (self.dinamicType)
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | traits];
        return [UIFont fontWithDescriptor:descriptor size:0];
    }
    else
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor fontDescriptorWithName:self.fontName size:self.fontSize];
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | traits];
        return [UIFont fontWithDescriptor:descriptor size:self.fontSize];
    }
}

- (void)invalidateFonts
{
    _archivedNoteBodyFont = nil;
    _archivedNoteTitleFont = nil;
    _noteBodyFont = nil;
    _noteTitleFont = nil;
}

@end
