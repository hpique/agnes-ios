//
//  HPNoteImporter.m
//  Agnes
//
//  Created by Hermes on 27/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteImporter.h"
#import "HPNoteManager.h"
#import "MHWDirectoryWatcher.h"
#import "SSZipArchive.h"

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

#pragma mark - Private

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
        for (NSString *fileName in txtContents)
        {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            BOOL success = [self importNoteAtPath:filePath error:error];
            if (!success) return NO;
        }
    }
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'zip'"];
        NSArray *zipContents = [allContents filteredArrayUsingPredicate:predicate];
        for (NSString *fileName in zipContents)
        {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            BOOL success = [self importNotesFromArchiveAtPath:filePath error:error];
            if (!success) return NO;
        }
    }
    return YES;
}

- (BOOL)importNoteAtPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    HPNoteManager *noteManager = [HPNoteManager sharedManager];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    if (!text)
    {
        NSLog(@"Read file failed with error %@", [*error localizedDescription]);
        return NO;
    }
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:error];
    if (!attributes)
    {
        NSLog(@"Get attributes failed with error %@", [*error localizedDescription]);
        return NO;
    }
    NSDate *createdAt = [attributes objectForKey:NSFileCreationDate];
    NSDate *modifiedAt = [attributes objectForKey:NSFileModificationDate];
    
    BOOL removed = [fileManager removeItemAtPath:path error:error];
    if (!removed)
    {
        NSLog(@"Remove file failed with error %@", [*error localizedDescription]);
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        [noteManager importNoteWithText:text createdAt:createdAt modifiedAt:modifiedAt];
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
    
    success = [self importNotesAtPath:importPath error:error];
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

@end
