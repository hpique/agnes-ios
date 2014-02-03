//
//  HPAttachment+Template.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAttachment+Template.h"

@implementation HPAttachment (Template)

+ (NSRegularExpression*)templateRegex
{
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static NSString *attachmentPattern = @"\\{img(?: mode=\"(.+)\")?\\}(.+)\\{/img\\}";
        regex = [NSRegularExpression regularExpressionWithPattern:attachmentPattern options:kNilOptions error:nil];
    });
    return regex;
}

+ (NSString*)imageNameFromTemplate:(NSString*)template match:(NSTextCheckingResult*)match
{
    const NSRange imageNameRange = [match rangeAtIndex:2];
    NSString *imageName = [template substringWithRange:imageNameRange];
    return imageName;
}

+ (HPAttachmentMode)modeFromTemplate:(NSString*)template match:(NSTextCheckingResult*)match
{
    HPAttachmentMode mode = HPAttachmentModeDefault;
    NSRange modeRange = [match rangeAtIndex:1];
    if (modeRange.location != NSNotFound)
    {
        NSString *modeString = [template substringWithRange:modeRange];
        mode = [modeString integerValue];
    }
    return mode;
}

- (NSString*)templateWithFilename:(NSString*)filename
{
    NSString *modeString = self.mode == HPAttachmentModeDefault ? @"" : [NSString stringWithFormat:@" mode=\"%d\"", self.mode];
    NSString *template = [NSString stringWithFormat:@"{img%@}%@{/img}", modeString, filename];
    return template;
}

@end
