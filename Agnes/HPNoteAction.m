//
//  HPNoteAction.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteAction.h"
#import "HPNoteManager.h"
#import "HPPreferencesManager.h"
#import "HPNote.h"
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
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-tintColor}" replacementBlock:^NSString *{
            return [HPPreferencesManager sharedManager].tintColorName;
        }]];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-barTintColor}" replacementBlock:^NSString *{
            return [HPPreferencesManager sharedManager].barTintColorName;
        }]];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-statusBarHidden}" replacementBlock:^NSString *{
            return [HPPreferencesManager sharedManager].statusBarHidden ? @"yes" : @"no";
        }]];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-dynamicType}" replacementBlock:^NSString *{
            return [HPPreferencesManager sharedManager].dynamicType ? @"yes" : @"no";
        }]];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-fontName}" replacementBlock:^NSString *{
            return [HPPreferencesManager sharedManager].fontName;
        }]];
        [actions addObject:[HPNoteActionReplace replaceActionWithTarget:@"{$agnes-fontSize}" replacementBlock:^NSString *{
            return [NSString stringWithFormat:@"%ld", (long)[HPPreferencesManager sharedManager].fontSize];
        }]];
        instance = actions;
    });
    return instance;
}

+ (void)willDisplayNote:(HPNote*)note text:(NSMutableAttributedString*)mutableText view:(id)view
{
    NSArray *actions = [HPNoteAction willDisplayNoteActions];
    for (HPNoteAction *action in actions)
    {
        [action apply:note text:mutableText view:view];
    }
}

+ (BOOL)willEditNote:(HPNote*)note text:(NSMutableString*)mutableText editor:(UITextView*)textView
{
    if (note.isSystem)
    {
        [[HPPreferencesManager sharedManager] applyPreferences:mutableText];
        [mutableText deleteCharactersInRange:NSMakeRange(0, mutableText.length)];
        [mutableText appendString:note.text];
        return YES;
    }
    return NO;
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

- (void)apply:(HPNote*)note text:(NSMutableAttributedString*)mutableText view:(id)view
{
    __block NSString *replacement = nil; // Do not calculate if there are no matches
    NSString *text = mutableText.string;
    [text hp_enumerateOccurrencesOfString:self.target options:NSLiteralSearch usingBlock:^(NSRange matchRange, BOOL *stop) {
        if (!replacement) replacement = self.replacementBlock();
        [mutableText replaceCharactersInRange:matchRange withString:replacement];
    }];
}

@end

@implementation HPNote(Action)

- (BOOL)canAutosave
{
    return !(self.isSystem);
}

- (BOOL)isSystem
{
    return [[HPNoteManager sharedManager] isSystemNote:self];
}

@end