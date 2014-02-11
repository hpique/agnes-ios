//
//  HPImageCache.m
//  Agnes
//
//  Created by Hermes on 10/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPImageCache.h"
#import "UIImage+hp_utils.h"

static NSString *_rootDirectory;

@implementation HPImageCache {
    NSMutableDictionary *_memoryCaches;
    NSMutableDictionary *_formats;
}

+ (void)initialize
{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    static NSString *cachePathComponent = @"HPImageCache";
    _rootDirectory = [cachesDirectory stringByAppendingPathComponent:cachePathComponent];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _memoryCaches = [NSMutableDictionary dictionary];
        _formats = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (HPImageCache*)sharedCache
{
    static HPImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPImageCache alloc] init];
    });
    return instance;
}

- (UIImage*)imageForEntity:(id<HPImageCacheEntity>)entity formatName:(NSString *)formatName
{
    NSString *entityId = entity.imageCacheId;
    UIImage *image = [self imageForEntityId:entityId format:formatName];
    if (image) return image;
    
    NSLog(@"memory cache miss %@/%@", formatName, entityId);
    
    NSString *path = [self pathForEntityId:entityId withFormat:formatName];
    NSData *imageData = [NSData dataWithContentsOfFile:path];
    if (imageData)
    {
        image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale]; // Do not use imageWithContentsOfFile: as it doesn't consider scale
        if (image) return image;
    }

    NSLog(@"disk cache miss %@/%@", formatName, entityId);
    
    NSData *fullSizeImageData = entity.imageCacheData;
    image = [self resizedImageWithData:fullSizeImageData formatName:formatName];
    [self setImage:image forEntityId:entityId format:formatName];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self saveImage:image entityId:entityId formatNamed:formatName];
    });
    return image;
}

- (BOOL)retrieveImageForEntity:(id<HPImageCacheEntity>)entity formatName:(NSString *)formatName completionBlock:(void(^)(id<HPImageCacheEntity> entity, NSString *format, UIImage *image))completionBlock
{
    NSString *entityId = entity.imageCacheId;
    UIImage *image = [self imageForEntityId:entityId format:formatName];
    if (image)
    {
        completionBlock(entity, formatName, image);
        return YES;
    }
    else
    {
        NSLog(@"memory cache miss %@/%@", formatName, entityId);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *path = [self pathForEntityId:entityId withFormat:formatName];
            NSData *imageData = [NSData dataWithContentsOfFile:path];
            UIImage *image;
            if (imageData && (image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale]))
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completionBlock(entity, formatName, image);
                });
            }
            else
            {
                NSLog(@"disk cache miss %@/%@", formatName, entityId);
                __block NSData *fullSizeImageData = nil;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    fullSizeImageData = entity.imageCacheData;
                });
                UIImage *image = [self resizedImageWithData:fullSizeImageData formatName:formatName];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self setImage:image forEntityId:entityId format:formatName];
                });
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completionBlock(entity, formatName, image);
                });
                [self saveImage:image entityId:entityId formatNamed:formatName];
            }
        });
        return NO;
    }
}

- (void)clearFormatNamed:(NSString*)formatName
{
    NSCache *cache = [_memoryCaches objectForKey:formatName];
    [cache removeAllObjects];
    NSString *directory = [_rootDirectory stringByAppendingPathComponent:formatName];
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtPath:directory error:&error])
    {
        NSLog(@"Failed to remove directory with error %@", error);
    }
}

- (void)registerFormat:(HPImageCacheFormat *)format
{
    [_formats setObject:format forKey:format.name];
}

- (void)removeImagesOfEntity:(id<HPImageCacheEntity>)entity
{
    NSString *entityId = entity.imageCacheId;
    for (NSCache *cache in _memoryCaches)
    {
        [cache removeObjectForKey:entityId];
    }
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *formatDirectories = [fileManager contentsOfDirectoryAtPath:_rootDirectory error:&error];
    if (!formatDirectories)
    {
        NSLog(@"Failed to list directory with error %@", error);
        return;
    }
    for (NSString *pathComponent in formatDirectories)
    {
        NSString *formatPath = [_rootDirectory stringByAppendingPathComponent:pathComponent];
        NSString *imagePath = [formatPath stringByAppendingPathComponent:entityId];
        [fileManager removeItemAtPath:imagePath error:nil];
    }
}

#pragma mark - Private

- (void)saveImage:(UIImage*)image entityId:(NSString*)entityId formatNamed:(NSString*)formatName
{
    NSData *resizedImageData = UIImageJPEGRepresentation(image, 0.75);
    NSString *path = [self pathForEntityId:entityId withFormat:formatName];
    NSError *error;
    if (![resizedImageData writeToFile:path options:kNilOptions error:&error])
    {
        NSLog(@"Failed to write to file %@", error);
    }
}

- (UIImage*)resizedImageWithData:(NSData*)imageData formatName:(NSString*)formatName
{
    UIImage *fullSizeImage = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
    HPImageCacheFormat *format = [_formats objectForKey:formatName];
    const CGSize formatSize = format.size;
    CGSize resizedSize;
    switch (format.scaleMode) {
        case HPImageCacheFormatScaleModeAspectFill:
            resizedSize = [fullSizeImage hp_aspectFillRectForSize:formatSize].size;
            break;
        case HPImageCacheFormatScaleModeAspectFit:
            resizedSize = [fullSizeImage hp_aspectFitRectForSize:formatSize].size;
            break;
        case HPImageCacheFormatScaleModeFill:
            resizedSize = formatSize;
            break;
    }
    if (!format.allowUpscaling)
    {
        CGSize originalSize = fullSizeImage.size;
        if (resizedSize.width > originalSize.width || resizedSize.height > originalSize.height)
        {
            return fullSizeImage;
        }
    }
    UIImage *image = [fullSizeImage hp_imageByScalingToSize:resizedSize];
    return image;
}

- (UIImage*)imageForEntityId:(NSString*)entityId format:(NSString*)format
{
    NSCache *cache = [_memoryCaches objectForKey:format];
    return [cache objectForKey:entityId];
}

- (void)setImage:(UIImage*)image forEntityId:(NSString*)entityId format:(NSString*)format
{
    NSCache *cache = [_memoryCaches objectForKey:format];
    if (!cache)
    {
        cache = [[NSCache alloc] init];
        [_memoryCaches setObject:cache forKey:format];
    }
    return [cache setObject:image forKey:entityId];
}

- (NSString*)pathForEntityId:(NSString*)entityId withFormat:(NSString*)format
{
    NSString *directory = [_rootDirectory stringByAppendingPathComponent:format];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Failed to create directory with error %@", error);
    }
    NSString *path = [directory stringByAppendingPathComponent:entityId];
    return path;
}

@end

@implementation HPImageCacheFormat

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name;
    }
    return self;
}

@end
