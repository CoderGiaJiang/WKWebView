//
//  JSEventHandler.m
//  PocketLover
//
//  Created by GiaJiang on 2017/8/17.
//  Copyright © 2017年 Dev. All rights reserved.
//

#import "JSEventHandler.h"
#import "JSEventHandler+Common.h"

@interface JSEventHandler ()
/**   */
@property (nonatomic, strong) WKWebView *webView;

@end

NSString *const JSRemoveCallBackName = @"cleanAllCallBacks";

#pragma mark - 和 WEB 端协议好的字段
// JS 类
NSString *const JSClassName = @"JSEventHandler";
// JS 类 调用 JSCallBackName 的方法名
NSString *const JSCallBackFunctionName = @"callBack";

// optional
NSString *const JSParams = @"params";
NSString *const JSCallBackName = @"callBackName";

@implementation JSEventHandler

- (instancetype)initWithWebView:(WKWebView *)webView controller:(UIViewController *)controller {
    if ([super init]) {
        self.webView = webView;
        self.viewController = controller;
    }
    return self;
}

- (instancetype)initWithWebView:(WKWebView *)webView {
    if ([super init]) {
        self.webView = webView;
    }
    return self;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([message.name isEqualToString:JsVoidMethod]) {
        // 解析 WEB 端传过来的参数， body 可以传字典或者数组，如果需要返回值需要用到字典 传一个字典 {JSParams : 参数 , JSCallBackName: JS 方法名}
        NSArray *params = message.body[JSParams];
        [self interactWitMethodName:JsVoidMethod params:params :nil];
        
    }else if([message.name isEqualToString:JsCallBackMethod]) {
        NSArray *params = message.body[JSParams];
        NSString *callBackName = message.body[JSCallBackName];
        __weak  WKWebView *weakWebView = _webView;
        // 执行 OC 方法，执行回调之后，再调用 JS 的方法
        [self interactWitMethodName:JsCallBackMethod params:params :^(id response) {
            // 调用 JS JSCallBackFunctionName 这个方法, 通过 response 返回参数给 WEB
            NSString *js = [NSString stringWithFormat:@"%@.%@('%@','%@');", JSClassName, JSCallBackFunctionName,callBackName, response];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                    NSLog(@"执行完 JS 方法");
                }];
            });
        }];
    }
}

// 执行本地写好的 OC 方法
- (void)interactWitMethodName:(NSString *)methodName params:(NSArray *)params :(void(^)(id response))callBack{
    // 四种情况：1、有参有回调 2、无参有回调 3、无参无回调 4、有参无回调
    NSMutableArray *paramArray = [NSMutableArray array];
    !params ?: [paramArray addObjectsFromArray:params]; // 添加参数
    !callBack ?: [paramArray addObject:callBack]; // 添加回调
    
    // 拼接参数 冒号
    for (int i = 0; i < paramArray.count; i++) {
        methodName = [methodName stringByAppendingString:@":"];
    }
    
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector withObjects:paramArray];
    }
}

- (id)performSelector:(SEL)aSelector withObjects:(NSArray *)objects {
    NSMethodSignature *signature = [self methodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    
    NSUInteger i = 1;
    
    // 设置参数
    for (id object in objects) {
        id tempObject = object;
        if ([tempObject isKindOfClass:[NSNumber class]]) {
            NSInteger objint = [tempObject integerValue];
            [invocation setArgument:&objint atIndex:++i];
        }
        else {
            [invocation setArgument:&tempObject atIndex:++i];
        }
    }
    // 调用
    [invocation invoke];
    
    // 返回值
    if ([signature methodReturnLength]) {
        id data;
        [invocation getReturnValue:&data];
        return data;
    }
    return nil;
}

@end
