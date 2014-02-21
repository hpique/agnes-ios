//
//  HPModelContextImporter.h
//  Agnes
//
//  Created by Hermes on 21/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPModelContextImporter : NSObject

- (void)importNotesAtContext:(NSManagedObjectContext*)fromContext intoContext:(NSManagedObjectContext*)toContext completion:(void(^)())completionBlock;

@end
