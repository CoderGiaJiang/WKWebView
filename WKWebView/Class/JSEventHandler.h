//
//  JSEventHandler.h
//  PocketLover
//
//  Created by GiaJiang on 2017/8/17.
//  Copyright © 2017年 Dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

extern NSString *const JSClassName;
extern NSString *const JSRemoveCallBackName;

@interface JSEventHandler : NSObject
<
    WKScriptMessageHandler
>

/**   */
@property (nonatomic, weak) UIViewController *viewController; // 用于跳转

- (instancetype)initWithWebView:(WKWebView *)webView;
- (instancetype)initWithWebView:(WKWebView *)webView controller:(UIViewController *)controller;

@end
