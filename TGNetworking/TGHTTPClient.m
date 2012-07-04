//
//  TGHTTPClient.m
//  TGNetworking
//
//  Created by Brandon Smith on 6/28/12.
//  Copyright (c) 2012 TokenGnome. All rights reserved.
//

#import "TGHTTPClient.h"
#import "Reachability.h"

static NSOperationQueue *_sharedQueue;
static Reachability *_reachability;
typedef void (^ResponseHandler)(NSURLResponse *, NSData *, NSError *);

@implementation TGHTTPClient {
    NSMutableArray *queuedRequests;
}

@synthesize hostName = _hostName;
@synthesize port = _port;
@synthesize isSecure;

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
            dispatch_once(&onceToken, ^{ 
                _sharedQueue = [[NSOperationQueue alloc] init]; 
                _sharedQueue.maxConcurrentOperationCount = 2;
            });
        }
        if (!_reachability) {
            static dispatch_once_t reachToken;
            dispatch_once(&reachToken, ^{ 
                _reachability = [Reachability reachabilityForInternetConnection]; 
                [_reachability startNotifier];
            });
        }
        queuedRequests = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(reachabilityChanged) 
                                                     name:kReachabilityChangedNotification 
                                                   object:nil];
        _hostName = hostName;
        _port = port;
        self.isSecure = YES;
    }
    return self;
}

- (void)enqueueRequest:(NSURLRequest *)request callback:(ResourceResponseHandler)block {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    // Get a ref to the caller queue for later callback
    dispatch_queue_t callerQueue = dispatch_get_current_queue();
    
    [NSURLConnection sendAsynchronousRequest:request queue:_sharedQueue completionHandler:^(NSURLResponse *resp, NSData *data, NSError *err) {
        // Probably should have some sort of atomic operation here.  Multiple clients could be mucking with this.
        if (_sharedQueue.operationCount <= 1) [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        // Connection error occurred
        if (err) {
            // Try again once the reachability has changed
            [queuedRequests addObject:[NSDictionary dictionaryWithObjectsAndKeys:request, @"request", [block copy], @"block", nil]];
            return;
        }
        
        // Check for HTTP Status code issues
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)resp;
        if (httpResp.statusCode != 200 && httpResp.statusCode != 304 && httpResp.statusCode != 204) {
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
    NSString *protocol = self.isSecure ? @"https" : @"http";
    NSString *reqStr = [NSString stringWithFormat:@"%@://%@", protocol, self.hostName];
    if (self.port) reqStr = [reqStr stringByAppendingFormat:@":%@", self.port];
    NSURL *requestURL = [NSURL URLWithString:[reqStr stringByAppendingPathComponent:path]];
    [self getResourceAtURL:requestURL callback:block];
}

- (void)postData:(NSData *)data contentType:(NSString *)mimeType toURL:(NSURL *)url callback:(ResourceResponseHandler)block {
    // Create the HTTP POST request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:mimeType forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    [self enqueueRequest:request callback:block];
}

- (void)putData:(NSData *)data contentType:(NSString *)mimeType toURL:(NSURL *)url callback:(ResourceResponseHandler)block {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    [request setValue:mimeType forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    [self enqueueRequest:request callback:block];
}

- (void)deleteResourceAtURL:(NSURL *)url callback:(ResourceResponseHandler)block {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"DELETE"];
    [self enqueueRequest:request callback:block];
}

- (void)reachabilityChanged {
    NSArray *requests = [NSArray arrayWithArray:queuedRequests];
    [queuedRequests removeAllObjects];
    for (NSDictionary *requestInfo in requests) {
        [self enqueueRequest:[requestInfo objectForKey:@"request"] callback:[requestInfo objectForKey:@"block"]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
