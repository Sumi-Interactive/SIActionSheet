//
//  SIActionSheet.m
//  SIActionSheet
//
//  Created by Kevin Cao on 13-05-26.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "SIActionSheet.h"
#import "SIPopoverBackgroundView.h"
#import "SISecondaryWindowRootViewController.h"
#import <QuartzCore/QuartzCore.h>

#define ROW_HEIGHT 54
#define HORIZONTAL_PADDING 20
#define PADDING_TOP 20
#define GAP 20

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

@property (nonatomic, copy) NSAttributedString *attributedTitle;
@property (nonatomic, assign) SIActionSheetButtonType type;
@property (nonatomic, copy) SIActionSheetHandler action;

@end

@implementation SIActionSheetItem

@end

@interface SIActionSheetViewController : SISecondaryWindowRootViewController

@property (nonatomic, strong) SIActionSheet *actionSheet;

@end

@implementation SIActionSheetViewController

- (void)loadView
{
    self.view = self.actionSheet;
}

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
    appearance.seperatorColor = [UIColor colorWithWhite:0 alpha:0.1];
    appearance.shadowOpacity = 0.5;
    
    appearance.defaultButtonBackgroundColor = [UIColor colorWithWhite:0.99 alpha:1];
    appearance.cancelButtonBackgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    appearance.destructiveButtonBackgroundColor = [UIColor colorWithWhite:0.99 alpha:1];
    
    UIFont *titleFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.1;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    appearance.titleAttributes = @{NSFontAttributeName : titleFont, NSParagraphStyleAttributeName : paragraphStyle};
    
    UIFont *defaultButtonFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    UIFont *otherButtonFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    appearance.defaultButtonAttributes = @{NSFontAttributeName : defaultButtonFont, NSForegroundColorAttributeName : [UIColor darkGrayColor], NSParagraphStyleAttributeName : paragraphStyle};
    appearance.cancelButtonAttributes = @{NSFontAttributeName : otherButtonFont, NSForegroundColorAttributeName : [UIColor darkGrayColor], NSParagraphStyleAttributeName : paragraphStyle};
    appearance.destructiveButtonAttributes = @{NSFontAttributeName : otherButtonFont, NSForegroundColorAttributeName : [UIColor colorWithRed:0.96f green:0.37f blue:0.31f alpha:1.00f], NSParagraphStyleAttributeName : paragraphStyle};
}

- (id)init
{
	return [self initWithTitle:nil];
}

- (id)initWithTitle:(NSString *)title
{
	self = [super init];
	if (self) {
        if (title) {
            _attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:[self titleAttributes]];
        }
		self.items = [NSMutableArray array];
	}
	return self;
}

- (id)initWithAttributedTitle:(NSAttributedString *)attributedTitle
{
    self = [super init];
	if (self) {
		_attributedTitle = attributedTitle;
		self.items = [NSMutableArray array];
	}
	return self;
}

#pragma mark - Setters & Getters

- (void)setTitle:(NSString *)title
{
    if (title) {
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:[self titleAttributes]];
        self.attributedTitle = attributedTitle;
    } else {
        self.attributedTitle = nil;
    }
}

- (NSString *)title
{
    return self.attributedTitle.string;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    _attributedTitle = [attributedTitle copy];
    if (self.isVisible) {
        [self setupTitleLabel];
        [self setNeedsLayout];
    }
}

#pragma mark - Layout

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

- (void)addButtonWithTitle:(NSString *)title type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler
{
    NSDictionary *attributes = nil;
    switch (type) {
        case SIActionSheetButtonTypeDefault:
            attributes = self.defaultButtonAttributes;
            break;
        case SIActionSheetButtonTypeCancel:
            attributes = self.cancelButtonAttributes;
            break;
        case SIActionSheetButtonTypeDestructive:
            attributes = self.destructiveButtonAttributes;
            break;
    }
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    [self addButtonWithAttributedTitle:attributedTitle type:type handler:handler];
}

- (void)addButtonWithAttributedTitle:(NSAttributedString *)attributedTitle type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler
{
    SIActionSheetItem *item = [[SIActionSheetItem alloc] init];
	item.attributedTitle = attributedTitle;
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
	if (self.attributedTitle) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.numberOfLines = 0;
			[self.containerView addSubview:self.titleLabel];
		}
		self.titleLabel.attributedText = self.attributedTitle;
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
    if (!self.attributedTitle) {
        return 0;
    }
    
    CGRect rect = [self.attributedTitle boundingRectWithSize:CGSizeMake(self.bounds.size.width - HORIZONTAL_PADDING * 2, CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                     context:nil];
    return ceil(rect.size.height);
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
        
        UIView *solid = [[UIView alloc] initWithFrame:cell.bounds];
        solid.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05]; // darken overlay
        cell.selectedBackgroundView = solid;
	}
	
    SIActionSheetItem *item = self.items[indexPath.row];
    switch (item.type) {
        case SIActionSheetButtonTypeDefault:
            cell.backgroundColor = self.defaultButtonBackgroundColor;
            break;
        case SIActionSheetButtonTypeCancel:
            cell.backgroundColor = self.cancelButtonBackgroundColor;
            break;
        case SIActionSheetButtonTypeDestructive:
            cell.backgroundColor = self.destructiveButtonBackgroundColor;
            break;
        default:
            break;
    }
    cell.textLabel.attributedText = item.attributedTitle;
    
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

- (NSDictionary *)titleAttributes
{
    if (!_titleAttributes) {
        return [[[self class] appearance] titleAttributes];
    }
    return _titleAttributes;
}

- (NSDictionary *)defaultButtonAttributes
{
    NSDictionary *attributes = _defaultButtonAttributes;
    if (!attributes) {
        attributes = [[[self class] appearance] defaultButtonAttributes];
    }
    return [self tintedAttributes:attributes];
}

- (NSDictionary *)cancelButtonAttributes
{
    NSDictionary *attributes = _cancelButtonAttributes;
    if (!attributes) {
        attributes = [[[self class] appearance] cancelButtonAttributes];
    }
    return [self tintedAttributes:attributes];
}

- (NSDictionary *)destructiveButtonAttributes
{
    NSDictionary *attributes = _destructiveButtonAttributes;
    if (!attributes) {
        attributes = [[[self class] appearance] destructiveButtonAttributes];
    }
    return [self tintedAttributes:attributes];
}

// support tint
- (NSDictionary *)tintedAttributes:(NSDictionary *)attributes
{
    if (!attributes[NSForegroundColorAttributeName]) {
        NSMutableDictionary *temp = [attributes mutableCopy];
        temp[NSForegroundColorAttributeName] = self.tintColor;
        attributes = [temp copy];
    }
    return attributes;
}

@end
