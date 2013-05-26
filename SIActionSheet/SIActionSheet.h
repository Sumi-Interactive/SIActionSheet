//
//  SIActionSheet.h
//  SIActionSheet
//
//  Created by Kevin Cao on 13-05-26.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const SIActionSheetWillShowNotification;
extern NSString *const SIActionSheetDidShowNotification;
extern NSString *const SIActionSheetWillDismissNotification;
extern NSString *const SIActionSheetDidDismissNotification;

@class SIActionSheet;

typedef NS_ENUM(NSInteger, SIActionSheetButtonType) {
    SIActionSheetButtonTypeDefault = 0,
    SIActionSheetButtonTypeDestructive,
    SIActionSheetButtonTypeCancel
};
typedef void(^SIActionSheetHandler)(SIActionSheet *actionSheet);

@interface SIActionSheet : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign, getter = isTapBackgroundToDismissEnabled) BOOL tapBackgroundToDismissEnabled;

@property (nonatomic, copy) SIActionSheetHandler willShowHandler;
@property (nonatomic, copy) SIActionSheetHandler didShowHandler;
@property (nonatomic, copy) SIActionSheetHandler willDismissHandler;
@property (nonatomic, copy) SIActionSheetHandler didDismissHandler;

- (id)initWithTitle:(NSString *)title;
- (void)addButtonWithTitle:(NSString *)title type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler;

- (void)show;
// TODO: iPad support
//- (void)showFromRect:(CGRect)rect inView:(UIView *)view;
- (void)dismissAnimated:(BOOL)animated;

@end
