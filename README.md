TGNetworking
============

Static library for simple iOS networking

## Adding this library as a submodule

+ cd into your projects repository
+ git add submodule git://github.com/brcosm/TGNetworking.git
+ File > add the .xcodeproj file to your project in Xcode
+ Targets > {Your target} > Build Phases > Target Dependencies > Add TGNetworking
+ Targets > {Your target} > Build Phases > Link Binary With Libraries > Add libTGNetworking.a
+ Targets > {Your target} > Build Settings > Linking > Other Linker Flags > Add
  + -ObjC
  + -all_load
+ Targets > {Your target} > Build Settings > Search Paths > Header Search Paths > Add (including ")
  + "$(TARGET_BUILD_DIR)/usr/local/lib/include"
  + "$(OBJROOT)/UninstalledProducts/include"
+ Import with #import <TGNetworking/TGNetworking.h>

## Usage

``` objective-c
TGHTTPClient *client = [[TGHTTPClient alloc] initWithHostName:@"localhost" port:@"8000"];
[client enqueueJSONRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8000"]] callback:^(id json, NSError *error) {
	if ([json isKindOfClass:[NSDictionary class]]) {
    	for (NSString *key in [json allKeys]) NSLog(@"%@", key);
   	 } else if ([json isKindOfClass:[NSArray class]]) {
     	for (id obj in json) NSLog(@"%@", [obj description]);
   	 } else if (error) {
     	NSLog(@"%@", error.localizedDescription);
     }
 }];
 ```
