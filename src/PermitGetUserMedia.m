#import "PermitGetUserMedia.h"
#import <WebKit/WebKit.h>

@interface PermitGetUserMediaUIDelegate : NSObject<WKUIDelegate>

@property id<WKUIDelegate> previousDelegate;

- (instancetype)initWithPreviousDelegate: (id<WKUIDelegate>)previousDelegate;

@end

@implementation PermitGetUserMediaUIDelegate

- (instancetype)
    initWithPreviousDelegate: (id<WKUIDelegate>) previousDelegate
{
    self = [super init];
    if (self) {
        self.previousDelegate = previousDelegate;
    }
    return self;
}

- (void)
                                   webView: (WKWebView *) webView
    requestMediaCapturePermissionForOrigin: (WKSecurityOrigin *) origin
                          initiatedByFrame: (WKFrameInfo *) frame
                                      type: (WKMediaCaptureType) type
                           decisionHandler: (void (^)(WKPermissionDecision decision)) decisionHandler
{
    BOOL isFileOrigin = [origin.protocol isEqualToString:@"file"];
    BOOL isLocalhostOrigin = ([origin.protocol isEqualToString:@"http"] || [origin.protocol isEqualToString:@"https"]) && [origin.host isEqualToString:@"localhost"];
    
    if (isFileOrigin || isLocalhostOrigin) {
        NSLog(@"Supressing media permission request for %@ origin", isFileOrigin ? @"file" : @"localhost");
        decisionHandler(WKPermissionDecisionGrant);
    } else {
        decisionHandler(WKPermissionDecisionPrompt);
    }
}

- (void)
    forwardInvocation: (NSInvocation *) invocation
{
    SEL aSelector = [invocation selector];

    if ([self.previousDelegate respondsToSelector:aSelector]) {
        [invocation invokeWithTarget:self.previousDelegate];
    } else {
        [super forwardInvocation:invocation];
    }
}

@end

@interface PermitGetUserMedia ()

@property PermitGetUserMediaUIDelegate * permitGetUserMediaDelegate;

@end

@implementation PermitGetUserMedia

- (void)
    pluginInitialize
{
    if ([self.webView isKindOfClass:NSClassFromString(@"WKWebView")]) {
        self.permitGetUserMediaDelegate = [[PermitGetUserMediaUIDelegate alloc]
            initWithPreviousDelegate:((WKWebView *)self.webView).UIDelegate];
        [self.webViewEngine updateWithInfo:@{kCDVWebViewEngineWKUIDelegate: self.permitGetUserMediaDelegate}];
    }
}

@end
