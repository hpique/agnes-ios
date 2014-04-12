//
//  AGNExportController.m
//  Agnes
//
//  Created by Hermés Piqué on 12/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNExportController.h"
#import "HPNoteExporter.h"
#import "HPNavigationBarToggleTitleView.h"
@import MessageUI;

@interface AGNExportController ()<MFMailComposeViewControllerDelegate>

@end

@implementation AGNExportController {
    HPNoteExporter *_noteExporter;
    UIDocumentInteractionController *_exportDocumentController;
}

#pragma mark Public

- (void)exportNotes:(NSArray*)notes title:(NSString*)title statusView:(HPNavigationBarToggleTitleView*)statusView;
{
    _noteExporter = [HPNoteExporter new];
    [statusView setSubtitle:NSLocalizedString(@"Preparing notes for export", @"") animated:YES transient:NO];
    
    [_noteExporter exportNotes:notes name:title progress:^(NSString *message) {
        [statusView setSubtitle:message animated:NO transient:NO];
    } success:^(NSURL *fileURL) {
        [statusView setSubtitle:@"" animated:YES transient:NO];
        [self exportFileURL:fileURL title:title];
    } failure:^(NSError *error) {
        [statusView setSubtitle:@"" animated:YES transient:NO];
        NSString *message = error ? [error localizedDescription] : NSLocalizedString(@"Unknown error", @"");
        [self alertErrorWithTitle:NSLocalizedString(@"Export Failed", @"") message:message];
        _noteExporter = nil;
    }];
}

#pragma mark Private

- (void)alertErrorWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
}

- (void)exportFileURL:(NSURL*)fileURL title:(NSString*)title
{
    if ([MFMailComposeViewController canSendMail])
    {
        NSString *path = fileURL.path;
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        NSAssert(attributes, @"Failed to get file attributes with error %@", error.localizedDescription);
        unsigned long long fileSize = attributes.fileSize;
        static unsigned long long MaxFileSize = 8 * 1024 * 1024; // 8MB
        if (fileSize < MaxFileSize)
        {
            NSData *data = [NSData dataWithContentsOfURL:fileURL];
            if (data)
            {
                MFMailComposeViewController *vc = [MFMailComposeViewController new];
                vc.mailComposeDelegate = self;
                NSString *subject = [NSString stringWithFormat:NSLocalizedString(@"%@ notes", @""), title];
                [vc setSubject:subject];
                [vc addAttachmentData:data mimeType:@"application/zip" fileName:@"notes.zip"];
                UIViewController *viewController = [self.delegate viewControllerForExportController:self];
                [viewController presentViewController:vc animated:YES completion:nil];
            }
            else
            {
                [self alertErrorWithTitle:NSLocalizedString(@"Export Failed", @"") message:NSLocalizedString(@"Unable to read zip file", @"")];
            }
        }
        else
        {
            [self exportNotesWithDocumentControllerFromFileURL:fileURL
                                                         title:title
                                                  errorMessage:NSLocalizedString(@"A documents app like Google Drive or Dropbox is required for large exports", @"")];
        }
    }
    else
    {
        [self exportNotesWithDocumentControllerFromFileURL:fileURL
                                                     title:title
                                              errorMessage:NSLocalizedString(@"A configured email client is required", @"")];
    }
    _noteExporter = nil;
}

- (void)exportNotesWithDocumentControllerFromFileURL:(NSURL*)fileURL title:(NSString*)title errorMessage:(NSString*)errorMessage
{
    _exportDocumentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    _exportDocumentController.name = [NSString stringWithFormat:NSLocalizedString(@"%@ notes.zip", @""), title];
    UIViewController *viewController = [self.delegate viewControllerForExportController:self];
    BOOL success = [_exportDocumentController presentOpenInMenuFromRect:CGRectZero inView:viewController.view animated:YES];
    if (!success)
    {
        _exportDocumentController = nil;
        [self alertErrorWithTitle:NSLocalizedString(@"Export Failed", @"") message:errorMessage];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    UIViewController *viewController = [self.delegate viewControllerForExportController:self];
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
