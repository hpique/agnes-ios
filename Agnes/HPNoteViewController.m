//
//  HPNoteViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteViewController.h"
#import "HPNote.h"
#import "HPNoteManager.h"
#import "HPBaseTextStorage.h"
#import "PSPDFTextView.h"

@interface HPNoteViewController () <UITextViewDelegate, UIActionSheetDelegate>

@end

@implementation HPNoteViewController {
    UITextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    NSTextStorage *_bodyTextStorage;

    UIBarButtonItem *_actionBarButtonItem;
    UIBarButtonItem *_addNoteBarButtonItem;
    UIBarButtonItem *_doneBarButtonItem;
    UIBarButtonItem *_trashBarButtonItem;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    _doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemAction:)];
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];

    self.navigationItem.rightBarButtonItems = @[_addNoteBarButtonItem, _actionBarButtonItem];
    self.toolbarItems = @[_trashBarButtonItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
 
    {
        _bodyTextStorage= [HPBaseTextStorage new];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        CGSize containerSize = CGSizeMake(self.view.bounds.size.width,  CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [_bodyTextStorage addLayoutManager:layoutManager];
        
        _bodyTextView = [[PSPDFTextView alloc] initWithFrame:self.view.bounds textContainer:container];
        _bodyTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bodyTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        _bodyTextView.delegate = self;
        [self.view addSubview:_bodyTextView];
    }
    
    [self displayNote];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = YES;
    if (self.note.empty)
    {
        [[HPNoteManager sharedManager] removeNote:self.note];
    }
}

#pragma mark - Private

- (void)displayNote
{
    _bodyTextView.text = self.note.text;
    self.note.views++;
}

- (void)trashNote
{
    [[HPNoteManager sharedManager] removeNote:self.note];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions

- (void)actionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    NSArray *activityItems = @[self.note.text];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    self.note = nil;
    [self displayNote];
}

- (void)doneBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.view endEditing:YES];
}

- (void)trashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if (!self.note || self.note.empty)
    {
        [self trashNote];
    }
    else
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:@"Delete Note" otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (!self.note)
    {
        self.note = [[HPNoteManager sharedManager] blankNote];
        self.note.views++;
    }
    else
    {
        self.note.modifiedAt = [NSDate date];
    }
    self.note.text = textView.text;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.navigationItem setRightBarButtonItems:@[_doneBarButtonItem, _actionBarButtonItem] animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.navigationItem setRightBarButtonItems:@[_addNoteBarButtonItem, _actionBarButtonItem] animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self trashNote];
    }
}


#pragma mark - Notifications

- (void)keyboardDidShowNotification:(NSNotification*)notification
{
    NSDictionary *info = notification.userInfo;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    _originalBodyTextViewInset = _bodyTextView.contentInset;
    _bodyTextView.contentInset = UIEdgeInsetsMake(_originalBodyTextViewInset.top, _originalBodyTextViewInset.left, keyboardSize.height, _originalBodyTextViewInset.right);
    _bodyTextView.scrollIndicatorInsets = _bodyTextView.contentInset;
}

- (void)keyboardWillHideNotification:(NSNotification*)notification
{
    _bodyTextView.contentInset = _originalBodyTextViewInset;
    _bodyTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

@end
