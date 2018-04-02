//
//  VideoListController.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/9.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "VideoListController.h"

@interface VideoListController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView* tableview;

@end
#define kscreenWidth [UIScreen mainScreen].bounds.size.width
#define kscreenheight [UIScreen mainScreen].bounds.size.height
@implementation VideoListController

-(UITableView *)tableview{
    
    if (_tableview == nil) {
        _tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, 20, kscreenWidth, kscreenheight) style:UITableViewStylePlain];
        _tableview.delegate = self;
        _tableview.dataSource = self;
    }
    return _tableview;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton* backBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 44, 44)];
    [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTitle:@"返回" forState:0];
    [self.view addSubview:backBtn];
    
    [self.view addSubview:self.tableview];
}

- (void)backAction{
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

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
