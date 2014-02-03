//
//  HPNote+AttributedText.h
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"

@interface HPNote (AttributedText)

- (NSAttributedString*)attributedTextForWidth:(CGFloat)width;

@end
