//
//  FavoritesViewController.m
//  shijing
//
//  Created by Macbook on 16/7/26.
//  Copyright © 2016年 Macbook. All rights reserved.
//

#import "FavoritesViewController.h"
#import <sqlite3.h>
#import "TextViewController.h"

#define kDataBaseFilePath [NSHomeDirectory() stringByAppendingString:@"/Documents/database.sqlite"]

@interface FavoritesViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView *_titleTableView;
    NSInteger _count;
    NSMutableArray *_titleArray;
    
    NSString *_filePath;
    NSArray *_groupArray;
    
    NSString *_sectionLocation;
    NSInteger _section;
    NSString *_rowLocation;
    NSInteger _row;
}
@end

@implementation FavoritesViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self searchFav];
    [_titleTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createTableView];
    [self searchFav];
    [self loadData];
    self.navigationController.navigationBar.translucent = NO;
    
    UIImageView *bgImageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    bgImageView.image = [UIImage imageNamed:@"IMG_0072_b.jpg"];
    [self.view insertSubview:bgImageView atIndex:0];
    _titleTableView.backgroundColor = [UIColor clearColor];
}

- (void)loadData{
    _filePath = [[NSBundle mainBundle]pathForResource:@"text" ofType:@"plist"];
    _groupArray = [NSArray arrayWithContentsOfFile:_filePath];
}

- (void)createTableView{
    _titleTableView = [[UITableView alloc]initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _titleTableView.delegate = self;
    _titleTableView.dataSource = self;
    [self.view addSubview:_titleTableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cellID"];
    }
    NSArray *locationArray = _titleArray[indexPath.row];
    
    _sectionLocation = locationArray[0];
    _section = [_sectionLocation integerValue];
    _rowLocation = locationArray[1];
    _row = [_rowLocation integerValue];
    NSArray *array = _groupArray[_section];
    NSDictionary *dic = array[_row+1];
    cell.textLabel.text = dic[@"name"];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)searchFav{
    _count = 0;
    _titleArray = [NSMutableArray arrayWithCapacity:400];
    //1.打开数据库
    sqlite3 *sqlite = NULL;
    int openDBResult = sqlite3_open([kDataBaseFilePath UTF8String], &sqlite);
    if (openDBResult != SQLITE_OK) {
        NSLog(@"open fail");
        return;
    }
    //2.构造SQL语句
    NSString *string = @"SELECT * FROM fav WHERE isFav LIKE 1;";
    //3.编译SQL语句
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(sqlite, [string UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"compile fail");
        sqlite3_close(sqlite);
        return;
    }
    //4.执行SQL句柄
    result = sqlite3_step(stmt);
    //5.处理执行结果
    while (result == SQLITE_ROW) {
        NSMutableArray *locationArray = [NSMutableArray arrayWithCapacity:2];
        NSString  *sectionLocation = [NSString stringWithFormat:@"%s",sqlite3_column_text(stmt, 2)];
        [locationArray addObject:sectionLocation];
        NSString *rowLocation = [NSString stringWithFormat:@"%s",sqlite3_column_text(stmt,3)];
        [locationArray addObject:rowLocation];
        _count++;
        result = sqlite3_step(stmt);
        [_titleArray addObject:locationArray];
    }
    //6.释放SQL句柄，关闭数据库
    sqlite3_finalize(stmt);
    sqlite3_close(sqlite);
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TextViewController *view = [[TextViewController alloc] init];
    NSArray *locationArray = _titleArray[indexPath.row];
    
    _sectionLocation = locationArray[0];
    _section = [_sectionLocation integerValue];
    _rowLocation = locationArray[1];
    _row = [_rowLocation integerValue];
    NSArray *array = _groupArray[_section];
    NSDictionary *dic = array[_row + 1];
    NSString *string = [NSString stringWithFormat:@"%@·%@", array[0], dic[@"name"]];
    view.title = string;
    view.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:view animated:YES];
    NSIndexPath *path = [NSIndexPath indexPathForRow:_row inSection:_section];
    view.indexPath = path;
//    NSLog(@"%@",path);
//    NSLog(@"%li",_row);
    
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
