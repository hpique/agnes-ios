//
//  HPNoteAction.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteAction.h"

@interface HPNoteActionReplace : HPNoteAction

@property (nonatomic, copy) NSString *target;
@property (nonatomic, copy) NSString* (^replacementBlock)();

+ (HPNoteActionReplace*)replaceActionWithTarget:(NSString*)target replacementBlock:(NSString* (^)())replacementBlock;

@end

@implementation HPNoteAction

- (void)apply:(HPNote *)note editableText:(NSMutableString *)editableText {}

+ (NSArray*)preActions
{
    static NSArray *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *actions = [NSMutableArray array];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-appName}" replacementBlock:^NSString *{
            return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        }]];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-appVersion}" replacementBlock:^NSString *{
            return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        }]];
        instance = actions;
    });
    return instance;
}

+ (void)applyPreActions:(HPNote*)note editableText:(NSMutableString*)editableText
{
    NSArray *actions = [HPNoteAction preActions];
    for (HPNoteAction *action in actions)
    {
        [action apply:note editableText:editableText];
    }
}

@end

@implementation HPNoteActionReplace

+ (HPNoteActionReplace*)replaceActionWithTarget:(NSString*)target replacementBlock:(NSString* (^)())replacementBlock
{
    HPNoteActionReplace *action = [HPNoteActionReplace new];
    action.target = target;
    action.replacementBlock = replacementBlock;
    return action;
}

- (void)apply:(HPNote *)note editableText:(NSMutableString *)editableText
{
    NSString *replacement = self.replacementBlock();
    [editableText replaceOccurrencesOfString:self.target withString:replacement options:NSLiteralSearch range:NSMakeRange(0, editableText.length)];
}

@end
