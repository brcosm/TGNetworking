TGNetworking
============

Static library for simple iOS http networking.  Currently a work in progress as I integrate bits and pieces from all of my apps.  Plan to implement the following:

1. Requests for all HTTP Verbs (GET/POST/PUT/DELETE)
        
		GET - Basic implementation complete
		PUT - Basic implementation complete
		POST - Bastic implementation compelte
		DELETE - Basic implementation complete
		
2. Reachability notification handling

        Requests which fail due to connection are put into a queue and automatically retried whenever the reachability status changes.  TGHTTPClient instances are responsible for their own retry queues.  If the client is not retained, no retries will occurr.
		Requests that fail due to server error execute the block with the appropriate error message.
		
3. Returns the appropriate ObjC type based on the MIME type of the response

        Current implementation will return NSDictionary, NSArray, UIImage, or NSData based on some very simple conditions.

## Adding this library as a submodule

1. cd into your project's repository
2. git add submodule git://github.com/brcosm/TGNetworking.git
3. File > add the .xcodeproj file to your project in Xcode
4. Targets > {Your target} > Build Phases > Target Dependencies > Add 
        
		TGNetworking
		SystemConfiguration
		
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
