//
//  HPDataActionViewController.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPDataActionViewController.h"
#import <MessageUI/MessageUI.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface HPDataActionViewController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@end

@implementation HPDataActionViewController {
    NSURL *_actionSheetURL;
    NSString *_actionSheetPhoneNumber;

    UIActionSheet *_emailActionSheet;
    UIActionSheet *_phoneNumberActionSheet;
    
    NSInteger _emailActionSheetMessageIndex;
    NSInteger _emailActionSheetContactsIndex;
    NSInteger _emailActionSheetCopyIndex;
    
    NSInteger _phoneNumberActionSheetCallIndex;
    NSInteger _phoneNumberActionSheetMessageIndex;
    NSInteger _phoneNumberActionSheetContactsIndex;
    NSInteger _phoneNumberActionSheetCopyIndex;
}


- (void)showActionSheetForURL:(NSURL*)url fromRect:(CGRect)rect inView:(UIView*)view
{
    _actionSheetURL = url;
    NSString *scheme = url.scheme;
    if ([scheme isEqualToString:@"mailto"])
    {
        [self showEmailActionSheetFromRect:rect inView:view];
    }
    else if ([scheme isEqualToString:@"tel"])
    {
        NSString *phoneNumber = url.host;
        [self showActionSheetForPhoneNumber:phoneNumber fromRect:rect inView:view];
    }
}

#pragma mark - Private

- (void)addContactWithEmail:(NSString*)email phoneNumber:(NSString*)phoneNumber image:(UIImage*)image
{
    ABRecordRef person = ABPersonCreate();
    
    if (email)
    {
        ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(emailMultiValue, (__bridge CFStringRef) email, kABWorkLabel, NULL);
        ABRecordSetValue(person, kABPersonEmailProperty, emailMultiValue, nil);
        CFRelease(emailMultiValue);
    }
    
    if (phoneNumber)
    {
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFStringRef) phoneNumber, kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
        CFRelease(phoneNumberMultiValue);
    }
    
    if (image)
    {
        CFErrorRef error = nil;
        NSData *data = UIImageJPEGRepresentation(image, 0.75);
        bool result = ABPersonSetImageData(person, (__bridge CFDataRef)data, &error);
        if (!result)
        {
            NSLog(@"Failed to set image data in person");
        }
    }
    
    ABUnknownPersonViewController *controller = [[ABUnknownPersonViewController alloc] init];
    controller.displayedPerson = person;
    controller.allowsAddingToAddressBook = YES;
    [self.navigationController pushViewController:controller animated:YES];
    CFRelease(person);
}

- (void)sendEmail:(NSString*)recipient
{
    if (![MFMailComposeViewController canSendMail]) return;
    
    MFMailComposeViewController* mailVC = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
    mailVC.mailComposeDelegate = self;
    [mailVC setToRecipients:@[recipient]];
    mailVC.modalPresentationStyle = UIModalPresentationFormSheet;
    mailVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:mailVC animated:YES completion:nil];
}

- (void)sendMessage:(NSString*)phoneNumber
{
    if (![MFMessageComposeViewController canSendText]) return;
    MFMessageComposeViewController *messageComposer = [MFMessageComposeViewController new];
    messageComposer.recipients = @[phoneNumber];
    messageComposer.messageComposeDelegate = self;
    [self presentViewController:messageComposer animated:YES completion:nil];
}

- (void)setPasteboard:(NSString*)value
{
    [UIPasteboard generalPasteboard].string = value;
}

- (void)showEmailActionSheetFromRect:(CGRect)rect inView:(UIView*)view
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    _emailActionSheetMessageIndex = -1;
    if ([MFMailComposeViewController canSendMail])
    {
        _emailActionSheetMessageIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"New Message", @"")];
    }
    _emailActionSheetContactsIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Add to Contacts", @"")];
    _emailActionSheetCopyIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", @"")];
    NSInteger cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    actionSheet.cancelButtonIndex = cancelButtonIndex;
    _emailActionSheet = actionSheet;
    [actionSheet showFromRect:rect inView:view animated:YES];
}

- (void)showActionSheetForPhoneNumber:(NSString*)phoneNumber fromRect:(CGRect)rect inView:(UIView*)view
{
    _actionSheetPhoneNumber = phoneNumber;
    _phoneNumberActionSheet = [[UIActionSheet alloc] init];
    _phoneNumberActionSheet.delegate = self;
    const BOOL canMakeCalls = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]];
    _phoneNumberActionSheetCallIndex = -1;
    if (canMakeCalls)
    {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Call %@", @""), phoneNumber];
        _phoneNumberActionSheetCallIndex = [_phoneNumberActionSheet addButtonWithTitle:title];
    }
    _phoneNumberActionSheetMessageIndex = -1;
    if ([MFMessageComposeViewController canSendText])
    {
        _phoneNumberActionSheetMessageIndex = [_phoneNumberActionSheet addButtonWithTitle:NSLocalizedString(@"Send Message", @"")];
    }
    _phoneNumberActionSheetContactsIndex = [_phoneNumberActionSheet addButtonWithTitle:NSLocalizedString(@"Add to Contacts", @"")];
    _phoneNumberActionSheetCopyIndex = [_phoneNumberActionSheet addButtonWithTitle:NSLocalizedString(@"Copy", @"")];
    NSInteger cancelButtonIndex = [_phoneNumberActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    _phoneNumberActionSheet.cancelButtonIndex = cancelButtonIndex;
    [_phoneNumberActionSheet showFromRect:rect inView:view animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_emailActionSheet == actionSheet)
    {
        NSString *email = [_actionSheetURL.absoluteString stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
        email = [email stringByRemovingPercentEncoding];
        if (buttonIndex == _emailActionSheetMessageIndex)
        {
            [self sendEmail:email];
        }
        else if (buttonIndex == _emailActionSheetContactsIndex)
        {
            [self addContactWithEmail:email phoneNumber:nil image:nil];
            
        }
        else if (buttonIndex == _emailActionSheetCopyIndex)
        {
            [self setPasteboard:email];
        }
    }
    else if (_phoneNumberActionSheet == actionSheet)
    {
        if (buttonIndex == _phoneNumberActionSheetCallIndex)
        {
            [[UIApplication sharedApplication] openURL:_actionSheetURL];
        }
        else if (buttonIndex == _phoneNumberActionSheetMessageIndex)
        {
            [self sendMessage:_actionSheetPhoneNumber];
        }
        else if (buttonIndex == _phoneNumberActionSheetContactsIndex)
        {
            [self addContactWithEmail:nil phoneNumber:_actionSheetPhoneNumber image:nil];
            
        }
        else if (buttonIndex == _phoneNumberActionSheetCopyIndex)
        {
            [self setPasteboard:_actionSheetPhoneNumber];
        }
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
