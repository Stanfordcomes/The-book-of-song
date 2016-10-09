//
//  BaseTabBarController.m
//  shijing
//
//  Created by Macbook on 16/7/26.
//  Copyright © 2016年 Macbook. All rights reserved.//

#import "BaseTabBarController.h"
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
@interface BaseTabBarController ()
{
    UIImageView *_arrowImageView;
}
@end

@implementation BaseTabBarController
- (instancetype)init{
    self = [super init];
    if (self) {
        [self createSubViewControllers];
        [self customTabBar];
    }
    return self;
}

- (void)createSubViewControllers{
    [super viewDidLoad];
    NSArray *storyboardNames = @[@"Bookmarks",@"Favorites",@"More"];
    NSMutableArray *mArray = [[NSMutableArray alloc]init];
    for (NSString *name in storyboardNames) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:[NSBundle mainBundle]];
        UINavigationController *nav = [storyboard instantiateInitialViewController];
        [mArray addObject:nav];
    }
    self.viewControllers = [mArray copy];
}

- (void)customTabBar{
        for (UIView *subView in self.tabBar.subviews) {
            Class buttonClass = NSClassFromString(@"UITabBarButton");
            if ([subView isKindOfClass:buttonClass]) {
                [subView removeFromSuperview];
            }
            NSArray *titleArray = @[@"书单",@"收藏",@"我们"];
            NSArray *imageArray = @[@"Bookmarks@2x.png", @"Favorites@2x.png", @"More@2x.png"];
            for (int i = 0; i < 3; i++) {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(i*kScreenWidth/3, 0, kScreenWidth/3, 49);
                [self.tabBar addSubview:button];
                button.tag = i;
                [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
                [button setTitle:titleArray[i] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont systemFontOfSize:16];
                [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:imageArray[i]] forState:UIControlStateNormal];
            }
    }
    // 选中框
    _arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth / 3, 49)];
    _arrowImageView.backgroundColor = [UIColor grayColor];
    _arrowImageView.alpha = 0.2;
    [self.tabBar insertSubview:_arrowImageView atIndex:1];
}

- (void)buttonAction:(UIButton *)button{
    self.selectedIndex = button.tag;
    [UIView animateWithDuration:0.3 animations:^{
        _arrowImageView.center = button.center;
    }];
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
