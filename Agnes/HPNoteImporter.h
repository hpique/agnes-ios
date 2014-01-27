//
//  HPNoteImporter.h
//  Agnes
//
//  Created by Hermes on 27/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPNoteImporter : NSObject

+ (HPNoteImporter*)sharedImporter;

- (void)startWatching;

@end
