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
typedef void(^SIActionSheetHandler)(SIActionSheet *actionSheet);
typedef void(^SIActionSheetDismissHandler)(SIActionSheet *actionSheet, NSInteger buttonIndex);

@interface SIActionSheet : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSAttributedString *attributedTitle;

@property (nonatomic, assign) BOOL allowTapBackgroundToDismiss;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

@property (nonatomic, copy) SIActionSheetHandler willShowHandler;
@property (nonatomic, copy) SIActionSheetHandler didShowHandler;
@property (nonatomic, copy) SIActionSheetDismissHandler willDismissHandler;
@property (nonatomic, copy) SIActionSheetDismissHandler didDismissHandler;

// theme

@property (nonatomic, strong) UIColor *viewBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is [UIColor white]
@property (nonatomic, strong) UIColor *seperatorColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is [UIColor colorWithWhite:0 alpha:0.1]
@property (nonatomic, assign) CGFloat cornerRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 2.0
@property (nonatomic, assign) CGFloat shadowRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 0.0

@property (nonatomic, strong) NSDictionary *titleAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSDictionary *defaultButtonAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDictionary *cancelButtonAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDictionary *destructiveButtonAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *defaultButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *cancelButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *destructiveButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;

- (id)initWithTitle:(NSString *)title;
- (id)initWithAttributedTitle:(NSAttributedString *)attributedTitle;
- (void)addButtonWithTitle:(NSString *)title type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler;
- (void)addButtonWithTitle:(NSString *)title font:(UIFont *)font color:(UIColor *)color type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler;
- (void)addButtonWithAttributedTitle:(NSAttributedString *)attributedTitle type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler;

- (void)show;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view;
- (void)dismissWithButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated; // (buttonIndex == -1) means no button is clicked.

@end
