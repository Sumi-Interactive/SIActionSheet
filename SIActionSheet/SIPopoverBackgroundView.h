//
//  SIPopoverBackgroundView.h
//  SIActionSheet
//
//  Created by Kevin Cao on 13-8-7.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SIPopoverBackgroundView : UIPopoverBackgroundView

@property (nonatomic, strong) UIColor *tintColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is white
@property (nonatomic, assign) CGFloat borderWidth NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 0.0
@property (nonatomic, assign) CGFloat cornerRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 4.0

@end
