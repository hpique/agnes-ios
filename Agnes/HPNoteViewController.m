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
#import "HPTagSuggestionsView.h"
#import "HPNoteAction.h"
#import "HPIndexItem.h"
#import "PSPDFTextView.h"
#import "HPBrowserViewController.h"

@interface HPNoteViewController () <UITextViewDelegate, UIActionSheetDelegate, HPTagSuggestionsViewDelegate>

@end

@implementation HPNoteViewController {
    BOOL _bodyTextViewChanged;
    UITextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    HPBaseTextStorage *_bodyTextStorage;
    UITapGestureRecognizer *_textTapGestureRecognizer;

    UIBarButtonItem *_actionBarButtonItem;
    UIBarButtonItem *_addNoteBarButtonItem;
    UIBarButtonItem *_archiveBarButtonItem;
    UIBarButtonItem *_doneBarButtonItem;
    UIBarButtonItem *_trashBarButtonItem;
    UIBarButtonItem *_unarchiveBarButtonItem;
    
    UIActionSheet *_deleteNoteActionSheet;
    
    NSInteger _noteIndex;
    
    HPTagSuggestionsView *_suggestionsView;
}

@synthesize noteTextView = _bodyTextView;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    _archiveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(archiveBarButtomItemAction:)];
    _doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemAction:)];
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];
    _unarchiveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(unarchiveBarButtomItemAction:)];
    
    _addNoteBarButtonItem.enabled = !self.indexItem.disableAdd;
    _archiveBarButtonItem.enabled = !self.indexItem.disableRemove;
    _trashBarButtonItem.enabled = !self.indexItem.disableRemove;
    _unarchiveBarButtonItem.enabled = !self.indexItem.disableRemove;
    
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
        _bodyTextStorage.tag = self.indexItem.tag;
        
        _bodyTextView = [[UITextView alloc] initWithFrame:self.view.bounds textContainer:container];
        _bodyTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bodyTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _bodyTextView.textContainerInset = UIEdgeInsetsMake(20, 10, 20, 10);
        _bodyTextView.delegate = self;
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        [self.view addSubview:_bodyTextView];
        
        _textTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTagGestureRecognizer:)];
        [_bodyTextView addGestureRecognizer:_textTapGestureRecognizer];
        
        _suggestionsView = [[HPTagSuggestionsView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44) inputViewStyle:UIInputViewStyleKeyboard];
        _suggestionsView.delegate = self;
        _bodyTextView.inputAccessoryView = _suggestionsView;
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
    for (HPNote *note in self.notes)
    {
        if (!self.indexItem.disableRemove && [self isEmptyNote:note])
        {
            [[HPNoteManager sharedManager] trashNote:note];
        }
    }
}

#pragma mark - Class

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes indexItem:(HPIndexItem *)indexItem
{
    HPNote *note = [[HPNoteManager sharedManager] blankNoteWithTag:indexItem.tag];
    notes = [[NSArray arrayWithObject:note] arrayByAddingObjectsFromArray:notes];
    return [HPNoteViewController noteViewControllerWithNote:note notes:notes indexItem:indexItem];
}

+ (HPNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes indexItem:(HPIndexItem *)indexItem
{
    HPNoteViewController *noteViewController = [[HPNoteViewController alloc] init];
    noteViewController.note = note;
    noteViewController.notes = [NSMutableArray arrayWithArray:notes];
    noteViewController.indexItem = indexItem;
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

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    _bodyTextStorage.tag = self.indexItem.tag;
}

#pragma mark - Private

- (void)displayNote
{
    NSMutableString *editableText = [NSMutableString stringWithString:self.note.text];
    [HPNoteAction applyPreActions:self.note editableText:editableText];
    _bodyTextView.text = editableText;
    [[HPNoteManager sharedManager] viewNote:self.note];
    [self updateToolbar:NO /* animated */];
}

- (void)finishEditing
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)isEmptyNote:(HPNote*)note
{
    if (note.empty) return YES;
    NSString *blankText = [HPNote textOfBlankNoteWithTag:self.indexItem.tag];
    if ([note.text isEqualToString:blankText]) return YES;
    return NO;
}

- (void)trashNote
{
    [[HPNoteManager sharedManager] trashNote:self.note];
    [_notes removeObject:self.note];
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
    if (self.indexItem.disableAdd) return;
    
    HPNote *note = [[HPNoteManager sharedManager] blankNoteWithTag:self.indexItem.tag];
    [_notes insertObject:note atIndex:_noteIndex + 1];
    self.note = note;
    [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlUp];
}

- (void)handleURL:(NSURL*)url
{
    NSString *scheme = url.scheme;
    if ([scheme hasPrefix:@"http"])
    {
        [self openBrowserURL:url];
    }
    else
    {
        [self showActionSheetForURL:url];
    }
}

- (void)openBrowserURL:(NSURL*)url
{
    HPBrowserViewController *vc = [[HPBrowserViewController alloc] init];
    vc.url = url;
    [self.navigationController pushViewController:vc animated:YES];
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

UITextRange* UITextRangeFromNSRange(UITextView* textView, NSRange range)
{
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    return textRange;
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
    [[HPNoteManager sharedManager] archiveNote:self.note];
    [self updateToolbar:YES /* animated */];
    [self finishEditing];
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

- (void)textTagGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
{
    UITextView *textView = (UITextView*) gestureRecognizer.view;
    NSLayoutManager *layoutManager = _bodyTextView.layoutManager;
    CGPoint location = [gestureRecognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;
    
    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location inTextContainer:textView.textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    
    if (characterIndex >= textView.textStorage.length)
    {
        [textView becomeFirstResponder];
        return;
    }
    
    NSRange range;
    NSURL *url = [textView.attributedText attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:&range];
    if (url)
    {
        [self handleURL:url];
    }
    else
    {
        [textView setSelectedRange:NSMakeRange(characterIndex, 0)];
        [textView becomeFirstResponder];
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
        _deleteNoteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:@"Delete Note" otherButtonTitles:nil];
        [_deleteNoteActionSheet showInView:self.view];
    }
}

- (void)unarchiveBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPNoteManager sharedManager] unarchiveNote:self.note];
    [self updateToolbar:YES /* animated */];
    [self finishEditing];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    _bodyTextViewChanged = YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    _textTapGestureRecognizer.enabled = NO;
    [self.navigationItem setRightBarButtonItems:@[_doneBarButtonItem, _actionBarButtonItem] animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    _textTapGestureRecognizer.enabled = YES;
    if (_bodyTextViewChanged)
    {
        [[HPNoteManager sharedManager] editNote:self.note text:_bodyTextView.text];
        [self updateToolbar:YES /* animated */];
        _bodyTextViewChanged = NO;
    }
    [self.navigationItem setRightBarButtonItems:@[_addNoteBarButtonItem, _actionBarButtonItem] animated:YES];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange foundRange;
    NSString *prefix = [self selectedTagEnclosing:NO range:&foundRange];
    _suggestionsView.prefix = prefix;
}

#pragma mark - HPTagSuggestionsViewDelegate

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectSuggestion:(NSString*)suggestion
{
    NSRange foundRange;
    NSString *tag = [self selectedTagEnclosing:YES range:&foundRange];
    if (!tag) return;
    
    UITextRange *textRange = UITextRangeFromNSRange(_bodyTextView, foundRange);
    
    // Add space if there is none
    NSString *text = _bodyTextView.text;
    NSInteger nextCharacterLocation = foundRange.location + foundRange.length;
    NSString *nextCharacter = nextCharacterLocation < text.length ? [text substringWithRange:NSMakeRange(nextCharacterLocation, 1)] : @"";
    BOOL followedBySpace = [nextCharacter isEqualToString:@" "];
    NSString *replacement = followedBySpace ? suggestion : [NSString stringWithFormat:@"%@ ", suggestion];
    
    [_bodyTextView replaceRange:textRange withText:replacement];
}

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectKey:(NSString *)key
{
    NSRange replacementRange = _bodyTextView.selectedRange;
    UITextRange *textRange = UITextRangeFromNSRange(_bodyTextView, replacementRange);
    
    [_bodyTextView replaceRange:textRange withText:key];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_deleteNoteActionSheet == actionSheet)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex)
        {
            [self trashNote];
        }
        _deleteNoteActionSheet = nil;
    }
    else
    {
        [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
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
