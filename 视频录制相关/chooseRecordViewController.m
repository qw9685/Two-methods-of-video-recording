//
//  chooseRecordViewController.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/7.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "chooseRecordViewController.h"
#import "MovieFileOutputViewController.h"
#import "avassetWriterViewController.h"

@interface chooseRecordViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView* tableview;

@end

@implementation chooseRecordViewController

#define kscreenWidth [UIScreen mainScreen].bounds.size.width
#define kscreenheight [UIScreen mainScreen].bounds.size.height

-(UITableView *)tableview{
    
    if (_tableview == nil) {
        _tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, kscreenWidth, kscreenheight) style:UITableViewStylePlain];
        _tableview.delegate = self;
        _tableview.dataSource = self;
    }
    return _tableview;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.tableview];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"id"];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"id"] ;
        
    }
    cell.textLabel.text = indexPath.row == 0?@"AVCaptureMovieFileOutput":@"avassetWriter";
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self presentViewController:indexPath.row == 0?[MovieFileOutputViewController new] : [avassetWriterViewController new] animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
