//
//  AGNTagTapGestureRecognizer.h
//  Agnes
//
//  Created by Hermés Piqué on 17/03/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AGNTagTapGestureRecognizer : UITapGestureRecognizer

@property (nonatomic, readonly) NSRange tagRange;
@property (nonatomic, readonly) CGRect tagRect;

@end
