//
//  HPTagSuggestionsView.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTagSuggestionsView.h"
#import "HPTagManager.h"
#import "HPTag.h"
#import "HPKeyboardButton.h"

@interface HPHashSupplementaryView : UICollectionReusableView

@property (nonatomic, readonly) HPKeyboardButton *button;

@end

@interface HPTagSuggestionCell : UICollectionViewCell

@property (nonatomic, readonly) HPKeyboardButton *button;

@end

@interface HPTagSuggestionsView()<UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation HPTagSuggestionsView {
    UICollectionView *_suggestionsView;
}

- (id)initWithFrame:(CGRect)frame inputViewStyle:(UIInputViewStyle)inputViewStyle
{
    self = [super initWithFrame:frame inputViewStyle:inputViewStyle];
    if (self) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 6;
        layout.minimumInteritemSpacing = 0;
        _suggestionsView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _suggestionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _suggestionsView.dataSource = self;
        _suggestionsView.delegate = self;
        _suggestionsView.showsHorizontalScrollIndicator = NO;
        _suggestionsView.showsVerticalScrollIndicator = NO;
        _suggestionsView.contentInset = UIEdgeInsetsMake(0, 3, 0, 3);
        _suggestionsView.backgroundColor = [UIColor clearColor];
        [_suggestionsView registerClass:[HPTagSuggestionCell class] forCellWithReuseIdentifier:@"Cell"];
        [_suggestionsView registerClass:[HPHashSupplementaryView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
        [self addSubview:_suggestionsView];
    }
    return self;
}

- (void)layoutSubviews
{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)_suggestionsView.collectionViewLayout;
    const CGFloat height = self.bounds.size.height;
    layout.itemSize = CGSizeMake(100, height);
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    CGSize buttonSize = [HPKeyboardButton sizeForOrientation:interfaceOrientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const CGFloat keySeparator = landscape ? 5 : 6;
    layout.headerReferenceSize = CGSizeMake(buttonSize.width + keySeparator, height);
    CGFloat sideInset = landscape ? 23 : 3;
    _suggestionsView.contentInset = UIEdgeInsetsMake(0, sideInset, 0, sideInset);
    [_suggestionsView.collectionViewLayout invalidateLayout];
    [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible
{
    return YES;
}

#pragma mark - Public

- (void)setPrefix:(NSString *)prefix
{
    _prefix = prefix;
    HPTagManager *manager = [HPTagManager sharedManager];
    NSArray *tagNames = self.prefix ? [manager tagNamesWithPrefix:prefix] : @[];
    tagNames = [tagNames sortedArrayWithOptions:kNilOptions usingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
        HPTag *tag1 = [manager tagForName:name1];
        HPTag *tag2 = [manager tagForName:name2];
        const NSUInteger count1 = tag1 ? tag1.cd_notes.count : 0;
        const NSUInteger count2 = tag2 ? tag2.cd_notes.count : 0;
        if (count1 < count2) return NSOrderedDescending;
        if (count1 > count2) return NSOrderedAscending;
        const NSUInteger length1 = name1.length;
        const NSUInteger length2 = name2.length;
        if (length1 < length2) return NSOrderedAscending;
        if (length1 > length2) return NSOrderedDescending;
        return [name1 compare:name2 options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
    }];
    _suggestions = tagNames;
    [_suggestionsView reloadData];
}

#pragma mark - Private

- (void)hashButtonAction:(UIButton*)sender
{
    NSString *key = [sender titleForState:UIControlStateNormal];
    [self.delegate tagSuggestionsView:self didSelectKey:key];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return MIN(_suggestions.count, 6);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader)
    {
        HPHashSupplementaryView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
        [view.button addTarget:self action:@selector(hashButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        return view;
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HPTagSuggestionCell *cell= [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *suggestion = _suggestions[indexPath.row];
    [cell.button setTitle:suggestion forState:UIControlStateNormal];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *suggestion = _suggestions[indexPath.row];
    [self.delegate tagSuggestionsView:self didSelectSuggestion:suggestion];
}

@end

@implementation HPTagSuggestionCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _button = [[HPKeyboardButton alloc] initWithFrame:self.bounds];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.enabled = NO;
        [self.contentView addSubview:_button];
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_button);
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_button]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDictionary];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_button
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:-1]]; // For the shadow
        [self.contentView addConstraints:constraints];
    }
    return self;
}

@end

@implementation HPHashSupplementaryView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _button = [[HPKeyboardButton alloc] init];
        [_button setTitle:@"#" forState:UIControlStateNormal];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_button];
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_button);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_button]-6-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDictionary]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_button
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:-1]]; // For the shadow
    }
    return self;
}

@end