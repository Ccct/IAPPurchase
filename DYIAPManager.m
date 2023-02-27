//
//  DYIAPManager.m
//  FirstRoadNetwork
//
//  Created by Zhang Dream on 2019/7/29.
//  Copyright © 2019 DYLY. All rights reserved.
//

#import "DYIAPManager.h"
#import <StoreKit/StoreKit.h>
#import "DYIAPOrder.h"
#import "DYIAPDao.h"

@interface DYIAPManager ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>

@property (nonatomic, copy)   CompleteCallback callback;

@property (nonatomic, strong) SKProduct *product;

@property (nonatomic, strong) DYIAPOrder *order;

@property (nonatomic, copy)   NSString *productID;

@end


@implementation DYIAPManager

+ (DYIAPManager *)sharedInstance {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (void)clear {
    self.callback  = nil;
    self.productID = nil;
    self.product   = nil;
    self.order     = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[AFNetworkReachabilityManager sharedManager] addObserver:self forKeyPath:@"networkReachabilityStatus" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkUnverifiedReceipts) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

#pragma mark - 启动购买流程 1：vip充值   2：路币充值
-(void)startPurchaseWithId:(NSString *)productID callback:(CompleteCallback)callback {
    
    //toast:支付处理中，请勿关闭页面
    
    NSLog(@"-------------- 启动购买流程 ---------------------");
    
    if(productID.length == 0) {
        NSError *error = [NSError errorWithDomain:@"com.dyly.domin"
                                     code:0
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
        !callback ?: callback(error, nil);
        return;
    }
    if ([SKPaymentQueue canMakePayments] == NO) {
        NSError *error = [NSError errorWithDomain:@"com.dyly.domin"
                                             code:0
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"你被禁止应用内付费购买", NSLocalizedDescriptionKey, nil]];
        !callback ?: callback(error, nil);
        return;
    }
    
    _productID = productID;
    self.callback = callback;
    NSSet<NSString *> *productIDSet = [NSSet setWithObject:productID];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIDSet];
    request.delegate = self;
    [request start];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    NSLog(@"-------------- 收到产品反馈消息 ---------------------\n");
    
    NSArray *product = response.products;
    if([product count] == 0){
        [[HUDHelper sharedInstance] syncStopLoading];
        NSError *error = [NSError errorWithDomain:@"com.dyly.domin"
                                             code:0
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
        !_callback ?: _callback(error, nil);
        [self clear];
        NSLog(@"-------------- 购买失败，无商品可购买，请检查苹果内购商品设置 ------------------");
        return;
    }
    
//    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    
    SKProduct *p = nil;
    for (int i = 0; i < product.count; i++) {
        
        SKProduct *pro = product[i];
        
        NSLog(@"请求到商品%d:\n",i);
        NSLog(@"productId:%@\n\n", [pro productIdentifier]);
        NSLog(@"price：%@\n", [pro price]);
        NSLog(@"description:%@\n", [pro description]);
        NSLog(@"localizedTitle:%@\n", [pro localizedTitle]);
        NSLog(@"localizedDescription:%@\n", [pro localizedDescription]);
        
        if([pro.productIdentifier isEqualToString:_productID]){
            p = pro;
            break;
        }
    }
    
    if(!p){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *failError = [NSError errorWithDomain:@"com.dyly.domain"
                                                     code:0
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
            !self.callback ?: self.callback(failError, nil);
            [self clear];
            [[HUDHelper sharedInstance] syncStopLoading];
            NSLog(@"\n-------------- 购买失败，无此productId商品 ------------------\n");
        });
        
        return;
    }
    
    _product = p;
    DYIAPOrder *order = [[DYIAPOrder alloc] init];
    order.productID = _productID;
    order.userID = [WMKAccountTool instance].account.customerId;
    order.objectSource = self.objectSource;
    _order = order;
    
    [DYIAPDao insertOrder:order];
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    
    NSLog(@"\n-------------- 请求生成订单信息接口 ------------------\n");
    
    //请求公司的接口，生成订单信息
    if(1){
        
        self.order.orderId = @"idStr";
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else{
        
        NSLog(@"生成订单信息失败");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[HUDHelper sharedInstance] syncStopLoading];
            NSError *failError = [NSError errorWithDomain:@"com.dyly.domain"
                                                     code:0
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
            !self.callback ?: self.callback(failError, nil);
            [self clear];
        });
    }
}

#pragma mark - SKRequestDelegate
//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
   
    NSError *failError = [NSError errorWithDomain:@"com.dyly.domain"
                                             code:0
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
    !_callback ?: _callback(failError, nil);
    [self clear];
    NSLog(@"------------------错误-----------------:%@", error);
}

- (void)requestDidFinish:(SKRequest *)request{
    NSLog(@"------------反馈信息结束-----------------");
}

#pragma mark - 交易结束处理
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    
    NSLog(@"---------  交易结束 -----------");
    
    NSLog(@"receipt %@",_order.receipt);
    NSLog(@"productID %@",_order.productID);
    NSLog(@"transactionId %@",_order.transactionId);
    NSLog(@"userID %@",_order.userID);
    NSLog(@"objectSource %ld",(long)_order.objectSource);
    NSLog(@"orderId %@",_order.orderId);
    
    NSLog(@"---------  正在发起回调 -----------");
    
    //调公司接口，验证 receipt
    if(1){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //关闭toast
        });
        
        @strongify(self)
        if (obj) {
            
            [DYIAPDao deleteOrder:self.order];
            
            if ([self.product.productIdentifier isEqualToString:transaction.payment.productIdentifier]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    !self.callback ?: self.callback(nil, nil);
                    [self clear];
                });
            }
            
            NSLog(@"---------  回调成功 -----------");
        } else {
            if ([self.product.productIdentifier isEqualToString:transaction.payment.productIdentifier]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    !self.callback ?: self.callback(error, nil);
                    [self clear];
                });
            }
            NSLog(@"---------  回调失败 %@ -----------",error.description);
        }
        
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"---------  交易结束 -----------");
    }
}

#pragma mark - SKPaymentTransactionObserver
//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{
    
    for(SKPaymentTransaction *tran in transaction){
        
        NSLog(@"队列状态变化 %@", tran);
        switch (tran.transactionState) {
                
            case SKPaymentTransactionStatePurchased: {
                
                //要进行验证票据，无网或者其它验证失败的情况，需要存储到本地，等下次再上传
                //取得票据
                NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData *receipt = nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:[receiptUrl path]]) {
                    receipt = [NSData dataWithContentsOfURL:receiptUrl];
                }
                if (!receipt) {
                    //无票据
                    NSError *failError = [NSError errorWithDomain:@"com.dyly.domin"
                                                             code:0
                                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
                    !_callback ?: _callback(failError, nil);
                    [self clear];
                    
                    [[HUDHelper sharedInstance] syncStopLoading];
                    
                    NSLog(@"\n------------- 购买失败，无receipt ------------------\n");
                    
                    return;
                }
                
                //刚启动app时进来的
                if(!_order){
                    NSArray<DYIAPOrder *> * ordersArr = [DYIAPDao queryAllOrders];
                    for (DYIAPOrder *obj in ordersArr) {
                        if([obj.transactionId isEqualToString:tran.transactionIdentifier]){
                            _order = obj;
                        }
                    }
                }else{
                    NSString *encodingReceipt = [receipt base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
                    _order.receipt = encodingReceipt;
                    _order.transactionId = tran.transactionIdentifier;
                    [DYIAPDao updateSourceWithOrderId:self.order.orderId TransactionId:tran.transactionIdentifier Receipt:encodingReceipt forProductID:_order.productID];
                }
                [self completeTransaction:tran];
                NSLog(@"交易完成");
            }
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表(正在购买)");
                break;
            case SKPaymentTransactionStateRestored:{
                NSLog(@"已经购买过商品");
                [[HUDHelper sharedInstance] syncStopLoading];
                [self restoreTransaction:tran];
            }
                break;
            case SKPaymentTransactionStateFailed:{
                NSLog(@"交易失败");
                [[HUDHelper sharedInstance] syncStopLoading];
                [self failedTransaction:tran];
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Action

/// 交易失败处理
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    [DYIAPDao deleteOrder:_order];
    if ([_product.productIdentifier isEqualToString:transaction.payment.productIdentifier]) {
         NSError *failError = [NSError errorWithDomain:@"com.dyly.domin"
                                                 code:0
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"购买失败，请稍后重试", NSLocalizedDescriptionKey, nil]];
        !_callback ?: _callback(failError, nil);
        
        [self clear];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

/// 已经购买过商品 处理 - 非消耗型项目和自动续期订阅类型需要恢复购买
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

/// 添加监听
- (void)addTransactionObserver {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

/// 移除监听
- (void)removeTransactionObserver {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - 检测未完成支付回调的订单
/// 检测未完成支付回调的订单 - 检测时机：app进入前台、app刚启动
- (void)checkUnverifiedReceipts {

    NSLog(@"开始检测未完成支付回调的订单");
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSArray<DYIAPOrder *> *orders = [DYIAPDao queryAllOrders];
        NSLog(@"orders : %@",orders);
        [orders enumerateObjectsUsingBlock:^(DYIAPOrder * _Nonnull order, NSUInteger idx, BOOL * _Nonnull stop) {
            
            //调公司接口，验证Receipt
            if(1){
                [DYIAPDao deleteOrder:obj];
            }
        }];
    });
}

#pragma mark - 网络监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"networkReachabilityStatus"]) {
        AFNetworkReachabilityStatus status = [change[@"new"] integerValue];
        if (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi) {
            [self checkUnverifiedReceipts];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 验证购买，避免越狱软件模拟苹果请求达到非法购买问题
-(void)verifyPurchaseWithPaymentTransaction{
    
    //从沙盒中获取 交易凭证 并且 拼接成请求体数据
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData=[NSData dataWithContentsOfURL:receiptUrl];
    
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];//转化为base64字符串
    
    NSString *bodyString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", receiptString];//拼接请求数据
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    //创建请求到苹果官方进行购买验证
    //sandbox环境
    NSString *verifyUrl = @"https://sandbox.itunes.apple.com/verifyReceipt";
#if DEBUG
    verifyUrl = @"https://sandbox.itunes.apple.com/verifyReceipt";
#else
    //正式环境
    verifyUrl = @"https://buy.itunes.apple.com/verifyReceipt";
#endif
    
    NSURL *url=[NSURL URLWithString:verifyUrl];
    NSMutableURLRequest *requestM=[NSMutableURLRequest requestWithURL:url];
    requestM.HTTPBody = bodyData;
    requestM.HTTPMethod = @"POST";
    //创建连接并发送同步请求
    NSError *error=nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:requestM returningResponse:nil error:&error];
    if (error) {
        NSLog(@"验证购买过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"%@",dic);
    if([dic[@"status"] intValue]==0){
        NSLog(@"购买成功！");
        NSDictionary *dicReceipt= dic[@"receipt"];
        NSDictionary *dicInApp=[dicReceipt[@"in_app"] firstObject];
        NSString *productIdentifier= dicInApp[@"product_id"];//读取产品标识
        //如果是消耗品则记录购买数量，非消耗品则记录是否购买过
        if ([productIdentifier isEqualToString:@"123"]) {
            NSInteger purchasedCount = [[NSNotificationCenter defaultCenter] integerForKey:productIdentifier];//已购买数量
            [[NSNotificationCenter defaultCenter] setInteger:(purchasedCount+1) forKey:productIdentifier];
        }else{
            [[NSNotificationCenter defaultCenter] setBool:YES forKey:productIdentifier];
        }
        //在此处对购买记录进行存储，可以存储到开发商的服务器端
    }else{
        NSLog(@"购买失败，未通过验证！");
    }
}

@end
