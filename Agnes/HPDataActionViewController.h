//
//  HPDataActionViewController.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPAgnesViewController.h"

@interface HPDataActionViewController : HPAgnesViewController<UIActionSheetDelegate>

- (void)addContactWithEmail:(NSString*)email phoneNumber:(NSString*)phoneNumber image:(UIImage*)image;

- (void)showActionSheetForURL:(NSURL*)url fromRect:(CGRect)rect inView:(UIView*)view;

@end
