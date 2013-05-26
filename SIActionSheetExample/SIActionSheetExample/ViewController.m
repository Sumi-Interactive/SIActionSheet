//
//  ViewController.m
//  SIActionSheetExample
//
//  Created by Kevin Cao on 13-5-26.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "ViewController.h"
#import "SIActionSheet.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
    actionSheet.tapBackgroundToDismissEnabled = YES;
    [actionSheet show];
    
    SIActionSheet *actionSheet2 = [[SIActionSheet alloc] initWithTitle:@"Sumi2"];
    [actionSheet2 addButtonWithTitle:@"Button1" type:SIActionSheetButtonTypeDefault handler:^(SIActionSheet *actionSheet) {
        NSLog(@"%@", actionSheet);
    }];
    [actionSheet2 show];
}

@end
