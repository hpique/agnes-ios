//
//  HPImageCache.h
//  Agnes
//
//  Created by Hermes on 10/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HPAttachment;

@protocol HPImageCacheEntity;
@class HPImageCacheFormat;

@interface HPImageCache : NSObject

+ (HPImageCache*)sharedCache;

- (void)registerFormat:(HPImageCacheFormat*)format;

- (UIImage*)imageForEntity:(id<HPImageCacheEntity>)entity formatName:(NSString *)formatName;

- (BOOL)retrieveImageForEntity:(id<HPImageCacheEntity>)entity formatName:(NSString *)formatName completionBlock:(void(^)(id<HPImageCacheEntity> entity, NSString *formatName, UIImage *image))completionBlock;

- (void)clearFormatNamed:(NSString*)formatName;

- (void)removeImagesOfEntity:(id<HPImageCacheEntity>)entity;

@end

@protocol HPImageCacheEntity <NSObject>

@property (nonatomic, readonly) NSString *imageCacheId;
@property (nonatomic, readonly) NSData *imageCacheData;

@end

typedef NS_ENUM(NSInteger, HPImageCacheFormatScaleMode)
{
    HPImageCacheFormatScaleModeFill = UIViewContentModeScaleToFill,
    HPImageCacheFormatScaleModeAspectFit = UIViewContentModeScaleAspectFit,
    HPImageCacheFormatScaleModeAspectFill = UIViewContentModeScaleAspectFill
};

@interface HPImageCacheFormat : NSObject

@property (nonatomic, assign) BOOL allowUpscaling;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) HPImageCacheFormatScaleMode scaleMode;

// TODO: Remove images when maximum is reached
@property (nonatomic, assign) NSUInteger maxDiskBytes;
@property (nonatomic, readonly) NSUInteger usedDiskBytes;

- (id)initWithName:(NSString*)name;

@end
