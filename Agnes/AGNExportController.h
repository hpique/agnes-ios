//
//  AGNExportController.h
//  Agnes
//
//  Created by Hermés Piqué on 12/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

@import UIKit;
@class HPNavigationBarToggleTitleView;

@protocol AGNExportControllerDelegate;

@interface AGNExportController : NSObject

@property (nonatomic, weak) id<AGNExportControllerDelegate> delegate;

- (void)exportNotes:(NSArray*)notes title:(NSString*)title statusView:(HPNavigationBarToggleTitleView*)statusView;

@end

@protocol AGNExportControllerDelegate<NSObject>

- (UIViewController*)viewControllerForExportController:(AGNExportController*)exportController;

@end
