//
//  ViewController.m
//  TV
//
//  Created by xiong on 2016/12/7.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SGWiFiUploadManager.h"
#import "NSObject+kvoRuntime.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic, strong) NSArray        *dataSource;
@property(nonatomic, strong) NSDictionary   *tvDic;
@property(nonatomic, strong) UITableView    *TVList;
@property(nonatomic, strong) AVPlayer       *play;
@property(nonatomic, strong) AVPlayerItem   *playItem;
@property(nonatomic, strong) AVPlayerLayer *playlayer;
@property(nonatomic, strong) UIView         *toolsView;
@property(nonatomic, strong) NSString       *ip;
@property(nonatomic, strong) UIActivityIndicatorView     *activity;

@end

@implementation ViewController
-(AVPlayer *)play{
    if (!_play) {
        _play = [[AVPlayer alloc] init];

    }
    return _play;
}
-(NSArray *)dataSource{
    if (!_dataSource) {
    NSString *make = [[NSBundle mainBundle] pathForResource:@"tv" ofType:@"plist"];
    self.tvDic = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:make]];
    _dataSource =  [[self.tvDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2 options:NSBackwardsSearch];
        }];

    }
    return _dataSource;
}
-(UIActivityIndicatorView *)activity{
    if (!_activity) {
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];//设置进度轮显示类型
        _activity.hidden = YES;
    }
    return _activity;
}
- (void)setupServer {
    SGWiFiUploadManager *mgr = [SGWiFiUploadManager sharedManager];
    BOOL success = [mgr startHTTPServerAtPort:10086];
    if (success) {
        [mgr setFileUploadStartCallback:^(NSString *fileName, NSString *savePath) {
            NSLog(@"File %@ Upload Start", fileName);
        }];
        [mgr setFileUploadProgressCallback:^(NSString *fileName, NSString *savePath, CGFloat progress) {
            NSLog(@"File %@ on progress %f", fileName, progress);
        }];
        [mgr setFileUploadFinishCallback:^(NSString *fileName, NSString *savePath) {
            NSLog(@"File Upload Finish %@ at %@", fileName, savePath);
            NSLog(@"后缀 is %@", [savePath pathExtension]);
            
            if ([[savePath pathExtension] isEqualToString:@"plist"]) {
                NSLog(@"直播源后缀正确");
                
                NSDictionary *temp = [[NSDictionary alloc] initWithContentsOfFile:savePath];
                if (temp == nil) {
                    //解析不出来就退出、提示内容错误
                    NSLog(@"直播源错误");
                    return;
                }
                
                //尝试解析、解析成功，文件移动到document
                NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"wifi.plist"];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:path]) {
                    [fileManager removeItemAtPath:path error:nil];
                
                }
                NSError *error;
                BOOL copySuccess = [fileManager moveItemAtPath:savePath toPath:path error:&error];
                
                if (!copySuccess) {
                    NSLog(@"copy error is %@", error);
                }
                
            }else{
                NSLog(@"直播源后缀错误");
                //提示文件格式不对，删除
            }
            
        }];
    }

    
    self.ip = [NSString stringWithFormat:@"http://%@:10086",mgr.ip];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.playItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://120.87.4.70/PLTV/88888894/224/3221225489/index.m3u8"]];
    [self.play replaceCurrentItemWithPlayerItem:self.playItem];
//    self.play  = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:@"http://111.39.226.103:8112/120000001001/wlds:8080/ysten-business/live/hdzhejiangstv/.m3u8"]];
    AVPlayerLayer *playlaer = [AVPlayerLayer playerLayerWithPlayer:self.play];
    playlaer.frame = self.view.bounds;
    playlaer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:playlaer];
    self.playlayer = playlaer;
    [self.play play];
    [self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    self.activity.center = self.view.center;
    [self.view addSubview:self.activity];
    [self.activity startAnimating];
    
    UIView *toolsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, self.view.frame.size.height)];
    toolsView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:toolsView];
    
    //wiif 传源工具
    UIButton *WIFIcontent = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 40)];
    [WIFIcontent setTitle:@"传源" forState:UIControlStateNormal];
    WIFIcontent.transform = CGAffineTransformRotate(WIFIcontent.titleLabel.transform, M_PI_2);

    //wiif 传输过来的源
    UIButton *newRouce = [[UIButton alloc] initWithFrame:CGRectMake(0, 90, 60, 40)];
    [newRouce setTitle:@"WIFI源" forState:UIControlStateNormal];
    newRouce.transform = CGAffineTransformRotate(newRouce.titleLabel.transform, M_PI_2);
    [toolsView addSubview:WIFIcontent];
    [toolsView addSubview:newRouce];
    [newRouce setBackgroundImage:[UIImage imageNamed:@"arrow"] forState:UIControlStateNormal];
    [WIFIcontent setBackgroundImage:[UIImage imageNamed:@"arrow"] forState:UIControlStateNormal];
    [WIFIcontent addTarget:self action:@selector(alertHttpAddress) forControlEvents:UIControlEventTouchUpInside];
    [newRouce    addTarget:self action:@selector(updateSource:) forControlEvents:UIControlEventTouchUpInside];
    
    self.TVList = [[UITableView alloc] initWithFrame:CGRectMake(60, 0, 170, self.view.frame.size.height) style:UITableViewStylePlain];
    self.TVList.delegate = self;
    self.TVList.dataSource = self;
    [toolsView addSubview: self.TVList];
    self.toolsView = toolsView;
    [self setupServer];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"addobser%@",change);
    
    if (self.playItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.activity stopAnimating];
        
    }else if (self.playItem.status == AVPlayerItemStatusFailed){
        NSLog(@"播放失败");
    
    }else{
        NSLog(@"未知");
    }
    //    AVPlayerStatusUnknown,
    //    AVPlayerStatusReadyToPlay,
    //    AVPlayerStatusFailed

}
-(void)updateSource:(UIButton *)btn{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"wifi.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    if ([btn.titleLabel.text isEqualToString:@"WIFI源"]) {
        //切换到WiFi源
        if ([fileManager fileExistsAtPath:path]) {
            
            NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:path];
            
            NSLog(@"文件存在，处理%@",[dic allKeys]);
            self.tvDic = dic;
            self.dataSource =  [[self.tvDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1 compare:obj2 options:NSBackwardsSearch];
            }];
            [self.TVList reloadData];
            [btn setTitle:@"本地" forState:UIControlStateNormal];
            
        }else{
            NSLog(@"不存在，提示");
        }
        
        
    }else{
        //切换到本地源
        NSString *make = [[NSBundle mainBundle] pathForResource:@"tv" ofType:@"plist"];
        self.tvDic = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:make]];
        _dataSource =  [[self.tvDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2 options:NSBackwardsSearch];
        }];
        [self.TVList reloadData];
        [btn setTitle:@"WIFI源" forState:UIControlStateNormal];
    }

}

//提示传源地址
-(void)alertHttpAddress{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"传源地址(plist)" message:self.ip  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       NSLog(@"touch is ok");
        
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}



-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    cell.textLabel.text = self.dataSource[indexPath.row];
    
    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    
    @try {
        [self.playItem removeObserver:self forKeyPath:@"status"];
    } @catch (NSException *exception) {
        NSLog(@"多次删");
    }

    
    
    NSString *url = [self.tvDic valueForKey:self.dataSource[indexPath.row]];
    self.playItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    [self.play replaceCurrentItemWithPlayerItem:self.playItem];
    [self.activity startAnimating];
    [self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}
//- (BOOL)shouldAutorotate
//{
//    return YES;
//}
//
///**
// *  设置特殊的界面支持的方向,这里特殊界面只支持Home在右侧的情况
// */
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscape;
//}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"展开");
    if (self.toolsView.hidden) {
        self.toolsView.hidden = NO;

    }else{
        self.toolsView.hidden = YES;
    }

}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.playlayer.frame = self.view.frame;
    self.toolsView.frame = CGRectMake(0, 0, self.toolsView.frame.size.width, self.view.frame.size.height);
    self.TVList.frame    = CGRectMake(60, 0, self.TVList.frame.size.width, self.view.frame.size.height);
    self.activity.center = self.view.center;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
