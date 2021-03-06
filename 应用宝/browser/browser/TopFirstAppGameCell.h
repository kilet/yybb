//
//  TopFirstAppGameCell.h
//  MyHelper
//
//  Created by 李环宇 on 15-1-5.
//  Copyright (c) 2015年 myHelper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CollectionCells.h"
#import "PublicCollectionCell.h"

@interface TopFirstAppGameCell : UICollectionViewCell
{
UIImageView *lineView1;
UIImageView *lineView2;
}

//属性
@property (nonatomic, retain) NSString *appdigitalid;
@property (nonatomic, retain) NSString *appID;
@property (nonatomic, retain) NSString *plist;
@property (nonatomic, retain) NSString *installtype;

@property (nonatomic, retain) NSDictionary *cellDataDic;
@property (nonatomic , retain) NSString *downLoadSource;//来源

//UI
@property (nonatomic, strong) CollectionViewCellImageView_my * iconImageView;
@property (nonatomic, strong) UILabel * nameLabel;
@property (nonatomic, strong) UILabel * subLabel;
@property (nonatomic, strong) UIImageView * bottomlineView;
@property (nonatomic, strong) UIImageView * backlineView;
@property (nonatomic, strong) UIImageView * bottomImage;
@property (nonatomic, strong) UIImageView * downloadIconImageView;

@property (nonatomic, strong) UILabel * priceLabel;
@property (nonatomic, strong) CollectionViewCellButton_my * downButton;
@property (nonatomic, strong) UILabel * sizeLabel;
@property (nonatomic, strong) UILabel * orderLabel;
@property (nonatomic, strong) UIButton *downLoadBtn;

- (void)firstimageFrame:(CGSize)size;
- (void)setCellData:(NSDictionary *)showCellDic;
- (void)initDownloadButtonState; // 设置按钮状态
@end
