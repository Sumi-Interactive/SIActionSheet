//
//  SIActionSheet.m
//  SIActionSheet
//
//  Created by Kevin Cao on 13-05-26.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "SIActionSheet.h"
#import "SIPopoverBackgroundView.h"
#import "UIWindow+SIUtils.h"
#import <QuartzCore/QuartzCore.h>

#define HEADER_HEIGHT 40
#define ROW_HEIGHT 54
#define VERTICAL_INSET 8
#define HORIZONTAL_PADDING 20
#define PADDING_TOP 20
#define GAP 20
#define TITLE_LINES_MAX 5

NSString *const SIActionSheetWillShowNotification = @"SIActionSheetWillShowNotification";
NSString *const SIActionSheetDidShowNotification = @"SIActionSheetDidShowNotification";
NSString *const SIActionSheetWillDismissNotification = @"SIActionSheetWillDismissNotification";
NSString *const SIActionSheetDidDismissNotification = @"SIActionSheetDidDismissNotification";

NSString *const SIActionSheetDismissNotificationUserInfoButtonIndexKey = @"SIActionSheetDismissNotificationUserInfoButtonIndexKey";

@interface SIActionSheet () <UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIWindow *actionsheetWindow;
@property (nonatomic, strong) UIWindow *oldKeyWindow;
@property (nonatomic, strong) UIPopoverController *popoverController;
#ifdef __IPHONE_7_0
@property (nonatomic, assign) UIViewTintAdjustmentMode oldTintAdjustmentMode;
#endif


- (CGFloat)preferredHeight;

@end

@interface SIActionSheetItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIActionSheetButtonType type;
@property (nonatomic, copy) SIActionSheetShowHandler action;

@end

@implementation SIActionSheetItem

@end

@interface SIActionSheetViewController : UIViewController

@property (nonatomic, strong) SIActionSheet *actionSheet;

@end

@implementation SIActionSheetViewController

- (void)loadView
{
    self.view = self.actionSheet;
}

#ifdef __IPHONE_7_0
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}
#endif

- (NSUInteger)supportedInterfaceOrientations
{
    UIViewController *viewController = [self.actionSheet.oldKeyWindow currentViewController];
    if (viewController) {
        return [viewController supportedInterfaceOrientations];
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    UIViewController *viewController = [self.actionSheet.oldKeyWindow currentViewController];
    if (viewController) {
        return [viewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    }
    return YES;
}

- (BOOL)shouldAutorotate
{
    UIViewController *viewController = [self.actionSheet.oldKeyWindow currentViewController];
    if (viewController) {
        return [viewController shouldAutorotate];
    }
    return YES;
}

#ifdef __IPHONE_7_0
- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIWindow *window = self.actionSheet.oldKeyWindow;
    if (!window) {
        window = [UIApplication sharedApplication].windows[0];
    }
    return [[window viewControllerForStatusBarStyle] preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    UIWindow *window = self.actionSheet.oldKeyWindow;
    if (!window) {
        window = [UIApplication sharedApplication].windows[0];
    }
    return [[window viewControllerForStatusBarHidden] prefersStatusBarHidden];
}
#endif

- (CGSize)contentSizeForViewInPopover
{
    return [self preferredContentSize];
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(320.0, [self.actionSheet preferredHeight] + 58); // TODO: replace hardcode value
}

@end

@implementation SIActionSheet

@synthesize viewBackgroundColor = _viewBackgroundColor;

+ (void)initialize
{
    if (self != [SIActionSheet class])
        return;
    
    SIActionSheet *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.titleColor = [UIColor grayColor];
    appearance.titleFont = [UIFont systemFontOfSize:16];
    appearance.defaultButtonColor = [UIColor darkGrayColor];
    appearance.defaultButtonBackgroundColor = [UIColor colorWithWhite:0 alpha:0.01];
    appearance.defaultButtonFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    appearance.cancelButtonColor = [UIColor darkGrayColor];
    appearance.cancelButtonBackgroundColor = [UIColor colorWithWhite:0 alpha:0.03];
    appearance.cancelButtonFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    appearance.destructiveButtonColor = [UIColor colorWithRed:0.322 green:0.110 blue:0.097 alpha:1.000];
    appearance.destructiveButtonBackgroundColor = [UIColor colorWithRed:0.96f green:0.37f blue:0.31f alpha:1.00f];
    appearance.destructiveButtonFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    appearance.seperatorColor = [UIColor colorWithWhite:0 alpha:0.1];
    appearance.shadowOpacity = 0.5;
}

- (id)init
{
	return [self initWithTitle:nil];
}

- (id)initWithTitle:(NSString *)title
{
	self = [super init];
	if (self) {
		_title = title;
		self.items = [NSMutableArray array];
	}
	return self;
}

- (void)layoutSubviews
{
    CGFloat height = MIN([self preferredHeight], self.bounds.size.height);
    self.containerView.frame = CGRectMake(0, self.bounds.size.height - height, self.bounds.size.width, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.containerView.bounds].CGPath;
	if (self.titleLabel) {
		self.titleLabel.frame = CGRectMake(HORIZONTAL_PADDING, PADDING_TOP, self.containerView.bounds.size.width - HORIZONTAL_PADDING * 2, [self heightForTitleLabel]);
        CGFloat y = PADDING_TOP + self.titleLabel.frame.size.height + GAP;
		self.tableView.frame = CGRectMake(0, y, self.containerView.bounds.size.width, self.containerView.bounds.size.height - y);
	} else {
		self.tableView.frame = self.containerView.bounds;
	}
    self.backgroundView.frame = self.bounds;
}

#pragma mark - Public

- (BOOL)isVisible
{
    if (self.actionsheetWindow || self.popoverController) {
        return YES;
    }
    return NO;
}

- (void)setTitle:(NSString *)title
{
    if (_title != title) {
        _title = title;
        [self setupTitleLabel];
        [self setNeedsLayout];
    }
}

- (void)addButtonWithTitle:(NSString *)title type:(SIActionSheetButtonType)type handler:(SIActionSheetShowHandler)handler
{
	SIActionSheetItem *item = [[SIActionSheetItem alloc] init];
	item.title = title;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
}

- (void)show
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSLog(@"Not support yet, please use showFromRect:inView: instead.");
        return;
    }
    
    if (self.isVisible) {
        return;
    }
    
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillShowNotification object:self userInfo:nil];
    
    SIActionSheetViewController *viewController = [self actionSheetViewController];
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    window.opaque = NO;
    window.windowLevel = UIWindowLevelStatusBar + [UIApplication sharedApplication].windows.count;
    window.rootViewController = viewController;
    self.actionsheetWindow = window;
    
    self.oldKeyWindow = [UIApplication sharedApplication].keyWindow;
    [self.actionsheetWindow makeKeyAndVisible];
#ifdef __IPHONE_7_0
    if ([self.oldKeyWindow respondsToSelector:@selector(tintAdjustmentMode:)]) {
       self.oldTintAdjustmentMode = self.oldKeyWindow.tintAdjustmentMode;
    }
#endif
    
    [self layoutIfNeeded];
    
    self.backgroundView.alpha = 0;
    CGRect targetRect = self.containerView.frame;
    CGRect initialRect = targetRect;
    initialRect.origin.y += initialRect.size.height;
    self.containerView.frame = initialRect;
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundView.alpha = 1;
                         self.containerView.frame = targetRect;
#ifdef __IPHONE_7_0
                         if ([self.oldKeyWindow respondsToSelector:@selector(setTintAdjustmentMode:)]) {
                             self.oldKeyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
                         }
#endif
                     }
                     completion:^(BOOL finished) {
                         if (self.didShowHandler) {
                             self.didShowHandler(self);
                         }
                         [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidShowNotification object:self userInfo:nil];
                     }];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view
{
    if (self.isVisible) {
        return;
    }
    
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillShowNotification object:self userInfo:nil];
    
    [[SIPopoverBackgroundView appearance] setTintColor:self.viewBackgroundColor];
    
    SIActionSheetViewController *viewController = [self actionSheetViewController];
    self.popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
    self.popoverController.delegate = self;
    self.popoverController.popoverBackgroundViewClass = [SIPopoverBackgroundView class];
    
    [self.popoverController presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    // tweak ui for popover
    self.backgroundView.hidden = YES;
    self.containerView.layer.cornerRadius = [[SIPopoverBackgroundView appearance] cornerRadius];
    self.containerView.layer.shadowOpacity = 0;
    
    if (self.didShowHandler) {
        self.didShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidShowNotification object:self userInfo:nil];
}

- (void)dismissWithButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [self dismissWithButtonIndex:buttonIndex animated:animated notifyDelegate:NO];
}

- (void)dismissWithButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated notifyDelegate:(BOOL)notifyFlag
{
    if (!self.isVisible) {
        return;
    }
    
    NSDictionary *userInfo = @{SIActionSheetDismissNotificationUserInfoButtonIndexKey : @(buttonIndex)};
    
    if (notifyFlag) {
        if (self.willDismissHandler) {
            self.willDismissHandler(self, buttonIndex);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillDismissNotification object:self userInfo:userInfo];
    }
    
    if (self.actionsheetWindow) {
        void (^dismissCompletion)(void) = ^{
            if (notifyFlag) {
                if (self.didDismissHandler) {
                    self.didDismissHandler(self, buttonIndex);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidDismissNotification object:self userInfo:userInfo];
            }
            
            [self.actionsheetWindow removeFromSuperview];
            self.actionsheetWindow = nil;
            
            [self.oldKeyWindow makeKeyWindow];
            self.oldKeyWindow = nil;
        };
        
        if (animated) {
            CGRect targetRect = self.containerView.frame;
            targetRect.origin.y += targetRect.size.height;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.backgroundView.alpha = 0;
                                 self.containerView.frame = targetRect;
#ifdef __IPHONE_7_0
                                 if ([self.oldKeyWindow respondsToSelector:@selector(setTintAdjustmentMode:)]) {
                                     self.oldKeyWindow.tintAdjustmentMode = self.oldTintAdjustmentMode;
                                 }
#endif
                             }
                             completion:^(BOOL finished) {
                                 dismissCompletion();
                             }];
        } else {
#ifdef __IPHONE_7_0
            if ([self.oldKeyWindow respondsToSelector:@selector(setTintAdjustmentMode:)]) {
                self.oldKeyWindow.tintAdjustmentMode = self.oldTintAdjustmentMode;
            }
#endif
            dismissCompletion();
        }
        
    } else {
        if (self.popoverController) {
            [self.popoverController dismissPopoverAnimated:animated];
            self.popoverController = nil;
        }
        
        if (notifyFlag) {
            if (self.didDismissHandler) {
                self.didDismissHandler(self, buttonIndex);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidDismissNotification object:self userInfo:userInfo];
        }
    }
}

#pragma mark - Private

- (SIActionSheetViewController *)actionSheetViewController
{
    SIActionSheetViewController *viewController = [[SIActionSheetViewController alloc] initWithNibName:nil bundle:nil];
    viewController.actionSheet = self;
    [self setupViews];
    return viewController;
}

- (void)setupViews
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self addSubview:self.backgroundView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
        [self.backgroundView addGestureRecognizer:tap];
    }
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.layer.shadowOpacity = self.shadowOpacity;
    self.containerView.layer.shadowRadius = 3;
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.containerView.bounds].CGPath;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.containerView.backgroundColor = [UIColor clearColor];
    } else {
        self.containerView.backgroundColor = self.viewBackgroundColor;
    }
    [self addSubview:self.containerView];
    
	self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
	self.tableView.dataSource = self;
    self.tableView.delegate = self;
	self.tableView.alwaysBounceVertical = NO;
	self.tableView.rowHeight = ROW_HEIGHT;
    self.tableView.separatorColor = self.seperatorColor;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.backgroundColor = [UIColor clearColor];
	[self.containerView addSubview:self.tableView];
    
    UIView *solid = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 1 / [UIScreen mainScreen].scale)];
    solid.backgroundColor = self.seperatorColor;
    self.tableView.tableHeaderView = solid;
	
	[self setupTitleLabel];
}

- (void)setupTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
			self.titleLabel.text = self.title;
			self.titleLabel.textColor = self.titleColor;
			self.titleLabel.font = self.titleFont;
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.numberOfLines = TITLE_LINES_MAX;
			[self.containerView addSubview:self.titleLabel];
		}
		self.titleLabel.text = self.title;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
}

- (CGFloat)preferredHeight
{
	CGFloat height = self.items.count * ROW_HEIGHT + 1;
	if (self.title) {
		height += PADDING_TOP + GAP + [self heightForTitleLabel];
	}
	return height;
}

- (CGFloat)heightForTitleLabel
{
    CGSize size = [self.title sizeWithFont:self.titleFont constrainedToSize:CGSizeMake(self.bounds.size.width - HORIZONTAL_PADDING * 2, self.titleFont.lineHeight * TITLE_LINES_MAX)];
    return ceil(size.height);
}

- (NSArray *)visibleCellsWithType:(SIActionSheetButtonType)type
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.tableView.visibleCells.count];
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        SIActionSheetItem *item = self.items[indexPath.row];
        if (item.type == type) {
            [result addObject:cell];
        }
    }
    return [result copy];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        
        UIView *solid = [[UIView alloc] initWithFrame:cell.bounds];
        solid.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05]; // darken overlay
        cell.selectedBackgroundView = solid;
	}
	
    SIActionSheetItem *item = self.items[indexPath.row];
    switch (item.type) {
        case SIActionSheetButtonTypeDefault:
            cell.backgroundColor = self.defaultButtonBackgroundColor;
            cell.textLabel.textColor = self.defaultButtonColor;
            cell.textLabel.font = self.defaultButtonFont;
            break;
        case SIActionSheetButtonTypeCancel:
            cell.backgroundColor = self.cancelButtonBackgroundColor;
            cell.textLabel.textColor = self.cancelButtonColor;
            cell.textLabel.font = self.cancelButtonFont;
            break;
        case SIActionSheetButtonTypeDestructive:
            cell.backgroundColor = self.destructiveButtonBackgroundColor;
            cell.textLabel.textColor = self.destructiveButtonColor;
            cell.textLabel.font = self.destructiveButtonFont;
            break;
        default:
            break;
    }
    cell.textLabel.text = item.title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SIActionSheetItem *item = self.items[indexPath.row];
    if (item.action) {
        item.action(self);
    }
    
    [self dismissWithButtonIndex:indexPath.row animated:YES notifyDelegate:YES];
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return self.allowTapBackgroundToDismiss;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissWithButtonIndex:-1 animated:NO notifyDelegate:YES];
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
    SIActionSheetItem *item = self.items[button.tag];
	if (item.action) {
		item.action(self);
	}
	[self dismissWithButtonIndex:button.tag animated:YES notifyDelegate:YES];
}

- (void)tapHandler:(UIGestureRecognizer *)recognizer
{
    if (self.allowTapBackgroundToDismiss) {
        [self dismissWithButtonIndex:-1 animated:YES notifyDelegate:YES];
    }
}

#pragma mark - UIAppearance setters

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor
{
    if (_viewBackgroundColor == viewBackgroundColor) {
        return;
    }
    _viewBackgroundColor = viewBackgroundColor;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[SIPopoverBackgroundView appearance] setTintColor:viewBackgroundColor];
    } else {
        self.containerView.backgroundColor = viewBackgroundColor;
    }
}

- (UIColor *)viewBackgroundColor
{
    if (!_viewBackgroundColor) {
        return [[[self class] appearance] viewBackgroundColor];
    }
    return _viewBackgroundColor;
}

- (void)setTitleFont:(UIFont *)titleFont
{
    if (_titleFont == titleFont) {
        return;
    }
    _titleFont = titleFont;
    
    self.titleLabel.font = titleFont;
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (_titleColor == titleColor) {
        return;
    }
    _titleColor = titleColor;
    
    self.titleLabel.textColor = titleColor;
}

- (void)setDefaultButtonFont:(UIFont *)defaultButtonFont
{
    if (_defaultButtonFont == defaultButtonFont) {
        return;
    }
    _defaultButtonFont = defaultButtonFont;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeDefault];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).textLabel.font = defaultButtonFont;
    }];
}

- (void)setDefaultButtonColor:(UIColor *)defaultButtonColor
{
    if (_defaultButtonColor == defaultButtonColor) {
        return;
    }
    _defaultButtonColor = defaultButtonColor;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeDefault];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).textLabel.textColor = defaultButtonColor;
    }];
}

- (void)setDefaultButtonBackgroundColor:(UIColor *)defaultButtonBackgroundColor
{
    if (_defaultButtonBackgroundColor == defaultButtonBackgroundColor) {
        return;
    }
    _defaultButtonBackgroundColor = defaultButtonBackgroundColor;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeDefault];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).backgroundColor = defaultButtonBackgroundColor;
    }];
}

- (void)setCancelButtonFont:(UIFont *)cancelButtonFont
{
    if (_cancelButtonFont == cancelButtonFont) {
        return;
    }
    _cancelButtonFont = cancelButtonFont;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeCancel];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).textLabel.font = cancelButtonFont;
    }];
}

- (void)setCancelButtonColor:(UIColor *)cancelButtonColor
{
    if (_cancelButtonColor == cancelButtonColor) {
        return;
    }
    _cancelButtonColor = cancelButtonColor;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeCancel];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).textLabel.textColor = cancelButtonColor;
    }];
}

- (void)setCancelButtonBackgroundColor:(UIColor *)cancelButtonBackgroundColor
{
    if (_cancelButtonBackgroundColor == cancelButtonBackgroundColor) {
        return;
    }
    _cancelButtonBackgroundColor = cancelButtonBackgroundColor;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeCancel];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).backgroundColor = cancelButtonBackgroundColor;
    }];
}

- (void)setDestructiveButtonFont:(UIFont *)destructiveButtonFont
{
    if (_destructiveButtonFont == destructiveButtonFont) {
        return;
    }
    _destructiveButtonFont = destructiveButtonFont;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeDestructive];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).textLabel.font = destructiveButtonFont;
    }];
}

- (void)setDestructiveButtonColor:(UIColor *)destructiveButtonColor
{
    if (_destructiveButtonColor == destructiveButtonColor) {
        return;
    }
    _destructiveButtonColor = destructiveButtonColor;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeDestructive];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).textLabel.textColor = destructiveButtonColor;
    }];
}

- (void)setDestructiveButtonBackgroundColor:(UIColor *)destructiveButtonBackgroundColor
{
    if (_destructiveButtonBackgroundColor == destructiveButtonBackgroundColor) {
        return;
    }
    _destructiveButtonBackgroundColor = destructiveButtonBackgroundColor;
    
    NSArray *cells = [self visibleCellsWithType:SIActionSheetButtonTypeDestructive];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((UITableViewCell *)obj).backgroundColor = destructiveButtonBackgroundColor;
    }];
}

- (void)setSeperatorColor:(UIColor *)seperatorColor
{
    if (_seperatorColor == seperatorColor) {
        return;
    }
    _seperatorColor = seperatorColor;
    
    self.tableView.separatorColor = seperatorColor;
    self.tableView.tableHeaderView.backgroundColor = seperatorColor;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity
{
    if (_shadowOpacity == shadowOpacity) {
        return;
    }
    _shadowOpacity = shadowOpacity;
    
    self.containerView.layer.shadowOpacity = shadowOpacity;
}

@end
