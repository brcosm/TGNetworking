//
//  TGHTTPClient.h
//  TGNetworking
//
//  Created by Brandon Smith on 6/28/12.
//  Copyright (c) 2012 TokenGnome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^JSONResponseHandler)(id, NSError *);
typedef void (^ImageResponseHandler)(UIImage *, NSError *);

@interface TGHTTPClient : NSObject

@property (nonatomic, readonly) NSString *hostName;
@property (nonatomic, readonly) NSString *port;

- (id)initWithHostName:(NSString *)hostName port:(NSString *)port;

- (void)enqueueJSONRequest:(NSURLRequest *)request callback:(JSONResponseHandler)block;

- (void)enqueueImageRequest:(NSURLRequest *)request callback:(ImageResponseHandler)block;

@end
