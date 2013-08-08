//
//  SIPopoverBackgroundView.m
//  SIActionSheet
//
//  Created by Kevin Cao on 13-8-7.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "SIPopoverBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define kArrowBase 24.0f
#define kArrowHeight 12.0f

@interface SIPopoverBackgroundView()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *arrowImageView;

@property (nonatomic, assign) BOOL needRedrawBackgroundImage;
@property (nonatomic, assign) BOOL needRedrawArrowImage;

@end


@implementation SIPopoverBackgroundView

@synthesize arrowDirection  = _arrowDirection;
@synthesize arrowOffset     = _arrowOffset;

+ (void)initialize
{
    if (self != [SIPopoverBackgroundView class])
        return;
    
    SIPopoverBackgroundView *appearance = [self appearance];
    appearance.tintColor = [UIColor whiteColor];
    appearance.borderWidth = 0.0;
    appearance.cornerRadius = 4.0;
}


#pragma mark - Graphics Methods

- (UIImage *)fillImage
{
    CGSize size = CGSizeMake(self.cornerRadius * 2 + 1, self.cornerRadius * 2 + 1);
    UIImage *image = [self drawImageWithWidth:size.width
                                       height:size.height
                                        block:^(CGContextRef context) {
                                            [self.tintColor set];
                                            CGContextFillEllipseInRect(context, CGRectMake(0, 0, size.width, size.height));
                                        }];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(self.cornerRadius, self.cornerRadius, self.cornerRadius, self.cornerRadius)];
    return image;
}


- (UIImage *)arrowImage
{
    CGSize size = CGSizeMake([[self class] arrowBase], [[self class] arrowHeight]);
    UIImage *image = [self drawImageWithWidth:size.width
                                       height:size.height
                                        block:^(CGContextRef context) {
                                            CGMutablePathRef arrowPath = CGPathCreateMutable();
                                            CGPathMoveToPoint(arrowPath, NULL, (size.width/2.0f), 0.0f); //Top Center
                                            CGPathAddLineToPoint(arrowPath, NULL, size.width, size.height); //Bottom Right
                                            CGPathAddLineToPoint(arrowPath, NULL, 0.0f, size.height); //Bottom Right
                                            CGPathCloseSubpath(arrowPath);
                                            CGContextAddPath(context, arrowPath);
                                            CGPathRelease(arrowPath);
                                            [self.tintColor set];
                                            CGContextDrawPath(context, kCGPathFill);
                                        }];
    return image;
}

- (UIImage *)drawImageWithWidth:(CGFloat)width height:(CGFloat)height block:(void(^)(CGContextRef context))block
{
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (block) block(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark - UIPopoverBackgroundView Overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.backgroundImageView = [[UIImageView alloc] init];
        [self addSubview:self.backgroundImageView];
        
        self.arrowImageView = [[UIImageView alloc] init];
        [self addSubview:self.arrowImageView];
        
        self.needRedrawArrowImage = YES;
        self.needRedrawBackgroundImage = YES;
        
    }
    return self;
}

- (CGFloat)arrowOffset
{
    CGFloat arrowOffset = _arrowOffset;
    CGFloat arrowHalfBase = [[self class] arrowBase] / 2;
    
    switch (self.arrowDirection)
    {
        case UIPopoverArrowDirectionUp:
        case UIPopoverArrowDirectionDown:
        {
            CGFloat width = self.bounds.size.width;
            
            CGFloat maxOffset = (width/2) - (arrowHalfBase + self.cornerRadius);
            if (arrowOffset > maxOffset) return maxOffset;
            if (arrowOffset < -maxOffset) return -maxOffset;
            
            break;
        }
            
        case UIPopoverArrowDirectionLeft:
        case UIPopoverArrowDirectionRight:
        {
            CGFloat height = self.bounds.size.height;
            
            CGFloat maxOffset = (height/2) - (arrowHalfBase + self.cornerRadius);
            if (arrowOffset > maxOffset) return maxOffset;
            
            CGFloat minOffset = arrowHalfBase - (height/2);
            if (arrowOffset < minOffset) return minOffset;
            
            break;
        }
            
        default:
            break;
    }
    
    return arrowOffset;
}

+ (CGFloat)arrowBase
{
    return kArrowBase;
}

+ (CGFloat)arrowHeight
{
    return kArrowHeight;
}

+ (UIEdgeInsets)contentViewInsets
{
    CGFloat inset = [[self appearance] borderWidth];
    return UIEdgeInsetsMake(inset, inset, inset, inset);
}

+ (BOOL)wantsDefaultContentAppearance
{
    return NO;
}

- (void)layoutSubviews
{
    if (self.needRedrawBackgroundImage) {
        self.backgroundImageView.image = [self fillImage];
        self.needRedrawBackgroundImage = NO;
    }
    if (self.needRedrawArrowImage) {
        self.arrowImageView.image = [self arrowImage];
        self.needRedrawArrowImage = NO;
    }
    
    CGSize arrowSize = CGSizeMake([[self class] arrowBase], [[self class] arrowHeight]);
    
    CGFloat x = round((self.bounds.size.width - arrowSize.width) / 2);
    CGFloat y = round((self.bounds.size.height - arrowSize.width) / 2);
    
    self.arrowImageView.transform = CGAffineTransformIdentity;
    switch (self.arrowDirection)
    {
        case UIPopoverArrowDirectionUp:
            self.backgroundImageView.frame = CGRectMake(0, arrowSize.height, self.bounds.size.width, self.bounds.size.height - arrowSize.height);
            self.arrowImageView.frame = CGRectMake(x + self.arrowOffset, 0.0f, arrowSize.width, arrowSize.height);
            
            break;
            
        case UIPopoverArrowDirectionLeft:
            self.backgroundImageView.frame = CGRectMake(arrowSize.height, 0, self.bounds.size.width - arrowSize.height, self.bounds.size.height);
            
            self.arrowImageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.arrowImageView.frame = CGRectMake(0, y + self.arrowOffset, arrowSize.height, arrowSize.width);
            
            break;
            
        case UIPopoverArrowDirectionDown:
            self.backgroundImageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - arrowSize.height);
            
            self.arrowImageView.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, -arrowSize.height);
            self.arrowImageView.frame = CGRectMake(x + self.arrowOffset, self.bounds.size.height - arrowSize.height, arrowSize.width, arrowSize.height);
            
            break;
            
        case UIPopoverArrowDirectionRight:
            self.backgroundImageView.frame = CGRectMake(0, 0, self.bounds.size.width - arrowSize.height, self.bounds.size.height);
            
            self.arrowImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.arrowImageView.frame = CGRectMake(self.bounds.size.width - arrowSize.height, y + self.arrowOffset, arrowSize.height, arrowSize.width);
            
            break;
            
        default:
            break;
    }
    
    self.backgroundImageView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.backgroundImageView.bounds cornerRadius:self.cornerRadius].CGPath;
    self.backgroundImageView.layer.shadowOpacity = 0.3;
    self.backgroundImageView.layer.shadowRadius = 20;
    self.backgroundImageView.layer.shadowOffset = CGSizeZero;
}

- (void)setTintColor:(UIColor *)tintColor
{
    if (_tintColor == tintColor) {
        return;
    }
    _tintColor = tintColor;
    
    self.needRedrawArrowImage = YES;
    self.needRedrawBackgroundImage = YES;
    [self setNeedsLayout];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    if (_borderWidth == borderWidth) {
        return;
    }
    _borderWidth = borderWidth;
    [self setNeedsLayout];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    
    self.needRedrawBackgroundImage = YES;
    [self setNeedsLayout];
}

@end
