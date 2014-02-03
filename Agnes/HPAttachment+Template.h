//
//  HPAttachment+Template.h
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAttachment.h"

@interface HPAttachment (Template)

+ (NSRegularExpression*)templateRegex;

+ (NSString*)imageNameFromTemplate:(NSString*)template match:(NSTextCheckingResult*)match;

+ (HPAttachmentMode)modeFromTemplate:(NSString*)template match:(NSTextCheckingResult*)match;

- (NSString*)templateWithFilename:(NSString*)filename;

@end
