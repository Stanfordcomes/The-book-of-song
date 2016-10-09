//
//  SearchViewController.m
//  shijing
//
//  Created by Macbook on 16/7/26.
//  Copyright © 2016年 Macbook. All rights reserved.//

#import "SearchViewController.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor brownColor];
    self.bar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 65, 300, 35)];
    [self.view addSubview:self.bar];
    self.bar.keyboardType = UIKeyboardTypePhonePad;
    self.bar.delegate = self;
    self.bar.placeholder = @"搜索";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
