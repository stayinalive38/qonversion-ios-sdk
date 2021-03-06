#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "QNProductCenterManager.h"
#import "QNAPIClient.h"
#import "QNUserDefaultsStorage.h"
#import "QNStoreKitService.h"
#import "QNTestConstants.h"
#import "QNLaunchResult.h"

#import "Helpers/XCTestCase+TestJSON.h"

@interface QNProductCenterManager (Private)

@property (nonatomic) QNStoreKitService *storeKitService;
@property (nonatomic) QNUserDefaultsStorage *persistentStorage;

@property (nonatomic) QNPurchaseCompletionHandler purchasingBlock;

@property (nonatomic, copy) NSMutableArray *permissionsBlocks;
@property (nonatomic, copy) NSMutableArray *productsBlocks;
@property (nonatomic) QNAPIClient *apiClient;

@property (nonatomic) QNLaunchResult *launchResult;
@property (nonatomic) NSError *launchError;

@property (nonatomic, assign) BOOL launchingFinished;
@property (nonatomic, assign) BOOL productsLoaded;

- (void)checkPermissions:(QNPermissionCompletionHandler)result;

@end

@interface ProductCenterManagerTests : XCTestCase

@property (nonatomic) id mockClient;
@property (nonatomic) QNProductCenterManager *manager;

@end

@implementation ProductCenterManagerTests

- (void)setUp {
  _mockClient = OCMClassMock([QNAPIClient class]);
  
  _manager = [[QNProductCenterManager alloc] init];
  [_manager setApiClient:_mockClient];
}

- (void)tearDown {
  _manager = nil;
}

- (void)testThatProductCenterGetLaunchModel {
  XCTestExpectation *expectation = [self expectationWithDescription:@""];
  
  OCMStub([_mockClient launchRequest:([OCMArg invokeBlockWithArgs:[self JSONObjectFromContentsOfFile:keyQNInitFullSuccessJSON], [NSNull null], nil])]);
  
  [_manager launch:^(QNLaunchResult * _Nullable result, NSError * _Nullable error) {
    XCTAssertNotNil(result);
    XCTAssertNil(error);
    XCTAssertEqual(result.permissions.count, 2);
    XCTAssertEqual(result.products.count, 1);
    XCTAssertEqualObjects(result.uid, @"qonversion_user_id");
    
    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:keyQNTestTimeout handler:nil];
}

- (void)testThatCheckPermissionStoreBlocksWhenLaunchingIsActive {
  // Given
  
  // When
  [_manager checkPermissions:^(NSDictionary<NSString *,QNPermission *> * _Nonnull result, NSError * _Nullable error) {
    
  }];
  
  // Then
  XCTAssertEqual(_manager.permissionsBlocks.count, 1);
}

- (void)testThatCheckPermissionCallBlockWhenLaunchingFinished {
  // Given
  _manager.launchingFinished = YES;
  XCTestExpectation *expectation = [self expectationWithDescription:@""];
  
  // When
  [_manager checkPermissions:^(NSDictionary<NSString *,QNPermission *> * _Nonnull result, NSError * _Nullable error) {
    XCTAssertNil(result);
    XCTAssertNil(error);
    XCTAssertEqual([NSThread mainThread], [NSThread currentThread]);
    
    [expectation fulfill];
  }];
  
  // Then
  [self waitForExpectationsWithTimeout:keyQNTestTimeout handler:nil];
}

@end
