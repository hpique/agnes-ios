//
//  HPAgnesNavigationController.m
//  Agnes
//
//  Created by Hermes on 28/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesNavigationController.h"
#import "HPPreferencesManager.h"
#import "HPFontManager.h"

@interface HPAgnesNavigationController ()

@end

@implementation HPAgnesNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [super initWithRootViewController:rootViewController])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
}

#pragma mark - Actions

- (void)didChangePreferences:(NSNotification*)notification
{
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    [preferences styleNavigationBar:self.navigationBar];
}

@end
