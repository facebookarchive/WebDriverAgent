#if defined(__cplusplus)
#define XCT_EXPORT extern "C"
#else
#define XCT_EXPORT extern
#endif

#if __has_feature(objc_generics)
#define XCT_GENERICS_AVAILABLE 1
#endif

#if __has_feature(nullability)
#define XCT_NULLABLE_AVAILABLE 1
#endif

#if (!defined(__OBJC_GC__) || (defined(__OBJC_GC__) && ! __OBJC_GC__)) && (defined(__OBJC2__) && __OBJC2__) && (!defined (TARGET_OS_WATCH) || (defined(TARGET_OS_WATCH) && ! TARGET_OS_WATCH))
#ifndef XCT_UI_TESTING_AVAILABLE
#define XCT_UI_TESTING_AVAILABLE 1
#endif
#endif

#ifndef XCT_NULLABLE_AVAILABLE
#define XCT_NULLABLE_AVAILABLE 0
#endif

#ifndef XCT_GENERICS_AVAILABLE
#define XCT_GENERICS_AVAILABLE 0
#endif

#ifndef XCT_UI_TESTING_AVAILABLE
#define XCT_UI_TESTING_AVAILABLE 0
#endif

#if TARGET_OS_SIMULATOR
#define XCTEST_SIMULATOR_UNAVAILABLE(_msg) __attribute__((availability(ios,unavailable,message=_msg)))
#else
#define XCTEST_SIMULATOR_UNAVAILABLE(_msg)
#endif