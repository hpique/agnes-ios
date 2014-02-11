//
//  HPAgnesImageCache.m
//  Agnes
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesImageCache.h"
#import "HPImageCache.h"
#import "HPAttachment.h"
#import "HPData.h"
#import "HPNoteTableViewCell.h"
#import "HPNoteViewController.h"
#import "HPAttachmentManager.h"
#import "HPFontManager.h"
#import "UIImage+hp_utils.h"

static NSString *const HPAgnesImageCacheFormatList = @"list";
static NSString *const HPAgnesImageCacheFormatDetailDefault = @"detail";
static NSString *const HPAgnesImageCacheFormatDetailCharacter = @"character";

@interface HPAttachment(HPImageCacheEntity)<HPImageCacheEntity>

@end

@implementation HPAgnesImageCache {
    HPImageCacheFormat *_listFormat;
    HPImageCacheFormat *_characterFormat;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        HPImageCache *cache = [HPImageCache sharedCache];
        {
            _listFormat = [[HPImageCacheFormat alloc] initWithName:HPAgnesImageCacheFormatList];
            CGFloat length = [HPNoteTableViewCell thumbnailViewWidth];
            _listFormat.size = CGSizeMake(length, length);
            _listFormat.allowUpscaling = YES;
            _listFormat.scaleMode = HPImageCacheFormatScaleModeAspectFill;
            [cache registerFormat:_listFormat];
        }
        const CGFloat minimumNoteWidth = [HPNoteViewController minimumNoteWidth];
        {
            HPImageCacheFormat *format = [[HPImageCacheFormat alloc] initWithName:HPAgnesImageCacheFormatDetailDefault];
            format.size = CGSizeMake(minimumNoteWidth, minimumNoteWidth);
            format.scaleMode = HPImageCacheFormatScaleModeAspectFit;
            [cache registerFormat:format];
        }
        {
            _characterFormat = [[HPImageCacheFormat alloc] initWithName:HPAgnesImageCacheFormatDetailCharacter];
            const CGFloat height = [HPFontManager sharedManager].noteBodyLineHeight;
            _characterFormat.size = CGSizeMake(minimumNoteWidth, height);
            _characterFormat.scaleMode = HPImageCacheFormatScaleModeAspectFit;
            [cache registerFormat:_characterFormat];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attachmentsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPAttachmentManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPAttachmentManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
}

+ (HPAgnesImageCache*)sharedCache
{
    static HPAgnesImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPAgnesImageCache alloc] init];
    });
    return instance;
}

- (UIImage*)noteDetailImageForAttachment:(HPAttachment*)attachment
{
    NSString *formatName = nil;
    switch (attachment.mode) {
        case HPAttachmentModeDefault:
            formatName = HPAgnesImageCacheFormatDetailDefault;
            break;
        case HPAttachmentModeCharacter:
            formatName = HPAgnesImageCacheFormatDetailCharacter;
            break;
    }
    return [[HPImageCache sharedCache] imageForEntity:attachment formatName:formatName];
}

- (BOOL)retrieveListImageForAttachment:(HPAttachment*)attachment completionBlock:(void(^)(HPAttachment *attachment, UIImage *image))completionBlock
{
    return [[HPImageCache sharedCache] retrieveImageForEntity:attachment formatName:HPAgnesImageCacheFormatList completionBlock:^(id<HPImageCacheEntity> entity, NSString *formatName, UIImage *image) {
        completionBlock(entity, image);
    }];
}

#pragma mark - Notifications

- (void)attachmentsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSSet *deleted = [userInfo objectForKey:NSDeletedObjectsKey];
    HPImageCache *cache = [HPImageCache sharedCache];
    for (HPAttachment *attachment in deleted)
    {
        [cache removeImagesOfEntity:attachment];
    }
}

- (void)didChangeFontsNotification:(NSNotification*)notification
{
    HPImageCache *cache = [HPImageCache sharedCache];
    {
        [cache clearFormatNamed:_listFormat.name];
        CGFloat length = [HPNoteTableViewCell thumbnailViewWidth];
        _listFormat.size = CGSizeMake(length, length);
    }
    {
        const CGFloat height = [HPFontManager sharedManager].noteBodyLineHeight;
        _characterFormat.size = CGSizeMake(_characterFormat.size.width, height);
        [cache clearFormatNamed:_characterFormat.name];
    }
}

@end

@implementation HPAttachment(HPImageCacheEntity)

- (NSString*)imageCacheId
{
    return self.uuid;
}

- (NSData*)imageCacheData
{
    return self.data.data;
}

@end
