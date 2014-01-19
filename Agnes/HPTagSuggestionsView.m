//
//  HPTagSuggestionsView.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTagSuggestionsView.h"
#import "HPNoteManager.h"

@interface HPTagSuggestionCell : UICollectionViewCell

@property (nonatomic, readonly) UILabel *label;

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
        _suggestionsView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _suggestionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _suggestionsView.dataSource = self;
        _suggestionsView.delegate = self;
        _suggestionsView.backgroundColor = [UIColor clearColor];
        [_suggestionsView registerClass:[HPTagSuggestionCell class] forCellWithReuseIdentifier:@"Cell"];
        [self addSubview:_suggestionsView];
    }
    return self;
}

#pragma mark - Public

- (void)setPrefix:(NSString *)prefix
{
    _prefix = prefix;
    _suggestions = [[HPNoteManager sharedManager] tagNamesWithPrefix:prefix];
    [_suggestionsView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _suggestions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HPTagSuggestionCell *cell= [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.label.text = _suggestions[indexPath.row];
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

@end

@implementation HPTagSuggestionCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _label = [[UILabel alloc] initWithFrame:self.bounds];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_label];
    }
    return self;
}

@end