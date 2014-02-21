//
//  HPNoteImporter.m
//  Agnes
//
//  Created by Hermes on 27/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteImporter.h"
#import "HPNoteManager.h"
#import "HPAttachment.h"
#import "HPAttachment+Template.h"
#import "HPData.h"
#import "MHWDirectoryWatcher.h"
#import "SSZipArchive.h"
#import "NSNotification+hp_status.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation HPNoteImporter {
    MHWDirectoryWatcher *_directoryWatcher;
}

+ (HPNoteImporter*)sharedImporter
{
    static HPNoteImporter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPNoteImporter alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init])
    {
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _directoryWatcher = [MHWDirectoryWatcher directoryWatcherAtPath:documentsPath startImmediately:NO callback:^{
            [self didUpdateDocumentsAtPath:documentsPath];
        }];
    }
    return self;
}

- (void)startWatching
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    [self importNotesAtPath:documentsPath];
}

#pragma mark - Actions

- (void)didUpdateDocumentsAtPath:(NSString*)path
{
    [self importNotesAtPath:path];
}

#pragma mark - Private (background)

- (NSArray*)attachmentsInText:(NSMutableString*)text directory:(NSString*)directory
{
    NSRegularExpression *regex = [HPAttachment templateRegex];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *attachments = [NSMutableArray array];
    NSArray *matches = [regex matchesInString:text options:kNilOptions range:NSMakeRange(0, text.length)];
    for (NSInteger i = matches.count - 1; i >= 0; i--)
    {
        NSTextCheckingResult *result = matches[i];
        NSString *filename = [HPAttachment imageNameFromTemplate:text match:result];
        NSString *path = [directory stringByAppendingPathComponent:filename];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (!data) break;
        
        UIImage *image = [UIImage imageWithData:data];
        if (!image) break;
        HPAttachment *attachment = [HPAttachment attachmentWithImage:image context:nil];
        
        NSError *error;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
        if (!attributes)
        {
            NSLog(@"Get attributes failed with error %@", [error localizedDescription]);
            break;
        }
        attachment.createdAt = [attributes objectForKey:NSFileCreationDate];
        attachment.mode = [HPAttachment modeFromTemplate:text match:result];
        [attachments insertObject:attachment atIndex:0]; // Reverse order
        BOOL removed = [fileManager removeItemAtPath:path error:&error];
        if (!removed)
        {
            NSLog(@"Remove file failed with error %@", [error localizedDescription]);
        }
        
        NSRange matchRange = [result rangeAtIndex:0];
        [text replaceCharactersInRange:matchRange withString:[HPNote attachmentString]];
    }
    return attachments;
}

- (void)importNotesAtPath:(NSString*)path
{
    [_directoryWatcher stopWatching];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self importNotesAtPath:path error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_directoryWatcher startWatching];
        });
    });
}

- (BOOL)importNotesAtPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allContents = [fileManager contentsOfDirectoryAtPath:path error:error];
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'txt'"];
        NSArray *txtContents = [allContents filteredArrayUsingPredicate:predicate];
        if (txtContents.count > 0)
        {
            [self postStatus:NSLocalizedString(@"Importing notes", @"") transient:YES];
            __block BOOL success = YES;
            [txtContents enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
                NSString *format = NSLocalizedString(@"Importing note %ld of %ld", @"");
                NSString *message = [NSString stringWithFormat:format, (long)idx + 1, txtContents.count];
                [self postStatus:message transient:YES];
                
                NSString *filePath = [path stringByAppendingPathComponent:fileName];
                success = [self importNoteAtPath:filePath error:error];
                if (!success) *stop = YES;
            }];
            if (success)
            {
                [self postStatus:NSLocalizedString(@"Import finished", @"") transient:YES];
            }
            else
            {
                [self postStatus:NSLocalizedString(@"Import finished with errors", @"") transient:YES];
            }
        }
    }
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'zip'"];
        NSArray *zipContents = [allContents filteredArrayUsingPredicate:predicate];
        for (NSString *fileName in zipContents)
        {
            [self postStatus:NSLocalizedString(@"Importing from archive", @"") transient:YES];
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            BOOL success = [self importNotesFromArchiveAtPath:filePath error:error];
            if (success)
            {
                [self postStatus:NSLocalizedString(@"Import finished", @"") transient:YES];
            }
            else
            {
                [self postStatus:NSLocalizedString(@"Import finished with errors", @"") transient:YES];
            }
        }
    }
    return YES;
}

- (BOOL)importNoteBatchAtPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *noteImports = [NSMutableArray array];
    NSArray *allContents = [fileManager contentsOfDirectoryAtPath:path error:error];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'txt'"];
    NSArray *txtContents = [allContents filteredArrayUsingPredicate:predicate];
    [txtContents enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        NSString *format = NSLocalizedString(@"Preparing note %ld of %ld", @"");
        NSString *message = [NSString stringWithFormat:format, (long)idx + 1, txtContents.count];
        [self postStatus:message transient:YES];
        
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        HPNoteImport *noteImport = [self noteImportFromPath:filePath error:error];
        BOOL removed = [fileManager removeItemAtPath:filePath error:error];
        if (!removed)
        {
            NSLog(@"Remove file failed with error %@", [*error localizedDescription]);
        }
        if (!noteImport)
        {
            *stop = YES;
            return;
        }
        [noteImports addObject:noteImport];
    }];
    [self postStatus:NSLocalizedString(@"Importing notes", @"") transient:YES];
    
    HPNoteManager *noteManager = [HPNoteManager sharedManager];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [noteManager importNotes:noteImports];
    });
    return YES;
}

- (BOOL)importNoteAtPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    HPNoteImport *noteImport = [self noteImportFromPath:path error:error];
    BOOL removed = [fileManager removeItemAtPath:path error:error];
    if (!removed)
    {
        NSLog(@"Remove file failed with error %@", [*error localizedDescription]);
    }
    HPNoteManager *noteManager = [HPNoteManager sharedManager];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [noteManager importNotes:@[noteImport]];
    });
    return YES;
}

- (BOOL)importNotesFromArchiveAtPath:(NSString*)path error:(NSError**)error
{
    NSString *importPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"import"];
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMddhhmmssSSSS"];
    NSDate *date = [NSDate date];
    NSString *dateString = [format stringFromDate:date];
    
    importPath = [importPath stringByAppendingPathComponent:dateString];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:importPath])
    {
        BOOL success = [fileManager removeItemAtPath:importPath error:error];
        if (!success)
        {
            NSLog(@"Remove previous import directory failed with error %@", [*error localizedDescription]);
            return NO;
        }
    }
    BOOL success = [fileManager createDirectoryAtPath:importPath withIntermediateDirectories:YES attributes:nil error:error];
    if (!success)
    {
        NSLog(@"Create import directory failed with error %@", [*error localizedDescription]);
        return NO;
    }
    success = [SSZipArchive unzipFileAtPath:path toDestination:importPath];
    if (!success) return NO;
    
    success = [self importNoteBatchAtPath:importPath error:error];
    BOOL removed = [fileManager removeItemAtPath:importPath error:error];
    if (!removed)
    {
        NSLog(@"Remove import directory failed with error %@", [*error localizedDescription]);
    }
    removed = [fileManager removeItemAtPath:path error:error];
    if (!removed)
    {
        NSLog(@"Remove file failed with error %@", [*error localizedDescription]);
    }
    return success;
}

- (HPNoteImport*)noteImportFromPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    if (!text)
    {
        NSLog(@"Read file failed with error %@", [*error localizedDescription]);
        return nil;
    }
    NSMutableString *mutableText = text.mutableCopy;
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSArray *attachments = [self attachmentsInText:mutableText directory:directory];
    
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:error];
    if (!attributes)
    {
        NSLog(@"Get attributes failed with error %@", [*error localizedDescription]);
        return nil;
    }
    
    NSDate *createdAt = [attributes objectForKey:NSFileCreationDate];
    NSDate *modifiedAt = [attributes objectForKey:NSFileModificationDate];

    HPNoteImport *noteImport = [HPNoteImport noteImportWithText:mutableText createdAt:createdAt modifiedAt:modifiedAt attachments:attachments];
    return noteImport;
}

- (void)postStatus:(NSString*)message transient:(BOOL)transient
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] hp_postStatus:message transient:transient object:self];
    });
}

@end
