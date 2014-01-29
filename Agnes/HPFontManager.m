//
//  HPFontManager.m
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPFontManager.h"
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
    });
    return instance;
}

- (UIFont*)fontForNoteTitle
{
    if (!_noteTitleFont)
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | UIFontDescriptorTraitBold];
        _noteTitleFont = [UIFont fontWithDescriptor:descriptor size:0];
    }
    return _noteTitleFont;
}

- (UIFont*)fontForNoteBody
{
    if (!_noteBodyFont)
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        _noteBodyFont = [UIFont fontWithDescriptor:descriptor size:0];
    }
    return _noteBodyFont;
}

- (UIFont*)fontForArchivedNoteTitle
{
    if (!_archivedNoteTitleFont)
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
        _archivedNoteTitleFont = [UIFont fontWithDescriptor:descriptor size:0];
    }
    return _archivedNoteTitleFont;
}

- (UIFont*)fontForArchivedNoteBody
{
    if (!_archivedNoteBodyFont)
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        _archivedNoteBodyFont = [UIFont fontWithDescriptor:descriptor size:0];
    }
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

#pragma mark - Actions

- (void)contentSizeCategoryDidChangeNotification:(NSNotification*)notification
{
    [self invalidateFonts];
}

#pragma mark - Private

- (void)invalidateFonts
{
    _archivedNoteBodyFont = nil;
    _archivedNoteTitleFont = nil;
    _noteBodyFont = nil;
    _noteTitleFont = nil;
}

@end
