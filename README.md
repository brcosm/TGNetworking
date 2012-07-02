TGNetworking
============

Static library for simple iOS http networking.  Currently a work in progress as I integrate bits and pieces from all of my apps.  Plan to implement the following:

1. Requests for all HTTP Verbs (GET/POST/PUT/DELETE)
2. Reachability notification handling

## Adding this library as a submodule

1. cd into your projects repository
2. git add submodule git://github.com/brcosm/TGNetworking.git
3. File > add the .xcodeproj file to your project in Xcode
4. Targets > {Your target} > Build Phases > Target Dependencies > Add TGNetworking
5. Targets > {Your target} > Build Phases > Link Binary With Libraries > Add libTGNetworking.a
6. Targets > {Your target} > Build Settings > Linking > Other Linker Flags > Add

        -ObjC
        -all_load
      
7. Targets > {Your target} > Build Settings > Search Paths > Header Search Paths > Add (including ")

        "$(TARGET_BUILD_DIR)/usr/local/lib/include"
        "$(OBJROOT)/UninstalledProducts/include"
        
8. Import with:
 
        #import <TGNetworking/TGNetworking.h>

## Usage

``` objective-c
TGHTTPClient *client = [[TGHTTPClient alloc] initWithHostName:@"localhost" port:@"8000"];
[client getResourceAtPath:@"items.json" callback:^(id obj, NSError *error) {
	if ([obj isKindOfClass:[NSDictionary class]]) {
    	for (NSString *key in [obj allKeys]) NSLog(@"%@", key);
   	 } else if ([obj isKindOfClass:[NSArray class]]) {
     	for (id o in obj) NSLog(@"%@", [o description]);
   	 } else if (error) {
     	NSLog(@"%@", error.localizedDescription);
     }
 }];
 ```
