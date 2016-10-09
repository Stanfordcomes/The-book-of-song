//
//  TextViewController.m
//  shijing
//
//  Created by Macbook on 16/7/26.
//  Copyright © 2016年 Macbook. All rights reserved.
//

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kDataBaseFilePath [NSHomeDirectory() stringByAppendingString:@"/Documents/database.sqlite"]
#import "TextViewController.h"
#import <sqlite3.h>

@interface TextViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSString *_filePath;
    NSArray *_groupArray;
    NSArray *_contentArray;
    NSDictionary *_detailDictionary;
    
    NSArray *_textArray;
    NSArray *_noteArray;
    NSArray *_versionArray;
    NSString *_musicStr;
    
    UIImageView *_midView;
    UIImageView *_noteImage;
    UIButton *_notebutton;
    UIImageView *_noteBg;
    UIImageView *_bottomView;
    UITableView *_textTableView;
    UITableView *_annotationTableView;
    
    UISlider *_slider;
    UILabel *_leftLabel; // 当前时间
    UILabel *_rightLabel; // 总时间
    UIButton *_playButton; // 播放暂停按钮
    UIButton *_nextButton; // 下一章
    UIButton *_prevButton; // 上一章
    UIButton *_loopButton; // 循环播放
    
    //AVAudioPlayer *_player;
    NSTimer *_timer;
    
    NSInteger _isFav;
    NSMutableArray *_favArray;
}
@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadData];
    [self readSongInfo];
    [self creatTopView];
    [self creatMidView];
    [self creatBottomView];
    
    _favArray = [NSMutableArray arrayWithCapacity:305];
    for (int i = 0; i < 305; i++) {
        [_favArray addObject:@0];
    }
    [self searchFav];
}
-(void)viewWillDisappear:(BOOL)animated{
    [_player pause];
}
#pragma mark - 数据加载
- (void)loadData{
    _filePath = [[NSBundle mainBundle]pathForResource:@"text" ofType:@"plist"];
    _groupArray = [NSArray arrayWithContentsOfFile:_filePath];
}

- (void)readSongInfo{
    
    _contentArray = _groupArray[self.indexPath.section];
    _detailDictionary = _contentArray[self.indexPath.row + 1];
    
    NSString *string = [NSString stringWithFormat:@"%@·%@", _contentArray[0], _detailDictionary[@"name"]];
    self.title = string;
    
    _textArray = _detailDictionary[@"text"];
    _noteArray = _detailDictionary[@"note"];
    _versionArray = _detailDictionary[@"version"];
    _musicStr = _detailDictionary[@"music"];
    
    NSString *musicPath = [[NSBundle mainBundle]pathForResource:_musicStr ofType:nil];
    NSURL *musicUrl = [NSURL fileURLWithPath:musicPath];
    if (_player) {
        _player = nil;
        [_timer invalidate];
        _timer = nil;
    }
    _player = [[AVAudioPlayer alloc]initWithContentsOfURL:musicUrl error:NULL];;
    [_player prepareToPlay];
    [self playAction:_playButton];
    NSTimeInterval totalTime = _player.duration;
    _rightLabel.text = [self formatTime:totalTime];
    
}

#pragma mark - creatUI
- (void)creatTopView {
    
    // 设置左右item
    //判断是否收藏
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"收藏"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(favoritesAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
}

- (void)creatMidView {
    
    _midView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight - 120 - 64)];
    _midView.image = [UIImage imageNamed:@"IMG_0073_b.jpg"];
    _midView.userInteractionEnabled = YES;
    [self.view addSubview:_midView];
    
    //一个浅白色的视图
    UIImageView *maskView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    maskView.backgroundColor = [UIColor whiteColor];
    maskView.alpha = 0.8;
    [_midView addSubview:maskView];
    
    // 1.正文
    _textTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, _midView.bounds.size.height - 10) style:UITableViewStylePlain];
    _textTableView.delegate = self;
    _textTableView.dataSource = self;
    _textTableView.backgroundColor = [UIColor clearColor];
    _textTableView.separatorColor = [UIColor clearColor];
    [_midView addSubview:_textTableView];
    
    // 2.注释
    _noteBg = [[UIImageView alloc]initWithFrame:CGRectMake(0, _midView.frame.size.height , kScreenWidth, kScreenHeight/2-60)];
    [_midView addSubview:_noteBg];
    _noteBg.image = [UIImage imageNamed:@"IMG_0068_blackwhite.jpg"];
    
    _notebutton = [[UIButton alloc] initWithFrame:CGRectMake(0, _midView.frame.size.height - 30, kScreenWidth, 30)];
    _notebutton.backgroundColor = [UIColor clearColor];
    [_midView addSubview:_notebutton];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 35, 30)];
    label.text = @"注释";
    [_notebutton addSubview:label];
    
    _noteImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"down.png"]];
    _noteImage.frame = CGRectMake(45, 0, 30, 30);
    [_notebutton addSubview:_noteImage];
    
    [_notebutton addTarget:self action:@selector(noteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    _annotationTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_notebutton.frame), kScreenWidth, kScreenHeight/2-120) style:UITableViewStylePlain];
    _annotationTableView.delegate = self;
    _annotationTableView.dataSource = self;
    _annotationTableView.hidden = YES;
    _annotationTableView.separatorColor = [UIColor clearColor];
    [_midView addSubview:_annotationTableView];
    _annotationTableView.backgroundColor = [UIColor clearColor];
}


- (void)creatBottomView {
    
    _bottomView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kScreenHeight - 120 - 64, kScreenWidth, 120)];
    _bottomView.backgroundColor = [UIColor whiteColor];
    _bottomView.alpha = 0.9;
    _bottomView.userInteractionEnabled = YES;
    [self.view addSubview:_bottomView];
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 20)];
    [_slider addTarget:self action:@selector(changeToProgress) forControlEvents:UIControlEventValueChanged];
    [_bottomView addSubview:_slider];
    
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 70, 30)];
    _leftLabel.text = @"00:00";
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.textColor = [UIColor blackColor];
    _leftLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_leftLabel];
    
    _rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth - 70, 15, 70, 30)];
    _rightLabel.text = @"00:58";
    _rightLabel.backgroundColor = [UIColor clearColor];
    _rightLabel.textColor = [UIColor blackColor];
    _rightLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_rightLabel];
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = CGRectMake(0, 0, 65, 65);
   _playButton.center = CGPointMake(kScreenWidth / 2, _bottomView.bounds.size.height / 2 + 10);
    [_playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_playButton];
    
    _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _prevButton.frame = CGRectMake(0, 0, 40, 40);
    _prevButton.center = CGPointMake(kScreenWidth / 4, _playButton.center.y);;
    [_prevButton setImage:[UIImage imageNamed:@"prev"] forState:UIControlStateNormal];
    [_prevButton addTarget:self action:@selector(prevAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_prevButton];
    
    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _nextButton.frame = CGRectMake(0, 0, 40, 40);
    _nextButton.center = CGPointMake(kScreenWidth / 4 * 3, _playButton.center.y);
    [_nextButton setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
    [_nextButton addTarget:self action:@selector(nextAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_nextButton];
    
    _loopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _loopButton.frame = CGRectMake(kScreenWidth - 100, 80, 100, 40);
    [_loopButton setTitle:@"单曲循环" forState:UIControlStateNormal];
    [_loopButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_loopButton addTarget:self action:@selector(loopAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_loopButton];
    
}

#pragma mark - action
- (void)favoritesAction {
        NSInteger sum = 0;
    if (_indexPath.section == 0) {
        
    }else{
    for (int i = 0; i < _indexPath.section; i++) {
        NSArray *array = _groupArray[i];
        sum += array.count-1;
    }
    }
    sum += _indexPath.row;
    [self updateFavTableWithSum:sum];
}

//查找数据库
- (void)searchFav{
    _isFav = 0;
    //1.打开数据库
    sqlite3 *sqlite = NULL;
    int openDBResult = sqlite3_open([kDataBaseFilePath UTF8String], &sqlite);
    if (openDBResult != SQLITE_OK) {
        NSLog(@"open fail");
        return;
    }
    //2.构造SQL语句
    NSString *string = [NSString stringWithFormat:@"SELECT * FROM fav WHERE sectionLocation LIKE %li AND rowLocation LIKE %li;",_indexPath.section,_indexPath.row];
    //3.编译SQL语句
    //创建SQL语句的句柄 句柄：操作编译后的SQL语句
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(sqlite, [string UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"compile fail");
        sqlite3_close(sqlite);
        return;
    }
    sqlite3_bind_text(stmt, 1, "%g%" ,-1, NULL);
    //4.执行SQL句柄
    //获取第一个数据
    result = sqlite3_step(stmt);
    
    //5.处理执行结果
    if (result == SQLITE_ROW) {
        _isFav = sqlite3_column_int(stmt, 1);
        NSLog(@"%li",_isFav);
        
    }

    //6.释放SQL句柄，关闭数据库
    sqlite3_finalize(stmt);
    sqlite3_close(sqlite);
    if (_isFav == 1) {
        self.navigationItem.rightBarButtonItem.title=@"已收藏";
    }else{
        self.navigationItem.rightBarButtonItem.title=@"收藏";
    }
}

//更新数据库
- (void)updateFavTableWithSum:(NSInteger)sum{
    
    NSString *sectionLocation = [NSString stringWithFormat:@"%li",_indexPath.section];
    NSString *rowLocation = [NSString stringWithFormat:@"%li",_indexPath.row];
    //1.打开数据库
    sqlite3 *sqlite = NULL;
    int openDBResult = sqlite3_open([kDataBaseFilePath UTF8String], &sqlite);
    if (openDBResult != SQLITE_OK) {
        NSLog(@"open fail");
        return;
    }
    //2.构造SQL语句
    NSString *string = [[NSString alloc]init];
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"收藏"]) {
        self.navigationItem.rightBarButtonItem.title = @"已收藏";
        string = [NSString stringWithFormat:@"UPDATE fav  SET isFav=1,sectionLocation=%@,rowLocation=%@ WHERE id=%li;",sectionLocation,rowLocation,sum];
    }else{
        self.navigationItem.rightBarButtonItem.title = @"收藏";
        string = [NSString stringWithFormat:@"UPDATE fav  SET isFav=0,sectionLocation=%@,rowLocation=%@ WHERE id=%li;",sectionLocation,rowLocation,sum];
    }
    //3.编译SQL语句
    //创建SQL语句的句柄
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
    if (result == SQLITE_DONE) {
        NSLog(@"update success");
    }else{
        NSLog(@"update fail");
    }
    //6.释放SQL句柄，关闭数据库
    sqlite3_finalize(stmt);
    sqlite3_close(sqlite);
}

- (void)noteAction:(UIButton *)button {
    _annotationTableView.hidden = !_annotationTableView.hidden;
    if (button.frame.origin.y == _midView.frame.size.height - 30) {
        _notebutton.frame = CGRectMake(0, _midView.frame.size.height / 2, kScreenWidth, 30);
        _noteImage.image = [UIImage imageNamed:@"up.png"];
    } else {
        _notebutton.frame = CGRectMake(0, _midView.frame.size.height - 30, kScreenWidth, 30);
        _noteImage.image = [UIImage imageNamed:@"down.png"];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [_annotationTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    _noteBg.frame = CGRectMake(0, CGRectGetMaxY(_notebutton.frame)-30, kScreenWidth, kScreenHeight / 2 - 120);
    _annotationTableView.frame = CGRectMake(0, CGRectGetMaxY(_notebutton.frame), kScreenWidth, kScreenHeight / 2 - 120);
    
}

- (void)playAction:(UIButton *)button {
    if (_player.playing) {
        [button setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_player pause];
        if (_timer) {
            [_timer invalidate];
            _timer=nil;
        }
    }else{
        [button setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [_player play];
        if (!_timer) {
            _timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(changeMusicProgress) userInfo:nil repeats:YES];
        }
    }
}

- (void)prevAction:(UIButton *)button {
    if (_indexPath.section == 0 && _indexPath.row == 0) {
        NSArray *array = _groupArray[_groupArray.count - 1];
        _indexPath = [NSIndexPath indexPathForRow:array.count - 2 inSection:_groupArray.count - 1];
    } else if (_indexPath.row == 0) {
        NSArray *array = _groupArray[self.indexPath.section - 1];
        _indexPath = [NSIndexPath indexPathForRow:array.count - 2 inSection:_indexPath.section - 1];
    } else {
        _indexPath = [NSIndexPath indexPathForRow:_indexPath.row - 1 inSection:_indexPath.section];
    }
    [self readSongInfo];
    [_textTableView reloadData];
    [_annotationTableView reloadData];
    [self searchFav];
}

- (void)nextAction:(UIButton *)button {
    NSArray *array = _groupArray[_groupArray.count - 1];
    if (_indexPath.section == _groupArray.count - 1 && _indexPath.row == array.count - 2) {
        _indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    } else if (_indexPath.row == _contentArray.count - 2) {
        _indexPath = [NSIndexPath indexPathForRow:0 inSection:_indexPath.section + 1];
    } else {
        _indexPath = [NSIndexPath indexPathForRow:_indexPath.row + 1 inSection:_indexPath.section];
    }
    [self readSongInfo];
    [_textTableView reloadData];
    [_annotationTableView reloadData];
    [self searchFav];
    
}

- (void)loopAction:(UIButton *)button {
    
    if ([_loopButton.titleLabel.text isEqualToString:@"单曲循环"]) {
        [_loopButton setTitle:@"循环播放" forState:UIControlStateNormal];
        
    } else {
        [_loopButton setTitle:@"单曲循环" forState:UIControlStateNormal];
    }
}

- (void)changeMusicProgress{
    NSTimeInterval time = _player.currentTime;
    _leftLabel.text = [self formatTime:time];
    _slider.value = _player.currentTime/_player.duration;
    if (_slider.value >= 0.99) {
        if ([_loopButton.titleLabel.text isEqualToString:@"循环播放"]) {
            [self nextAction:_nextButton];
        } else {
            _slider.value = 0;
            [self readSongInfo];
        }
    }
}

- (void)changeToProgress{
    NSTimeInterval currentTime = _slider.value*_player.duration;
    _player.currentTime = currentTime;
}

#pragma mark - tableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"textCell"];
    }
    cell.backgroundColor = [UIColor clearColor];
    
    if (tableView == _textTableView) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.text = _textArray[indexPath.row];
    } else {
        if (indexPath.row < _noteArray.count) {
            NSString *noteString = [NSString stringWithFormat:@"%li：%@", (long)indexPath.row, _noteArray[indexPath.row]];
            cell.textLabel.text = noteString;
            
        } else if(indexPath.row == _noteArray.count) {
            cell.textLabel.text = @"［译文］";
       } else {
            cell.textLabel.text = _versionArray[indexPath.row-_noteArray.count-1];
        }
    }
    cell.textLabel.numberOfLines = 0;
    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == _textTableView) {
        return _textArray.count;
    } else {
        return _noteArray.count+_versionArray.count + 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    // 设置label的最大宽度
    CGSize maxSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 10000);
    // 设置计算的字体大小
    NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:17]};
    NSString *text;
    CGRect frame;
    if (tableView == _textTableView) {
        text = _textArray[indexPath.row];
    }else{
        if (indexPath.row < _noteArray.count) {
            text = _noteArray[indexPath.row];
        }
        else if(indexPath.row > _noteArray.count){
            text = _versionArray[indexPath.row - _noteArray.count - 1];
        }
    }
    frame = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    CGFloat height = ceilf(frame.size.height) + 20;
    return height * 5 / 4;
}

#pragma mark - 格式化时间
- (NSString *)formatTime:(NSTimeInterval)timeInterval{
    int minute = timeInterval / 60;
    int second = (int)timeInterval % 60;
    NSString *string = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    return string;
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
