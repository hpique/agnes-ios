//
//  HPNoteExporter.m
//  Agnes
//
//  Created by Hermes on 21/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteExporter.h"
#import "HPNote.h"
#import "SSZipArchive.h"

@implementation HPNoteExporter

- (void)exportNotes:(NSArray*)notes
               name:(NSString*)name
            success:(void (^)(NSURL *fileURL))successBlock
            failure:(void (^)(NSError *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"export"];

        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyyMMddhhmmssSSSS"];
        NSDate *date = [NSDate date];
        NSString *dateString = [format stringFromDate:date];
        
        exportPath = [exportPath stringByAppendingPathComponent:dateString];
        
        NSError *error;
        if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
        {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:exportPath error:&error];
            if (!success)
            {
                [self handleError:error failure:failureBlock];
                return;
            }
        }
        
        NSString *notesDirectory = [exportPath stringByAppendingPathComponent:@"notes"];
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:notesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success)
        {
            [self handleError:error failure:failureBlock];
            return;
        }
        
        [notes enumerateObjectsUsingBlock:^(HPNote *note, NSUInteger idx, BOOL *stop)
         {
             NSString *filename = [NSString stringWithFormat:@"%@% ld.txt", name, (long)idx + 1];
             NSString *path = [notesDirectory stringByAppendingPathComponent:filename];
             NSError *error = nil;
             BOOL success = [note.text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
             if (!success)
             {
                 [self handleError:error failure:failureBlock];
                 *stop = YES;
             }
         }];
        
        NSString *zipDirectory = [exportPath stringByAppendingPathComponent:@"zip"];
        success = [[NSFileManager defaultManager] createDirectoryAtPath:zipDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success)
        {
            [self handleError:error failure:failureBlock];
            return;
        }
        
        NSString *zipPath = [zipDirectory stringByAppendingPathComponent:@"notes.zip"];
        success = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:notesDirectory];
        if (!success)
        {
            [self handleError:nil failure:failureBlock];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [NSURL fileURLWithPath:zipPath];
            successBlock(url);
        });
        [[NSFileManager defaultManager] removeItemAtPath:notesDirectory error:nil];
    });
}

#pragma mark - Private (background)

- (void)handleError:(NSError*)error failure:(void (^)(NSError *error))failureBlock
{
    NSLog(@"Export notes failed with error %@", [error localizedDescription]);
    if (failureBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
    }
}

@end