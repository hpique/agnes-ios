//
//  HPBrowserViewController.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPBrowserViewController.h"

//static const NSTimeInterval HPBrowserNavigationBarDelay = 2;

@interface HPBrowserViewController ()<UIWebViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation HPBrowserViewController {
//    CGPoint _previousOffset;
//    BOOL _canToggleNavigationBar;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.navigationController.navigationBar.topItem.title = @"";
//    self.webView.scrollView.delegate = self;
//    _previousOffset = self.webView.scrollView.contentOffset;
//    _canToggleNavigationBar = YES;

}

#pragma mark - Public

- (void)setUrl:(NSURL *)url
{
    _url = url;
    self.title = self.url.host;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    if (self.navigationController.navigationBarHidden)
//    {
//        [self.navigationController setNavigationBarHidden:NO animated:YES];
//        _canToggleNavigationBar = NO;
//        [self performSelector:@selector(resetNavigationBarToggle) withObject:nil afterDelay:HPBrowserNavigationBarDelay];
//    }
    NSURLRequest *request = webView.request;
    NSURL *url = request.URL;
    if ([url.scheme hasPrefix:@"http"])
    {
        _url = url;
        self.title = self.url.host;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    CGPoint currentOffset = scrollView.contentOffset;
//    if (_canToggleNavigationBar)
//    {
//        if (self.navigationController.navigationBarHidden)
//        {
//            if (_previousOffset.y > currentOffset.y)
//            {
//                _canToggleNavigationBar = NO;
//                [self.navigationController setNavigationBarHidden:NO animated:YES];
//                [self performSelector:@selector(resetNavigationBarToggle) withObject:nil afterDelay:HPBrowserNavigationBarDelay];
//            }
//        }
//        else
//        {
//            CGSize contentSize = self.webView.scrollView.contentSize;
//            if (contentSize.height > self.webView.bounds.size.height)
//            {
//                _canToggleNavigationBar = NO;
//                [self.navigationController setNavigationBarHidden:YES animated:YES];
//                [self performSelector:@selector(resetNavigationBarToggle) withObject:nil afterDelay:HPBrowserNavigationBarDelay];
//            }
//        }
//    }
//    _previousOffset = currentOffset;
}

#pragma mark - Private

//- (void)resetNavigationBarToggle
//{
//    _canToggleNavigationBar = YES;
//}


@end
