//
//  CustomNavigationBar.m
//  browser
//
//  Created by liguiyang on 14-5-27.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "CustomNavigationBar.h"

@implementation CustomNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //2.7版
        UIColor *bgColor = (IOS7)?[UIColor clearColor]:[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1];
        //新春版
//        UIColor *bgColor = (IOS7)?[UIColor clearColor]:NEWYEAR_RED;
        self.backgroundColor = bgColor;
        
        UIImage * image = [UIImage imageNamed:@"nav_back.png"];
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [backBtn setBackgroundImage:image forState:UIControlStateNormal];
        backBtn.frame = CGRectMake(0, 0, image.size.width/2, image.size.height/2);
        [backBtn addTarget:self action:@selector(popView) forControlEvents:UIControlEventTouchUpInside];
        backBtn.hidden = YES;
        
        // titleLabel
        UILabel *titLabel = [[UILabel alloc] init];
        titLabel.font = [UIFont systemFontOfSize:16.0f];
        titLabel.textAlignment = NSTextAlignmentCenter;
        titLabel.backgroundColor = [UIColor clearColor];
        titLabel.userInteractionEnabled = YES;
        
        //新春版
//        titLabel.textColor = [UIColor whiteColor];
        
        // praiseButton
        UIButton *praiseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [LocalImageManager setImageName:@"praise_find.png" complete:^(UIImage *image) {
            [praiseBtn setImage:image forState:UIControlStateNormal];
        }];
        [LocalImageManager setImageName:@"praise_findSelected.png" complete:^(UIImage *image) {
            [praiseBtn setImage:image forState:UIControlStateSelected];
        }];
        praiseBtn.enabled = NO;
        praiseBtn.hidden = YES;
        
        // shareButton
        UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [LocalImageManager setImageName:@"share.png" complete:^(UIImage *image) {
            [shareBtn setImage:image forState:UIControlStateNormal];
        }];
        shareBtn.enabled = NO;
        shareBtn.hidden = YES;
        
        // rightButton
        UIButton *rightTopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [rightTopBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        //15.5
        rightTopBtn.titleLabel.font = [UIFont systemFontOfSize:15.5];
        
        [self addSubview:backBtn];
        [self addSubview:titLabel];
        [self addSubview:praiseBtn];
        [self addSubview:shareBtn];
        [self addSubview:rightTopBtn];
        
        self.backButton = backBtn;
        self.titleLabel = titLabel;
        self.praiseButton = praiseBtn;
        self.shareButton  = shareBtn;
        self.rightTopButton = rightTopBtn;
        
        // set frame
        UIImage *img = [UIImage imageNamed:@"nav_back.png"];
        backItemSize = img.size;
        
        [self setCustomFrame];
    }
    return self;
}

#pragma mark - Utility
-(void)showBackButton:(BOOL)showFlag navigationTitle:(NSString *)title rightButtonType:(RightButtonType)btnType
{ // 导航栏样式
    self.backButton.hidden = !showFlag;
    self.titleLabel.hidden = NO;
    self.praiseButton.hidden = YES;
    self.shareButton.hidden = YES;
    self.rightTopButton.hidden = (btnType==rightButtonType_NONE)?YES:NO;
    
    width_title = 160;
    originX_title = (MainScreen_Width-width_title)*0.5;
    originX_RightTopBtn = MainScreen_Width-70-15;
    
    self.titleLabel.text = title;
    //新春版
//    self.titleLabel.textColor = [UIColor whiteColor];
    [self setCustomFrame];
}

-(void)showNavigationTitleView:(NSString *)title
{
    self.backButton.hidden = YES;
    self.titleLabel.hidden = NO;
    self.praiseButton.hidden = YES;
    self.shareButton.hidden = YES;
    self.rightTopButton.hidden = YES;
    
    self.titleLabel.text = title;
    
    width_title = MainScreen_Width-110;
    self.titleLabel.frame = CGRectMake(0, 0, width_title, self.frame.size.height);
}

-(void)praiseAndShareButtonSelectEnable:(BOOL)flag
{
    self.praiseButton.enabled = flag;
    self.shareButton.enabled  = flag;
}

-(void)popView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(popCurrentViewController)]) {
        [self.delegate popCurrentViewController];
    }
}

-(void)setCustomFrame
{
    CGFloat stateBarHeight = 0;
    CGFloat navHeight = 44;
    self.frame = CGRectMake(0, 0, MainScreen_Width, navHeight+stateBarHeight);
    originX_PraiseBtn = self.frame.size.width-(backItemSize.width*0.5+15)-34*2-17-25;
    
    self.backButton.frame = CGRectMake(15, (self.frame.size.height-backItemSize.height*0.5)*0.5, backItemSize.width*0.5, backItemSize.height*0.5);
    self.titleLabel.frame = CGRectMake(originX_title, stateBarHeight, width_title, navHeight-1);
    self.praiseButton.frame = CGRectMake(originX_PraiseBtn, stateBarHeight+5, 34, 34);
    self.shareButton.frame = CGRectMake(_praiseButton.frame.origin.x+_praiseButton.frame.size.width+17, stateBarHeight+5, 34, 34);
    self.rightTopButton.frame = CGRectMake(MainScreen_Width - 15 - 40, stateBarHeight+5, 40, 34);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
