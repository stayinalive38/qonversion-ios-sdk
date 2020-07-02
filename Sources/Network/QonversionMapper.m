#import <Foundation/Foundation.h>
#import "QUtils.h"
#import "QonversionMapper.h"
#import "RenewalProductDetails.h"
#import "QonversionCheckResult+Protected.h"
#import "RenewalProductDetails+Protected.h"
#import "QonversionLaunchResult+Protected.h"

NSString * const QonversionErrorDomain = @"com.qonversion.io";

static NSDictionary <NSString *, NSNumber *> *RenewalProductDetailsStatuses = nil;
static NSDictionary <NSString *, NSNumber *> *RenewalProductDetailsStates = nil;
static NSDictionary <NSString *, NSNumber *> *PermissionStates = nil;


@interface QonversionMapperObject : NSObject

@property (nonatomic, nullable) NSDictionary *data;
@property (nonatomic, copy, nullable) NSError *error;

@end

@implementation QonversionMapperObject : NSObject

@end

@implementation QonversionComposeModel : NSObject
@end

@implementation QonversionLaunchComposeModel

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _error = [coder decodeObjectForKey:NSStringFromSelector(@selector(error))];
        _result = [coder decodeObjectForKey:NSStringFromSelector(@selector(result))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_error forKey:NSStringFromSelector(@selector(error))];
    [coder encodeObject:_result forKey:NSStringFromSelector(@selector(result))];
}


- (void)setResult:(QonversionLaunchResult *)result {
    _result = result;
}

@end

@implementation QonversionCheckResultComposeModel : QonversionComposeModel
@end

@implementation QonversionMapper

+ (void)load {
    RenewalProductDetailsStatuses = @{
        @"cancelled": @0,
        @"active": @1,
        @"refunded": @2,
    };
    
    RenewalProductDetailsStates = @{
        @"trial": @0,
        @"subscription": @1,
    };
    
}

- (QonversionCheckResultComposeModel *)composeModelFrom:(NSData *)data {
    QonversionMapperObject *object = [self mapperObjectFrom:data];
    QonversionCheckResultComposeModel *result = [QonversionCheckResultComposeModel new];

    if (object.error == NULL && [object.data isKindOfClass:NSDictionary.class]) {
        QonversionCheckResult *resultObject = [[QonversionMapper new] fillCheckResultWith:object.data];
        [result setResult:resultObject];
        return result;
    } else {
        [result setError:object.error];
        return result;
    }
}

- (QonversionCheckResult *)fillCheckResultWith:(NSDictionary *)dict {
    QonversionCheckResult *result = [[QonversionCheckResult alloc] init];
    
    NSNumber *timestamp = dict[@"timestamp"];
    NSNumber *environment = dict[@"environment"];
    
    NSArray *activeProductsDict = dict[@"active_renew_products"];
    NSArray *allProductsDict = dict[@"all_renewal_products"];
    
    [result setEnvironment:environment.intValue];
    [result setTimestamp:timestamp.intValue];

    id allProducts = [self fillRenewalProducts:allProductsDict];
    id activeProducts = [self fillRenewalProducts:activeProductsDict];

    [result setAllProducts:allProducts];
    [result setActiveProducts:activeProducts];

    return result;
}

- (NSArray<RenewalProductDetails *> *)fillRenewalProducts:(NSArray *)dict {
    NSMutableArray *products = [[NSMutableArray alloc] init];

    for (NSDictionary* itemDict in dict) {
        RenewalProductDetails *item = [self fillRenewalProduct:itemDict];
        if (item) {
            [products addObject:item];
        }
    }

    return [products copy];
}

- (RenewalProductDetails *)fillRenewalProduct:(NSDictionary *)dict {
    RenewalProductDetails *item = [[RenewalProductDetails alloc] init];
    
    NSString *productID = dict[@"product_id"] ?: @"";
    NSString *originalID = dict[@"original_transaction_id"] ?: @"";

    if (!productID || !originalID) {
        return nil;
    }
    
    NSNumber *created = dict[@"created_at"] ?: @0;
    NSNumber *purchased = dict[@"purchased_at"] ?: @0;
    NSNumber *expires = dict[@"expires_at"] ?: @0;
    NSNumber *expired = dict[@"expired"] ?: @0;
    NSNumber *billingRetry = dict[@"billing_retry"] ?: @0;
    
    [item setProductID:productID];
    [item setOriginalTransactionID:originalID];
    [item setCreatedAt:created.intValue];
    [item setPurchasedAt:purchased.intValue];
    [item setExpiresAt:expires.intValue];
    [item setExpired:expired.boolValue];
    [item setBillingRetry:billingRetry.boolValue];
    
    NSString *status = dict[@"status"] ?: @"";
    [item setStatus:(RenewalProductDetailsStatuses[status] ?: @-1).intValue];
    
    NSString *state = dict[@"state"] ?: @"";
    [item setState:(RenewalProductDetailsStates[state] ?: @-1).intValue];
    
    return item;
}

- (QonversionLaunchComposeModel * _Nonnull)composeLaunchModelFrom:(NSData * _Nullable)data {
    QonversionMapperObject *object = [self mapperObjectFrom:data];
    QonversionLaunchComposeModel *result = [QonversionLaunchComposeModel new];

    if (object.error == NULL && [object.data isKindOfClass:NSDictionary.class]) {
        QONVERSION_LOG(@"Qonversion Launch Log Response:\n%@", object.data);
        QonversionLaunchResult *resultObject = [[QonversionMapper new] fillLaunchResult:object.data];
        [result setResult:resultObject];
        return result;
    } else {
        [result setError:object.error];
        return result;
    }
}

- (QonversionLaunchResult * _Nonnull)fillLaunchResult:(NSDictionary *)dict {
    QonversionLaunchResult *result = [[QonversionLaunchResult alloc] init];
    NSDictionary *permissionsDict = dict[@"permissions"] ?: @{};
    NSDictionary *productsDict = dict[@"products"] ?: @{};
    NSDictionary *userProductsDict = dict[@"user_products"] ?: @{};
    
    [result setUid:((NSString *)dict[@"uid"] ?: @"")];
    [result setPermissions:[self fillPermissions:permissionsDict]];
    [result setProducts:[self fillProducts:productsDict]];
    [result setUserProducts:[self fillProducts:userProductsDict]];
    
    return result;
}

- (NSDictionary <NSString *, QonversionPermission *> *)fillPermissions:(NSDictionary *)dict {
    NSMutableDictionary <NSString *, QonversionPermission *> *permissions = [NSMutableDictionary new];
    
    for (NSDictionary* itemDict in dict) {
        QonversionPermission *item = [self fillPermission:itemDict];
        if (item && item.permissionID) {
            permissions[item.permissionID] = item;
        }
    }
    
    return [[NSDictionary alloc] initWithDictionary:permissions];
}

- (NSDictionary <NSString *, QonversionProduct *> *)fillProducts:(NSDictionary *)dict {
    NSMutableDictionary <NSString *, QonversionProduct *> *products = [NSMutableDictionary new];
    
    for (NSDictionary* itemDict in dict) {
        QonversionProduct *item = [self fillProduct:itemDict];
        if (item && item.qonversionID) {
            products[item.qonversionID] = item;
        }
    }
    
    return [[NSDictionary alloc] initWithDictionary:products];
}

- (QonversionPermission * _Nonnull)fillPermission:(NSDictionary *)dict {
    QonversionPermission *result = [[QonversionPermission alloc] init];
    result.permissionID = dict[@"id"];
    result.isActive = ((NSNumber *)dict[@"active"] ?: @0).boolValue;
    result.renewState = ((NSNumber *)dict[@"renew_state"] ?: @0).intValue;
    result.productID = ((NSString *)dict[@"associated_product"] ?: @"");
    
    NSTimeInterval started = ((NSNumber *)dict[@"started_timestamp"] ?: @0).intValue;
    result.startedDate = [[NSDate alloc] initWithTimeIntervalSince1970:started];
    result.expirationDate = nil;
    
    if (dict[@"expiration_timestamp"]) {
        NSTimeInterval expiration = ((NSNumber *)dict[@"expiration_timestamp"] ?: @0).intValue;
        result.expirationDate = [[NSDate alloc] initWithTimeIntervalSince1970:expiration];
    }
    
    return result;
}

- (QonversionProduct * _Nonnull)fillProduct:(NSDictionary *)dict {
    QonversionProduct *result = [[QonversionProduct alloc] init];
    
    result.duration = ((NSNumber *)dict[@"duration"] ?: @0).integerValue;
    result.type = ((NSNumber *)dict[@"type"] ?: @0).integerValue;
    result.qonversionID = ((NSString *)dict[@"id"] ?: @"");
    result.storeID = ((NSString *)dict[@"store_id"] ?: @"");
    
    return result;
}

+ (NSError *)error:(NSString *)message code:(QErrorCode)errorCode  {
    NSDictionary *info = @{NSLocalizedDescriptionKey: NSLocalizedString(message, nil)};
    return [[NSError alloc] initWithDomain:QonversionErrorDomain code:errorCode userInfo:info];
}

- (QonversionMapperObject *)mapperObjectFrom:(NSData *)data {
    QonversionMapperObject *object = [QonversionMapperObject new];
    
    if (!data || ![data isKindOfClass:NSData.class]) {
        [object setError:[QonversionMapper error:@"Could not receive data" code:QErrorCodeFailedReceiveData]];
        return object;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    if (!dict || ![dict respondsToSelector:@selector(valueForKey:)]) {
        [object setError:[QonversionMapper error:@"Could not parse response" code:QErrorCodeFailedParseResponse]];
        return object;
    }
    
    NSNumber *success = dict[@"success"];
    NSDictionary *resultData = dict[@"data"];
    
      if (success.boolValue && resultData) {
          [object setData:resultData];
          return object;
      } else {
          NSString *message = dict[@"data"][@"message"] ?: @"";
          [object setError:[QonversionMapper error:message code:QErrorCodeIncorrectRequest]];
          return object;
      }
}

@end

