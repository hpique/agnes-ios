//
//  HPFontManager.m
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPFontManager.h"
#import "HPNote.h"

@implementation HPFontManager

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
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | UIFontDescriptorTraitBold];
    UIFont *font = [UIFont fontWithDescriptor:descriptor size:15];
    return font;
}

- (UIFont*)fontForNoteBody
{
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    UIFont *font = [UIFont fontWithDescriptor:descriptor size:15];
    return font;
}

- (UIFont*)fontForArchivedNoteTitle
{
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
    UIFont *font = [UIFont fontWithDescriptor:descriptor size:15];
    return font;
}

- (UIFont*)fontForArchivedNoteBody
{
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFont *font = [UIFont fontWithDescriptor:descriptor size:15];
    return font;
}

- (UIFont*)fontForTitleOfNote:(HPNote*)note
{
    return note.archived ? [self fontForArchivedNoteTitle] : [self fontForNoteTitle];
}

- (UIFont*)fontForBodyOfNote:(HPNote*)note
{
    return note.archived ? [self fontForArchivedNoteBody] : [self fontForNoteBody];
}

@end
