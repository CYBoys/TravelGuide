//
//  CQTypeTableController.m
//  CQTravelGuide
//
//  Created by chairman on 15/11/10.
//  Copyright © 2015年 LaiYong. All rights reserved.
//

#import "TypeTableViewController.h"
#import "RXMLElement.h"
#import "SightType.h"
#import "DownLoadManager.h"
#import "DataBaseManager.h"
#import "FMDB.h"
@interface TypeTableViewController ()
@property (strong, nonatomic) NSMutableArray *parseList;
@property (nonatomic, strong) DataBaseManager *DBManager;
@property (nonatomic, assign) BOOL databaseHasData;///<数据库是否有数据
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation TypeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDate *nowDate = [NSDate date];//获取系统当前时间
    self.DBManager = [[DataBaseManager alloc]init];
    NSDate *lastArchiveDate = self.DBManager.lastArchiveDate;//调取数据库最后存档时间
//    NSDate *date = [[DataBaseManager defaultManager]lastArchiveDate];
    
    long dateLongTime =  nowDate.timeIntervalSinceNow - lastArchiveDate.timeIntervalSinceNow;
    NSLog(@"距离现在已经有%li小时",dateLongTime/60/60);//   秒/分/时
    NSUInteger dateTime = dateLongTime/60/60;
    BOOL isBig = dateTime>=8;//判断时间差(小时)是否大于需要自动从网络请求的时间 根据需求设定时间
    NSLog(@"%i",isBig);
    if (isBig || ![self.DBManager numberOfCQType]) {//当时间差大于3小时 或者数据库数据为空时
        self.databaseHasData = NO;
        if (![self.DBManager numberOfCQType]) {
            NSLog(@"数据库为空");
        }
    } else { //当时间差小于3小时 并且数据库数据不为空时
        self.databaseHasData = YES;
    }
    if (!self.databaseHasData) {//当数据库数据为不存在时
        [self refreshBarBtn:nil];
    }
}


//- (void)downloadXML:(NSString *)link {
//    NSURL *url = [NSURL URLWithString:link];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
//        if (connectionError) {
//            NSLog(@"链接错误:%@",connectionError);
//        }
//        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
//        if (code!=200) {
//            NSLog(@"响应错误代码:%li",code);
//        }
//        [self praseXML:data];
//    }];
//}

- (void)praseXML:(NSData *)data {
    RXMLElement *root = [RXMLElement elementFromXMLData:data];
    if (!root) {    //当data为nil时候 直接return
        return;
    }
    [self.DBManager deleteAllSightType];//清空数据库
    [root iterateWithRootXPath:@"//city" usingBlock:^(RXMLElement *city) {
        NSString *typeID = [city child:@"id"].text;
        NSString *typeName = [city child:@"name"].text;
        SightType *theType = [[SightType alloc]init];
        theType.typeName =  typeName;
        theType.typeID = @(typeID.integerValue);
        [self.parseList addObject:theType];

        [self.DBManager insertIntoCQTypeAtIndex:theType];//添加到数据库 离线缓存
//        [[DataBaseManager defaultManager]insertIntoCQTypeAtIndex:theType];
    }];
    [self.tableView reloadData];
}
//刷新数据
- (IBAction)refreshBarBtn:(UIBarButtonItem *)sender {
    self.parseList = [[NSMutableArray alloc]init];
    NSString *link = @"http://1100163.sinaapp.com/open/?sort=all";
    
    DownLoadManager *downLoadXML = [[DownLoadManager alloc]init];
    //block调用
    [downLoadXML downloadXML:link withData:^(NSData *data) {
        [self praseXML:data];
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.databaseHasData?[self.DBManager numberOfCQType]:self.parseList.count;
//    return self.databaseHasData?[[DataBaseManager defaultManager]numberOfCQType]:self.parseList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CQTypeCell" forIndexPath:indexPath];
    
    self.indexPath = indexPath;
    
    SightType *theType;
    if (!self.databaseHasData) {
        theType  = self.parseList[indexPath.row];
    } else {
        theType = [self.DBManager cqTypeAtIndex:indexPath.row];
//        theType = [[DataBaseManager defaultManager]cqTypeAtIndex:indexPath.row];
    }
    cell.textLabel.text = theType.typeName;

    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
    SightType *theType = self.parseList[indexPath.row];
    if ([segue.identifier isEqualToString:@"type2sign"]) {
        if (self.databaseHasData) {
//            SightType *theType = [[DataBaseManager defaultManager]cqTypeAtIndex:indexPath.row];
               SightType *theType = [self.DBManager cqTypeAtIndex:indexPath.row];
            [segue.destinationViewController setValue:theType forKey:@"currentType"];
        } else {
            [segue.destinationViewController setValue:theType forKey:@"currentType"];
        }
    }
}


@end
