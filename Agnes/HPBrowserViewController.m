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
    UIBarButtonItem *_backBarButtonItem;
    UIBarButtonItem *_forwardBarButtonItem;
    UIBarButtonItem *_shareBarButtonItem;
    UIBarButtonItem *_safariBarButtonItem;
    BOOL _previousToolbarHiddenValue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.navigationController.navigationBar.topItem.title = @"";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemAction:)];

    _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-previous"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(backBarButtonItemAction:)];
    _backBarButtonItem.enabled = NO;
    _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-next"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(forwardBarButtonItemAction:)];
    _forwardBarButtonItem.enabled = NO;
    _safariBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-safari"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(safariBarButtonItemAction:)];
    _shareBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareBarButtonItemAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[_backBarButtonItem, flexibleSpace, _forwardBarButtonItem, flexibleSpace, _shareBarButtonItem, flexibleSpace, _safariBarButtonItem];
    
    //    self.webView.scrollView.delegate = self;
//    _previousOffset = self.webView.scrollView.contentOffset;
//    _canToggleNavigationBar = YES;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _previousToolbarHiddenValue = self.navigationController.toolbarHidden;
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = _previousToolbarHiddenValue;
}

#pragma mark - Public

- (void)setUrl:(NSURL *)url
{
    _url = url;
    self.title = self.url.host;
}

#pragma mark - Actions

- (void)doneBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)backBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.webView goBack];
}

- (void)forwardBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.webView goForward];
}

- (void)safariBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[UIApplication sharedApplication] openURL:self.url];
}

- (void)shareBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    NSArray *activityItems = @[self.url];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
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

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    _backBarButtonItem.enabled = [webView canGoBack];
    _forwardBarButtonItem.enabled = [webView canGoForward];
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
