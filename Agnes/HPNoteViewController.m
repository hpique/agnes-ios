//
//  HPNoteViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteViewController.h"
#import "HPNote.h"
#import "HPNote+AttributedText.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPBaseTextStorage.h"
#import "HPTagSuggestionsView.h"
#import "HPNoteAction.h"
#import "HPIndexItem.h"
#import "HPNoteActivityItemSource.h"
#import "HPPreferencesManager.h"
#import "HPBrowserViewController.h"
#import "HPFontManager.h"
#import "HPAttachment.h"
#import "PSPDFTextView.h"
#import "HPImageViewController.h"
#import "HPImageZoomAnimationController.h"
#import "NSString+hp_utils.h"
#import "HPNoFirstResponderActionSheet.h"
#import "HPAgnesUIMetrics.h"
#import "UIImage+hp_utils.h"
#import "UITextView+hp_utils.h"
#import "UIView+hp_utils.h"
#import <MobileCoreServices/MobileCoreServices.h>

const NSTimeInterval HPNoteEditorAttachmentAnimationDuration = 0.3;
const CGFloat HPNoteEditorAttachmentAnimationFrameRate = 60;

@interface HPNoteViewController () <UITextViewDelegate, UIActionSheetDelegate, HPTagSuggestionsViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIViewControllerTransitioningDelegate, HPImageViewControllerDelegate>

@property (nonatomic, assign) HPNoteDetailMode detailMode;
@property (nonatomic, assign) BOOL textChanged;
@property (nonatomic, readonly) BOOL typing;

@end

@implementation HPNoteViewController {
    PSPDFTextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    UIEdgeInsets _originalTextContainerInset;
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

    UIActionSheet *_attachmentActionSheet;
    NSInteger _attachmentActionSheetCameraIndex;
    NSInteger _attachmentActionSheetPhotosIndex;
    UIActionSheet *_deleteNoteActionSheet;
    
    NSMutableArray *_notes;
    NSInteger _noteIndex;

    HPTagSuggestionsView *_suggestionsView;
    BOOL _viewDidAppear;
    BOOL _hasEnteredEditingModeOnce;
    
    NSUInteger _presentedImageCharacterIndex;
    UIImage *_presentedImageMedium;
    CGRect _presentedImageRect;
    HPImageViewController *_presentedImageViewController;
    
    NSTimer *_autosaveTimer;
    NSTimer *_typingTimer;
    NSDate *_typingPreviousDate;
    
    __weak IBOutlet NSLayoutConstraint *_toolbarHeightConstraint;
    
    CFTimeInterval _attachmentAnimationStart;
    UIView *_attachmentAnimationView;
    CADisplayLink *_attachmentAnimationDisplayLink;
    NSUInteger _attachmentAnimationIndex;
}

@synthesize notes = _notes;
@synthesize noteTextView = _bodyTextView;
@synthesize search = _search;
@synthesize transitioning = _transitioning;
@synthesize typing = _typing;
@synthesize wantsDefaultTransition = _wantsDefaultTransition;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    _archiveBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-archive"] style:UIBarButtonItemStylePlain target:self action:@selector(archiveBarButtonItemAction:)];
    _attachmentBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-attachment"] landscapeImagePhone:[UIImage imageNamed:@"icon-attachment-landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(attachmentBarButtonItemAction:)];
    _doneBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(doneBarButtonItemAction:)];
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];
    _unarchiveBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-inbox"] style:UIBarButtonItemStylePlain target:self action:@selector(unarchiveBarButtonItemAction:)];
    
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
        _bodyTextView.backgroundColor = [UIColor clearColor]; // Allows nicer transition for text elements when returning to the list
        _bodyTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bodyTextView.font = [HPFontManager sharedManager].fontForNoteBody;

        CGFloat sideInset = [HPAgnesUIMetrics sideMarginForInterfaceOrientation:self.interfaceOrientation] - _bodyTextView.textContainer.lineFragmentPadding;
        _bodyTextView.textContainerInset = UIEdgeInsetsMake(20, sideInset, 20 + self.toolbar.frame.size.height, sideInset);
        _bodyTextView.delegate = self;
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        [self.view addSubview:_bodyTextView];
        [self.view bringSubviewToFront:self.toolbar];
        
        _textTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapGestureRecognizer:)];
        [_bodyTextView addGestureRecognizer:_textTapGestureRecognizer];
        
        _suggestionsView = [[HPTagSuggestionsView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44) inputViewStyle:UIInputViewStyleKeyboard];
        _suggestionsView.delegate = self;
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
            _bodyTextView.inputAccessoryView = _suggestionsView;
        }
    }
    
    [self layoutToolbar];
    [self displayNote];
}

- (void)dealloc
{
    [_autosaveTimer invalidate];
    [_attachmentAnimationDisplayLink invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.note isNew] && !_viewDidAppear)
    {
        _bodyTextView.selectedRange = NSMakeRange(0, 0);
        [self.noteTextView becomeFirstResponder];
    }
    _viewDidAppear = YES;
    self.transitioning = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.typing) [self setTyping:NO animated:animated];
    if (!self.transitioning) return; // Don't continue if we're presenting a modal controller
    
    // TODO: Do this only when we're transitiong back to the list or to the menu
    for (HPNote *note in self.notes)
    {
        if (!self.indexItem.disableRemove && [note isEmptyInTag:self.indexItem.tag])
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.noteTextView.inputAccessoryView = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? nil : _suggestionsView;
    [self.noteTextView resignFirstResponder];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self layoutToolbar];
    CGFloat sideInset = [HPAgnesUIMetrics sideMarginForInterfaceOrientation:self.interfaceOrientation] - _bodyTextView.textContainer.lineFragmentPadding;
    _bodyTextView.textContainerInset = UIEdgeInsetsMake(20, sideInset, 20 + self.toolbar.frame.size.height, sideInset);
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
    if (!self.textChanged) return NO;
    
    if (![note isNew] || ![_bodyTextView.text hp_isEmptyInTag:self.indexItem.tag])
    {
        NSMutableString *mutableText = [NSMutableString stringWithString:self.noteTextView.text];
        const BOOL changed = [HPNoteAction willEditNote:note text:mutableText editor:self.noteTextView];
        NSAttributedString *attributedText = self.noteTextView.attributedText;
        NSArray *attachments = [attributedText hp_attachments];
        [[HPNoteManager sharedManager] editNote:self.note text:mutableText attachments:attachments];
        if (changed)
        {
            NSMutableAttributedString *attributedText = self.note.attributedText.mutableCopy;
            [HPNoteAction willDisplayNote:self.note text:attributedText view:self.noteTextView];
            _bodyTextView.attributedText = attributedText;
        }
        [self updateToolbar:animated];
        [self displayDetail];
        self.textChanged = NO;
        
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

+ (CGFloat)minimumNoteWidth
{
    const CGFloat sideMargin = [HPAgnesUIMetrics sideMarginForInterfaceOrientation:UIInterfaceOrientationPortrait]; // Portrait has the smallest margins
    const CGSize screenSize = [UIScreen mainScreen].bounds.size;
    const CGFloat minLength = MIN(screenSize.width, screenSize.height);
    const CGFloat width = minLength - sideMargin * 2;
    return width;
}

- (void)setNote:(HPNote *)note
{
    _note = note;
    _detailMode = note.detailMode;
    _noteIndex = [self.notes indexOfObject:self.note];
}

- (void)setNotes:(NSArray*)notes
{
    NSArray *reversed = [notes reverseObjectEnumerator].allObjects;
    _notes = reversed.mutableCopy;
    _noteIndex = [self.notes indexOfObject:self.note];
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    _bodyTextStorage.tag = self.indexItem.tag.name;
}

#pragma mark - Private

- (void)autosave
{
    if (!(self.note.canAutosave)) return;
    [self saveNote:NO];
}

- (void)displayNote
{
    _hasEnteredEditingModeOnce = NO;
    _bodyTextStorage.search = self.search;
    NSMutableAttributedString *attributedText = self.note.attributedText.mutableCopy;
    [HPNoteAction willDisplayNote:self.note text:attributedText view:self.noteTextView];
    _bodyTextView.text = @" "; // HACK: See: http://stackoverflow.com/questions/21731207/how-to-clear-uitextview-for-real
    _bodyTextView.attributedText = attributedText;
    _bodyTextView.selectedRange = NSMakeRange(0, 0);
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
            NSInteger wordCount = _bodyTextView.text.hp_wordCount;
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

- (void)trashNote
{
    [[HPNoteManager sharedManager] trashNote:self.note];
    [_notes removeObject:self.note];
    self.note = nil;
    [self finishEditing];
}

- (void)changeNoteWithTransitionOptions:(UIViewAnimationOptions)options
{

    [_bodyTextView scrollToVisibleCaretAnimated:NO];
    [UIView transitionWithView:self.view duration:1.0 options:options animations:^{
        [self displayNote];
    } completion:^(BOOL finished) {
//        [_bodyTextView scrollToVisibleCaretAnimated:NO];
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

- (void)didDismissImageViewController
{
    _presentedImageMedium = nil;
    _presentedImageRect = CGRectNull;
    _presentedImageViewController = nil;
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

- (void)layoutToolbar
{
    const CGFloat height = self.navigationController.toolbar.frame.size.height;
    _toolbarHeightConstraint.constant = height;
}

- (void)openBrowserURL:(NSURL*)url
{
    HPBrowserViewController *vc = [[HPBrowserViewController alloc] init];
    vc.url = url;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)presentTextAttachment:(NSTextAttachment*)textAttachment atIndex:(NSInteger)characterIndex
{
    UITextView *textView = self.noteTextView;
    HPAttachment *attachment = [textView.attributedText attribute:HPNoteAttachmentAttributeName atIndex:characterIndex effectiveRange:nil];
    // Ignore character attachments
    if (attachment.mode != HPAttachmentModeDefault) return;
    
    NSLayoutManager *layoutManager = textView.layoutManager;
    const NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:NSMakeRange(characterIndex, 1) actualCharacterRange:nil];
    [layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, characterIndex)];
    CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];
    rect = CGRectOffset(rect, textView.textContainerInset.left, textView.textContainerInset.top);
    rect = CGRectIntegral(rect);
    _presentedImageCharacterIndex = characterIndex;
    _presentedImageRect = rect;
    _presentedImageMedium = textAttachment.image;
    
    UIImage *fullSizeImage = attachment.image;
    HPImageViewController *viewController = [[HPImageViewController alloc] initWithImage:fullSizeImage];
    viewController.delegate = self;
    viewController.transitioningDelegate = self;
    _presentedImageViewController = viewController;
    
    UIBarButtonItem *trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(attachmentTrashBarButtonItemAction:)];
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(attachmentActionBarButtonItemAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    viewController.toolbarItems = @[trashBarButtonItem, flexibleSpace, actionBarButtonItem];
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)presentImagePickerControllerWithType:(UIImagePickerControllerSourceType)type
{
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.delegate = self;
    controller.sourceType = type;
    [self presentViewController:controller animated:YES completion:^{}];
}

- (void)setDetailMode:(HPNoteDetailMode)detailMode
{
    _detailMode = detailMode;
    if (!self.note) return;
    [[HPNoteManager sharedManager] setDetailMode:self.detailMode ofNote:self.note];
}

- (void)setTextChanged:(BOOL)textChanged
{
    const BOOL wasChanged = _textChanged;
    _textChanged = textChanged;
    if (self.textChanged)
    {
        if (!wasChanged)
        {
            [_autosaveTimer invalidate];
            static CGFloat autosaveDelay = 10;
            _autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:autosaveDelay target:self selector:@selector(autosave) userInfo:nil repeats:NO];
        }
    }
    else
    {
        [_autosaveTimer invalidate];
    }
}

- (void)setTyping:(BOOL)typing animated:(BOOL)animated
{
    _typing = typing;
    [_typingTimer invalidate];
    if (typing)
    {
        HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
        NSDate *now = [NSDate date];
        if (_typingPreviousDate)
        {
            NSTimeInterval currentSpeed = [now timeIntervalSinceDate:_typingPreviousDate];
            static CGFloat currentSpeedWeight = 0.05;
            preferences.typingSpeed = preferences.typingSpeed * (1 - currentSpeedWeight) + currentSpeed * currentSpeedWeight;
        }
        _typingPreviousDate = now;
        if (!self.navigationController.navigationBarHidden)
        {
            [self.navigationController setNavigationBarHidden:YES animated:animated];
            if (![UIApplication sharedApplication].statusBarHidden)
            {
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            }
        }
        static CGFloat stopMultiplier = 5;
        static CGFloat minimumDelay = 2;
        const CGFloat typingDelay = MAX(preferences.typingSpeed * stopMultiplier, minimumDelay) ;
        _typingTimer = [NSTimer scheduledTimerWithTimeInterval:typingDelay target:self selector:@selector(didFinishTyping) userInfo:nil repeats:NO];
    }
    else if (self.navigationController.navigationBarHidden)
    {
        if ([UIApplication sharedApplication].statusBarHidden && ![HPPreferencesManager sharedManager].statusBarHidden)
        {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        }
        _typingPreviousDate = nil;
        [self.navigationController setNavigationBarHidden:NO animated:animated];
        [_bodyTextView scrollToVisibleCaretAnimated:NO];
    }
}

- (void)didFinishTyping
{
    [self setTyping:NO animated:YES];
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
    [self autosave];
    HPNoteActivityItemSource *activityItem = [[HPNoteActivityItemSource alloc] initWithNote:self.note];
    activityItem.selectedRange = _bodyTextView.selectedRange;
    NSMutableArray *items = [NSMutableArray arrayWithObject:activityItem];
    NSAttributedString *attributedText = self.noteTextView.attributedText;
    UIImage *attachmentImage = [attributedText hp_imageOfFirstAttachment];
    if (attachmentImage) [items addObject:attachmentImage];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)archiveBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPTagManager sharedManager] archiveNote:self.note];
    [self finishEditing];
}

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self changeToEmptyNote];
}

- (void)attachmentBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    _attachmentActionSheet = [[HPNoFirstResponderActionSheet alloc] init];
    _attachmentActionSheet.delegate = self;
    _attachmentActionSheetCameraIndex = -1;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        _attachmentActionSheetCameraIndex = [_attachmentActionSheet addButtonWithTitle:NSLocalizedString(@"Camera", @"")];
    }
    _attachmentActionSheetPhotosIndex = -1;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        _attachmentActionSheetPhotosIndex = [_attachmentActionSheet addButtonWithTitle:NSLocalizedString(@"Photos", @"")];
    }
    NSInteger cancelButtonIndex = [_attachmentActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    _attachmentActionSheet.cancelButtonIndex = cancelButtonIndex;
    [_attachmentActionSheet showInView:self.view];
}

- (void)attachmentTrashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    NSMutableAttributedString *attributedString = self.noteTextView.attributedText.mutableCopy;
    [attributedString replaceCharactersInRange:NSMakeRange(_presentedImageCharacterIndex, 1) withString:@""];
    self.noteTextView.attributedText = attributedString;
    self.textChanged = YES;
    [self saveNote:NO];
    _presentedImageRect = CGRectMake(_presentedImageRect.origin.x + _presentedImageRect.size.width / 2, _presentedImageRect.origin.y, 1, 1);
    [self dismissViewControllerAnimated:YES completion:^{
        [self didDismissImageViewController];
    }];
}

- (void)attachmentActionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    UIImage *image = _presentedImageViewController.image;
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    [_presentedImageViewController presentViewController:activityViewController animated:YES completion:nil];
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

- (void)textTapGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
{
    UITextView *textView = (UITextView*) gestureRecognizer.view;
    NSLayoutManager *layoutManager = _bodyTextView.layoutManager;
    CGPoint location = [gestureRecognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;
    
    NSUInteger characterIndex;
    CGFloat fraction = 0; // When an attachment or url are the last elements, the fraction tells us if the location is outside the image
    characterIndex = [layoutManager characterIndexForPoint:location inTextContainer:textView.textContainer fractionOfDistanceBetweenInsertionPoints:&fraction];
    
    if (characterIndex >= textView.textStorage.length)
    {
        [textView becomeFirstResponder];
        return;
    }
    
    NSRange range;
    NSTextAttachment *textAttachment = [textView.attributedText attribute:NSAttachmentAttributeName atIndex:characterIndex effectiveRange:&range];
    if (textAttachment && fraction < 1)
    {
        [self presentTextAttachment:textAttachment atIndex:characterIndex];
        return;
    }
    
    NSURL *url = [textView.attributedText attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:&range];
    if (url && fraction < 1)
    {
        [self handleURL:url];
        return;
    }

    characterIndex = MIN(characterIndex + round(fraction), textView.text.length); // In case fraction > 1, although it doesn't appear it can be
    [textView setSelectedRange:NSMakeRange(characterIndex, 0)];
    [textView becomeFirstResponder];
}

- (void)trashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self.note isEmptyInTag:self.indexItem.tag])
    {
        [self trashNote];
    }
    else
    {
        _deleteNoteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:NSLocalizedString(@"Delete Note", @"") otherButtonTitles:nil];
        [_deleteNoteActionSheet showInView:self.view];
    }
}

- (void)unarchiveBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPTagManager sharedManager] unarchiveNote:self.note];
    [self finishEditing];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.textChanged = YES;
    [self setTyping:YES animated:YES];
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
    if (self.textChanged)
    {
        [self saveNote:YES];
    }
    [self.navigationItem setRightBarButtonItems:@[_addNoteBarButtonItem, _actionBarButtonItem, _attachmentBarButtonItem] animated:YES];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange foundRange;
    NSString *prefix = [_bodyTextView.text hp_tagInRange:_bodyTextView.selectedRange enclosing:NO tagRange:&foundRange];
    _suggestionsView.prefix = prefix;
}

#pragma mark - HPTagSuggestionsViewDelegate

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectSuggestion:(NSString*)suggestion
{
    [[UIDevice currentDevice] playInputClick];
    NSRange foundRange;
    NSString *tag = [_bodyTextView.text hp_tagInRange:_bodyTextView.selectedRange enclosing:YES tagRange:&foundRange];
    if (!tag) return;
    
    UITextRange *textRange = [_bodyTextView hp_textRangeFromRange:foundRange];
    
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
    [[UIDevice currentDevice] playInputClick];
    NSRange replacementRange = _bodyTextView.selectedRange;
    UITextRange *textRange = [_bodyTextView hp_textRangeFromRange:replacementRange];
    
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
    else if (_attachmentActionSheet == actionSheet)
    {
        if (buttonIndex == _attachmentActionSheetCameraIndex)
        {
            [self presentImagePickerControllerWithType:UIImagePickerControllerSourceTypeCamera];
        }
        else if (buttonIndex == _attachmentActionSheetPhotosIndex)
        {
            [self presentImagePickerControllerWithType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
        _attachmentActionSheet = nil;
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

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize keyboardSize = [self.view convertRect:keyboardRect fromView:nil].size; // Account for orientation changes
    
    _originalBodyTextViewInset = _bodyTextView.contentInset;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(_originalBodyTextViewInset.top, _originalBodyTextViewInset.left, keyboardSize.height, _originalBodyTextViewInset.right);
    _originalTextContainerInset = _bodyTextView.textContainerInset;
    UIEdgeInsets textContainerInset = UIEdgeInsetsMake(_originalTextContainerInset.top, _originalTextContainerInset.left, 0, _originalTextContainerInset.right);
    
    [UIView hp_animateWithKeyboardNotification:notification animations:^{
        _bodyTextView.contentInset = contentInset;
        _bodyTextView.scrollIndicatorInsets = contentInset;
        _bodyTextView.textContainerInset = textContainerInset;
        [_bodyTextView scrollToVisibleCaretAnimated:NO];
    }];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    if (self.transitioning) return; // Do not animate keyboard when animating to list
    
    [self setTyping:NO animated:YES];
    
    UIEdgeInsets contentInset = UIEdgeInsetsMake(_bodyTextView.contentInset.top, _originalBodyTextViewInset.left, _originalBodyTextViewInset.bottom, _originalBodyTextViewInset.right);
    
    [UIView hp_animateWithKeyboardNotification:notification animations:^{
        _bodyTextView.contentInset = contentInset;
        _bodyTextView.scrollIndicatorInsets = contentInset;
        _bodyTextView.textContainerInset = _originalTextContainerInset;
    }];
}

#pragma mark - HPDataActionViewController

- (void)addContactWithEmail:(NSString *)email phoneNumber:(NSString *)phoneNumber image:(UIImage*)image
{ // Attempt to find addditional contact data in the note
    NSAttributedString *attributedText = self.noteTextView.attributedText;
    if (!email) email = [attributedText hp_valueOfLinkWithScheme:@"mailto"];
    if (!phoneNumber) phoneNumber = [attributedText hp_valueOfLinkWithScheme:@"tel"];
    if (!image)
    {
        NSAttributedString *attributedText = self.noteTextView.attributedText;
        image = [attributedText hp_imageOfFirstAttachment];
    }
    [super addContactWithEmail:email phoneNumber:phoneNumber image:image];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSUInteger index = _hasEnteredEditingModeOnce ? _bodyTextView.selectedRange.location : 0; // selectedRange gives the last position by default
    if (index == NSNotFound) index = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *data = UIImageJPEGRepresentation(image, 1);
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSUInteger actualIndex = [[HPNoteManager sharedManager] attachToNote:self.note data:data type:(NSString*)kUTTypeImage index:index]; // TODO: What happens with settings notes?
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                NSAttributedString *attributedText = self.note.attributedText;
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self animateAttachmentAtIndex:actualIndex inAttributedText:attributedText];
                });
            });
        });
    });
    [self dismissViewControllerAnimated:YES completion:^{
        dispatch_semaphore_signal(sema);
    }];
}

- (void)animateAttachmentAtIndex:(NSUInteger)index inAttributedText:(NSAttributedString*)attributedText
{
    self.noteTextView.attributedText = attributedText;
    self.textChanged = YES;
    
    CGRect destinationRect = [self.noteTextView hp_rectForCharacterRange:NSMakeRange(index, 1)];
    destinationRect = [self.view convertRect:destinationRect fromView:self.noteTextView];
    NSTextAttachment *textAttachment = [self.noteTextView.attributedText attribute:NSAttachmentAttributeName atIndex:index effectiveRange:nil];
    UIImage *scaledImage = textAttachment.image;
    [_bodyTextStorage beginAnimatingAttachmentAtIndex:index];
    CGRect originRect = [self.noteTextView hp_rectForCharacterRange:NSMakeRange(index, 1)];
    originRect = [self.view convertRect:originRect fromView:self.noteTextView];
    
    _attachmentAnimationView = [[UIImageView alloc] initWithImage:scaledImage];
    _attachmentAnimationView.frame = originRect;
    [self.view addSubview:_attachmentAnimationView];
    [self.view bringSubviewToFront:self.toolbar];
    [UIView animateWithDuration:HPNoteEditorAttachmentAnimationDuration animations:^{
        _attachmentAnimationView.frame = destinationRect;
    }];
    _attachmentAnimationStart = CACurrentMediaTime();
    _attachmentAnimationIndex = index;
    _attachmentAnimationDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(attachmentAnimation:)];
    [_attachmentAnimationDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)attachmentAnimation:(CADisplayLink*)displayLink
{
    CFTimeInterval timestamp = displayLink.timestamp;
    CFTimeInterval interval = timestamp - _attachmentAnimationStart;
    CGFloat progress = interval / HPNoteEditorAttachmentAnimationDuration;
    if (progress < 1)
    {
        [_bodyTextStorage setAnimationProgress:progress ofAttachmentAtIndex:_attachmentAnimationIndex];
    } else {
        [_bodyTextStorage endAnimatingAttachmentAtIndex:_attachmentAnimationIndex];
        [displayLink invalidate];
        [_attachmentAnimationView removeFromSuperview];
        _attachmentAnimationView = nil;
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if ([presented isKindOfClass:HPImageViewController.class])
    {
        HPImageZoomAnimationController *controller = [[HPImageZoomAnimationController alloc] initWithReferenceImage:_presentedImageMedium
                                                                          view:self.noteTextView
                                                                          rect:_presentedImageRect];
        controller.coverColor = [UIColor whiteColor];
        return controller;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    if ([dismissed isKindOfClass:HPImageViewController.class])
    {
        HPImageZoomAnimationController *controller = [[HPImageZoomAnimationController alloc] initWithReferenceImage:_presentedImageMedium
                                                                                                               view:self.noteTextView
                                                                                                               rect:_presentedImageRect];
        controller.coverColor = [UIColor whiteColor];
        return controller;
    }
    return nil;
}

#pragma mark - UIImageViewControllerDelegate

- (void)imageViewControllerDidDismiss:(HPImageViewController*)imageViewController
{
    [self didDismissImageViewController];
}

@end
