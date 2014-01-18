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
#import "HPTagSuggestionsView.h"

@interface HPNoteViewController () <UITextViewDelegate, UIActionSheetDelegate, HPTagSuggestionsViewDelegate>

@end

@implementation HPNoteViewController {
    UITextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    HPBaseTextStorage *_bodyTextStorage;

    UIBarButtonItem *_actionBarButtonItem;
    UIBarButtonItem *_addNoteBarButtonItem;
    UIBarButtonItem *_archiveBarButtonItem;
    UIBarButtonItem *_doneBarButtonItem;
    UIBarButtonItem *_trashBarButtonItem;
    UIBarButtonItem *_unarchiveBarButtonItem;
    
    NSInteger _noteIndex;
    
    HPTagSuggestionsView *_suggestionsView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    _archiveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(archiveBarButtomItemAction:)];
    _doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemAction:)];
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];
    _unarchiveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(unarchiveBarButtomItemAction:)];

    self.navigationItem.rightBarButtonItems = @[_addNoteBarButtonItem, _actionBarButtonItem];
    
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
        _bodyTextStorage.tag = self.tag;
        
        _bodyTextView = [[PSPDFTextView alloc] initWithFrame:self.view.bounds textContainer:container];
        _bodyTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bodyTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        _bodyTextView.textContainerInset = UIEdgeInsetsMake(20, 10, 20, 10);
        _bodyTextView.delegate = self;
        [self.view addSubview:_bodyTextView];
    }
    
    _suggestionsView = [[HPTagSuggestionsView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44) inputViewStyle:UIInputViewStyleKeyboard];
    _suggestionsView.delegate = self;
    
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
    for (HPNote *note in self.notes)
    {
        
        if (note.managed)
        {
            if ([self isEmptyNote:note])
            {
                [[HPNoteManager sharedManager] removeNote:note];
            }
        } else if (![self isEmptyNote:note])
        {
            [[HPNoteManager sharedManager] addNote:note];
        }
    }
}

#pragma mark - Class

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes tag:(NSString*)tag
{
    HPNote *note = [HPNote blankNoteWithTag:tag];
    notes = [[NSArray arrayWithObject:note] arrayByAddingObjectsFromArray:notes];
    return [HPNoteViewController noteViewControllerWithNote:note notes:notes tag:tag];
}

+ (HPNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes tag:(NSString*)tag
{
    HPNoteViewController *noteViewController = [[HPNoteViewController alloc] init];
    noteViewController.note = note;
    noteViewController.notes = [NSMutableArray arrayWithArray:notes];
    noteViewController.tag = tag;
    return noteViewController;
}

#pragma mark - Public

- (void)setNote:(HPNote *)note
{
    _note = note;
    _noteIndex = [self.notes indexOfObject:self.note];
}

- (void)setNotes:(NSMutableArray *)notes
{
    _notes = notes;
    _noteIndex = [self.notes indexOfObject:self.note];
}

- (void)setTag:(NSString *)tag
{
    _tag = tag;
    _bodyTextStorage.tag = self.tag;
}

#pragma mark - Private

- (void)displayNote
{
    _bodyTextView.text = self.note.text;
    self.note.views++;
    [self updateToolbar:NO /* animated */];
}

- (void)finishEditing
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)isEmptyNote:(HPNote*)note
{
    if (note.empty) return YES;
    NSString *trimmedText = [note.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self.tag isEqualToString:trimmedText]) return YES;
    return NO;
}

- (void)trashNote
{
    self.note.text = @""; // Note will be removed on viewWillDisappear:
    [self finishEditing];
}

- (void)changeNoteWithTransitionOptions:(UIViewAnimationOptions)options
{
    [self.view endEditing:YES];
    [UIView transitionWithView:self.view duration:1.0 options:options animations:^{
        [self displayNote];
    } completion:^(BOOL finished) {
    }];
}

- (void)changeToEmptyNote
{
    HPNote *note = [HPNote blankNoteWithTag:self.tag];
    [_notes insertObject:note atIndex:_noteIndex + 1];
    self.note = note;
    [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlUp];
}

- (NSString*)selectedTagEnclosing:(BOOL)enclosing range:(NSRange*)foundRange
{
    NSRange selectedRange = _bodyTextView.selectedRange;
    NSRange lineRange = [_bodyTextView.text lineRangeForRange:NSMakeRange(selectedRange.location, 0)];
    NSInteger length = enclosing ? lineRange.length : NSMaxRange(selectedRange) - lineRange.location;
    NSString *line = [_bodyTextView.text substringWithRange:NSMakeRange(lineRange.location, length)];
    NSInteger cursorLocationInLine = selectedRange.location - lineRange.location;
    NSRegularExpression *regex = [HPNote tagRegularExpression];
    
    __block BOOL found = NO;
    [regex enumerateMatchesInString:line options:0 range:NSMakeRange(0, line.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange resultRange = result.range;
        if (!NSLocationInRange(cursorLocationInLine, resultRange) && NSMaxRange(resultRange) != cursorLocationInLine) return;
        
        *foundRange = resultRange;
        found = YES;
        *stop = YES;
    }];
    if (found)
    {
        NSString *tag = [line substringWithRange:*foundRange];
        *foundRange = NSMakeRange(lineRange.location + (*foundRange).location, (*foundRange).length);
        return tag;
    }
    return nil;
}

- (void)updateToolbar:(BOOL)animated
{
    UIBarButtonItem *rightBarButtonItem = self.note.archived ? _unarchiveBarButtonItem : _archiveBarButtonItem;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[_trashBarButtonItem, flexibleSpace, rightBarButtonItem] animated:animated];
}

#pragma mark - Actions

- (void)actionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    NSArray *activityItems = @[self.note.text];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)archiveBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    self.note.archived = YES;
    [self updateToolbar:YES /* animated */];
}

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self changeToEmptyNote];
}

- (void)doneBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.view endEditing:YES];
}

- (IBAction)swipeRightAction:(id)sender
{
    if (_noteIndex > 0)
    {
        NSInteger previousIndex = _noteIndex - 1;
        _note = self.notes[previousIndex];
        _noteIndex = previousIndex;
        [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlDown];
    }
    else
    {
        [self finishEditing];
    }
}

- (IBAction)swipeLeftAction:(id)sender
{
    NSInteger nextIndex = _noteIndex + 1;
    if (nextIndex < self.notes.count)
    {
        _note = self.notes[nextIndex];
        _noteIndex = nextIndex;
        [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlUp];
    }
    else
    {
        [self changeToEmptyNote];
    }
}

- (void)trashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self isEmptyNote:self.note])
    {
        [self trashNote];
    }
    else
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:@"Delete Note" otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
}

- (void)unarchiveBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    self.note.archived = NO;
    [self updateToolbar:YES /* animated */];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (![self isEmptyNote:self.note] && !self.note.managed)
    {
        [[HPNoteManager sharedManager] addNote:self.note];
    }
    [self updateToolbar:YES /* animated */];
    self.note.modifiedAt = [NSDate date];
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

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange foundRange;
    NSString *prefix = [self selectedTagEnclosing:NO range:&foundRange];
    if (prefix)
    {
        _suggestionsView.prefix = prefix;
        if (_suggestionsView.suggestions.count > 0)
        {
            if (!textView.inputAccessoryView)
            {
                textView.inputAccessoryView = _suggestionsView;
                [textView reloadInputViews];
            }
        }
        else
        {
            textView.inputAccessoryView = nil;
            [textView reloadInputViews];
        }
    }
    else
    {
        textView.inputAccessoryView = nil;
        [textView reloadInputViews];
    }
}

#pragma mark - HPTagSuggestionsViewDelegate

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectSuggestion:(NSString*)suggestion
{
    NSRange foundRange;
    NSString *tag = [self selectedTagEnclosing:YES range:&foundRange];
    if (!tag) return;
    
    UITextPosition *beginning = _bodyTextView.beginningOfDocument;
    UITextPosition *start = [_bodyTextView positionFromPosition:beginning offset:foundRange.location];
    UITextPosition *end = [_bodyTextView positionFromPosition:start offset:foundRange.length];
    UITextRange *textRange = [_bodyTextView textRangeFromPosition:start toPosition:end];
    
    // Add space if there is none
    NSString *text = _bodyTextView.text;
    NSInteger nextCharacterLocation = foundRange.location + foundRange.length;
    NSString *nextCharacter = nextCharacterLocation < text.length ? [text substringWithRange:NSMakeRange(nextCharacterLocation, 1)] : @"";
    BOOL followedBySpace = [nextCharacter isEqualToString:@" "];
    NSString *replacement = followedBySpace ? suggestion : [NSString stringWithFormat:@"%@ ", suggestion];
    
    [_bodyTextView replaceRange:textRange withText:replacement];
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
