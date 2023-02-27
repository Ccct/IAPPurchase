//
//  DYIAPManager.h
//  FirstRoadNetwork
//
//  Created by Zhang Dream on 2019/7/29.
//  Copyright © 2019 DYLY. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompleteCallback)(NSError *error, id result);

NS_ASSUME_NONNULL_BEGIN

@interface DYIAPManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign)NSInteger objectSource;

- (void)addTransactionObserver;

- (void)removeTransactionObserver;

//启动购买流程 1：vip充值   2：路币充值
- (void)startPurchaseWithId:(NSString *)productID callback:(CompleteCallback)callback;

/// 检测未完成支付回调的订单 - 检测时机：app进入前台、app刚启动
- (void)checkUnverifiedReceipts;

@end

NS_ASSUME_NONNULL_END
