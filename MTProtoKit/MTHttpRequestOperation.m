#import "MTHttpRequestOperation.h"

#import "../thirdparty/AFNetworking/AFHTTPSessionManager.h"

#if defined(MtProtoKitDynamicFramework)
#   import <MTProtoKitDynamic/MTDisposable.h>
#   import <MTProtoKitDynamic/MTSignal.h>
#elif defined(MtProtoKitMacFramework)
#   import <MTProtoKitMac/MTDisposable.h>
#   import <MTProtoKitMac/MTSignal.h>
#else
#   import <MTProtoKit/MTDisposable.h>
#   import <MTProtoKit/MTSignal.h>
#endif

@implementation MTHttpRequestOperation

+ (MTSignal *)dataForHttpUrl:(NSURL *)url {
    return [self dataForHttpUrl:url headers:nil];
}

+ (MTSignal *)dataForHttpUrl:(NSURL *)url headers:(NSDictionary *)headers {
    return [[MTSignal alloc] initWithGenerator:^id<MTDisposable>(MTSubscriber *subscriber) {
        
        AFHTTPRequestSerializer * serilization = [[AFHTTPRequestSerializer alloc] init];
        [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, __unused BOOL *stop) {
            [serilization setValue:value forHTTPHeaderField:key];
        }];
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager setRequestSerializer:serilization];


        manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

        
        NSURLSessionDataTask * task = [manager GET: url.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            [subscriber putNext:responseObject];
            [subscriber putCompletion];
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            [subscriber putError:nil];
        }];
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//        [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, __unused BOOL *stop) {
//            [request setValue:value forHTTPHeaderField:key];
//        }];
//        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
//
//        [operation setSuccessCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
//        [operation setFailureCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
//
//        [operation setCompletionBlockWithSuccess:^(__unused NSOperation *operation, __unused id responseObject)
//        {
//            [subscriber putNext:[(AFHTTPRequestOperation *)operation responseData]];
//            [subscriber putCompletion];
//        } failure:^(__unused NSOperation *operation, __unused NSError *error)
//        {
//            [subscriber putError:nil];
//        }];
//
//        [operation start];
//
        __weak NSURLSessionDataTask *weakTask = task;
        
        return [[MTBlockDisposable alloc] initWithBlock:^
        {
            __strong NSURLSessionDataTask *strongTask = weakTask;
            [strongTask cancel];
        }];
    }];
}
@end
