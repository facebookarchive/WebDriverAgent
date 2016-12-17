\
#ifndef CBXMacros_h
#define CBXMacros_h

#define CBX_CURRENT_ROUTE_VERSION 1.0
#define CBXVersionedRoute(endpoint, version) [NSString stringWithFormat:@"/%0.1f%@", version, endpoint]
#define CBXRoute(endpoint) CBXVersionedRoute(endpoint, CBX_CURRENT_ROUTE_VERSION)

#define FLOAT_EPSILON 0.0001
#define float_eq(f1, f2) (fabs(f1 - f2) < FLOAT_EPSILON)
#endif
