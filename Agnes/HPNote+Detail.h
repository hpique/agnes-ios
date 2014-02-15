//
//  HPNote+Detail.h
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

@interface HPNote (Detail)

@property (nonatomic, readonly) NSAttributedString *attributedText;

- (BOOL)isEmptyInTag:(HPTag*)tag;

+ (NSParagraphStyle*)paragraphStyleOfAttributedText:(NSAttributedString*)attributedText paragraphRange:(NSRange)paragraphRange;

@end

@interface NSAttributedString(HPNote)

- (NSArray*)hp_attachments;

- (UIImage*)hp_imageOfFirstAttachment;

- (NSString*)hp_valueOfLinkWithScheme:(NSString*)scheme;

@end

@interface NSString(HPNote)

- (BOOL)hp_isEmptyInTag:(HPTag*)tag;

- (NSString*)hp_tagInRange:(NSRange)selectedRange enclosing:(BOOL)enclosing tagRange:(NSRange*)foundRange;

@end
