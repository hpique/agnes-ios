//
//  AGNNoteViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNNoteViewController.h"
#import "AGNTagTapGestureRecognizer.h"
#import "AGNTypingController.h"
#import "HPNote.h"
#import "HPNote+Detail.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPBaseTextStorage.h"
#import "HPTagSuggestionsView.h"
#import "HPNoteAction.h"
#import "HPIndexItem.h"
#import "HPNoteActivityItemSource.h"
#import "AGNPreferencesManager.h"
#import "HPBrowserViewController.h"
#import "HPFontManager.h"
#import "HPAttachment.h"
#import "HPImageViewController.h"
#import "HPImageZoomAnimationController.h"
#import "NSString+hp_utils.h"
#import "HPNoFirstResponderActionSheet.h"
#import "HPAgnesUIMetrics.h"
#import "HPDataActionController.h"
#import "HPTracker.h"
#import "HPTextInteractionTapGestureRecognizer.h"
#import "UIImage+hp_utils.h"
#import "UITextView+hp_utils.h"
#import "UIViewController+hp_modals.h"
#import <PSPDFTextView/PSPDFTextView.h>
#import <MobileCoreServices/MobileCoreServices.h>

const NSTimeInterval AGNNoteEditorAttachmentAnimationDuration = 0.3;
const CGFloat AGNNoteEditorAttachmentAnimationFrameRate = 60;

@interface AGNNoteViewController () <UITextViewDelegate, UIActionSheetDelegate, HPTagSuggestionsViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIViewControllerTransitioningDelegate, HPImageViewControllerDelegate, HPTextInteractionTapGestureRecognizerDelegate, AGNTypingControllerDelegate, HPDataActionControllerDelegate>

@property (nonatomic, assign) HPNoteDetailMode detailMode;
@property (nonatomic, assign) BOOL textChanged;

@end

@implementation AGNNoteViewController {
    PSPDFTextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    UIEdgeInsets _originalTextContainerInset;
    HPBaseTextStorage *_bodyTextStorage;

    UIBarButtonItem *_actionBarButtonItem;
    UIBarButtonItem *_attachmentBarButtonItem;
    UIBarButtonItem *_addNoteBarButtonItem;
    UIBarButtonItem *_archiveBarButtonItem;
    UIBarButtonItem *_detailBarButtonItem;
    UIBarButtonItem *_doneBarButtonItem;
    UIBarButtonItem *_trashBarButtonItem;
    UIBarButtonItem *_unarchiveBarButtonItem;
    
    IBOutlet UILabel *_detailLabel;

    UIPopoverController *_navigationBarPopoverController;
    UIActionSheet *_attachmentActionSheet;
    NSInteger _attachmentActionSheetCameraIndex;
    NSInteger _attachmentActionSheetPhotosIndex;
    UIActionSheet *_deleteNoteActionSheet;
    HPDataActionController *_dataActionController;
    
    NSMutableArray *_notes;
    NSInteger _noteIndex;
    HPTag *_currentTag;

    HPTagSuggestionsView *_suggestionsView;
    BOOL _viewDidAppear;
    BOOL _hasEnteredEditingModeOnce;
    
    NSUInteger _presentedImageCharacterIndex;
    UIImage *_presentedImageMedium;
    CGRect _presentedImageRect;
    HPImageViewController *_presentedImageViewController;
    
    NSTimer *_autosaveTimer;
    
    AGNTypingController *_typingController;
    
    __weak IBOutlet NSLayoutConstraint *_toolbarHeightConstraint;
    
    CFTimeInterval _attachmentAnimationStart;
    UIView *_attachmentAnimationView;
    CADisplayLink *_attachmentAnimationDisplayLink;
    NSUInteger _attachmentAnimationIndex;
    
    CGPoint _scrollViewPreviousOffset;
    
    BOOL _ignoreNotesDidChangeNotification;
}

@synthesize notes = _notes;
@synthesize noteTextView = _bodyTextView;
@synthesize search = _search;
@synthesize transitioning = _transitioning;
@synthesize wantsDefaultTransition = _wantsDefaultTransition;

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-plus"] style:UIBarButtonItemStylePlain target:self action:@selector(addNoteBarButtonItemAction:)];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    
    {
        _bodyTextStorage = [HPBaseTextStorage new];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        CGSize containerSize = CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [_bodyTextStorage addLayoutManager:layoutManager];
        _bodyTextStorage.tag = _currentTag.name;
        
        _bodyTextView = [[PSPDFTextView alloc] initWithFrame:self.view.bounds textContainer:container];
        _bodyTextView.opaque = NO;
        _bodyTextView.backgroundColor = [UIColor clearColor]; // Allows nicer transition for text elements when returning to the list
        _bodyTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bodyTextView.font = [HPFontManager sharedManager].fontForNoteBody;

        _bodyTextView.delegate = self;
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        [self.view addSubview:_bodyTextView];
        [self.view bringSubviewToFront:self.toolbar];
        
        UIGestureRecognizer *textInteractionGestureRecognizer = [HPTextInteractionTapGestureRecognizer new];
        textInteractionGestureRecognizer.delegate = self;
        [_bodyTextView addGestureRecognizer:textInteractionGestureRecognizer];
        
        UIGestureRecognizer *tagGestureRecognizer = [AGNTagTapGestureRecognizer new];
        tagGestureRecognizer.delegate = self;
        [tagGestureRecognizer addTarget:self action:@selector(tagTapGesture:)];
        [_bodyTextView addGestureRecognizer:tagGestureRecognizer];
    }
    
    [self layoutToolbar];
    [self updateTextInset];
    
    if (!_note)
    {
        self.note = [self insertBlankNote];
    }
    [self displayNote];
    
    _typingController = [AGNTypingController new];
    _typingController.delegate = self;
    
    _dataActionController = [HPDataActionController new];
    _dataActionController.delegate = self;
}

- (void)dealloc
{
    [_autosaveTimer invalidate];
    [_attachmentAnimationDisplayLink invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[HPTracker defaultTracker] trackScreenWithName:@"Note"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.note isNew] && !_viewDidAppear)
    {
        _bodyTextView.selectedRange = NSMakeRange(0, 0);
        [_bodyTextView becomeFirstResponder];
    }
    _viewDidAppear = YES;
    self.transitioning = NO;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateTextInset];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_typingController.typing) [_typingController setTyping:NO animated:animated];
    if (!self.transitioning) return; // Don't continue if we're presenting a modal controller
    
    // TODO: Do this only when we're transitiong back to the list or to the menu
    for (HPNote *note in self.notes)
    {
        if (!self.indexItem.disableRemove && [note isEmptyInTag:_currentTag])
        {
            _ignoreNotesDidChangeNotification = YES;
            [[HPNoteManager sharedManager] trashNote:note];
            _ignoreNotesDidChangeNotification = NO;
        }
    }
    
    [self hp_dismissActionSheet:&_attachmentActionSheet animated:animated];
    [self hp_dismissActionSheet:&_deleteNoteActionSheet animated:animated];
    [self hp_dismissPopover:&_navigationBarPopoverController animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.transitioning = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.noteTextView resignFirstResponder];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self layoutToolbar];
    [self updateTextInset];
}

#pragma mark - Class

+ (AGNNoteViewController*)noteViewControllerWithNote:(HPNote*)note notes:(NSArray*)notes indexItem:(HPIndexItem *)indexItem
{
    AGNNoteViewController *noteViewController = [[AGNNoteViewController alloc] init];
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
    
    if (![note isNew] || ![_bodyTextView.text hp_isEmptyInTag:_currentTag])
    {
        NSMutableString *mutableText = [NSMutableString stringWithString:self.noteTextView.text];
        const BOOL changed = [HPNoteAction willEditNote:note text:mutableText editor:self.noteTextView];
        NSAttributedString *attributedText = self.noteTextView.attributedText;
        NSArray *attachments = [attributedText hp_attachments];
        _ignoreNotesDidChangeNotification = YES;
        [[HPNoteManager sharedManager] editNote:self.note text:mutableText attachments:attachments];
        _ignoreNotesDidChangeNotification = NO;
        if (changed)
        {
            NSMutableAttributedString *attributedText = self.note.attributedText.mutableCopy;
            [HPNoteAction willDisplayNote:self.note text:attributedText view:self.noteTextView];
            _bodyTextView.attributedText = attributedText;
        }
        [self updateToolbar:animated];
        [self displayDetail];
        self.textChanged = NO;

        _currentTag = [self bestTagForNewNotes];
        return YES;
    }
    return NO;
}

- (void)setNote:(HPNote *)note
{
    _note = note;
    _detailMode = note.detailMode;
    _noteIndex = _note ? [_notes indexOfObject:_note] : NSNotFound;
}

- (void)setNotes:(NSArray*)notes
{
    NSArray *reversed = [notes reverseObjectEnumerator].allObjects;
    _notes = reversed.mutableCopy;
    _noteIndex = _note ? [_notes indexOfObject:_note] : NSNotFound;
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    _currentTag = indexItem.tag;
    _bodyTextStorage.tag = _currentTag.name;
}

#pragma mark Layout

+ (CGFloat)minimumNoteWidth
{
    const CGFloat minimumWidth = 768 - 240; // For iPad
    const CGFloat sideMargin = [HPAgnesUIMetrics sideMarginForInterfaceOrientation:UIInterfaceOrientationPortrait width:minimumWidth]; // Portrait has the smallest margins
    const CGSize screenSize = [UIScreen mainScreen].bounds.size;
    const CGFloat minLength = MIN(MIN(screenSize.width, screenSize.height), minimumWidth);
    const CGFloat width = minLength - sideMargin * 2;
    return width;
}

#pragma mark Layout (private)

- (void)updateTextInset
{
    const CGFloat width = self.view.bounds.size.width;
    const CGFloat sideMargin = [HPAgnesUIMetrics sideMarginForInterfaceOrientation:self.interfaceOrientation width:width];
    const CGFloat sideInset = sideMargin - _bodyTextView.textContainer.lineFragmentPadding;
    _bodyTextView.textContainerInset = UIEdgeInsetsMake(20, sideInset, 20 + self.toolbar.frame.size.height, sideInset);
}

- (void)layoutToolbar
{
    const CGFloat height = self.navigationController.toolbar.frame.size.height;
    _toolbarHeightConstraint.constant = height;
}

#pragma mark - Private

- (void)autosave
{
    if (!(self.note.canAutosave)) return;
    [self saveNote:NO];
}

- (HPTag*)bestTagForNewNotes
{
    NSSet *currentUserTags = self.note.userTags;
    if (currentUserTags.count == 0) return _currentTag;
    if (currentUserTags.count == 1) return [currentUserTags anyObject];
    
    NSCountedSet *tags = [NSCountedSet set];
    NSArray *notes = self.notes.copy;
    for (HPNote *note in notes)
    {
        [tags unionSet:note.userTags];
    }
    HPTag *bestTag = nil;
    NSUInteger maxCount = 0;
    for (HPTag *tag in tags)
    {
        const NSUInteger count = [tags countForObject:tag];
        if (count > maxCount)
        {
            bestTag = tag;
            maxCount = count;
        }
    }
    return bestTag ? : _currentTag;
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
    
    [self saveNote:YES];
    self.note = [self insertBlankNote];
    [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlUp];
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
    _ignoreNotesDidChangeNotification = YES;
    [[HPNoteManager sharedManager] viewNote:self.note];
    _ignoreNotesDidChangeNotification = NO;
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

- (void)didDismissImageViewController
{
    _presentedImageMedium = nil;
    _presentedImageRect = CGRectNull;
    _presentedImageViewController = nil;
}

- (void)finishEditing
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleURL:(NSURL*)url fromRect:(CGRect)rect inView:(UIView*)view
{
    NSString *scheme = url.scheme;
    if ([scheme hasPrefix:@"http"])
    {
        [self openBrowserURL:url];
    }
    else
    {
        [_dataActionController showActionSheetForURL:url fromRect:rect inView:view];
    }
}

- (HPNote*)insertBlankNote
{
    HPNote *note = [[HPNoteManager sharedManager] blankNoteWithTag:_currentTag];
    if (_notes.count == 0)
    {
        _notes = [NSMutableArray arrayWithObject:note];
    }
    else
    {
        [_notes insertObject:note atIndex:_noteIndex + 1];
    }
    return note;
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
    _ignoreNotesDidChangeNotification = YES;
    [[HPNoteManager sharedManager] setDetailMode:self.detailMode ofNote:self.note];
    _ignoreNotesDidChangeNotification = NO;
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

- (void)trashNote
{
    _ignoreNotesDidChangeNotification = YES;
    [[HPNoteManager sharedManager] trashNote:self.note];
    _ignoreNotesDidChangeNotification = NO;
    [_notes removeObject:self.note];
    self.note = nil;
    [self finishEditing];
}

- (void)updateToolbar:(BOOL)animated
{
    UIBarButtonItem *rightBarButtonItem = self.note.archived ? _unarchiveBarButtonItem : _archiveBarButtonItem;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.toolbar setItems:@[_trashBarButtonItem, flexibleSpace, _detailBarButtonItem, flexibleSpace, rightBarButtonItem] animated:animated];
}

#pragma mark Toolbar

- (void)archiveBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self hp_dismissActionSheet:&_deleteNoteActionSheet animated:YES]) return;
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"archive_note"];
    [[HPTagManager sharedManager] archiveNote:self.note];
    [self finishEditing];
}

- (IBAction)detailLabelTapGestureRecognizer:(id)sender
{
    if ([self hp_dismissActionSheet:&_deleteNoteActionSheet animated:YES]) return;
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"toggle_note_detail"];
    self.detailMode = (self.detailMode + 1) % HPNoteDetailModeCount;
    [self displayDetail];
}

- (void)trashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self hp_dismissActionSheet:&_deleteNoteActionSheet animated:YES]) return;
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"trash_note"];
    if ([self.note isEmptyInTag:_currentTag])
    {
        [self trashNote];
    }
    else
    {
        _deleteNoteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:NSLocalizedString(@"Delete Note", @"") otherButtonTitles:nil];
        [_deleteNoteActionSheet showFromBarButtonItem:barButtonItem animated:YES];
    }
}

- (void)unarchiveBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self hp_dismissActionSheet:&_deleteNoteActionSheet animated:YES]) return;
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"unarchive_note"];
    [[HPTagManager sharedManager] unarchiveNote:self.note];
    [self finishEditing];
}

#pragma mark Navigation Bar

- (void)actionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self hp_dismissPopover:&_navigationBarPopoverController animated:YES]) return;
    [self hp_dismissActionSheet:&_attachmentActionSheet animated:YES];
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"share_note"];
    [self autosave];
    HPNoteActivityItemSource *activityItem = [[HPNoteActivityItemSource alloc] initWithNote:self.note];
    activityItem.selectedRange = _bodyTextView.selectedRange;
    NSMutableArray *items = [NSMutableArray arrayWithObject:activityItem];
    NSAttributedString *attributedText = self.noteTextView.attributedText;
    UIImage *attachmentImage = [attributedText hp_imageOfFirstAttachment];
    if (attachmentImage) [items addObject:attachmentImage];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    _navigationBarPopoverController = [self hp_presentActivityViewController:activityViewController fromBarButtonItem:barButtonItem animated:YES];
    if (_navigationBarPopoverController)
    {
        activityViewController.completionHandler = ^(NSString *activityType, BOOL completed){
            [_navigationBarPopoverController dismissPopoverAnimated:YES];
            _navigationBarPopoverController = nil;
        };
    }
}

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self hp_dismissActionSheet:&_attachmentActionSheet animated:YES];
    [self hp_dismissPopover:&_navigationBarPopoverController animated:YES];
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"add_note"];
    [self changeToEmptyNote];
}

- (void)attachmentBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self hp_dismissActionSheet:&_attachmentActionSheet animated:YES]) return;
    [self hp_dismissPopover:&_navigationBarPopoverController animated:YES];
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"add_attachment"];
    _attachmentActionSheet = [HPNoFirstResponderActionSheet new];
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
    
    [_attachmentActionSheet showFromBarButtonItem:barButtonItem animated:YES];
}

#pragma mark Actions

- (void)attachmentTrashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"trash_attachment"];
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
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"share_attachment"];
    UIImage *image = _presentedImageViewController.image;
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    [_presentedImageViewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)doneBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"dismiss_keyboard"];
    [self.view endEditing:YES];
}

- (IBAction)swipeRightAction:(id)sender
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"swipe_right"];
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
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"swipe_left"];
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

- (IBAction)swipeDown:(id)sender
{ // For when the text view doesn't have enough content to enable scrolling
    [_typingController setTyping:NO animated:YES];
}

- (void)tagTapGesture:(AGNTagTapGestureRecognizer*)gestureRecognizer
{
    NSString *tagName = [_bodyTextView.text substringWithRange:gestureRecognizer.tagRange];
    HPTag *tag = [[HPTagManager sharedManager] tagWithName:tagName];
    HPIndexItem *indexItem = [HPIndexItem indexItemWithTag:tag];
    [self.delegate noteViewController:self didSelectIndexItem:indexItem];
    [self finishEditing];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _scrollViewPreviousOffset = scrollView.contentOffset;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!scrollView.isDragging) return;
    const CGPoint offset = scrollView.contentOffset;
    if (_scrollViewPreviousOffset.y > offset.y)
    { // Scrolling down
        [_typingController setTyping:NO animated:YES];
    }
    _scrollViewPreviousOffset = offset;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    textView.inputAccessoryView = nil;
    _suggestionsView = [HPTagSuggestionsView new];
    _suggestionsView.delegate = self;
    NSRange tagRange;
    _suggestionsView.prefix = [_bodyTextView.text hp_tagInRange:textView.selectedRange enclosing:NO tagRange:&tagRange];
    textView.inputAccessoryView = _suggestionsView;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.textChanged = YES;
    [_typingController setTyping:YES animated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    _hasEnteredEditingModeOnce = YES;
    _bodyTextStorage.search = nil;
    [self.navigationItem setRightBarButtonItems:@[_doneBarButtonItem, _actionBarButtonItem, _attachmentBarButtonItem] animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self saveNote:YES];
    [self.navigationItem setRightBarButtonItems:@[_addNoteBarButtonItem, _actionBarButtonItem, _attachmentBarButtonItem] animated:YES];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange tagRange;
    _suggestionsView.prefix = [textView.text hp_tagInRange:_bodyTextView.selectedRange enclosing:NO tagRange:&tagRange];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    [_typingController performSelector:@selector(finishTyping) withObject:nil afterDelay:0.5]; // Give time to UITextView to update the selection
    return !_bodyTextView.isFirstResponder;
}

#pragma mark AGNTypingControllerDelegate

- (UINavigationController*)navigationControllerForTypingController:(AGNTypingController*)typingController
{
    return self.navigationController;
}

- (void)typingController:(AGNTypingController*)typingController didShowBarsAnimated:(BOOL)animated
{
    [_bodyTextView scrollToVisibleCaretAnimated:NO];
}

#pragma mark HPTextInteractionTapGestureRecognizerDelegate

-(void)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer handleTapOnURL:(NSURL*)url inRange:(NSRange)characterRange
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"click_link"];
    
    const CGRect rect = [_bodyTextView hp_rectForCharacterRange:characterRange];
    [self handleURL:url fromRect:rect inView:_bodyTextView];
}

-(void)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer handleTapOnTextAttachment:(NSTextAttachment*)textAttachment inRange:(NSRange)characterRange
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"show_attachment"];
    [self presentTextAttachment:textAttachment atIndex:characterRange.location];
}

#pragma mark - HPTagSuggestionsViewDelegate

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectSuggestion:(NSString*)suggestion
{
    [[UIDevice currentDevice] playInputClick];
    NSRange foundRange;
    NSString *tag = [_bodyTextView.text hp_tagInRange:_bodyTextView.selectedRange enclosing:YES tagRange:&foundRange];
    if (!tag) return;
    
    NSString *text = _bodyTextView.text;
    NSString *replacement = [text hp_stringByAddingSorroundingSpacesToString:suggestion inRange:foundRange];
    UITextRange *textRange = [_bodyTextView hp_textRangeFromRange:foundRange];
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
}

#pragma mark Notifications

- (void)applicationWillResignActiveNotification:(NSNotification*)notification
{
    [self autosave];
}

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

    // Neither of these properties can be animated
    _bodyTextView.contentInset = contentInset;
    _bodyTextView.scrollIndicatorInsets = contentInset;
    _bodyTextView.textContainerInset = textContainerInset;
}

- (void)keyboardDidShowNotification:(NSNotification *)notification
{
    // TODO: Do this earlier
    [_bodyTextView scrollToVisibleCaretAnimated:YES];
}

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    if (_ignoreNotesDidChangeNotification) return;
    
    NSDictionary *userInfo = notification.userInfo;
    NSSet *deleted = userInfo[NSDeletedObjectsKey];
    if ([deleted containsObject:_note])
    {
        [self finishEditing];
    }
    else
    {
        NSMutableArray *notes = _notes.mutableCopy;
        [notes removeObjectsInArray:deleted.allObjects];
        _notes = notes;
        _noteIndex = [notes indexOfObject:_note];
    }
    NSSet *updated = userInfo[NSUpdatedObjectsKey];
    if ([updated containsObject:_note])
    {
        [self displayNote];
    }

}

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    if (_currentTag)
    {
        NSDictionary *userInfo = notification.userInfo;
        NSSet *deleted = userInfo[NSDeletedObjectsKey];
        if ([deleted containsObject:_currentTag])
        {
            _currentTag = nil;
        }
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    if (self.transitioning) return; // Do not animate keyboard when animating to list
    
    [_typingController setTyping:NO animated:YES];
    
    UIEdgeInsets contentInset = UIEdgeInsetsMake(_bodyTextView.contentInset.top, _originalBodyTextViewInset.left, _originalBodyTextViewInset.bottom, _originalBodyTextViewInset.right);

    // Neither of these properties can be animated
    _bodyTextView.contentInset = contentInset;
    _bodyTextView.scrollIndicatorInsets = contentInset;
    _bodyTextView.textContainerInset = _originalTextContainerInset;
}

#pragma mark - HPDataActionControllerDelegate

- (UIViewController*)viewControllerForDataActionController:(HPDataActionController*)dataActionController
{
    return self;
}

- (void)dataActionController:(HPDataActionController*)dataActionController willAddContact:(HPContact*)contact
{ // Attempt to find addditional contact data in the note
    NSAttributedString *attributedText = self.noteTextView.attributedText;
    if (!contact.email) contact.email = [attributedText hp_valueOfLinkWithScheme:@"mailto"];
    if (!contact.phoneNumber) contact.phoneNumber = [attributedText hp_valueOfLinkWithScheme:@"tel"];
    if (!contact.image)
    {
        NSAttributedString *attributedText = self.noteTextView.attributedText;
        contact.image = [attributedText hp_imageOfFirstAttachment];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSUInteger index = _hasEnteredEditingModeOnce ? _bodyTextView.selectedRange.location : 0; // selectedRange gives the last position by default
    if (index == NSNotFound) index = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *data = UIImageJPEGRepresentation(image, AGNAttachmentImageQuality);
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            _ignoreNotesDidChangeNotification = YES;
            NSUInteger actualIndex = [[HPNoteManager sharedManager] attachToNote:self.note data:data type:(NSString*)kUTTypeImage index:index]; // TODO: What happens with settings notes?
            _ignoreNotesDidChangeNotification = NO;
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
    [UIView animateWithDuration:AGNNoteEditorAttachmentAnimationDuration animations:^{
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
    CGFloat progress = interval / AGNNoteEditorAttachmentAnimationDuration;
    if (progress < 1)
    {
        [_bodyTextStorage setAnimationProgress:progress ofAttachmentAtIndex:_attachmentAnimationIndex];
    }
    else
    {
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

#pragma mark UIImageViewControllerDelegate

- (void)imageViewControllerDidDismiss:(HPImageViewController*)imageViewController
{
    [self didDismissImageViewController];
}

@end
