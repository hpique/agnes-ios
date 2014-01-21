//
//  HPTagSuggestionsView.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTagSuggestionsView.h"
#import "HPTagManager.h"
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
        _suggestionsView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _suggestionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _suggestionsView.dataSource = self;
        _suggestionsView.delegate = self;
        _suggestionsView.contentInset = UIEdgeInsetsMake(0, 3, 0, 3);
        _suggestionsView.backgroundColor = [UIColor clearColor];
        [_suggestionsView registerClass:[HPTagSuggestionCell class] forCellWithReuseIdentifier:@"Cell"];
        [_suggestionsView registerClass:[HPHashSupplementaryView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
        [self addSubview:_suggestionsView];
    }
    return self;
}

#pragma mark - Public

- (void)setPrefix:(NSString *)prefix
{
    _prefix = prefix;
    _suggestions = self.prefix ? [[HPTagManager sharedManager] tagNamesWithPrefix:prefix] : @[];
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
    return _suggestions.count;
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

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100, 44);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(26 + 6, 44);
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
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0]];
    }
    return self;
}

@end