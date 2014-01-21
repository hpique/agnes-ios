//
//  HPNoteExporter.h
//  Agnes
//
//  Created by Hermes on 21/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPNoteExporter : NSObject

- (void)exportNotes:(NSArray*)notes
               name:(NSString*)name
            success:(void (^)(NSURL *fileURL))successBlock
            failure:(void (^)(NSError *error))failureBlock;

@end
