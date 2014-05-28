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
#import "UIWindow+SIUtils.h"
#import <QuartzCore/QuartzCore.h>

#define ROW_HEIGHT 50
#define HORIZONTAL_PADDING 20
#define PADDING_TOP 20
#define GAP 20
#define CONTAINER_INSET 10

NSString *const SIActionSheetWillShowNotification = @"SIActionSheetWillShowNotification";
NSString *const SIActionSheetDidShowNotification = @"SIActionSheetDidShowNotification";
NSString *const SIActionSheetWillDismissNotification = @"SIActionSheetWillDismissNotification";
NSString *const SIActionSheetDidDismissNotification = @"SIActionSheetDidDismissNotification";

NSString *const SIActionSheetDismissNotificationUserInfoButtonIndexKey = @"SIActionSheetDismissNotificationUserInfoButtonIndexKey";

@interface SIActionSheet () <UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *wrapperView;
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
    return CGSizeMake(320.0, [self.actionSheet preferredHeight]);
}

@end

@implementation SIActionSheet

@synthesize viewBackgroundColor = _viewBackgroundColor;
@synthesize title = _title, attributedTitle = _attributedTitle;

+ (void)initialize
{
    if (self != [SIActionSheet class])
        return;
    
    SIActionSheet *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.seperatorColor = [UIColor colorWithWhite:0 alpha:0.1];
    appearance.cornerRadius = 2;
    
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
    appearance.defaultButtonAttributes = @{NSFontAttributeName : defaultButtonFont, NSParagraphStyleAttributeName : paragraphStyle};
    appearance.cancelButtonAttributes = @{NSFontAttributeName : otherButtonFont, NSParagraphStyleAttributeName : paragraphStyle};
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
    if ([_title isEqualToString:title]) {
        return;
    }
    
    _title = [title copy];
    _attributedTitle = nil;
    if (self.isVisible) {
        [self setupTitleLabel];
    }
}

- (NSString *)title
{
    if (!_title) {
        return _attributedTitle.string;
    }
    return _title;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    if (_attributedTitle == attributedTitle) {
        return;
    }
    
    _attributedTitle = [attributedTitle copy];
    _title = nil;
    if (self.isVisible) {
        [self setupTitleLabel];
    }
}

- (NSAttributedString *)attributedTitle
{
    if (_attributedTitle) {
        return _attributedTitle;
    }
    if (_title) {
        return [[NSAttributedString alloc] initWithString:_title attributes:[self titleAttributes]];
    }
    return nil;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    self.backgroundView.frame = self.bounds;
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat width = self.bounds.size.width;
    CGFloat height = [self preferredHeight];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        width -= CONTAINER_INSET * 2;
        height = MIN(height, self.bounds.size.height - CONTAINER_INSET * 2);
        x += CONTAINER_INSET;
        y = self.bounds.size.height - height - CONTAINER_INSET;
    }
    
    self.containerView.frame = CGRectMake(x, y, width, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.containerView.bounds].CGPath;
    
	if (self.titleLabel) {
        CGSize size = [self titleLabelSize];
		self.titleLabel.frame = CGRectMake(HORIZONTAL_PADDING, PADDING_TOP, size.width, size.height);
        CGFloat y = PADDING_TOP + self.titleLabel.frame.size.height + GAP;
		self.tableView.frame = CGRectMake(0, y, self.containerView.bounds.size.width, self.containerView.bounds.size.height - y);
	} else {
		self.tableView.frame = self.containerView.bounds;
	}
    
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
    NSAssert(title != nil, @"Title can't be nil");
    SIActionSheetItem *item = [[SIActionSheetItem alloc] init];
	item.title = title;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
}

- (void)addButtonWithTitle:(NSString *)title font:(UIFont *)font color:(UIColor *)color type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler
{
    NSAssert(title != nil, @"Title can't be nil");
    NSDictionary *defaults = nil;
    switch (type) {
        case SIActionSheetButtonTypeDefault:
            defaults = self.defaultButtonAttributes;
            break;
        case SIActionSheetButtonTypeCancel:
            defaults = self.cancelButtonAttributes;
            break;
        case SIActionSheetButtonTypeDestructive:
            defaults = self.destructiveButtonAttributes;
            break;
    }
    NSMutableDictionary *temp = [defaults mutableCopy];
    if (font) {
        temp[NSFontAttributeName] = font;
    }
    if (color) {
        temp[NSForegroundColorAttributeName] = color;
    }
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:temp];
    [self addButtonWithAttributedTitle:attributedTitle type:type handler:handler];
}

- (void)addButtonWithAttributedTitle:(NSAttributedString *)attributedTitle type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler
{
    NSAssert(attributedTitle != nil, @"Attributed title can't be nil");
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
    
    [self setupPopoverController];
    [self.popoverController presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    if (self.didShowHandler) {
        self.didShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidShowNotification object:self userInfo:nil];
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if (self.isVisible) {
        return;
    }
    
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillShowNotification object:self userInfo:nil];
    
    [self setupPopoverController];
    [self.popoverController presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated:YES];
    
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
            self.popoverController.contentViewController.view.layer.allowsGroupOpacity = YES;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self addSubview:self.backgroundView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
        [self.backgroundView addGestureRecognizer:tap];
    }
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.layer.shadowRadius = self.shadowRadius;
    self.containerView.layer.shadowOpacity = self.shadowRadius > 0 ? 0.5 : 0;
    self.containerView.layer.shadowOffset = CGSizeZero;
    
    [self addSubview:self.containerView];
    
    self.wrapperView = [[UIView alloc] initWithFrame:self.bounds];
    self.wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.wrapperView.autoresizesSubviews = NO;
    self.wrapperView.layer.cornerRadius = self.cornerRadius;
    self.wrapperView.clipsToBounds = YES;
    self.wrapperView.backgroundColor = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [UIColor clearColor] : self.viewBackgroundColor;
    [self.containerView addSubview:self.wrapperView];
    
	self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
	self.tableView.dataSource = self;
    self.tableView.delegate = self;
	self.tableView.alwaysBounceVertical = NO;
	self.tableView.rowHeight = ROW_HEIGHT;
    self.tableView.separatorColor = self.seperatorColor;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.backgroundColor = [UIColor clearColor];
	[self.wrapperView addSubview:self.tableView];
    
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
			[self.wrapperView addSubview:self.titleLabel];
		}
		self.titleLabel.attributedText = self.attributedTitle;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
    [self setNeedsLayout];
}

- (void)setupPopoverController
{
    [[SIPopoverBackgroundView appearance] setTintColor:self.viewBackgroundColor];
    
    SIActionSheetViewController *viewController = [self actionSheetViewController];
    self.popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
    self.popoverController.delegate = self;
    self.popoverController.backgroundColor = [UIColor whiteColor];
    //    self.popoverController.popoverBackgroundViewClass = [SIPopoverBackgroundView class];
    
    // tweak ui for popover
    self.backgroundView.hidden = YES;
    self.containerView.layer.cornerRadius = [[SIPopoverBackgroundView appearance] cornerRadius];
    self.containerView.layer.shadowOpacity = 0;
}

- (CGFloat)preferredHeight
{
	CGFloat height = self.items.count * ROW_HEIGHT + 1;
	if (self.title) {
		height += PADDING_TOP + GAP + [self titleLabelSize].height;
	}
	return height;
}

- (CGSize)titleLabelSize
{
    if (!self.titleLabel) {
        return CGSizeZero;
    }
    
    CGFloat width = self.bounds.size.width - CONTAINER_INSET * 2 - HORIZONTAL_PADDING * 2;
    return CGSizeMake(width, ceil([self.titleLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height));
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
        cell.textLabel.backgroundColor = [UIColor clearColor];
	}
    
    NSDictionary *attributes = nil;
    SIActionSheetItem *item = self.items[indexPath.row];
    switch (item.type) {
        case SIActionSheetButtonTypeDefault:
            cell.backgroundColor = self.defaultButtonBackgroundColor;
            attributes = self.defaultButtonAttributes;
            break;
        case SIActionSheetButtonTypeCancel:
            cell.backgroundColor = self.cancelButtonBackgroundColor;
            attributes = self.cancelButtonAttributes;
            break;
        case SIActionSheetButtonTypeDestructive:
            cell.backgroundColor = self.destructiveButtonBackgroundColor;
            attributes = self.destructiveButtonAttributes;
            break;
        default:
            break;
    }
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[self imageWithUIColor:[self highlightedColorWithColor:cell.backgroundColor]]];
    cell.textLabel.attributedText = item.attributedTitle ? item.attributedTitle : [[NSAttributedString alloc] initWithString:item.title attributes:[self tintedAttributes:attributes]];
    
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
    if (self.allowTapBackgroundToDismiss) {
        NSDictionary *userInfo = @{SIActionSheetDismissNotificationUserInfoButtonIndexKey : @(-1)};
        if (self.willDismissHandler) {
            self.willDismissHandler(self, -1);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillDismissNotification object:self userInfo:userInfo];
    }
    return self.allowTapBackgroundToDismiss;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popoverController = nil;
    
    NSDictionary *userInfo = @{SIActionSheetDismissNotificationUserInfoButtonIndexKey : @(-1)};
    if (self.didDismissHandler) {
        self.didDismissHandler(self, -1);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidDismissNotification object:self userInfo:userInfo];
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
        self.wrapperView.backgroundColor = viewBackgroundColor;
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

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    self.wrapperView.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (_shadowRadius == shadowRadius) {
        return;
    }
    _shadowRadius = shadowRadius;
    
    self.containerView.layer.shadowRadius = shadowRadius;
    self.containerView.layer.shadowOpacity = shadowRadius > 0 ? 0.5 : 0;
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
    return attributes;
}

- (NSDictionary *)cancelButtonAttributes
{
    NSDictionary *attributes = _cancelButtonAttributes;
    if (!attributes) {
        attributes = [[[self class] appearance] cancelButtonAttributes];
    }
    return attributes;
}

- (NSDictionary *)destructiveButtonAttributes
{
    NSDictionary *attributes = _destructiveButtonAttributes;
    if (!attributes) {
        attributes = [[[self class] appearance] destructiveButtonAttributes];
    }
    return attributes;
}

#pragma mark - Helpers

// auto detected darken or lighten
- (UIColor *)highlightedColorWithColor:(UIColor *)color
{
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    CGFloat adjustment = 0.1;
    
    int numComponents = CGColorGetNumberOfComponents([color CGColor]);
    
    // grayscale
    if (numComponents == 2) {
        [color getWhite:&brightness alpha:&alpha];
        brightness += brightness > 0.5 ? -adjustment : adjustment * 2; // emphasize lighten adjustment value by two
        return [UIColor colorWithWhite:brightness alpha:alpha];
    }
    
    // RGBA
    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    brightness += brightness > 0.5 ? -adjustment : adjustment * 2;
    
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (UIImage *)imageWithUIColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color set];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

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
