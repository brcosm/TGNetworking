//
//  TGHTTPClient.h
//  TGNetworking
//
//  Created by Brandon Smith on 6/28/12.
//  Copyright (c) 2012 TokenGnome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ResourceResponseHandler)(id, NSError *);

@interface TGHTTPClient : NSObject

@property (nonatomic, readonly) NSString *hostName;
@property (nonatomic, readonly) NSString *port;
@property (nonatomic, assign)   BOOL isSecure;

- (id)initWithHostName:(NSString *)hostName port:(NSString *)port;

- (void)getResourceAtURL:(NSURL *)url callback:(ResourceResponseHandler)block;

- (void)getResourceAtPath:(NSString *)path callback:(ResourceResponseHandler)block;

- (void)postData:(NSData *)data contentType:(NSString *)mimeType toURL:(NSURL *)url callback:(ResourceResponseHandler)block;

@end
