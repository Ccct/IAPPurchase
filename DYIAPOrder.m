//
//  DYIAPOrder.m
//  FirstRoadNetwork
//
//  Created by Zhang Dream on 2019/7/30.
//  Copyright © 2019 DYLY. All rights reserved.
//

#import "DYIAPOrder.h"

@implementation DYIAPOrder

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.userID = [aDecoder decodeObjectForKey:@"userID"];
    self.productID = [aDecoder decodeObjectForKey:@"productID"];
    self.totalFee = [aDecoder decodeIntegerForKey:@"totalFee"];
    self.transactionId = [aDecoder decodeObjectForKey:@"transactionId"];
    self.receipt = [aDecoder decodeObjectForKey:@"receipt"];
    self.objectSource = [aDecoder decodeIntegerForKey:@"objectSource"];
    self.orderId = [aDecoder decodeObjectForKey:@"orderId"];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_userID forKey:@"userID"];
    [aCoder encodeObject:_productID forKey:@"productID"];
    [aCoder encodeInteger:_totalFee forKey:@"totalFee"];
    [aCoder encodeObject:_transactionId forKey:@"transactionId"];
    [aCoder encodeObject:_receipt forKey:@"receipt"];
    [aCoder encodeInteger:_objectSource forKey:@"objectSource"];
    [aCoder encodeObject:_orderId forKey:@"orderId"];
}

-(id)copyWithZone:(NSZone *)zone {
    DYIAPOrder *copy = [[DYIAPOrder alloc] init];
    if (copy) {
        copy.userID = [self.userID copyWithZone:zone];
        copy.productID = [self.productID copyWithZone:zone];
        copy.totalFee = self.totalFee;
        copy.transactionId = [self.transactionId copyWithZone:zone];
        copy.receipt = [self.receipt copyWithZone:zone];
        copy.objectSource = self.objectSource;
        copy.orderId = [self.orderId copyWithZone:zone];
    }
    return copy;
}

@end
