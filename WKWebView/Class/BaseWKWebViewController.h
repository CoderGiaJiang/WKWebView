//
//  BaseWKWebViewController.h
//  PocketLover
//
//  Created by GiaJiang on 2017/8/14.
//  Copyright © 2017年 Dev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface BaseWKWebViewController : UIViewController

+ (instancetype)instanceWithURL:(NSString *)url;
+ (instancetype)instanceWithUserInfoForURL:(NSString *)url;

- (WKWebView *)webView;

@end
