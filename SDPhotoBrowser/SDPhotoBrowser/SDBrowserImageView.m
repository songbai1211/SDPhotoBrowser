//
//  SDBrowserImageView.m
//  SDPhotoBrowser
//
//  Created by aier on 15-2-6.
//  Copyright (c) 2015年 GSD. All rights reserved.
//

#import "SDBrowserImageView.h"
#import "UIImageView+WebCache.h"
#import "SDPhotoBrowserConfig.h"

static const CGFloat kBrowserImageViewWidth = 320;

@implementation SDBrowserImageView
{
    SDWaitingView *_waitingView;
    BOOL _didCheckSize;
    UIScrollView *_scroll;
    UIImageView *_scrollImageView;
    UIScrollView *_zoomingScroolView;
    UIImageView *_zoomingImageView;
    CGFloat _totalScale;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.contentMode = UIViewContentModeScaleAspectFit;
        _totalScale = 1.0;
        
        // 捏合手势缩放图片
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImage:)];
        [self addGestureRecognizer:pinch];
    }
    return self;
}

- (BOOL)isScaled
{
    return  1.0 != _totalScale;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _waitingView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    
    if (self.image.size.height > self.bounds.size.height) {
        if (!_scroll) {
            UIScrollView *scroll = [[UIScrollView alloc] init];
            scroll.backgroundColor = [UIColor whiteColor];
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.image = self.image;
            _scrollImageView = imageView;
            [scroll addSubview:imageView];
            scroll.backgroundColor = SDPhotoBrowserBackgrounColor;
            _scroll = scroll;
            [self addSubview:scroll];
        }
        _scroll.frame = self.bounds;
        _scrollImageView.bounds = CGRectMake(0, 0, kBrowserImageViewWidth, self.image.size.height);
        _scrollImageView.center = CGPointMake(_scroll.frame.size.width * 0.5, _scrollImageView.frame.size.height * 0.5);
        _scroll.contentSize = CGSizeMake(0, self.image.size.height);
        
        
    } else {
        if (_scroll) [_scroll removeFromSuperview]; // 防止旋转时适配的scrollView的影响
    }
    
    
}



- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    _waitingView.progress = progress;

}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    SDWaitingView *waiting = [[SDWaitingView alloc] init];
    waiting.bounds = CGRectMake(0, 0, 100, 100);
    waiting.mode = SDWaitingViewProgressMode;
    _waitingView = waiting;
    [self addSubview:waiting];
    
    
    __weak SDBrowserImageView *imageViewWeak = self;

    [self sd_setImageWithURL:url placeholderImage:placeholder options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
        imageViewWeak.progress = (CGFloat)receivedSize / expectedSize;
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        [imageViewWeak removeWaitingView];
        
        if (error) {
            UILabel *label = [[UILabel alloc] init];
            label.bounds = CGRectMake(0, 0, 160, 30);
            label.center = CGPointMake(imageViewWeak.bounds.size.width * 0.5, imageViewWeak.bounds.size.height * 0.5);
            label.text = @"图片加载失败";
            label.font = [UIFont systemFontOfSize:16];
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
            label.layer.cornerRadius = 5;
            label.clipsToBounds = YES;
            label.textAlignment = NSTextAlignmentCenter;
            [imageViewWeak addSubview:label];
        }
   
    }];
}

- (void)zoomImage:(UIPinchGestureRecognizer *)recognizer
{
    if (!_zoomingScroolView) {
        _zoomingScroolView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _zoomingScroolView.backgroundColor = SDPhotoBrowserBackgrounColor;
        UIImageView *zoomingImageView = [[UIImageView alloc] initWithImage:self.image];
        zoomingImageView.bounds = self.bounds;
        zoomingImageView.contentMode = UIViewContentModeScaleAspectFill;
        _zoomingImageView = zoomingImageView;
        [_zoomingScroolView addSubview:zoomingImageView];
        [self addSubview:_zoomingScroolView];
    }
    CGFloat scale = recognizer.scale;
    CGFloat temp = _totalScale + (scale - 1);
    [self setTotalScale:temp];
    recognizer.scale = 1.0;
}

- (void)setTotalScale:(CGFloat)totalScale
{
    if ((_totalScale < 0.5 && totalScale < _totalScale) || (_totalScale > 2.0 && totalScale > _totalScale)) return; // 最大缩放 2倍,最小0.5倍
    
    _totalScale = totalScale;
    
    _zoomingImageView.transform = CGAffineTransformMakeScale(totalScale, totalScale);
    
    if (totalScale > 1) {
        _zoomingScroolView.contentSize = _zoomingImageView.frame.size;
        _zoomingScroolView.contentInset = UIEdgeInsetsMake(_zoomingImageView.bounds.size.height, _zoomingImageView.bounds.size.width, 0, 0);
    } else {
        _zoomingScroolView.contentSize = _zoomingScroolView.frame.size;
        _zoomingScroolView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _zoomingImageView.center = _zoomingScroolView.center;
    }
}

// 清除缩放
- (void)eliminateScale
{
    [_zoomingScroolView removeFromSuperview];
    _zoomingScroolView = nil;
    _zoomingImageView = nil;
    _totalScale = 1.0;
}

- (void)removeWaitingView
{
    [_waitingView removeFromSuperview];
}


@end
