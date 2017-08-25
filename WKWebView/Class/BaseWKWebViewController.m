//
//  BaseWKWebViewController.m
//  PocketLover
//
//  Created by GiaJiang on 2017/8/14.
//  Copyright © 2017年 Dev. All rights reserved.
//

#import "BaseWKWebViewController.h"
#import <objc/runtime.h>
#import "JSEventHandler.h"
#import "JSEventHandler+Common.h"

// 大多数App需要支持iOS7以上的版本，而WKWebView只在iOS8后才能用，所以需要一个兼容性方案，既iOS7下用UIWebView，iOS8后用WKWebView。这个库提供了这种兼容性方案：https://github.com/wangyangcc/IMYWebView

@interface BaseWKWebViewController ()
<
    WKUIDelegate,
    WKNavigationDelegate
>

/**   */
@property (nonatomic, strong) WKWebView *webView;
/** 所有 addScriptMessageHandler 添加的方法名数组 */
@property (nonatomic, strong) NSMutableArray *scripts;
/** 网址 */
@property (nonatomic, copy) NSString *url;
/** webView 配置类 */
@property (nonatomic, strong) WKWebViewConfiguration *wkConfig;
/** 菊花 */
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndiView;
/** 加载重试提示 */
@property (nonatomic, strong) UILabel *noDataHint;

@end

@implementation BaseWKWebViewController

#pragma mark - 初始化方法
// 添加用户信息
+ (instancetype)instanceWithUserInfoForURL:(NSString *)url {
    NSString *appendString = [[self class] appendUserIdAndSkeyFrom:url];
    return [[[self class]alloc]initWithURL:appendString];
}

+ (instancetype)instanceWithURL:(NSString *)url {
    return [[[self class]alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSString *)url {
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
        self.url = url;
    }
    return self;
}

/** 添加uid和skey */
+ (NSString *)appendUserIdAndSkeyFrom:(NSString *)originUrl {
    
    NSString *userIdStr = @"userID";
    NSString *skey = @"token";
    /*!
     * 1、判断有无参数
     *    无参数 添加uid和skey
     *    有参数 判断添加 uid和skey
     */
    
    NSString *newString = nil;
    
    if ([originUrl rangeOfString:@"?"].location == NSNotFound) { /** 没有问号 */
        newString = [NSString stringWithFormat:@"%@?uid=%@&skey=%@",
                     originUrl,
                     userIdStr,
                     skey];
        return newString;
    }
    
    if ([originUrl hasSuffix:@"&"]){ /** 结尾有& */
        newString = [NSString stringWithFormat:@"%@uid=%@&skey=%@",
                     originUrl,
                     userIdStr,
                     skey];
        return newString;
    }
    
    newString = [NSString stringWithFormat:@"%@&uid=%@&skey=%@",
                 originUrl,
                 userIdStr,
                 skey];
    return newString;
}

#pragma mark - view cycle
- (void)dealloc {
    //    [userContentController addScriptMessageHandler:self  name:script] 前面添加过的方法名要移除掉
    for (NSString *name in self.scripts) {
        [[_webView configuration].userContentController removeScriptMessageHandlerForName:name];
    }
    
    [_webView evaluateJavaScript:[NSString stringWithFormat:@"%@.%@();", JSClassName, JSRemoveCallBackName] completionHandler:^(id _Nullable data, NSError * _Nullable error) {
    }];//删除所有的回调事件
    
    // KVO
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    
    NSLog(@"WKWebViewController 销毁");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.webView];
    [self addScriptMessageName:JsVoidMethod];
    [self addScriptMessageName:JsCallBackMethod];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStyleDone target:self action:@selector(goback)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"前进" style:UIBarButtonItemStyleDone target:self action:@selector(gofarward)];
}

- (void)goback {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (void)gofarward {
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (void)addScriptMessageName:(NSString *)name {
    [self.scripts addObject:name];
    [self registerOCCodeForJS_WithName:name];
}

- (void)registerOCCodeForJS_WithName:(NSString *)name {
    //OC注册供JS调用的方法
    JSEventHandler *hendler = [[JSEventHandler alloc]initWithWebView:self.webView controller:self];
    [[self.webView configuration].userContentController addScriptMessageHandler:hendler name:name];
    
#pragma mark - JS调用 OC eg:
//    function comeBackView() {
//        window.webkit.messageHandlers.closeMe.postMessage(null);
//    }
}

#pragma mark - 动态加载并运行 JS 代码
- (void)registerJSCodeForOC {
    // 图片缩放的js代码
    NSString *js = @"var count = document.images.length;for (var i = 0; i < count; i++) {var image = document.images[i];image.style.width=320;};window.alert('找到' + count + '张图');";
    //javaScriptString是JS方法名，completionHandler是异步回调block
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.noDataHint.userInteractionEnabled = NO;
    self.noDataHint.hidden = YES;
    [self.loadingIndiView startAnimating];
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // 类似 UIWebView 的 －webViewDidFinishLoad:
    [self.loadingIndiView stopAnimating];
    self.noDataHint.hidden = YES;
    self.webView.hidden = NO;
    
//    [self getCookie];
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    // 类似 UIWebView 的- webView:didFailLoadWithError:
    [self.loadingIndiView stopAnimating];
    self.noDataHint.hidden = NO;
    self.noDataHint.userInteractionEnabled = YES;
    self.webView.hidden = YES;
}

// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    // 类似 UIWebView 的 -webView: shouldStartLoadWithRequest: navigationType:
    
    // 意见反馈 交互处理，点击提交后返回设置页
    NSString *requestString = [navigationResponse.response.URL absoluteString];
    if ([requestString containsString:@"gotoSet"]) {
        [webView stopLoading];
        [self.navigationController popViewControllerAnimated:YES];
        decisionHandler(WKNavigationResponsePolicyCancel);
        return;
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated){
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - WKUIDelegate, 处理 WEB 界面的三种提示框
// 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(void (^)())completionHandler {
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告框" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {completionHandler();}]];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认框" message:@"JS调用confirm"preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ completionHandler(YES);}]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {completionHandler(NO);}]];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:prompt message:defaultText preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {completionHandler([[alert.textFields lastObject] text]);}]];
    [self presentViewController:alert animated:YES completion:NULL];
    completionHandler(@"handler");
}

#pragma mark - 添加 Cookie
// UIWebView 会自动去 NSHTTPCookieStorage 中读取 cookie，但是 WKWebView 并不会去读取,因此导致 cookie 丢失以及一系列问题，解决方式就是在 request 中手动帮其添加上。
- (NSString *)readCurrentCookieWithDomain:(NSString *)domainStr{
    NSHTTPCookieStorage*cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableString * cookieString = [[NSMutableString alloc]init];
    for (NSHTTPCookie*cookie in [cookieJar cookies]) {
        [cookieString appendFormat:@"%@=%@;",cookie.name,cookie.value];
    }
    
    //删除最后一个“；”
    [cookieString deleteCharactersInRange:NSMakeRange(cookieString.length - 1, 1)];
    return cookieString;
}

// 取出 Cookie
- (void)getCookie {
    //取出cookie
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    //js函数
    NSString *JSFuncString =
    @"function setCookie(name,value,expires)\
    {\
    var oDate=new Date();\
    oDate.setDate(oDate.getDate()+expires);\
    document.cookie=name+'='+value+';expires='+oDate+';path=/'\
    }\
    function getCookie(name)\
    {\
    var arr = document.cookie.match(new RegExp('(^| )'+name+'=({FNXX==XXFN}*)(;|$)'));\
    if(arr != null) return unescape(arr[2]); return null;\
    }\
    function delCookie(name)\
    {\
    var exp = new Date();\
    exp.setTime(exp.getTime() - 1);\
    var cval=getCookie(name);\
    if(cval!=null) document.cookie= name + '='+cval+';expires='+exp.toGMTString();\
    }";
    
    //拼凑js字符串
    NSMutableString *JSCookieString = JSFuncString.mutableCopy;
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        NSString *excuteJSString = [NSString stringWithFormat:@"setCookie('%@', '%@', 1);", cookie.name, cookie.value];
        [JSCookieString appendString:excuteJSString];
    }
    //执行js
    [self.webView evaluateJavaScript:JSCookieString completionHandler:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]){
        if (object == self.webView) {
            self.title = self.webView.title;
        }else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"estimatedProgress :%.f", self.webView.estimatedProgress);
        // 加载进度
    }
}

#pragma mark - setter and getter
- (NSMutableArray *)scripts {
    if (!_scripts) {
        _scripts = [NSMutableArray array];
    }
    return _scripts;
}

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:self.wkConfig];
        
        self.webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        
        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:self.url];
        NSString *encodedStr = [self.url stringByAddingPercentEncodingWithAllowedCharacters:set];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:encodedStr]];
        //    [request addValue:[self readCurrentCookieWithDomain:self.url] forHTTPHeaderField:@"Cookie"];
        [_webView loadRequest:request];
        
        [_webView addObserver:self
                   forKeyPath:@"title"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        [_webView addObserver:self
                   forKeyPath:@"estimatedProgress"
                      options:NSKeyValueObservingOptionNew
                      context:nil];

    }
    return _webView;
}

- (WKWebViewConfiguration *)wkConfig {
    if (!_wkConfig) {
        _wkConfig = [[WKWebViewConfiguration alloc] init];
        _wkConfig.allowsInlineMediaPlayback = YES;
        _wkConfig.allowsPictureInPictureMediaPlayback = YES;
        _wkConfig.processPool = [[WKProcessPool alloc] init];
        WKUserContentController *jsContentController = [[WKUserContentController alloc]init];
        _wkConfig.userContentController = jsContentController;
        
#pragma mark - 在客户端中加入 JS 代码
        // WKUserScriptInjectionTimeAtDocumentStart : 文档开始加载时注入
        // WKUserScriptInjectionTimeAtDocumentEnd : 加载结束时注入
        {
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"JSEventHandler" ofType:@"js"];
//            NSString *handlerJS = [NSString stringWithContentsOfFile:path encoding:kCFStringEncodingUTF8 error:nil];
//            handlerJS = [handlerJS stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//            WKUserScript *wkUserScript = [[WKUserScript alloc] initWithSource:handlerJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
//            [_wkConfig.userContentController addUserScript:wkUserScript];
        }
    }
    return _wkConfig;
}

- (UIActivityIndicatorView *)loadingIndiView {
    if (_loadingIndiView == nil) {
        _loadingIndiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _loadingIndiView.center = self.webView.center;
        [self.view addSubview:_loadingIndiView];
    }
    return _loadingIndiView;
}

- (UILabel *)noDataHint {
    if (_noDataHint == nil) {
        _noDataHint = [[UILabel alloc] initWithFrame:self.view.bounds];
        _noDataHint.textColor = [UIColor blackColor];
        _noDataHint.textAlignment = NSTextAlignmentCenter;
        _noDataHint.font = [UIFont systemFontOfSize:18];
        _noDataHint.text = @"加载失败，点击重新加载";
        _noDataHint.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleHeight
        | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:_noDataHint];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(reload)];
        [self.webView addGestureRecognizer:tap];
    }
    return _noDataHint;
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
