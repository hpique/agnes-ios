//
//  HPNoteActivityItemSource.m
//  Agnes
//
//  Created by Hermes on 25/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteActivityItemSource.h"
#import "HPNote.h"

static NSString* const HPActivityTypeMail = @"com.apple.UIKit.activity.Mail";

@implementation HPNoteActivityItemSource {
    HPNote *_note;
}

- (id)initWithNote:(HPNote*)note
{
    if (self = [super init])
    {
        _note = note;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return _note.text;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if ([activityType isEqualToString:HPActivityTypeMail])
    {
        return _note.body;
    }
    else
    {
        return _note.text;
    }
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return _note.title;
}

@end
