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
#import "HPNoteActivityItemSource.h"
#import "HPPreferencesManager.h"
#import "HPBrowserViewController.h"
#import "HPFontManager.h"
#import "PSPDFTextView.h"
#import "NSString+hp_utils.h"

@interface HPNoteViewController () <UITextViewDelegate, UIActionSheetDelegate, HPTagSuggestionsViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, assign) HPNoteDetailMode detailMode;

@end

@implementation HPNoteViewController {
    BOOL _bodyTextViewChanged;
    PSPDFTextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    HPBaseTextStorage *_bodyTextStorage;
    UITapGestureRecognizer *_textTapGestureRecognizer;

    UIBarButtonItem *_actionBarButtonItem;
    UIBarButtonItem *_attachmentBarButtonItem;
    UIBarButtonItem *_addNoteBarButtonItem;
    UIBarButtonItem *_archiveBarButtonItem;
    UIBarButtonItem *_detailBarButtonItem;
    UIBarButtonItem *_doneBarButtonItem;
    UIBarButtonItem *_trashBarButtonItem;
    UIBarButtonItem *_unarchiveBarButtonItem;
    
    IBOutlet UILabel *_detailLabel;
    
    UIActionSheet *_deleteNoteActionSheet;
    
    NSInteger _noteIndex;

    HPTagSuggestionsView *_suggestionsView;
    BOOL _viewDidAppear;
    BOOL _hasEnteredEditingModeOnce;
}

@synthesize noteTextView = _bodyTextView;
@synthesize search = _search;
@synthesize transitioning = _transitioning;
@synthesize wantsDefaultTransition = _wantsDefaultTransition;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    _archiveBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-archive"] style:UIBarButtonItemStylePlain target:self action:@selector(archiveBarButtomItemAction:)];
    _attachmentBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-attachment"] style:UIBarButtonItemStylePlain target:self action:@selector(attachmentBarButtomItemAction:)];
    _doneBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(doneBarButtonItemAction:)];
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];
    _unarchiveBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-inbox"] style:UIBarButtonItemStylePlain target:self action:@selector(unarchiveBarButtomItemAction:)];
    
    _addNoteBarButtonItem.enabled = !self.indexItem.disableAdd;
    _archiveBarButtonItem.enabled = !self.indexItem.disableRemove;
    _trashBarButtonItem.enabled = !self.indexItem.disableRemove;
    _unarchiveBarButtonItem.enabled = !self.indexItem.disableRemove;
    
    _detailLabel.font = [[HPFontManager sharedManager] fontForDetail];
    _detailBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_detailLabel];
    _detailBarButtonItem.width = 160;
    
    self.navigationItem.rightBarButtonItems = @[_addNoteBarButtonItem, _actionBarButtonItem, _attachmentBarButtonItem];
    
    self.toolbar.barTintColor = [UIColor whiteColor];
    self.toolbar.clipsToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
 
    {
        _bodyTextStorage = [HPBaseTextStorage new];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        CGSize containerSize = CGSizeMake(self.view.bounds.size.width,  CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [_bodyTextStorage addLayoutManager:layoutManager];
        _bodyTextStorage.tag = self.indexItem.tag.name;
        
        _bodyTextView = [[PSPDFTextView alloc] initWithFrame:self.view.bounds textContainer:container];
        _bodyTextView.opaque = NO;
        _bodyTextView.backgroundColor = [UIColor clearColor];
        _bodyTextView.translatesAutoresizingMaskIntoConstraints = NO;
        _bodyTextView.font = [HPFontManager sharedManager].fontForNoteBody;
        _bodyTextView.textContainerInset = UIEdgeInsetsMake(20, 10, 20 + self.toolbar.frame.size.height, 10);
        _bodyTextView.delegate = self;
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        [self.view addSubview:_bodyTextView];
        [self.view bringSubviewToFront:self.toolbar];
        
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _viewDidAppear = YES;
    if ([self.note isNew])
    {
        [self.noteTextView becomeFirstResponder];
    }
    self.transitioning = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    for (HPNote *note in self.notes)
    {
        if (!self.indexItem.disableRemove && [self isEmptyNote:note])
        {
            [[HPNoteManager sharedManager] trashNote:note];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.transitioning = NO;
}

#pragma mark - Class

+ (HPNoteViewController*)blankNoteViewControllerWithNotes:(NSArray*)notes indexItem:(HPIndexItem *)indexItem
{
    HPNote *note = [[HPNoteManager sharedManager] blankNoteWithTagOfName:indexItem.tag.name];
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

- (NSString*)search
{
    return _search;
}

- (void)setSearch:(NSString *)search
{
    _search = search;
    _bodyTextStorage.search = self.search;
}

- (BOOL)saveNote:(BOOL)animated
{
    HPNote *note = self.note;
    if (!note) return NO;
    if (!_bodyTextViewChanged) return NO;
    
    if (![note isNew] || ![self isEmptyText])
    {
        NSMutableString *mutableText = [NSMutableString stringWithString:self.noteTextView.text];
        const BOOL changed = [HPNoteAction willEditNote:note text:mutableText editor:self.noteTextView];
        [[HPNoteManager sharedManager] editNote:self.note text:mutableText];
        if (changed)
        {
            NSMutableAttributedString *attributedText = [self attributedNoteText].mutableCopy;
            [HPNoteAction willDisplayNote:self.note text:attributedText view:self.noteTextView];
            _bodyTextView.attributedText = attributedText;
        }
        [self updateToolbar:animated];
        [self displayDetail];
        _bodyTextViewChanged = NO;
        
        if (!self.indexItem)
        { // Find the best index item to return to
            HPIndexItem *indexItem = [self indexItemToReturn];
            [self.delegate noteViewController:self shouldReturnToIndexItem:indexItem];
        }
        return YES;
    }
    return NO;
}

- (HPIndexItem*)indexItemToReturn
{
    NSMutableSet *tags = [NSMutableSet set];
    BOOL inbox = NO;
    for (HPNote *note in self.notes)
    {
        NSSet *noteTags = note.cd_tags;
        if (noteTags.count == 0)
        {
            inbox = YES;
            break;
        }
        [tags addObjectsFromArray:noteTags.allObjects];
    }
    if (!inbox && tags.count == 1)
    {
        HPTag *tag = [tags anyObject];
        return [HPIndexItem indexItemWithTag:tag];
    }
    return [HPIndexItem inboxIndexItem];
}

- (void)setNote:(HPNote *)note
{
    _note = note;
    _detailMode = note.detailMode;
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
    _bodyTextStorage.tag = self.indexItem.tag.name;
}

#pragma mark - Private

- (NSAttributedString*)attributedNoteText
{
    const UIEdgeInsets insets = _bodyTextView.textContainerInset;
    const CGFloat width = _bodyTextView.bounds.size.width - insets.left - insets.right - _bodyTextView.textContainer.lineFragmentPadding * 2;
    return [self.note attributedTextForWidth:width];
}

- (void)displayNote
{
    _hasEnteredEditingModeOnce = NO;
    _bodyTextStorage.search = self.search;
    NSMutableAttributedString *attributedText = [self attributedNoteText].mutableCopy;
    [HPNoteAction willDisplayNote:self.note text:attributedText view:self.noteTextView];
    _bodyTextView.attributedText = attributedText;
    if ([self.note isNew] && _viewDidAppear)
    {
        [_bodyTextView becomeFirstResponder];
    }
    [[HPNoteManager sharedManager] viewNote:self.note];
    [self displayDetail]; // Do after viewing note as the number of views will increment
    [self updateToolbar:NO /* animated */];
}

- (void)displayDetail
{
    NSString *text = @"";
    switch (self.detailMode)
    {
        case HPNoteDetailModeModifiedAt:
            text = self.note.modifiedAtLongDescription;
            break;
        case HPNoteDetailModeCharacters:
        {
            NSInteger charCount = _bodyTextView.text.length;
            text = [NSString localizedStringWithFormat:NSLocalizedString(@"%ld characters", @""), (long)charCount];
            break;
        }
        case HPNoteDetailModeWords:
        {
            NSInteger wordCount = _bodyTextView.text.wordCount;
            text = [NSString localizedStringWithFormat:NSLocalizedString(@"%ld words", @""), (long)wordCount];
            break;
        }
        case HPNoteDetailModeNone:
            text = @"";
            break;
        case HPNoteDetailModeViews:
            text = [NSString localizedStringWithFormat:NSLocalizedString(@"%ld views", @""), (long)self.note.views];
            break;
    }
    _detailLabel.text = text;
}

- (void)finishEditing
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)isEmptyText
{
    NSString *editText = [_bodyTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (editText.length == 0) return YES;
    HPTag *tag = self.indexItem.tag;
    NSString *blankText = [HPNote textOfBlankNoteWithTagOfName:tag.name];
    blankText = [blankText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([editText isEqualToString:blankText]) return YES;
    return NO;
}

- (BOOL)isEmptyNote:(HPNote*)note
{
    if (note.empty) return YES;
    HPTag *tag = self.indexItem.tag;
    NSString *blankText = [HPNote textOfBlankNoteWithTagOfName:tag.name];
    if ([note.text isEqualToString:blankText]) return YES;
    return NO;
}

- (void)trashNote
{
    [[HPNoteManager sharedManager] trashNote:self.note];
    [_notes removeObject:self.note];
    self.note = nil;
    [self finishEditing];
}

- (void)changeNoteWithTransitionOptions:(UIViewAnimationOptions)options
{
    [UIView transitionWithView:self.view duration:1.0 options:options animations:^{
        [self displayNote];
    } completion:^(BOOL finished) {
        [_bodyTextView scrollRangeToVisible:NSMakeRange(0, 0)];
    }];
}

- (void)changeToEmptyNote
{
    if (self.indexItem.disableAdd) return;
    
    [self.view endEditing:YES];
    HPTag *tag = self.indexItem.tag;
    HPNote *note = [[HPNoteManager sharedManager] blankNoteWithTagOfName:tag.name];
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

- (void)setDetailMode:(HPNoteDetailMode)detailMode
{
    _detailMode = detailMode;
    if (!self.note) return;
    [[HPNoteManager sharedManager] setDetailMode:self.detailMode ofNote:self.note];
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
    [self.toolbar setItems:@[_trashBarButtonItem, flexibleSpace, _detailBarButtonItem, flexibleSpace, rightBarButtonItem] animated:animated];
}

#pragma mark - Actions

- (void)actionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    HPNoteActivityItemSource *activityItem = [[HPNoteActivityItemSource alloc] initWithNote:self.note];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[activityItem] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)archiveBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPNoteManager sharedManager] archiveNote:self.note];
    [self finishEditing];
}

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self changeToEmptyNote];
}

- (void)attachmentBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.delegate = self;
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:controller animated:YES completion:^{
    }];
}

- (IBAction)detailLabelTapGestureRecognizer:(id)sender
{
    self.detailMode = (self.detailMode + 1) % HPNoteDetailModeCount;
    [self displayDetail];
}

- (void)doneBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.view endEditing:YES];
}

- (IBAction)swipeRightAction:(id)sender
{
    if (_noteIndex > 0)
    {
        [self.view endEditing:YES];
        NSInteger previousIndex = _noteIndex - 1;
        _note = self.notes[previousIndex];
        _noteIndex = previousIndex;
        [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlDown];
    }
    else
    {
        self.wantsDefaultTransition = YES;
        [self finishEditing];
    }
}

- (IBAction)swipeLeftAction:(id)sender
{
    NSInteger nextIndex = _noteIndex + 1;
    if (nextIndex < self.notes.count)
    {
        [self.view endEditing:YES];
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
    [self finishEditing];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    _bodyTextViewChanged = YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    _hasEnteredEditingModeOnce = YES;
    _bodyTextStorage.search = nil;
    _textTapGestureRecognizer.enabled = NO;
    [self.navigationItem setRightBarButtonItems:@[_doneBarButtonItem, _actionBarButtonItem, _attachmentBarButtonItem] animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    _textTapGestureRecognizer.enabled = YES;
    if (_bodyTextViewChanged)
    {
        [self saveNote:YES];
    }
    [self.navigationItem setRightBarButtonItems:@[_addNoteBarButtonItem, _actionBarButtonItem, _attachmentBarButtonItem] animated:YES];
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

- (void)didChangeFontsNotification:(NSNotification*)notification
{
    HPFontManager *manager = [HPFontManager sharedManager];
    _bodyTextView.font = manager.fontForNoteBody;
    _detailLabel.font = manager.fontForDetail;
}

- (void)keyboardWillShowNotification:(NSNotification*)notification
{
    NSDictionary *info = notification.userInfo;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    _originalBodyTextViewInset = _bodyTextView.contentInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(_originalBodyTextViewInset.top, _originalBodyTextViewInset.left, keyboardSize.height, _originalBodyTextViewInset.right);

    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    [UIView animateWithDuration:duration delay:0 options:animationCurve animations:^{
        _bodyTextView.contentInset = insets;
        _bodyTextView.scrollIndicatorInsets = insets;
        [_bodyTextView scrollToVisibleCaretAnimated:NO];
    } completion:^(BOOL finished) {
    }];
}

- (void)keyboardWillHideNotification:(NSNotification*)notification
{
    if (self.transitioning) return; // Do not animate keyboard when animating to list
    
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    [UIView animateWithDuration:duration delay:0 options:animationCurve animations:^{
        _bodyTextView.contentInset = _originalBodyTextViewInset;
        _bodyTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
        [_bodyTextView scrollToVisibleCaretAnimated:NO];
    } completion:^(BOOL finished) {
    }];
}

#pragma mark - HPDataActionViewController

- (void)addContactWithEmail:(NSString *)email phoneNumber:(NSString *)phoneNumber
{ // Attempt to find addditional contact data in the note
    if (!email) email = [self valueInLinkWithScheme:@"mailto"];
    if (!phoneNumber) phoneNumber = [self valueInLinkWithScheme:@"tel"];
    [super addContactWithEmail:email phoneNumber:phoneNumber];
}

- (NSString*)valueInLinkWithScheme:(NSString*)scheme
{
    __block NSString *foundValue = nil;
    NSAttributedString *text = self.noteTextView.attributedText;
    NSRange allRange = NSMakeRange(0, text.length);
    [text enumerateAttribute:NSLinkAttributeName inRange:allRange options:0 usingBlock:^(NSURL *value, NSRange range, BOOL *stop) {
        NSString *valueScheme = value.scheme;
        if (![valueScheme isEqualToString:scheme]) return;
        
        NSString *remove = [NSString stringWithFormat:@"%@:", scheme];
        foundValue = [value.absoluteString stringByReplacingOccurrencesOfString:remove withString:@""];
        foundValue = [foundValue stringByRemovingPercentEncoding];
        *stop = YES;
    }];
    return foundValue;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSInteger index = _hasEnteredEditingModeOnce ? _bodyTextView.selectedRange.location : 0; // selectedRange gives the last position by default
    if (index == NSNotFound) index = 0;
    [[HPNoteManager sharedManager] attachToNote:self.note image:image index:index];
    
    [self dismissViewControllerAnimated:YES completion:^{}];
    
    { // Restore status bar
        [UIApplication sharedApplication].statusBarHidden = [HPPreferencesManager sharedManager].statusBarHidden;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    self.noteTextView.attributedText = [self attributedNoteText];
}

@end
