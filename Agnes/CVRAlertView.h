//
//  CVRAlertView.h
//  Agnes
//
//  Created by Hermes on 21/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVRAlertView : UIAlertView

- (void)showWithClickBlock:(void(^)(NSInteger buttonIndex))clickBlock;

@end
