//
//  JSEventHandler+Common.m
//  PocketLover
//
//  Created by GiaJiang on 2017/8/17.
//  Copyright © 2017年 Dev. All rights reserved.
//

#import "JSEventHandler+Common.h"

NSString *const JsVoidMethod = @"jsVoidMethod";
NSString *const JsCallBackMethod = @"jsCallBackMethod";

@implementation JSEventHandler (Common)

- (void)jsVoidMethod:(NSString *)firstParam :(NSString *)secondParam {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS调用OC" message:[NSString stringWithFormat:@"firstParam: %@, secondParam %@, 无返回值", firstParam, secondParam] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
    }]];
    [self.viewController presentViewController:alert animated:YES completion:NULL];
}

- (void)jsCallBackMethod:(NSString *)firstParam :(NSString *)secondParam :(void(^)(id response))callBack {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS调用OC" message:[NSString stringWithFormat:@"firstParam: %@, secondParam %@, 有返回值", firstParam, secondParam] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        !callBack ?: callBack(@"返回参数");
    }]];
    [self.viewController presentViewController:alert animated:YES completion:NULL];
    
}


@end
