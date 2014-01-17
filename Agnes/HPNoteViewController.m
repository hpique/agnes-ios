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

@interface HPNoteViewController () <UITextViewDelegate>

@end

@implementation HPNoteViewController {
    __weak IBOutlet UITextView *_bodyTextView;
    UIBarButtonItem *_trashBarButtonItem;
    UIEdgeInsets _originalBodyTextViewInset;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];
    self.toolbarItems = @[_trashBarButtonItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowNotification:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [self displayNote];
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
}

#pragma mark - Private

- (void)displayNote
{
    _bodyTextView.text = self.note.body;
    self.note.views++;
}

#pragma mark - Actions

- (void)trashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPNoteManager sharedManager] removeNote:self.note];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (!self.note)
    {
        self.note = [HPNote note];
        self.note.views++;
        [[HPNoteManager sharedManager] addNote:self.note];
    }
    else
    {
        self.note.modifiedAt = [NSDate date];
    }
    self.note.body = textView.text;
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
