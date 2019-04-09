//
//  LYViewController.m
//  LYRunloop
//
//  Created by 余河川 on 04/03/2019.
//  Copyright (c) 2019 余河川. All rights reserved.
//

#import "LYViewController.h"
#import <LYRunloop/LYRunloop.h>

@interface LYViewController ()

@end

@implementation LYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    for (NSInteger idx = 0; idx < 8; idx ++) {
        NSString *token = [NSString stringWithFormat:@"%li", (long)idx];
//        [LYRunloop ly_addActionWithFlag:token accuracy:1 startIndex:0 interval:2 repeat:5 action:^{
//            NSLog(@"do xxx");
//        })];
        NSLog(@"add add add");
        [LYRunloop ly_addActionWithFlag:token accuracy:0.5 startIndex:0 interval:3 repeat:5 error:nil action:^(NSString * _Nonnull flag, NSUInteger index) {
            NSLog(@"%@, %lu", flag, (unsigned long)index);
        }];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
