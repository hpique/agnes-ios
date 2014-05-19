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
#import "AGNNoteViewController.h"
#import "HPAttachmentManager.h"
#import "HPFontManager.h"
#import "UIImage+hp_utils.h"

static NSString *const HPAgnesImageCacheFormatDetailDefault = @"detail";
static NSString *const HPAgnesImageCacheFormatDetailCharacter = @"character";
static NSString *const HPAgnesImageCacheFormatThumbnail = @"thumbnail";

@implementation HPAgnesImageCache {
    HNKCacheFormat *_characterFormat;
    HNKCacheFormat *_thumbnailFormat;
}

@synthesize thumbnailFormat = _thumbnailFormat;

- (id)init
{
    self = [super init];
    if (self)
    {
        HNKCache *cache = [HNKCache sharedCache];
        const CGFloat minimumNoteWidth = [AGNNoteViewController minimumNoteWidth];
        {
            HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:HPAgnesImageCacheFormatDetailDefault];
            format.size = CGSizeMake(minimumNoteWidth, minimumNoteWidth);
            format.scaleMode = HNKScaleModeAspectFit;
            format.diskCapacity = 100 * 1024 * 1024;
            format.compressionQuality = AGNAttachmentImageQuality;
            format.preloadPolicy = HNKPreloadPolicyLastSession;
            [cache registerFormat:format];
        }
        {
            _characterFormat = [[HNKCacheFormat alloc] initWithName:HPAgnesImageCacheFormatDetailCharacter];
            const CGFloat height = [HPFontManager sharedManager].fontForNoteBody.pointSize;
            _characterFormat.size = CGSizeMake(minimumNoteWidth, height);
            _characterFormat.scaleMode = HNKScaleModeAspectFit;
            _characterFormat.diskCapacity = 1 * 1024 * 1024;
            [cache registerFormat:_characterFormat];
        }
        {
            _thumbnailFormat = [[HNKCacheFormat alloc] initWithName:HPAgnesImageCacheFormatThumbnail];
            CGFloat length = [HPNoteTableViewCell thumbnailViewWidth];
            _thumbnailFormat.size = CGSizeMake(length, length);
            _thumbnailFormat.allowUpscaling = YES;
            _thumbnailFormat.scaleMode = HNKScaleModeAspectFill;
            _thumbnailFormat.diskCapacity = 25 * 1024 * 1024;
            _thumbnailFormat.compressionQuality = AGNAttachmentImageQuality;
            _thumbnailFormat.preloadPolicy = HNKPreloadPolicyLastSession;
            [cache registerFormat:_thumbnailFormat];
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
    return [[HNKCache sharedCache] imageForEntity:attachment formatName:formatName error:nil];
}

- (void)prePopulateCacheWithThumbnailOfImageNamed:(NSString*)name atttachment:(HPAttachment*)attachment
{
    NSString *extension = [name pathExtension];
    name = [name stringByDeletingPathExtension];
    name = [NSString stringWithFormat:@"%@-thumbnail", name];
    name = [name stringByAppendingPathExtension:extension];
    UIImage *image = [UIImage imageNamed:name];
    [[HNKCache sharedCache] setImage:image forKey:attachment.cacheKey formatName:_thumbnailFormat.name];
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
        [cache removeImagesOfFormatNamed:_thumbnailFormat.name];
        const CGFloat length = [HPNoteTableViewCell thumbnailViewWidth];
        _thumbnailFormat.size = CGSizeMake(length, length);
    }
    {
        const CGFloat height = [HPFontManager sharedManager].fontForNoteBody.pointSize;
        _characterFormat.size = CGSizeMake(_characterFormat.size.width, height);
        [cache removeImagesOfFormatNamed:_characterFormat.name];
    }
}

@end

@implementation HPAttachment(HPImageCacheEntity)

- (NSString*)cacheKey
{
    return self.uuid;
}

- (NSData*)cacheOriginalData
{
    return self.data.data;
}

- (UIImage*)cacheOriginalImage { return nil; }

@end
