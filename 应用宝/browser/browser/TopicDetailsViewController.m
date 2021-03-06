//
//  TopicDetailsViewController.m
//  MyHelper
//
//  Created by mingzhi on 14/12/31.
//  Copyright (c) 2014年 myHelper. All rights reserved.
//

#import "TopicDetailsViewController.h"
#import "CollectionCells.h"
#import "MyCollectionViewFlowLayout.h"
#import "PublicCollectionCell.h"
#import "TopicDetailHeadView.h"
#import "SearchResult_DetailViewController.h"
#import "AppStatusManage.h"

@implementation TopicDetailTitleView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _coverView = [UILabel new];
        _coverView.backgroundColor = NavColor;
        _coverView.alpha = 0;
        _line = [UILabel new];
        _line.backgroundColor = BottomColor;
        [_coverView addSubview:_line];
        [self addSubview:_coverView];
        
        _titile = [UILabel new];
        _titile.textAlignment = NSTextAlignmentCenter;
        _titile.textColor = [UIColor whiteColor];
        _titile.text = @"title title title title";
        [self addSubview:_titile];
        
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setBackgroundImage:[[UIImage imageNamed:@"nav_back"] imageWithTintColor:[UIColor colorWithWhite:0.0 alpha:1.0] blendMode:kCGBlendModeOverlay] forState:UIControlStateNormal];
        [self addSubview:_backButton];
        
        
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGRect rect = self.bounds;
    CGFloat btnWidth = 80/2;
    _coverView.frame = rect;
    _titile.frame = CGRectMake(60, 20, rect.size.width-120, rect.size.height-20);
    _backButton.frame = CGRectMake(10, 20 + (44 - btnWidth)/2 , btnWidth, btnWidth);
    _line.frame = CGRectMake(0, rect.size.height - 0.5, MainScreen_Width, 0.5);
    
}
@end


@interface TopicDetailsViewController ()<UICollectionViewDataSource ,UICollectionViewDelegate ,UICollectionViewDelegateFlowLayout ,MyServerRequestManagerDelegate>
{
    //UI
    UICollectionView *myCollectionView;
    TopicDetailHeadView *detailHeadView;//专题图片和文字
    TopicDetailTitleView *titleView;//标题
    CollectionViewBack *backView;
    
    //数据
    float introTextHeight;//专题头文字显示高度
    NSDictionary *infoDic;
    NSArray *dataArray;
    SearchResult_DetailViewController *detailVC;//app详情页面

}
@end

@implementation TopicDetailsViewController

+ (id)defaults{
    
    static TopicDetailsViewController * _topicDetailsViewController = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _topicDetailsViewController = [TopicDetailsViewController new];
    });
    
    return _topicDetailsViewController;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //列表
    [self.view addSubview:self.myCollectionView];
    [self.myCollectionView addSubview:self.detailHeadView];
    
    //菊花
    backView = [CollectionViewBack new];
    backView.status = Loading;
    __weak TopicDetailsViewController* mySelf = self;
    __weak NSDictionary* myInfoDic = infoDic;
    [backView setClickActionWithBlock:^{
        [mySelf requestData:myInfoDic isUseCache:NO];
    }];
    [self.view addSubview:backView];
    
    //标题
    titleView = [TopicDetailTitleView new];
    [titleView.backButton addTarget:self action:@selector(backView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:titleView];
    
    detailVC = [[SearchResult_DetailViewController alloc]init];

}

- (void)viewWillLayoutSubviews{
    
    [super viewWillLayoutSubviews];
    CGRect rect = self.view.bounds;
    titleView.frame =  CGRectMake(0, 0, rect.size.width, 64);
    self.myCollectionView.frame = rect;
    self.myCollectionView.contentInset = UIEdgeInsetsMake(ORIGINAL_IMAGE_HEIGHT + introTextHeight + 20, 0, 0, 0);
    self.myCollectionView.contentOffset = CGPointMake(0, - (ORIGINAL_IMAGE_HEIGHT + introTextHeight + 20));
    self.detailHeadView.frame = CGRectMake(0, myCollectionView.contentOffset.y, MainScreen_Width, -myCollectionView.contentOffset.y);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[MyServerRequestManager getManager] removeListener:self];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)backView
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (UICollectionView *)myCollectionView{
    if (myCollectionView) return myCollectionView;
    
    MyCollectionViewFlowLayout *flowLayout = [MyCollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    myCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    myCollectionView.backgroundColor = hllColor(242, 242, 242, 1);
    myCollectionView.dataSource = self;
    myCollectionView.delegate = self;
    myCollectionView.indicatorStyle=UIScrollViewIndicatorStyleDefault;
    myCollectionView.alwaysBounceVertical = YES;
    
    [myCollectionView registerClass:[PublicCollectionCell class] forCellWithReuseIdentifier:RECOMMENDAPPS];
    
    return myCollectionView;
}

- (TopicDetailHeadView *)detailHeadView{
    if (detailHeadView) return detailHeadView;
    
    detailHeadView = [TopicDetailHeadView new];
    return detailHeadView;
}

#pragma mark - 清理缓存
- (void)clearCache{
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
#pragma mark - 请求数据
- (void)setDataDic:(NSDictionary *)dataDic
{
    if (!infoDic) infoDic = [NSMutableDictionary dictionary];
    infoDic = dataDic;
    [self requestData:infoDic isUseCache:YES];
}

- (void)setDataDic:(NSDictionary *)dataDic andColorm:(NSString *)colorm
{
    if (!infoDic) infoDic = [NSMutableDictionary dictionary];
    infoDic = dataDic;
    [self requestData:infoDic isUseCache:YES];
        
    [[ReportManage instance] reportOtherDetailClick:colorm appid:[infoDic objectForKey:SPECIAL_ID]];
}


- (void)requestData:(NSDictionary *)dic isUseCache:(BOOL)isUseCache
{
//    NSLog(@"专题详情请求数据");
    backView.status = Loading;
    
    [[MyServerRequestManager getManager] addListener:self];
    [[MyServerRequestManager getManager] requestSpecialDetail:[infoDic objectForKey:SPECIAL_ID] isUseCache:isUseCache userData:self];
}

#pragma mark - UICollectionView datasource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [dataArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PublicCollectionCell *cell = (PublicCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:RECOMMENDAPPS forIndexPath:indexPath];
    [cell setBottomLineLong:NO];
    
    //设置下线
    if (indexPath.row == dataArray.count-1) {
        [cell setBottomLineLong:YES];
    }
    //设置数据
    NSDictionary *showCellDic = [dataArray objectAtIndex:indexPath.row];
    
    //设置属性
    cell.downLoadSource = HOME_PAGE_RECOMMEND_MY(indexPath.section, indexPath.row);
    [cell setCellData:showCellDic];
    [cell initDownloadButtonState];

    return cell;
}

#pragma mark - UICollectionViewLayoutDelegate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = CGSizeMake(collectionView.frame.size.width, 168/2*MULTIPLE);//cell
    return size;
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);
    return insets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //cell
    PublicCollectionCell *cell = (PublicCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [[ReportManage instance] reportAppDetailClick:SPECIAL_APP([infoDic objectForKey:SPECIAL_ID], (long)indexPath.row) contentDic:cell.cellDataDic];
    
    if (SHOW_REAL_VIEW_FLAG&&!DIRECTLY_GO_APPSTORE) {
        [self pushToAppDetailViewWithAppInfor:cell.cellDataDic andSoure:@"topic_detail"];
    }else{
        [[NSNotificationCenter  defaultCenter] postNotificationName:OPEN_APPSTORE object:cell.appdigitalid];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (void)reloadListData
{
    [myCollectionView reloadData];
}

#pragma mark - scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    //定义为int而非float,防止某些情况下出现的值可能为0.0几,导致仿导航栏异常
    CGFloat bounceHeight = -scrollView.contentOffset.y - (ORIGINAL_IMAGE_HEIGHT + introTextHeight + 20);
    //下拉时大于0
    if (bounceHeight > 1) {
        //调整headView位置大小并自动调整专题图显示
        self.detailHeadView.frame = CGRectMake(0, myCollectionView.contentOffset.y, MainScreen_Width, -myCollectionView.contentOffset.y);
        //避免返回时scrollview执行
        if ([[self.navigationController class] isSubclassOfClass:[self class]]) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
        }
    }else{
        float colorValue = -bounceHeight/100.0;
        [titleView.backButton setBackgroundImage: [[UIImage imageNamed:@"nav_back"] imageWithTintColor:[UIColor colorWithWhite:1 - colorValue alpha:1.0] blendMode:kCGBlendModeOverlay] forState:UIControlStateNormal];
        titleView.titile.textColor = [UIColor colorWithWhite:1.0 - colorValue alpha:1.0];
        titleView.coverView.alpha = colorValue;
        if (colorValue>0.5) {
            [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
            [titleView.backButton setBackgroundImage:[UIImage imageNamed:@"nav_back"] forState:UIControlStateNormal];
        }
    }
}


#pragma mark - 曝光
BOOL _deceler_topic;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView.decelerating) _deceler_topic = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate && !_deceler_topic) [self baoguang]; _deceler_topic = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    if (self.view.hidden) return;
    [self baoguang];
}

- (void)baoguang{

    NSMutableArray *appidArray;
    NSMutableArray *appdigidArray;
    if (!appidArray) appidArray = [NSMutableArray array];
    if (!appdigidArray) appdigidArray = [NSMutableArray array];
    
    for (PublicCollectionCell * cell in self.myCollectionView.visibleCells) {
        [appidArray addObject:cell.appID];
        [appdigidArray addObject:cell.appdigitalid];
    }
    [[ReportManage instance] reportAppBaoGuang:SPECIAL_APP([infoDic objectForKey:SPECIAL_ID], (long)-1) appids:appidArray digitalIds:appdigidArray];
}

#pragma mark - 专题详情数据-回调
- (void)specialDetailRequestSuccess:(NSDictionary *)dataDic specialId:(NSString *)specialId isUseCache:(BOOL)isUseCache userData:(id)userData
{
    //检测数据
    if (![[MyVerifyDataValid instance] checkSpecialDetails:dataDic]) {
//        NSLog(@"专题详情数据有误");
        [self specialDetailRequestFailed:specialId isUseCache:isUseCache userData:userData];
        return;
    }
    
    backView.status = Hidden;
    
    NSDictionary *tmpdataDic = [[NSMutableDictionary dictionaryWithDictionary:dataDic] objectForKey:@"data"];
    dataArray = [tmpdataDic objectForKey:@"apps"];
    
    titleView.titile.text = [tmpdataDic getNSStringObjectForKey:TITLE];
    //introTextHeight = [[tmpdataDic objectForKey:INTRODUCE] sizeWithFont:[UIFont systemFontOfSize:textFont] constrainedToSize:CGSizeMake(self.view.bounds.size.width-20, MAXFLOAT)].height;
    //introTextHeight = [[tmpdataDic objectForKey:INTRODUCE] boundingRectWithSize:CGSizeMake(self.view.bounds.size.width-20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:textFont]} context:nil].size.height;
    introTextHeight = 44;
    [self.detailHeadView setIntroTextHeight:introTextHeight];
    self.detailHeadView.contentText = [tmpdataDic objectForKey:INTRODUCE];
    [self.detailHeadView.imageView sd_setImageWithURL:[NSURL URLWithString:[tmpdataDic getNSStringObjectForKey:BANNER]] placeholderImage:[UIImage imageNamed:@"jingxuan_topic"]];
    
    [self viewWillLayoutSubviews];
    
    [self.myCollectionView reloadData];
}

- (void)specialDetailRequestFailed:(NSString *)specialId isUseCache:(BOOL)isUseCache userData:(id)userData
{
    backView.status = Failed;
    
    titleView.titile.text = [infoDic objectForKey:TITLE];
    [titleView.backButton setBackgroundImage:[UIImage imageNamed:@"nav_back"] forState:UIControlStateNormal];
    titleView.titile.textColor = [UIColor blackColor];
    titleView.coverView.alpha = 1;
    
}

#pragma mark - 推详情
- (void)pushToAppDetailViewWithAppInfor:(NSDictionary *)inforDic andSoure:(NSString *)source{
    [detailVC setAppSoure:source];
    [detailVC beginPrepareAppContent:inforDic];
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)dealloc
{
    [[MyServerRequestManager getManager] removeListener:self];
}


@end
