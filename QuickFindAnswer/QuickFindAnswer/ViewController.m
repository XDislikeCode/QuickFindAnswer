//
//  ViewController.m
//  QuickFindAnswer
//
//  Created by canoe on 2018/1/15.
//  Copyright © 2018年 canoe. All rights reserved.
//

#import "ViewController.h"
#import <AipOcrSdk/AipOcrSdk.h>
#import <WebKit/WebKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <SafariServices/SafariServices.h>
#import <Photos/Photos.h>

#import "WJPhotoTool.h"

#import "XMacros.h"
#import "XCategoryHeader.h"

//主线程异步队列
#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@interface ViewController ()

@property(nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIImageView *myImageView;

@property(nonatomic, strong) SFSafariViewController * safari;

//@property(nonatomic, assign) BOOL reload;

@property(nonatomic, strong) UILabel *timeLabel;

@end

@implementation ViewController

-(void)searchWithText:(NSString *)string
{
    string = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    if (@available(iOS 9.0, *)) {
        SFSafariViewController * safari = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.baidu.com.cn/s?wd=%@",string]]];
        [self presentViewController:safari animated:NO completion:nil];
        self.safari = safari;
    } else {
        // Fallback on earlier versions
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, KScreenHeight - 40, 40, 40)];
    self.timeLabel.font = [UIFont systemFontOfSize:20.0];
    self.timeLabel.text = @"0";
    self.timeLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.timeLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (enter) name: UIApplicationDidBecomeActiveNotification object:nil];
    
    //注册程序进入后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (pop) name: UIApplicationDidEnterBackgroundNotification object:nil];
}


-(void)orcImage
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = @"Loading...";
    //文字识别
    NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"false"};
    [[AipOcrService shardService] detectTextBasicFromImage:self.image withOptions:options successHandler:^(id result) {
        
        dispatch_main_async_safe(^{
            hud.label.text = @"识别成功";
            [hud hideAnimated:YES afterDelay:0.5];
            
            NSString *keywords = [NSString string];
            if ([result[@"words_result"] count] > 0) {
                NSArray *array = result[@"words_result"];
                //先拼接成一个字符串
                for (NSInteger i = 0; i < array.count; i++) {
                    NSDictionary *dict = array[i];
                    keywords = [keywords stringByAppendingString:dict[@"words"]];
                }
                
                //以问号分割字符串，得到最前面的问题
                keywords = [[keywords componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?？"]] firstObject];
                //以.分割字符串，得到最后面的问题
                keywords = [[keywords componentsSeparatedByString:@"."] lastObject];
                [self searchWithText:keywords];
            }else
            {
                MBProgressHUD *haha = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                haha.mode = MBProgressHUDModeIndeterminate;
                haha.label.text = @"被玩坏了!";
                [haha hideAnimated:YES];
            }
        });
        
    } failHandler:^(NSError *err) {
        hud.label.text = @"识别失败，自己猜吧少年！";
        [hud hideAnimated:YES afterDelay:1.0];
    }];
}

-(void)enter
{
    [NSTimer scheduledTimerWithTimeInterval:1.0 block:^(NSTimer *timer) {
        self.timeLabel.text = [NSString stringWithFormat:@"%ld",self.timeLabel.text.integerValue + 1];
        if ([self.timeLabel.text isEqualToString:@"10"]) {
            [timer invalidate];
            self.timeLabel.text = @"0";
        }
    } repeats:YES];
    
    [WJPhotoTool latestAsset:^(WJAsset * _Nullable asset) {
        self.image = asset.image;
        self.image = [self.image imageByCropToRect:CGRectMake(0, 0, self.image.size.width, self.image.size.height/2)];
        self.image = [UIImage resizeImage:self.image withNewSize:CGSizeMake(KScreenWidth/2, KScreenHeight/4)];
        [self.myImageView setImage:self.image];
        [self orcImage];
    }];
}

-(void)pop
{
    if (self.safari) {
        [self.safari dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
