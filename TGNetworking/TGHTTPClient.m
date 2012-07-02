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

@implementation TGHTTPClient

@synthesize hostName = _hostName;
@synthesize port = _port;

+ (id)buildObjectWith:(NSData *)data response:(NSHTTPURLResponse *)response {
    NSError *error;
    NSString *mimeType = [response.MIMEType lowercaseString];
    if ([mimeType isEqualToString:@"application/json"]) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        return error ? error : json;
    }
    if ([mimeType hasPrefix:@"text"]) {
        // May want to check response.textEncodingName to determine the encoding
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if ([mimeType hasPrefix:@"image"]) {
        return [UIImage imageWithData:data];
    }
    return data;
}

- (id)initWithHostName:(NSString *)hostName port:(NSString *)port {
    self = [super init];
    if (self) {
        if (!_sharedQueue) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{ _sharedQueue = [[NSOperationQueue alloc] init]; });
            _sharedQueue.maxConcurrentOperationCount = 2;
        }
        _hostName = hostName;
        _port = port;
    }
    return self;
}

- (void)enqueueRequest:(NSURLRequest *)request callback:(ResourceResponseHandler)block {
    // Get a ref to the caller queue for later callback
    dispatch_queue_t callerQueue = dispatch_get_current_queue();
    
    [NSURLConnection sendAsynchronousRequest:request queue:_sharedQueue completionHandler:^(NSURLResponse *resp, NSData *data, NSError *err) {
        
        // Connection error occurred
        if (err) {
            dispatch_async(callerQueue, ^() { block(nil, err); });
            return;
        }
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)resp;
        
        // Check for HTTP Status code issues
        if (httpResp.statusCode != 200 && httpResp.statusCode != 304) {
            NSError *httpErr = [NSError errorWithDomain:NSURLErrorDomain code:httpResp.statusCode userInfo:httpResp.allHeaderFields];
            dispatch_async(callerQueue, ^{block(nil, httpErr);});
            return;
        }
        
        // Parse the header and body to generate appropriate object
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            id obj = [TGHTTPClient buildObjectWith:data response:(NSHTTPURLResponse *)resp];
            [obj isKindOfClass:[NSError class]] ? dispatch_async(callerQueue, ^{ block(nil, obj); }) : dispatch_async(callerQueue, ^{ block(obj, nil); });
        });
        
    }];
}


- (void)getResourceAtURL:(NSURL *)url callback:(ResourceResponseHandler)block {
    // Create the HTTP GET request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [self enqueueRequest:request callback:block];
}

- (void)getResourceAtPath:(NSString *)path callback:(ResourceResponseHandler)block {
    NSURL *requestURL = [NSURL URLWithString:[[NSString stringWithFormat:@"http://%@:%@", self.hostName, self.port] stringByAppendingPathComponent:path]];
    [self getResourceAtURL:requestURL callback:block];
}

- (void)postData:(NSData *)data contentType:(NSString *)mimeType toURL:(NSURL *)url callback:(ResourceResponseHandler)block {
    // Create the HTTP POST request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    [self enqueueRequest:request callback:block];
}

@end
