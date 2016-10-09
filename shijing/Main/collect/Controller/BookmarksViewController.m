//
//  BookmarksViewController.m
//  shijing
//
//  Created by Macbook on 16/7/26.
//  Copyright © 2016年 Macbook. All rights reserved.//

#import "BookmarksViewController.h"
#import "SearchViewController.h"
#import "TextViewController.h"
#import <sqlite3.h>

#define kDataBaseFilePath [NSHomeDirectory() stringByAppendingString:@"/Documents/database.sqlite"]
@interface BookmarksViewController ()<UITableViewDelegate,UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating>
{
    NSString *_filePath;
    NSArray *_groupArray;
    NSMutableArray *_dataArray;
    UISearchController *_searchController;
    NSMutableArray *_searchArray;
    UISearchBar *_searchBar;
}
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@end

@implementation BookmarksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
    
    UIImageView *bgImageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    bgImageView.image = [UIImage imageNamed:@"IMG_0062.JPG"];
    [self.view insertSubview:bgImageView atIndex:0];
    
    _contentTableView.backgroundColor = [UIColor clearColor];
    _contentTableView.sectionIndexBackgroundColor = [UIColor clearColor];
    _contentTableView.sectionIndexColor = [UIColor blackColor];
    
    self.navigationController.navigationBar.translucent = NO;
    UIView *maskView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    maskView.backgroundColor = [UIColor whiteColor];
    maskView.alpha = 0.7;
    [self.view insertSubview:maskView atIndex:1];
    [self createSearchBar];
    [self createDataBase];
    [self insertData];
    [_contentTableView reloadData];

}
- (void)viewWillAppear:(BOOL)animated{
    _searchController.searchBar.hidden = NO;
}
- (void)loadData{
    _filePath = [[NSBundle mainBundle]pathForResource:@"text" ofType:@"plist"];
    _groupArray = [NSArray arrayWithContentsOfFile:_filePath];
    _dataArray = [NSMutableArray array];
    for (NSArray *array in _groupArray) {
        for (int i = 1; i < array.count; i++) {
            NSDictionary *dataDic = array[i];
            NSString *dataString = dataDic[@"name"];
            [_dataArray insertObject:dataString atIndex:0];
        }
    }
}

#pragma mark - 数据库
- (void)createDataBase{
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:kDataBaseFilePath]) {
        NSLog(@"%@",kDataBaseFilePath);
        return;
    }
    [manager createFileAtPath:kDataBaseFilePath contents:nil attributes:nil];
    sqlite3 *sql = NULL;
    int openDBResult = sqlite3_open([kDataBaseFilePath UTF8String],&sql);
    if (openDBResult == SQLITE_OK) {
        NSLog(@"%@",kDataBaseFilePath);
    }else{
        [manager removeItemAtPath:kDataBaseFilePath error:nil];
    }
    NSString *sqlString = @"CREATE TABLE fav(id integer PRIMARY KEY,isFav integer,sectionLocation text,rowLocation text)";
    char *errmsg = NULL;
    int exeResult = sqlite3_exec(sql, [sqlString UTF8String], NULL, NULL, &errmsg);
    if (exeResult == SQLITE_OK) {
        NSLog(@"创建成功");
    }else{
        NSLog(@"创建失败");
        sqlite3_close(sql);
        [manager removeItemAtPath:kDataBaseFilePath error:nil];
    }
    sqlite3_close(sql);
}

//数据操作语言，插入数据
- (void)insertData{
    //1.打开数据库
    sqlite3 *sqlite = NULL;
    int openDBResult = sqlite3_open([kDataBaseFilePath UTF8String], &sqlite);
    if (openDBResult != SQLITE_OK) {
        NSLog(@"open fail");
        return;
    }
    //2.构造SQL语句
    //不能直接填入数据，需要使用？来替代数据
    for (int i = 0; i < 304; i++) {
        NSString *string = [NSString stringWithFormat:@"INSERT INTO fav(id,isFav) VALUES (%i,0)",i];
    //3.编译SQL语句
    //创建SQL语句的句柄 句柄：操作编译后的SQL语句
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(sqlite, [string UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"编译出错");
        sqlite3_close(sqlite);
        return;
    }
    //4.执行SQL句柄
    result = sqlite3_step(stmt);
    //5.处理执行结果
    if (result == SQLITE_DONE) {
        NSLog(@"insert success");
    }else{
        NSLog(@"insert fail");
    }
        //6.关闭数据库
        sqlite3_finalize(stmt);
    }
    sqlite3_close(sqlite);
}

#pragma mark - 搜索框的创建与实现
- (void)createSearchBar{
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.searchBar.frame = CGRectMake(50, 65, [UIScreen mainScreen].bounds.size.width - 50, 30);
    _contentTableView.tableHeaderView = _searchController.searchBar;
}
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = _searchController.searchBar.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchString];
    if (_searchArray != nil) {
        [_searchArray removeAllObjects];
    }
    _searchArray = [NSMutableArray arrayWithArray:[_dataArray filteredArrayUsingPredicate:predicate]];
    [_contentTableView reloadData];
}

#pragma mark - tableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (_searchController.active) {
        return _searchArray.count;
    } else {
        NSArray *array = _groupArray[section];
        return array.count - 1;
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (_searchController.active) {
        return 1;
    } else {
        return _groupArray.count;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (_searchController.active) {
        return nil;
    } else {
        NSArray *array = _groupArray[section];
        return array[0];
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    
    if (_searchController.active) {
        cell.textLabel.text = _searchArray[indexPath.row];
    } else {
        NSArray *array = _groupArray[indexPath.section];
        NSDictionary *dic = array[indexPath.row+1];
        cell.textLabel.text = dic[@"name"];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *sectionArray = [NSMutableArray array];
    for (NSArray *array in _groupArray) {
        [sectionArray insertObject:array[0] atIndex:sectionArray.count];
    }
    return sectionArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TextViewController *view = [[TextViewController alloc] init];
    view.hidesBottomBarWhenPushed = YES;
    _searchController.searchBar.hidden = YES;
    [self.navigationController pushViewController:view animated:YES];
    if (_searchArray != nil && _searchArray.count > 0) {
        NSString *textString = _searchArray[indexPath.row];
        for (NSInteger i = 0; i < _groupArray.count; i++) {
            NSArray *array = _groupArray[i];
            for (NSInteger j = 1; j < array.count; j++) {
                NSDictionary *dic = array[j];
                if ([textString isEqualToString:dic[@"name"]] ) {
                    view.indexPath = [NSIndexPath indexPathForRow:j - 1 inSection:i];
                }
            }
        }
    } else {
        view.indexPath = indexPath;
    }
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
