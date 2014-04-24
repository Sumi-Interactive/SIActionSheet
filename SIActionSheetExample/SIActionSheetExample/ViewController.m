//
//  ViewController.m
//  SIActionSheetExample
//
//  Created by Kevin Cao on 13-5-26.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "ViewController.h"
#import "SIActionSheet.h"

#define TEST_APPEARANCE 0

@interface ViewController () <UIActionSheetDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
#if TEST_APPEARANCE
    [[SIActionSheet appearance] setTitleFont:[UIFont boldSystemFontOfSize:18]];
    [[SIActionSheet appearance] setTitleColor:[UIColor redColor]];
    [[SIActionSheet appearance] setButtonFont:[UIFont fontWithName:@"AmericanTypewriter" size:17]];
    [[SIActionSheet appearance] setShadowOpacity:1];
    [[SIActionSheet appearance] setViewBackgroundColor:[UIColor lightGrayColor]];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)show1:(id)sender
{
    SIActionSheet *actionSheet = [[SIActionSheet alloc] initWithTitle:@"Sumi"];
    [actionSheet addButtonWithTitle:@"Button1" type:SIActionSheetButtonTypeDefault handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
        [self show2:nil];
    }];
    [actionSheet addButtonWithTitle:@"Button2" type:SIActionSheetButtonTypeDestructive handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet addButtonWithTitle:@"Cancel" type:SIActionSheetButtonTypeCancel handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    actionSheet.willShowHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"willShowHandler");
    };
    actionSheet.didShowHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"didShowHandler");
    };
    actionSheet.willDismissHandler = ^(SIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSLog(@"willDismissHandler:%d", buttonIndex);
    };
    actionSheet.didDismissHandler = ^(SIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSLog(@"didDismissHandler:%d", buttonIndex);
    };
    actionSheet.allowTapBackgroundToDismiss = YES;
    [actionSheet show];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        actionSheet.title = @"Donec sed odio dui. Curabitur blandit tempus porttitor. Maecenas faucibus mollis interdum. Vestibulum id ligula porta felis euismod semper.Nulla vitae elit libero, a pharetra augue.Aenean lacinia bibendum nulla sed consectetur. Maecenas sed diam eget risus varius blandit sit amet non magna. Etiam porta sem malesuada magna mollis euismod. Donec id elit non mi porta gravida at eget metus. Curabitur blandit tempus porttitor. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.";
    });
}

- (IBAction)show2:(id)sender
{
    UIFont *titleFont = [UIFont fontWithName:@"AmericanTypewriter" size:20];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.1;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName : titleFont, NSParagraphStyleAttributeName : paragraphStyle};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"Donec sed odio dui. Curabitur blandit tempus porttitor." attributes:attributes];
    
    SIActionSheet *actionSheet = [[SIActionSheet alloc] initWithAttributedTitle:attributedString];
    [actionSheet addButtonWithTitle:@"A Very Very Very Very Very Long Title Button1" type:SIActionSheetButtonTypeDefault handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet addButtonWithTitle:@"Button2" type:SIActionSheetButtonTypeCancel handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet addButtonWithTitle:@"Button3" type:SIActionSheetButtonTypeDestructive handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet show];
}

- (IBAction)show3:(id)sender
{
    SIActionSheet *actionSheet = [[SIActionSheet alloc] initWithTitle:@"NOTE: iCloud preference will overwrite local preference. The passcode will not be synced. "];
    [actionSheet addButtonWithTitle:@"Button1" type:SIActionSheetButtonTypeDefault handler:^(SIActionSheet *actionSheet) {
        NSLog(@"Button1");
    }];
    [actionSheet addButtonWithTitle:@"Button2" type:SIActionSheetButtonTypeDestructive handler:^(SIActionSheet *actionSheet) {
        NSLog(@"Button2");
    }];
    actionSheet.willShowHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"willShowHandler");
    };
    actionSheet.didShowHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"didShowHandler");
    };
    actionSheet.willDismissHandler = ^(SIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSLog(@"willDismissHandler:%d", buttonIndex);
    };
    actionSheet.didDismissHandler = ^(SIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSLog(@"didDismissHandler:%d", buttonIndex);
    };
    actionSheet.allowTapBackgroundToDismiss = YES;
    [actionSheet showFromRect:[sender frame] inView:self.view];
}

- (IBAction)show4:(id)sender
{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Donec ullamcorper nulla non metus auctor fringilla. Lorem ipsum dolor sit amet, consectetur adipiscing elit.Nulla vitae elit libero, a pharetra augue. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Cras mattis consectetur purus sit amet fermentum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Maecenas faucibus mollis interdum. Maecenas sed diam eget risus varius blandit sit amet non magna. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Donec id elit non mi porta gravida at eget metus. Donec ullamcorper nulla non metus auctor fringilla. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum.Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Donec ullamcorper nulla non metus auctor fringilla. Lorem ipsum dolor sit amet, consectetur adipiscing elit.Nulla vitae elit libero, a pharetra augue. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Cras mattis consectetur purus sit amet fermentum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Maecenas faucibus mollis interdum. Maecenas sed diam eget risus varius blandit sit amet non magna. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Donec id elit non mi porta gravida at eget metus. Donec ullamcorper nulla non metus auctor fringilla. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum."
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete"
                                                    otherButtonTitles:@"OK1", @"OK2", @"OK3", @"OK4", nil];
    
//    [actionSheet showFromRect:[sender frame] inView:self.view animated:YES];
    [actionSheet showInView:self.view];
}

- (IBAction)show5:(id)sender
{
    SIActionSheet *actionSheet = [[SIActionSheet alloc] initWithTitle:@"NOTE: iCloud preference will overwrite local preference. The passcode will not be synced. "];
    [actionSheet addButtonWithTitle:@"Button1" type:SIActionSheetButtonTypeDefault handler:^(SIActionSheet *actionSheet) {
        NSLog(@"Button1");
    }];
    [actionSheet addButtonWithTitle:@"Button2" type:SIActionSheetButtonTypeDestructive handler:^(SIActionSheet *actionSheet) {
        NSLog(@"Button2");
    }];
    actionSheet.willShowHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"willShowHandler");
    };
    actionSheet.didShowHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"didShowHandler");
    };
    actionSheet.willDismissHandler = ^(SIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSLog(@"willDismissHandler:%d", buttonIndex);
    };
    actionSheet.didDismissHandler = ^(SIActionSheet *actionSheet, NSInteger buttonIndex) {
        NSLog(@"didDismissHandler:%d", buttonIndex);
    };
    actionSheet.allowTapBackgroundToDismiss = YES;
    [actionSheet showFromBarButtonItem:sender];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex%d", buttonIndex);
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    NSLog(@"cancel");
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
