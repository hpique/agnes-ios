//
//  HPAgnesImageCache.m
//  Agnes
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesImageCache.h"
#import "HPData.h"
#import "HPNoteTableViewCell.h"
#import "HPNoteViewController.h"
#import "HPAttachmentManager.h"
#import "HPFontManager.h"
#import "UIImage+hp_utils.h"

static NSString *const HPAgnesImageCacheFormatList = @"list";
static NSString *const HPAgnesImageCacheFormatDetailDefault = @"detail";
static NSString *const HPAgnesImageCacheFormatDetailCharacter = @"character";

@implementation HPAgnesImageCache {
    HNKCacheFormat *_listFormat;
    HNKCacheFormat *_characterFormat;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        HNKCache *cache = [HNKCache sharedCache];
        {
            _listFormat = [[HNKCacheFormat alloc] initWithName:HPAgnesImageCacheFormatList];
            CGFloat length = [HPNoteTableViewCell thumbnailViewWidth];
            _listFormat.size = CGSizeMake(length, length);
            _listFormat.allowUpscaling = YES;
            _listFormat.scaleMode = HNKScaleModeAspectFill;
            _listFormat.diskCapacity = 25 * 1024 * 1024;
            _listFormat.compressionQuality = 0.75;
            [cache registerFormat:_listFormat];
        }
        const CGFloat minimumNoteWidth = [HPNoteViewController minimumNoteWidth];
        {
            HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:HPAgnesImageCacheFormatDetailDefault];
            format.size = CGSizeMake(minimumNoteWidth, minimumNoteWidth);
            format.scaleMode = HNKScaleModeAspectFit;
            format.diskCapacity = 100 * 1024 * 1024;
            format.compressionQuality = 0.75;
            [cache registerFormat:format];
        }
        {
            _characterFormat = [[HNKCacheFormat alloc] initWithName:HPAgnesImageCacheFormatDetailCharacter];
            const CGFloat height = [HPFontManager sharedManager].noteBodyLineHeight;
            _characterFormat.size = CGSizeMake(minimumNoteWidth, height);
            _characterFormat.scaleMode = HNKScaleModeAspectFit;
            _characterFormat.diskCapacity = 1 * 1024 * 1024;
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
    return [[HNKCache sharedCache] imageForEntity:attachment formatName:formatName];
}

- (BOOL)retrieveListImageForAttachment:(HPAttachment*)attachment completionBlock:(void(^)(HPAttachment *attachment, UIImage *image))completionBlock
{
    return [[HNKCache sharedCache] retrieveImageForEntity:attachment formatName:HPAgnesImageCacheFormatList completionBlock:^(id<HNKCacheEntity> entity, NSString *formatName, UIImage *image) {
        completionBlock(entity, image);
    }];
}

#pragma mark - Notifications

- (void)attachmentsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSSet *deleted = [userInfo objectForKey:NSDeletedObjectsKey];
    HNKCache *cache = [HNKCache sharedCache];
    for (HPAttachment *attachment in deleted)
    {
        [cache removeImagesOfEntity:attachment];
    }
}

- (void)didChangeFontsNotification:(NSNotification*)notification
{
    HNKCache *cache = [HNKCache sharedCache];
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

- (NSString*)cacheId
{
    return self.uuid;
}

- (NSData*)cacheOriginalData
{
    return self.data.data;
}

- (UIImage*)cacheOriginalImage { return nil; }

@end
