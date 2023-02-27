//
//  DYIAPOrder.h
//  FirstRoadNetwork
//
//  Created by Zhang Dream on 2019/7/30.
//  Copyright © 2019 DYLY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYIAPOrder : NSObject<NSCoding, NSCopying>

@property (nonatomic, strong) NSString *userID;

@property (nonatomic, strong) NSString *productID;

@property (nonatomic, assign) long totalFee;

@property (nonatomic, strong) NSString *transactionId;

@property (nonatomic, strong) NSString *receipt;

@property (nonatomic, assign) NSInteger objectSource;

@property (nonatomic, copy) NSString *orderId;

@end

NS_ASSUME_NONNULL_END
