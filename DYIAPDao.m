//
//  DYIAPDao.m
//  FirstRoadNetwork
//
//  Created by Zhang Dream on 2019/7/30.
//  Copyright © 2019 DYLY. All rights reserved.
//

#import "DYIAPDao.h"


@implementation DYIAPDao

+ (void)insertOrder:(DYIAPOrder *)order {
    NSMutableArray *orders = [self unarchiveUserActicity];
    if (!orders) {
        orders = [NSMutableArray array];
    }
    BOOL hasOrder = NO;
    NSString *orderId = order.productID;
    for (DYIAPOrder *orderSig in orders) {
        if ([orderId isEqualToString:orderSig.productID]) {
            hasOrder = YES;
            break;
        }
    }
    if (!hasOrder) {
        [orders addObject:order];
        [self archiveUserActicity:orders];
    }
}

+ (NSArray<DYIAPOrder *> *)queryAllOrders {
    NSMutableArray *orders = [self unarchiveUserActicity];
    return orders;
}

+ (void)deleteOrder:(DYIAPOrder *)order {
    NSMutableArray *orders = [self unarchiveUserActicity];
    BOOL hasOrder = NO;
    NSString *orderId = order.productID;
    DYIAPOrder *tempOrder = nil;
    for (DYIAPOrder *orderSig in orders) {
        if ([orderId isEqualToString:orderSig.productID]) {
            hasOrder = YES;
            tempOrder = orderSig;
            break;
        }
    }
    if (hasOrder) {
        [orders removeObject:tempOrder];
        [self archiveUserActicity:orders];
    }
}

+(void)updateSourceWithOrderId:(NSString *)orderId TransactionId:(NSString *)transactionId Receipt:(NSString *)receipt forProductID:(NSString *)productID {
    NSMutableArray *orders = [self unarchiveUserActicity];
    BOOL hasOrder = NO;
    DYIAPOrder *tempOrder = nil;
    for (DYIAPOrder *orderSig in orders) {
        if ([productID isEqualToString:orderSig.productID]) {
            hasOrder = YES;
            orderSig.orderId = orderId;
            orderSig.transactionId = transactionId;
            orderSig.receipt = receipt;
            break;
        }
    }
    if (hasOrder) {
        [self archiveUserActicity:orders];
    }
}

+ (NSMutableArray *)unarchiveUserActicity{
    NSString *appPath = [self cacheActivityDirectory];
    NSString *accountPath = [appPath stringByAppendingPathComponent:[NSString stringWithFormat:@"cacheOrder_%@", [WMKAccountTool instance].account.customerId]];
    NSArray *accont = [NSKeyedUnarchiver unarchiveObjectWithFile:accountPath];
    return [accont mutableCopy];
}

+ (void)archiveUserActicity:(NSArray *)activitys{
    NSString *appPath = [self cacheActivityDirectory];
    NSString *accountPath = [appPath stringByAppendingPathComponent:[NSString stringWithFormat:@"cacheOrder_%@",[WMKAccountTool instance].account.customerId]];
    [NSKeyedArchiver archiveRootObject:activitys toFile:accountPath];
}

+ (NSMutableString *)cacheActivityDirectory{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
                       objectAtIndex:0] stringByAppendingPathComponent:@"com.star.cacheOrder"];
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [path mutableCopy];
}

@end
