//
//  DYIAPDao.h
//  FirstRoadNetwork
//
//  Created by Zhang Dream on 2019/7/30.
//  Copyright © 2019 DYLY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DYIAPOrder.h"

NS_ASSUME_NONNULL_BEGIN

@interface DYIAPDao : NSObject

+ (void)insertOrder:(DYIAPOrder *)order;

+ (NSArray<DYIAPOrder *> *)queryAllOrders;

+ (void)deleteOrder:(DYIAPOrder *)order;

+ (void)updateSourceWithOrderId:(NSString *)orderId TransactionId:(NSString *)transactionId Receipt:(NSString *)receipt forProductID:(NSString *)productID;

@end

NS_ASSUME_NONNULL_END
