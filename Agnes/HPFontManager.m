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

NSString *const HPFontManagerDidChangeFontsNotification = @"HPFontManagerDidChangeFontsNotification";
NSString *const HPFontManagerSystemFontName = @"system";

@implementation HPFontManager {
    UIFont *_archivedNoteBodyFont;
    UIFont *_archivedNoteTitleFont;
    UIFont *_barButtonTitleFont;
    UIFont *_detailFont;
    UIFont *_indexCellDetailFont;
    UIFont *_indexCellTitleFont;
    UIFont *_navigationBarTitleFont;
    UIFont *_navigationBarDetailFont;
    UIFont *_noteBodyFont;
    UIFont *_noteTitleFont;
    UIFont *_searchBarFont;
}

@synthesize noteBodyLineHeight = _noteBodyLineHeight;
@synthesize noteTitleLineHeight = _noteTitleLineHeight;

- (id)init
{
    if (self = [super init])
    {
        _noteBodyLineHeight = -1;
        _noteTitleLineHeight = -1;
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

- (UIFont*)fontForBarButtonTitle
{
    if (!_barButtonTitleFont) _barButtonTitleFont = [self.fontForNoteBody fontWithSize:17];
    return _barButtonTitleFont;
}

- (UIFont*)fontForDetail
{
    if (!_detailFont) _detailFont = [self fontWithTextStyle:UIFontTextStyleFootnote addingTraits:kNilOptions scale:0.75];
    return _detailFont;
}

- (UIFont*)fontForIndexCellDetail
{
    if (!_indexCellDetailFont) _indexCellDetailFont = [self.fontForDetail fontWithSize:16];
    return _indexCellDetailFont;
}

- (UIFont*)fontForIndexCellTitle
{
    if (!_indexCellTitleFont) _indexCellTitleFont = [self.fontForNoteBody fontWithSize:18];
    return _indexCellTitleFont;
}

- (UIFont*)fontForNoteTitle
{
    if (!_noteTitleFont) _noteTitleFont = [self fontWithTextStyle:UIFontTextStyleBody addingTraits:UIFontDescriptorTraitBold];
    return _noteTitleFont;
}

- (UIFont*)fontForNavigationBarTitle
{
    if (!_navigationBarTitleFont) _navigationBarTitleFont = [self.fontForNoteTitle fontWithSize:17];
    return _navigationBarTitleFont;
}

- (UIFont*)fontForNavigationBarDetail
{
    if (!_navigationBarDetailFont) _navigationBarDetailFont = [self.fontForNoteBody fontWithSize:10];
    return _navigationBarDetailFont;
}

- (UIFont*)fontForNoteBody
{
    if (!_noteBodyFont) _noteBodyFont = [self fontWithTextStyle:UIFontTextStyleBody addingTraits:kNilOptions];
    return _noteBodyFont;
}

- (UIFont*)fontForSearchBar
{
    if (!_searchBarFont) _searchBarFont = [self.fontForNoteBody fontWithSize:14];
    return _searchBarFont;
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

- (CGFloat)noteBodyLineHeight
{
    if (_noteBodyLineHeight < 0)
    {
        _noteBodyLineHeight = [self lineHeightOfFont:self.fontForNoteBody];
    }
    return _noteBodyLineHeight;
}

- (CGFloat)noteTitleLineHeight
{
    if (_noteTitleLineHeight < 0)
    {
        _noteTitleLineHeight = [self lineHeightOfFont:self.fontForNoteTitle];
    }
    return _noteTitleLineHeight;
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

- (CGFloat)lineHeightOfFont:(UIFont*)font
{
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGFloat lineHeight = [@"" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:attributes context:nil].size.height;
    lineHeight = ceilf(lineHeight);
    return lineHeight;
}

- (UIFont*)fontWithTextStyle:(NSString*)textStyle addingTraits:(UIFontDescriptorSymbolicTraits)traits scale:(CGFloat)scale
{
    if (self.dinamicType)
    {
        UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | traits];
        return [UIFont fontWithDescriptor:descriptor size:0];
    }
    else
    {
        UIFontDescriptor *descriptor;
        CGFloat fontSize = ceil(self.fontSize * scale);
        if ([[self.fontName lowercaseString] isEqualToString:HPFontManagerSystemFontName])
        {
            UIFont *systemFont = [UIFont systemFontOfSize:fontSize];
            descriptor = systemFont.fontDescriptor;
        }
        else
        {
            descriptor = [UIFontDescriptor fontDescriptorWithName:self.fontName size:fontSize];
        }
        descriptor = [descriptor fontDescriptorWithSymbolicTraits:descriptor.symbolicTraits | traits];
        return [UIFont fontWithDescriptor:descriptor size:fontSize];
    }
}

- (UIFont*)fontWithTextStyle:(NSString*)textStyle addingTraits:(UIFontDescriptorSymbolicTraits)traits
{
    return [self fontWithTextStyle:textStyle addingTraits:traits scale:1];
}

- (void)invalidateFonts
{
    _noteBodyLineHeight = -1;
    _noteTitleLineHeight = -1;
    
    _archivedNoteBodyFont = nil;
    _archivedNoteTitleFont = nil;
    _barButtonTitleFont = nil;
    _detailFont = nil;
    _indexCellDetailFont = nil;
    _indexCellTitleFont = nil;
    _navigationBarDetailFont = nil;
    _navigationBarTitleFont = nil;
    _noteBodyFont = nil;
    _noteTitleFont = nil;
    _searchBarFont = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HPFontManagerDidChangeFontsNotification object:self];
}

@end
