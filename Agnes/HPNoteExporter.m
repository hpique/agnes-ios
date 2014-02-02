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
#import "HPAttachment.h"
#import "HPData.h"
#import "NSString+hp_utils.h"

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
        
        __block NSError *error;
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
        __block BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:notesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success)
        {
            [self handleError:error failure:failureBlock];
            return;
        }
        
        [notes enumerateObjectsUsingBlock:^(HPNote *note, NSUInteger idx, BOOL *stop)
         {
             NSString *filename = [NSString stringWithFormat:@"%@% ld", name, (long)idx + 1];
             success = [self exportNote:note withName:filename toDirectory:notesDirectory error:&error];
             if (!success) *stop = YES;
         }];
        if (!success)
        {
            [self handleError:error failure:failureBlock];
            return;
        }
        
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

- (BOOL)exportNote:(HPNote*)note withName:(NSString*)name toDirectory:(NSString*)directory error:(NSError**)error
{
    NSMutableString *text = note.text.mutableCopy;
    __block NSInteger attachmentIndex = 0;
    [text hp_enumerateOccurrencesOfString:[HPNote attachmentString] options:kNilOptions usingBlock:^(NSRange matchRange, BOOL *stop) {
        NSString *attachmentFilename = [NSString stringWithFormat:@"%@ attachment %ld.jpg", name, (long)attachmentIndex + 1];
        NSString *replacement = [NSString stringWithFormat:@"{img}%@{/img}", attachmentFilename];
        [text replaceCharactersInRange:matchRange withString:replacement];
        attachmentIndex++;
    }];

    NSString *filename = [name stringByAppendingPathExtension:@"txt"];
    NSString *path = [directory stringByAppendingPathComponent:filename];
    __block  BOOL success = [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error];
    if (!success) return NO;

    NSDictionary* attributes = @{NSFileCreationDate : note.createdAt, NSFileModificationDate : note.modifiedAt};
    success = [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:error];
    if (!success)
    {
        NSLog(@"Set attributes failed with error %@", [*error localizedDescription]);
    }
    
    [note.attachments enumerateObjectsUsingBlock:^(HPAttachment *attachment, NSUInteger idxAttachment, BOOL *stop) {
        NSData *data = attachment.data.data;
        NSString *attachmentFilename = [NSString stringWithFormat:@"%@ attachment %ld.jpg", name, (long)idxAttachment + 1];
        NSString *attachmentPath = [directory stringByAppendingPathComponent:attachmentFilename];
        success = [data writeToFile:attachmentPath atomically:YES];
        if (!success)
        {
            *stop = YES;
        }
        NSDictionary* attributes = @{NSFileCreationDate : attachment.createdAt};
        NSError *error;
        const BOOL didSetAttributes = [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:attachmentPath error:&error];
        if (!didSetAttributes)
        {
            NSLog(@"Set attributes failed with error %@", [error localizedDescription]);
        }
    }];
    return success;
}

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
