//
//  HPTagSuggestionsView.h
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HPTagSuggestionsViewDelegate;

@interface HPTagSuggestionsView : UIInputView<UIInputViewAudioFeedback>

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, readonly) NSArray *suggestions;
@property (nonatomic, weak) id<HPTagSuggestionsViewDelegate> delegate;

@end

@protocol HPTagSuggestionsViewDelegate <NSObject>

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectSuggestion:(NSString*)suggestion;

- (void)tagSuggestionsView:(HPTagSuggestionsView *)tagSuggestionsView didSelectKey:(NSString*)key;

@end
