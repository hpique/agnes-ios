//
//  HPDataActionController.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPContact : NSObject

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, strong) UIImage *image;

@end

@protocol HPDataActionControllerDelegate;

@interface HPDataActionController : NSObject

@property (nonatomic, weak) id<HPDataActionControllerDelegate> delegate;

- (void)showActionSheetForURL:(NSURL*)url fromRect:(CGRect)rect inView:(UIView*)view;

@end

@protocol HPDataActionControllerDelegate <NSObject>

- (UIViewController*)viewControllerForDataActionController:(HPDataActionController*)dataActionController;

- (void)dataActionController:(HPDataActionController*)dataActionController willAddContact:(HPContact*)contact;

@end
