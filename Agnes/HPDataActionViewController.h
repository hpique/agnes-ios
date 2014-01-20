//
//  HPDataActionViewController.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPDataActionViewController : UIViewController<UIActionSheetDelegate>

- (void)showActionSheetForURL:(NSURL*)url;

@end
