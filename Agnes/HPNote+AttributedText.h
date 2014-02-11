//
//  HPNote+AttributedText.h
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"

@interface HPAnimatedTextAttachment : NSTextAttachment

@property (nonatomic, assign) BOOL animating;

@property (nonatomic, assign) CGFloat animationProgress;

@end

@interface HPNote (AttributedText)

@property (nonatomic, readonly) NSAttributedString *attributedText;

+ (NSParagraphStyle*)paragraphStyleOfAttributedText:(NSAttributedString*)attributedText paragraphRange:(NSRange)paragraphRange;

@end

@interface NSAttributedString(HPNote)

- (NSArray*)hp_attachments;

- (UIImage*)hp_imageOfFirstAttachment;

- (NSString*)hp_valueOfLinkWithScheme:(NSString*)scheme;

@end
