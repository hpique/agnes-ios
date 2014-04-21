//
//  AGNGalleryController.h
//  Agnes
//
//  Created by Hermés Piqué on 21/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

@import UIKit;

@protocol AGNGalleryControllerDelegate;

@interface AGNGalleryController : NSObject

@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, weak) UIViewController *viewController;

@property (nonatomic, weak) id<AGNGalleryControllerDelegate> delegate;

- (void)presentAttachmentAtIndex:(NSUInteger)characterIndex;

@end

@protocol AGNGalleryControllerDelegate<NSObject>

- (void)galleryController:(AGNGalleryController*)galleryController didTrashAttachmentAtIndex:(NSUInteger)characterIndex;

@end
