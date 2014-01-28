//
//  HPNoteAction.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteAction.h"
#import "NSString+hp_utils.h"

@interface HPNoteActionReplace : HPNoteAction

@property (nonatomic, copy) NSString *target;
@property (nonatomic, copy) NSString* (^replacementBlock)();

+ (HPNoteActionReplace*)replaceActionWithTarget:(NSString*)target replacementBlock:(NSString* (^)())replacementBlock;

@end

@implementation HPNoteAction

- (void)apply:(HPNote*)note text:(NSMutableString*)mutableText view:(id)view {}

+ (NSArray*)willDisplayNoteActions
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
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-break}" replacementBlock:^NSString *{
            return @"";
        }]];
        instance = actions;
    });
    return instance;
}

+ (void)willDisplayNote:(HPNote*)note text:(NSMutableString*)mutableText view:(id)view
{
    NSArray *actions = [HPNoteAction willDisplayNoteActions];
    for (HPNoteAction *action in actions)
    {
        [action apply:note text:mutableText view:view];
    }
}

+ (void)willEditNote:(HPNote*)note editor:(UITextView*)textView
{
    
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

- (void)apply:(HPNote*)note text:(NSMutableString*)mutableText view:(id)view
{
    __block NSString *replacement = nil; // Do not calculate if there are no matches
    [mutableText hp_enumerateOccurrencesOfString:self.target options:NSLiteralSearch usingBlock:^(NSRange matchRange, BOOL *stop) {
        if (!replacement) replacement = self.replacementBlock();
        [mutableText replaceCharactersInRange:matchRange withString:replacement];
    }];
}

@end
