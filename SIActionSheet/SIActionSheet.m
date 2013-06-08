//
//  SIActionSheet.m
//  SIActionSheet
//
//  Created by Kevin Cao on 13-05-26.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "SIActionSheet.h"
#import <QuartzCore/QuartzCore.h>

#define HEADER_HEIGHT 40
#define ROW_HEIGHT 54
#define VERTICAL_INSET 8
#define HORIZONTAL_PADDING 10
#define PADDING_TOP 10
#define GAP 12
#define TITLE_LINES_MAX 5

NSString *const SIActionSheetWillShowNotification = @"SIActionSheetWillShowNotification";
NSString *const SIActionSheetDidShowNotification = @"SIActionSheetDidShowNotification";
NSString *const SIActionSheetWillDismissNotification = @"SIActionSheetWillDismissNotification";
NSString *const SIActionSheetDidDismissNotification = @"SIActionSheetDidDismissNotification";

@interface SIActionSheet () <UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIWindow *actionsheetWindow;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

- (void)setup;

@end

@interface SIActionSheetItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIActionSheetButtonType type;
@property (nonatomic, copy) SIActionSheetHandler action;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.actionSheet setup];
}

@end

@implementation SIActionSheet

+ (void)initialize
{
    if (self != [SIActionSheet class])
        return;
    
    SIActionSheet *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.titleColor = [UIColor grayColor];
    appearance.titleFont = [UIFont systemFontOfSize:16];
    appearance.buttonFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
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
		self.items = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)layoutSubviews
{
    CGFloat height = [self preferHeight];
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

- (void)setTitle:(NSString *)title
{
	_title = title;
	[self updateTitleLabel];
}

- (void)addButtonWithTitle:(NSString *)title type:(SIActionSheetButtonType)type handler:(SIActionSheetHandler)handler
{
	SIActionSheetItem *item = [[SIActionSheetItem alloc] init];
	item.title = title;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
}

- (void)show
{
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillShowNotification object:self userInfo:nil];
    
    SIActionSheetViewController *viewController = [[SIActionSheetViewController alloc] initWithNibName:nil bundle:nil];
    viewController.actionSheet = self;
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    window.opaque = NO;
    window.windowLevel = UIWindowLevelAlert;
    window.rootViewController = viewController;
    self.actionsheetWindow = window;
    
    [self.actionsheetWindow makeKeyAndVisible];
    
    self.backgroundView.alpha = 0;
    CGRect targetRect = self.containerView.frame;
    CGRect initialRect = targetRect;
    initialRect.origin.y += initialRect.size.height;
    self.containerView.frame = initialRect;
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundView.alpha = 1;
                         self.containerView.frame = targetRect;
                     }
                     completion:^(BOOL finished) {
                         if (self.didShowHandler) {
                             self.didShowHandler(self);
                         }
                         [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidShowNotification object:self userInfo:nil];
                     }];
}

- (void)dismissAnimated:(BOOL)animated
{
    if (self.willDismissHandler) {
        self.willDismissHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetWillDismissNotification object:self userInfo:nil];
    
    CGRect targetRect = self.containerView.frame;
    targetRect.origin.y += targetRect.size.height;
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundView.alpha = 0;
                         self.containerView.frame = targetRect;
                     }
                     completion:^(BOOL finished) {
                         if (self.didDismissHandler) {
                             self.didDismissHandler(self);
                         }
                         [[NSNotificationCenter defaultCenter] postNotificationName:SIActionSheetDidDismissNotification object:self userInfo:nil];
                         
                         [self.actionsheetWindow removeFromSuperview];
                         self.actionsheetWindow = nil;
                     }];
}

#pragma mark - Private

- (void)setup
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:self.backgroundView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    [self.backgroundView addGestureRecognizer:tap];
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.layer.shadowOpacity = self.shadowOpacity;
    self.containerView.layer.shadowRadius = 3;
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.containerView.bounds].CGPath;
    self.containerView.backgroundColor = self.viewBackgroundColor;
    [self addSubview:self.containerView];
    
	self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
	self.tableView.dataSource = self;
	[self.containerView addSubview:self.tableView];
	self.tableView.alwaysBounceVertical = NO;
	self.tableView.rowHeight = ROW_HEIGHT;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.contentInset = UIEdgeInsetsMake(VERTICAL_INSET, 0, VERTICAL_INSET, 0);
    self.tableView.backgroundColor = [UIColor clearColor];
	
	[self updateTitleLabel];
}

- (void)updateTitleLabel
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
	[self setNeedsLayout];
}

- (CGFloat)preferHeight
{
	CGFloat height = self.items.count * ROW_HEIGHT + VERTICAL_INSET * 2;
	if (self.title) {
		height += PADDING_TOP + GAP + [self heightForTitleLabel];
	}
	return height;
}

- (CGFloat)heightForTitleLabel
{
    CGSize size = [self.title sizeWithFont:self.titleFont constrainedToSize:CGSizeMake(self.bounds.size.width - HORIZONTAL_PADDING * 2, self.titleFont.lineHeight * TITLE_LINES_MAX)];
    return size.height;
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
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	while (cell.contentView.subviews.count) {
		[cell.contentView.subviews[0] removeFromSuperview];
	}
	
	SIActionSheetItem *item = self.items[indexPath.row];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = indexPath.row;
	button.frame = CGRectMake(HORIZONTAL_PADDING, (ROW_HEIGHT - 44) / 2, cell.contentView.bounds.size.width - HORIZONTAL_PADDING * 2, 44);
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	button.titleLabel.font = self.buttonFont;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.5;
	[button setTitle:item.title forState:UIControlStateNormal];
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	switch (item.type) {
		case SIActionSheetButtonTypeCancel:
			normalImage = [UIImage imageNamed:@"SIActionSheet.bundle/button-cancel"];
			highlightedImage = [UIImage imageNamed:@"SIActionSheet.bundle/button-cancel-d"];
			[button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
			break;
		case SIActionSheetButtonTypeDestructive:
			normalImage = [UIImage imageNamed:@"SIActionSheet.bundle/button-destructive"];
			highlightedImage = [UIImage imageNamed:@"SIActionSheet.bundle/button-destructive-d"];
			break;
		case SIActionSheetButtonTypeDefault:
		default:
			normalImage = [UIImage imageNamed:@"SIActionSheet.bundle/button-default"];
			highlightedImage = [UIImage imageNamed:@"SIActionSheet.bundle/button-default-d"];
			[button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
			break;
	}
	CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	normalImage = [normalImage resizableImageWithCapInsets:insets];
	highlightedImage = [highlightedImage resizableImageWithCapInsets:insets];
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
	
	[cell.contentView addSubview:button];
    
    return cell;
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
    SIActionSheetItem *item = self.items[button.tag];
	if (item.action) {
		item.action(self);
	}
	[self dismissAnimated:YES];
}

- (void)tapHandler:(UIGestureRecognizer *)recognizer
{
    if (self.tapBackgroundToDismissEnabled) {
        [self dismissAnimated:YES];
    }
}

#pragma mark - UIAppearance setters

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor
{
    if (_viewBackgroundColor == viewBackgroundColor) {
        return;
    }
    _viewBackgroundColor = viewBackgroundColor;
    self.containerView.backgroundColor = viewBackgroundColor;
//    self.tableView.backgroundColor = viewBackgroundColor;
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

- (void)setButtonFont:(UIFont *)buttonFont
{
    if (_buttonFont == buttonFont) {
        return;
    }
    _buttonFont = buttonFont;
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        UIButton *button = cell.contentView.subviews[0];
        button.titleLabel.font = self.buttonFont;
    }
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
