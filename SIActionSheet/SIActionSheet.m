//
//  SIActionSheet.m
//  SIActionSheet
//
//  Created by Kevin Cao on 13-05-26.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "SIActionSheet.h"

#define HEADER_HEIGHT 40
#define ROW_HEIGHT 54
#define VERTICAL_INSET 8

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
	if (self.titleLabel) {
		self.titleLabel.frame = CGRectMake(0, 0, self.containerView.bounds.size.width, HEADER_HEIGHT);
		self.tableView.frame = CGRectMake(0, HEADER_HEIGHT, self.containerView.bounds.size.width, self.containerView.bounds.size.height - HEADER_HEIGHT);
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
    [self addSubview:self.containerView];
    
	self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
	self.tableView.dataSource = self;
	[self.containerView addSubview:self.tableView];
	self.tableView.alwaysBounceVertical = NO;
	self.tableView.rowHeight = ROW_HEIGHT;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.contentInset = UIEdgeInsetsMake(VERTICAL_INSET, 0, VERTICAL_INSET, 0);
	
	[self updateTitleLabel];
}

- (void)updateTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
			self.titleLabel.text = self.title;
			self.titleLabel.textColor = [UIColor grayColor];
            //			self.titleLabel.font = GD_ACTIONSHEET_TITLE_FONT;
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
		height += HEADER_HEIGHT;
	}
	return height;
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
	button.frame = CGRectMake(10, (ROW_HEIGHT - 44) / 2, cell.contentView.bounds.size.width - 20, 44);
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    //	button.titleLabel.font = GD_ACTIONSHEET_BUTTON_FONT;
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

@end
