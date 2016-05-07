# RoutingHTTPServer

Adds a Sinatra-inspired routing API on top of [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer).

Supports iOS 4+ and OS X 10.7+

## Installation

 1. Add [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) to your project
 2. Add the files in the Source directory

## Usage

    http = [[RoutingHTTPServer alloc] init];
    [http setPort:8000];
    [http setDefaultHeader:@"Server" value:@"YourAwesomeApp/1.0"];

    [http handleMethod:@"GET" withPath:@"/hello" block:^(RouteRequest *request, RouteResponse *response) {
        [response setHeader:@"Content-Type" value:@"text/plain"];
        [response respondWithString:@"Hello!"];
    }];

Convenience methods are available for GET/POST/PUT/DELETE:

    [http get:@"/hello/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
        [response setHeader:@"Content-Type" value:@"text/plain"];
        [response respondWithString:[NSString stringWithFormat:@"Hello %@!", [request param:@"name"]]];
    }];

Note that in this example the path is `/hello/:name`, this will match `/hello/world`, `/hello/you`, and so forth. The named parameters in the path are added to the params dictionary in the request object. Query parameters are also included in this dictionary.

Paths can use wildcards:

    [http get:@"/files/*.*" withBlock:^(RouteRequest *request, RouteResponse *response) {
        // The "wildcards" parameter is an NSArray of wildcard matches
    }];

Or your own regular expressions by wrapping the string in braces:

    [http get:@"{^/page/(\\d+)}" withBlock:^(RouteRequest *request, RouteResponse *response) {
        // The "captures" parameter is an NSArray of capture groups
    }];

Routes can also be handled with selectors:

    - (void)setupRoutes {
        [http handleMethod:@"GET" withPath:@"/hello" target:self selector:@selector(handleHelloRequest:withResponse:)];
    }

    - (void)handleHelloRequest:(RouteRequest *)request withResponse:(RouteResponse *)response {
        [response respondWithString:@"Hello!"];
    }

RouteResponses can respond with an NSString or NSData object, a path to a file, or an existing HTTPResponse class. Responses can also be empty as long as a status code or custom header is set. For example, to perform a redirect:

    [http get:@"/old" withBlock:^(RouteRequest *request, RouteResponse *response) {
        [response setStatusCode:302]; // or 301
        [response setHeader:@"Location" value:[self.baseURL stringByAppendingString:@"/new"]];
    }];

The server object was also given a couple of enhancements:

 * Default headers can be set through `setDefaultHeader:value:` or a dictionary passed to `setDefaultHeaders`. This allows you to add things like a Server header.

 * The Connection header is added to every response. You can set it explicitly in your response object if you want to force closing of a keep-alive connection.

 * The dispatch queue on which routes are processed can be changed. By default routes are processed on CocoaHTTPServer's connection queue, changing this to `dispatch_get_main_queue()` will process all routes on the main thread instead. Connection handling still occurs in the background, only the route handlers are impacted.
