//
//  HPAgnesNavigationController.m
//  Agnes
//
//  Created by Hermes on 28/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesNavigationController.h"
#import "AGNPreferencesManager.h"
#import "HPFontManager.h"

@interface HPAgnesNavigationController ()

@end

@implementation HPAgnesNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [super initWithRootViewController:rootViewController])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:AGNPreferencesManagerDidChangePreferencesNotification object:[AGNPreferencesManager sharedManager]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNPreferencesManagerDidChangePreferencesNotification object:[AGNPreferencesManager sharedManager]];
}

#pragma mark - Actions

- (void)didChangePreferences:(NSNotification*)notification
{
    AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
    [preferences styleNavigationBar:self.navigationBar];
}

@end
