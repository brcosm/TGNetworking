//
//  TGHTTPClient.m
//  TGNetworking
//
//  Created by Brandon Smith on 6/28/12.
//  Copyright (c) 2012 TokenGnome. All rights reserved.
//

#import "TGHTTPClient.h"

static NSOperationQueue *_sharedQueue;
typedef void (^ResponseHandler)(NSURLResponse *, NSData *, NSError *);

@interface TGHTTPClient(/* Private */)
- (void)enqueueRequest:(NSURLRequest *)request callback:(ResponseHandler)block;
@end

@implementation TGHTTPClient

@synthesize hostName = _hostName;
@synthesize port = _port;

- (id)initWithHostName:(NSString *)hostName port:(NSString *)port {
    self = [super init];
    if (self) {
        if (!_sharedQueue) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{ _sharedQueue = [[NSOperationQueue alloc] init]; });
        }
        _hostName = hostName;
        _port = port;
    }
    return self;
}

- (void)enqueueRequest:(NSURLRequest *)request callback:(ResponseHandler)block {
    [NSURLConnection sendAsynchronousRequest:request queue:_sharedQueue completionHandler:block];
}

- (void)enqueueJSONRequest:(NSURLRequest *)request callback:(JSONResponseHandler)block {
    ResponseHandler responseBlock = ^(NSURLResponse *resp, NSData *data, NSError *err){
        // Check for connection error
        if (err) {
            dispatch_async(dispatch_get_main_queue(), ^{block(nil, err);});
            return;
        }
        // Check response code error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)resp;
        if (httpResp.statusCode != 200) {
            err = [NSError errorWithDomain:NSURLErrorDomain code:httpResp.statusCode userInfo:httpResp.allHeaderFields];
            dispatch_async(dispatch_get_main_queue(), ^{block(nil, err);});
            return;
        }
        // Parse json data
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *e;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&e];
            dispatch_async(dispatch_get_main_queue(), ^{block(json, e);});
        });
    };
    [self enqueueRequest:request callback:responseBlock];
}

- (void)enqueueImageRequest:(NSURLRequest *)request callback:(ImageResponseHandler)block {
    ResponseHandler responseBlock = ^(NSURLResponse *resp, NSData *data, NSError *err){
        // Check for connection error
        if (err) {
            dispatch_async(dispatch_get_main_queue(), ^{block(nil, err);});
            return;
        }
        // Check response code error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)resp;
        if (httpResp.statusCode != 200) {
            err = [NSError errorWithDomain:NSURLErrorDomain code:httpResp.statusCode userInfo:httpResp.allHeaderFields];
            dispatch_async(dispatch_get_main_queue(), ^{block(nil, err);});
            return;
        }
        // Convert data to image
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *e;
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{block(image, e);});
        });
    };
    [self enqueueRequest:request callback:responseBlock];
}

@end
