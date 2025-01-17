
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMADatabaseKeyValueStorageProviding;
@protocol AMADateProviding;
@class AMAIncrementableValueStorage;
@class AMAEnvironmentContainer;
@class AMAExtrasContainer;

@interface AMAReporterStateStorage : NSObject

@property (nonatomic, assign, readonly) BOOL firstEventSent;
@property (nonatomic, assign, readonly) BOOL initEventSent;
@property (nonatomic, assign, readonly) BOOL updateEventSent;
@property (nonatomic, assign, readonly) BOOL referrerEventSent;
@property (nonatomic, assign, readonly) BOOL emptyReferrerEventSent;

@property (nonatomic, strong, readonly) AMAIncrementableValueStorage *sessionIDStorage;
@property (nonatomic, strong, readonly) AMAIncrementableValueStorage *attributionIDStorage;
@property (nonatomic, strong, readonly) AMAIncrementableValueStorage *requestIDStorage;

@property (nonatomic, strong, readonly) AMAEnvironmentContainer *appEnvironment;
@property (nonatomic, strong, readonly) AMAEnvironmentContainer *errorEnvironment;
@property (nullable, nonatomic, strong, readonly) AMAExtrasContainer *extrasContainer;

@property (nonatomic, copy, nullable) NSString *profileID;
@property (nonatomic, assign, readonly) NSUInteger openID;

@property (nonatomic, strong, readonly) NSDate *lastStateSendDate;

@property (nonatomic, strong, readonly) NSDate *lastASATokenSendDate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithStorageProvider:(id<AMADatabaseKeyValueStorageProviding>)storageProvider
                       errorEnvironment:(AMAEnvironmentContainer *)errorEnvironment;
- (instancetype)initWithStorageProvider:(id<AMADatabaseKeyValueStorageProviding>)storageProvider
                       errorEnvironment:(AMAEnvironmentContainer *)errorEnvironment
                           dateProvider:(id<AMADateProviding>)dateProvider;

- (void)restoreState;

- (void)markFirstEventSent;
- (void)markInitEventSent;
- (void)markUpdateEventSent;
- (void)markReferrerEventSent;
- (void)markEmptyReferrerEventSent;

- (void)markStateSentNow;

- (void)markASATokenSentNow;
- (void)incrementOpenID;

@end

NS_ASSUME_NONNULL_END
