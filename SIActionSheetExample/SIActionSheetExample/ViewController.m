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

@interface ViewController ()

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
    actionSheet.willDismissHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"willDismissHandler");
    };
    actionSheet.didDismissHandler = ^(SIActionSheet *actionSheet) {
        NSLog(@"didDismissHandler");
    };
    actionSheet.allowTapBackgroundToDismiss = YES;
    [actionSheet show];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        actionSheet.title = @"NOTE: iCloud preference will overwrite local preference. The passcode will not be synced. ";
        actionSheet.titleFont = [UIFont systemFontOfSize:14];
    });
}

- (IBAction)show2:(id)sender
{
    SIActionSheet *actionSheet = [[SIActionSheet alloc] initWithTitle:@"NOTE: iCloud preference will overwrite local preference. The passcode will not be synced. NOTE: iCloud preference will overwrite local preference. The passcode will not be synced. NOTE: iCloud preference will overwrite local preference. The passcode will not be synced."];
    [actionSheet addButtonWithTitle:@"A Very Very Very Very Very Long Title Button1" type:SIActionSheetButtonTypeDefault handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet addButtonWithTitle:@"Button2" type:SIActionSheetButtonTypeCancel handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet show];
    actionSheet.titleColor = [UIColor redColor];
    actionSheet.buttonFont = [UIFont fontWithName:@"AmericanTypewriter" size:17];
}


@end
