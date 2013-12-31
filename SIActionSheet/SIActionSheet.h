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

extern NSString *const SIActionSheetDismissNotificationUserInfoButtonIndexKey;

@class SIActionSheet;

typedef NS_ENUM(NSInteger, SIActionSheetButtonType) {
    SIActionSheetButtonTypeDefault = 0,
    SIActionSheetButtonTypeDestructive,
    SIActionSheetButtonTypeCancel
};
typedef void(^SIActionSheetShowHandler)(SIActionSheet *actionSheet);
typedef void(^SIActionSheetDismissHandler)(SIActionSheet *actionSheet, NSInteger buttonIndex);

@interface SIActionSheet : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL allowTapBackgroundToDismiss;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

@property (nonatomic, copy) SIActionSheetShowHandler willShowHandler;
@property (nonatomic, copy) SIActionSheetShowHandler didShowHandler;
@property (nonatomic, copy) SIActionSheetDismissHandler willDismissHandler;
@property (nonatomic, copy) SIActionSheetDismissHandler didDismissHandler;

@property (nonatomic, strong) UIColor *viewBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *titleColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *titleFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *defaultButtonColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *defaultButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *defaultButtonFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *cancelButtonColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *cancelButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *cancelButtonFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *destructiveButtonColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *destructiveButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *destructiveButtonFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *seperatorColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat shadowOpacity NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 0.5

- (id)initWithTitle:(NSString *)title;
- (void)addButtonWithTitle:(NSString *)title type:(SIActionSheetButtonType)type handler:(SIActionSheetShowHandler)handler;

- (void)show;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view;
- (void)dismissWithButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated; // (buttonIndex == -1) means no button is clicked.

@end
