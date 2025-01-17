#import "AMACore.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaHostState/AppMetricaHostState.h>

#import "AMAAppMetricaImpl.h"

#import "AMAAdServicesDataProvider.h"
#import "AMAAdServicesReportingController.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAAppOpenWatcher.h"
#import "AMAAttributionController.h"
#import "AMAAutoPurchasesWatcher.h"
#import "AMACachingStorageProvider.h"
#import "AMADatabaseKeyValueStorageProviding.h"
#import "AMADeepLinkController.h"
#import "AMADefaultReportExecutionConditionChecker.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMADispatchStrategiesFactory.h"
#import "AMADispatcher.h"
#import "AMADispatcherDelegate.h"
#import "AMADispatchingController.h"
#import "AMAEnvironmentContainer.h"
#import "AMAEnvironmentContainerActionHistory.h"
#import "AMAEnvironmentContainerActionRedoManager.h"
#import "AMAErrorsFactory.h"
#import "AMAEvent.h"
#import "AMAEventBuilder.h"
#import "AMAEventCountDispatchStrategy.h"
#import "AMAEventStorage.h"
#import "AMAExtensionsReportController.h"
#import "AMAExtrasContainer.h"
#import "AMAInstantFeaturesConfiguration.h"
#import "AMAInternalEventsReporter.h"
#import "AMALocationManager.h"
#import "AMAMainReportExecutionConditionChecker.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAPermissionsController.h"
#import "AMAPersistentTimeoutConfiguration.h"
#import "AMAPreactivationActionHistory.h"
#import "AMAReachability.h"
#import "AMAReporter.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAReporterConfiguration.h"
#import "AMAReporterStateStorage.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAReportersContainer.h"
#import "AMASKAdNetworkRequestor.h"
#import "AMASearchAdsController.h"
#import "AMASelfReportExecutionConditionChecker.h"
#import "AMASessionStorage.h"
#import "AMAStartupCompletionObserving.h"
#import "AMAStartupItemsChangedNotifier.h"
#import "AMAStartupStorageProvider.h"
#import "AMATimeoutRequestsController.h"
#import "AMAUserProfileLogger.h"

@interface AMAAppMetricaImpl () <AMADispatcherDelegate,
                                 AMADispatchStrategyDelegate,
                                 AMAHostStateProviderDelegate,
                                 AMAReporterDelegate,
                                 AMAExtendedStartupObservingDelegate>

@property (nonatomic, copy, readwrite) NSString *apiKey;

@property (nonatomic, strong) AMADispatchingController *dispatchingController;
@property (nonatomic, strong) AMAReporter *reporter;
@property (nonatomic, strong) AMAStartupController *startupController;
@property (nonatomic, strong) AMADispatchStrategiesContainer *strategiesContainer;
@property (nonatomic, strong) AMAReportersContainer *reportersContainer;
@property (nonatomic, strong) id<AMAExecuting> executor;
@property (nonatomic, strong) id<AMAHostStateProviding> stateProvider;

@property (nonatomic, strong, readonly) AMAPreactivationActionHistory *preactivationActionHistory;
@property (nonatomic, strong) AMAStartupItemsChangedNotifier *startupItemsNotifier;
@property (nonatomic, strong) AMASearchAdsController *searchAdsController;
@property (nonatomic, strong) AMAAdServicesReportingController *adServicesController;
@property (nonatomic, strong) AMAExtensionsReportController *extensionsReportController;
@property (nonatomic, strong) AMAPermissionsController *permissionsController;
@property (nonatomic, strong, readonly) AMAAppOpenWatcher *appOpenWatcher;
@property (atomic, strong) AMADeepLinkController *deeplinkController;
@property (nonatomic, strong, readonly) AMAAutoPurchasesWatcher *autoPurchasesWatcher;
@property (nonatomic, copy) AMAAppMetricaPreloadInfo *preloadInfo;

@property (nonatomic, strong) NSHashTable *startupCompletionObservers;

@property (nonatomic, strong) NSHashTable *extendedStartupCompletionObservers;
@property (nonatomic, strong) NSHashTable *extendedReporterStorageControllersTable;
@property (nonatomic, strong) NSArray<Class<AMAEventPollingDelegate>> *eventPollingDelegates;

@end

@implementation AMAAppMetricaImpl

- (instancetype)init
{
    id<AMAExecuting> executor = [[AMAAsyncExecutor alloc] initWithIdentifier:self];
    return [self initWithHostStateProvider:nil executor:executor eventPollingDelegates:nil];
}

- (instancetype)initWithHostStateProvider:(id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAExecuting>)executor
                    eventPollingDelegates:(NSArray<Class<AMAEventPollingDelegate>> *)eventPollingDelegates
{
    self = [super init];
    if (self != nil) {
        _stateProvider = hostStateProvider;
        _executor = executor;
        _reportersContainer = [AMAReportersContainer new];
        _strategiesContainer = [AMADispatchStrategiesContainer new];
        _preactivationActionHistory = [[AMAPreactivationActionHistory alloc] init];
        _startupCompletionObservers = [NSHashTable weakObjectsHashTable];
        _extendedStartupCompletionObservers = [NSHashTable weakObjectsHashTable];
        _extendedReporterStorageControllersTable = [NSHashTable weakObjectsHashTable];
        _extensionsReportController = [[AMAExtensionsReportController alloc] init];
        _permissionsController = [[AMAPermissionsController alloc] init];
        _appOpenWatcher = [[AMAAppOpenWatcher alloc] init];
        // auto in app reporting executor should be the same as usual events reporting executor for conversion value flow to work
        _autoPurchasesWatcher = [[AMAAutoPurchasesWatcher alloc] initWithExecutor:executor];

        AMAPersistentTimeoutConfiguration *configuration =
            [AMAMetricaConfiguration sharedInstance].persistent.timeoutConfiguration;
        _dispatchingController = [[AMADispatchingController alloc] initWithTimeoutConfiguration:configuration];
        _dispatchingController.proxyDelegate = self;
        _eventPollingDelegates = eventPollingDelegates;

        [[AMASKAdNetworkRequestor sharedInstance] registerForAdNetworkAttribution];

        [self initializeStartupController];
        [self initializeIdentifierChangedNotifier];
        [self startReachability];
        [self reportExtensionsReportIfNeeded];

        [[AMALocationManager sharedManager] start];
        self.stateProvider.delegate = self;
        [self addStartupCompletionObserver:self.extensionsReportController];
    }
    return self;
}

- (void)execute:(dispatch_block_t)block
{
    [self.executor execute:block];
}

- (void)startReporter
{
    if ([AMAMetricaConfiguration sharedInstance].inMemory.sessionsAutoTracking) {
        [self execute:^{
            [self.reporter start];
        }];
    }
}

- (void)activateWithConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    self.apiKey = configuration.apiKey;

    [self migrate];
    AMAReporter *reporter = [self setupReporterWithConfiguration:configuration];
    self.deeplinkController = [[AMADeepLinkController alloc] initWithReporter:reporter executor:self.executor];
    if (configuration.appOpenTrackingEnabled) {
        [self.appOpenWatcher startWatchingWithDeeplinkController:self.deeplinkController];
    }
    if (configuration.revenueAutoTrackingEnabled) {
        [self.autoPurchasesWatcher startWatchingWithReporter:reporter];
    }
    [self logMetricaStart];
}

- (void)logMetricaStart
{
    NSString *buildType = nil;
#ifdef DEBUG
    buildType = @"Debug";
#else
    buildType = @"Release";
#endif
    NSString *versionName = [AMAPlatformDescription SDKVersionName];
    unsigned long buildNumber = (unsigned long)[AMAPlatformDescription SDKBuildNumber];

    AMALogNotify(@"AppMetrica activated with apiKey:%@ \nVersion:%@, %@ build %lu", self.apiKey, versionName, buildType, buildNumber);
}

- (void)dealloc
{
    AMALogNotify(@"%@ is being deallocated", NSStringFromClass(self.class));
}

- (void)reportEvent:(NSString *)eventName parameters:(NSDictionary *)params onFailure:(void (^)(NSError *))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportEvent:eventName parameters:params onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportEventWithType:(NSUInteger)eventType
                       name:(NSString *)name
                      value:(NSString *)value
                environment:(NSDictionary *)environment
                     extras:(NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(void (^)(NSError *))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportEventWithType:eventType
                                          name:name
                                         value:value
                                   environment:environment
                                        extras:extras
                                     onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportBinaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                          gZipped:(BOOL)gZipped
                      environment:(NSDictionary *)environment
                           extras:(NSDictionary<NSString *,NSData *> *)extras
                        onFailure:(void (^)(NSError *))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportBinaryEventWithType:eventType
                                                data:data
                                             gZipped:gZipped
                                         environment:environment
                                              extras:extras
                                           onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
                    environment:(NSDictionary *)environment
                         extras:(NSDictionary<NSString *,NSData *> *)extras
                      onFailure:(void (^)(NSError *))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportFileEventWithType:eventType
                                              data:data
                                          fileName:fileName
                                           gZipped:gZipped
                                         encrypted:encrypted
                                         truncated:truncated
                                       environment:environment
                                            extras:extras
                                         onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportEventWithParameters:(AMACustomEventParameters *)parameters
                        onFailure:(nullable void (^)(NSError *error))onFailure
{
    
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportEventWithParameters:parameters onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportEventWithBlock:(dispatch_block_t)reportEvent
                   onFailure:(nullable void (^)(NSError *error))onFailure
{
    if (self.reporter == nil) {
        [AMAFailureDispatcher dispatchError:[AMAErrorsFactory reporterNotReadyError] withBlock:onFailure];
    }
    else {
        if (reportEvent != nil) {
            reportEvent();
        }
    }
}

- (void)reportUserProfile:(AMAUserProfile *)userProfile onFailure:(void (^)(NSError *error))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportUserProfile:userProfile onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportRevenue:(AMARevenueInfo *)revenueInfo onFailure:(void (^)(NSError *error))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportRevenue:revenueInfo onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportECommerce:(AMAECommerce *)eCommerce onFailure:(void (^)(NSError *))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportECommerce:eCommerce onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

- (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenueInfo onFailure:(void (^)(NSError *error))onFailure
{
    [self execute:^{
        [self reportEventWithBlock:^{
            [self.reporter reportAdRevenue:adRevenueInfo onFailure:onFailure];
        } onFailure:onFailure];
    }];
}

#if !TARGET_OS_TV
- (void)setupWebViewReporting:(id<AMAJSControlling>)controller
{
    [controller setUpWebViewReporting:self.executor withReporter:self.reporter];
}
#endif

- (void)setUserProfileID:(NSString *)userProfileID
{
    [self execute:^{
        if (self.reporter != nil) {
            [self.reporter setUserProfileID:userProfileID];
        } else {
            self.preactivationActionHistory.userProfileID = userProfileID.copy;
        }
    }];
}

- (void)sendEventsBuffer
{
    [self execute:^{
        [self.reporter sendEventsBuffer];
    }];
}

- (void)pauseSession
{
    [self execute:^{
        [self.reporter pauseSession];
    }];
}

- (void)resumeSession
{
    [self execute:^{
        [self.reporter resumeSession];
    }];
}

- (void)sendEventsBufferWithApiKey:(NSString *)apiKey
{
    [self.dispatchingController performReportForApiKey:apiKey forced:YES];
}

- (AMAReporter *)reporterForConfiguration:(AMAReporterConfiguration *)configuration
{
    @synchronized(self) {
        AMAReporter *reporter = [self.reportersContainer reporterForApiKey:configuration.apiKey];
        if (reporter == nil) {
            AMAReporterStorage *reporterStorage =
                [[AMAReporterStoragesContainer sharedInstance] storageForApiKey:configuration.apiKey];
            reporter = [self createReporterWithStorage:reporterStorage
                                                  main:NO
                                     onStorageRestored:^(AMAEventBuilder *eventBuilder) {
                                         [self applyUserProfileIDWithStorage:reporterStorage
                                                               userProfileID:configuration.userProfileID];
                                     }
                                       onSetupComplete:nil];
        }
        return reporter;
    }
}

- (AMAReporter *)createReporterWithStorage:(AMAReporterStorage *)reporterStorage
                                      main:(BOOL)main
                         onStorageRestored:(void (^)(AMAEventBuilder *eventBuilder))onStorageRestored
                           onSetupComplete:(dispatch_block_t)onSetupComplete
{
    NSString *apiKey = reporterStorage.apiKey;

    AMAEventBuilder *eventBuilder = [self eventBuilderForAPIKey:apiKey
                                           reporterStateStorage:reporterStorage.stateStorage];
    AMAReporter *reporter = [self createReporterWithApiKey:apiKey
                                                      main:main
                                              eventBuilder:eventBuilder
                                           reporterStorage:reporterStorage
                                          internalReporter:[AMAAppMetrica sharedInternalEventsReporter]];
    reporter.delegate = self;

    __weak __typeof(self) weakSelf = self;
    [reporter setupWithOnStorageRestored:^ {
        if (onStorageRestored != nil) {
            onStorageRestored(eventBuilder);
        }
    } onSetupComplete:^{
        [weakSelf postSetupReporterWithStorage:reporterStorage
                                          main:main
                     executionConditionChecker:[self getExecutionConditionCheckerForApiKey:apiKey main:main]
        ];
        if (onSetupComplete != nil) {
            onSetupComplete();
        }
    }];
    
    [reporter reportFirstEventIfNeeded];

    [self.reportersContainer setReporter:reporter forApiKey:apiKey];
    return reporter;
}
// NOTE: Before you think of 'improving' this, it's overridden by AMAAppMetricaImplStub for tests. Best of luck.
- (AMAReporter *)createReporterWithApiKey:(NSString *)apiKey
                                     main:(BOOL)main
                             eventBuilder:(AMAEventBuilder *)eventBuilder
                          reporterStorage:(AMAReporterStorage *)reporterStorage
                         internalReporter:(AMAInternalEventsReporter *)internalReporter
{
    return [[AMAReporter alloc] initWithApiKey:apiKey
                                          main:main
                               reporterStorage:reporterStorage
                                  eventBuilder:eventBuilder
                              internalReporter:internalReporter
                      attributionCheckExecutor:self.executor];
}

- (void)postSetupReporterWithStorage:(AMAReporterStorage *)reporterStorage
                                main:(BOOL)main
           executionConditionChecker:(id<AMAReportExecutionConditionChecker>)executionConditionChecker
{
    NSString *apiKey = reporterStorage.apiKey;

    [self.dispatchingController registerDispatcherWithReporterStorage:reporterStorage main:main];

    AMADispatchStrategyMask typeMask =
        (AMADispatchStrategyMask) [AMADispatchStrategiesFactory allStrategiesTypesMask];
    NSArray *strategies = [AMADispatchStrategiesFactory strategiesForStorage:reporterStorage
                                                                    typeMask:typeMask
                                                                    delegate:self
                                                   executionConditionChecker:executionConditionChecker];
    [self updateStrategiesContainer:strategies];
    
    id<AMAKeyValueStorageProviding> reporterStorageProvider = (id<AMAKeyValueStorageProviding>)reporterStorage.keyValueStorageProvider;
    [self setupReporterWithExtendedReporterStorage:reporterStorageProvider main:main apiKey:apiKey];
}

- (void)updateStrategiesContainer:(NSArray *)strategies
{
    [self.strategiesContainer addStrategies:strategies];
    [self.strategiesContainer startStrategies:strategies];
}

- (AMAEventBuilder *)eventBuilderForAPIKey:(NSString *)apiKey
                      reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage
{
    AMAAppMetricaPreloadInfo *info = nil;
    if ([apiKey isEqual:self.apiKey]) {
        info = self.preloadInfo;
    }
    return [[AMAEventBuilder alloc] initWithStateStorage:reporterStateStorage preloadInfo:info];
}

- (id<AMAAppMetricaExtendedReporting>)manualReporterForConfiguration:(AMAReporterConfiguration *)configuration
{
    return [self reporterForConfiguration:configuration];
}

- (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey
{
    @synchronized (self) {
        return [self.reportersContainer reporterForApiKey:apiKey] != nil;
    }
}

- (void)setPreloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
{
    _preloadInfo = preloadInfo;

    if (preloadInfo != nil) {
        AMALogInfo(@"Set custom preload info %@", preloadInfo);
    }
}

- (id<AMAReportExecutionConditionChecker>)getExecutionConditionCheckerForApiKey:(NSString *)apiKey main:(BOOL)main
{
    if (main) {
        return [[AMAMainReportExecutionConditionChecker alloc] init];
    }
    else if ([apiKey isEqualToString:kAMAMetricaLibraryApiKey]) {
        return [[AMASelfReportExecutionConditionChecker alloc] init];
    }
    else {
        return [[AMADefaultReportExecutionConditionChecker alloc] init];
    }
}

#pragma mark - Working with Notifications

- (void)hostStateDidChange:(AMAHostAppState)hostState
{
    AMALogInfo(@"State changed to %d", (int)hostState);
    switch (hostState) {
        case AMAHostAppStateForeground:
            [self start];
            break;

        case AMAHostAppStateBackground:
            [self shutdown];
            break;

        case AMAHostAppStateTerminated:
            [self terminate];
            break;

        case AMAHostAppStateUnknown:
        default:
            break;
    }
}

- (void)initializeIdentifierChangedNotifier
{
    [self execute:^{
        self.startupItemsNotifier = [[AMAStartupItemsChangedNotifier alloc] init];
        [self addStartupCompletionObserver:self.startupItemsNotifier];
    }];
}

- (void)triggerSearchAdsRequest
{
    [self execute:^{
        [self.searchAdsController trigger];
    }];
}

- (void)triggerASATokenReporting
{
    [self execute:^{
        [self.adServicesController reportTokenIfNeeded];
    }];
}

- (void)reportExtensionsReportIfNeeded
{
    [self execute:^{
        [self.extensionsReportController reportIfNeeded];
    }];
}

- (void)reportPermissionsIfNeeded
{
    [self execute:^{
        NSString *permissionsJSON = [self.permissionsController updateIfNeeded];
        if (permissionsJSON != nil) {
            [self.reporter reportPermissionsEventWithPermissions:permissionsJSON onFailure:^(NSError *error) {
                AMALogError(@"Can't send permissions: %@", permissionsJSON);
            }];
        }
    }];
}

- (void)initializeStartupController
{
    [self execute:^{
        AMAPersistentTimeoutConfiguration *configuration = nil;
        AMATimeoutRequestsController *timeoutController = nil;

        configuration = [AMAMetricaConfiguration sharedInstance].persistent.timeoutConfiguration;
        timeoutController = [[AMATimeoutRequestsController alloc] initWithHostType:AMAStartupHostType
                                                                     configuration:configuration];
        self.startupController =
            [[AMAStartupController alloc] initWithTimeoutRequestsController:timeoutController];
        self.startupController.delegate = self;
        self.startupController.extendedDelegate = self;
    }];
}

// TODO: Observe configuration changes instead of calling this method on every configuration change
- (void)handleConfigurationUpdate
{
    [self execute:^{
        [self.strategiesContainer handleConfigurationUpdate];
    }];
}

- (void)reportDatabaseInconsistencyStateIfNeeded
{
    [self execute:^{
        NSString *inconsistencyDescription = [[AMAMetricaConfiguration sharedInstance] detectedInconsistencyDescription];
        if (inconsistencyDescription.length > 0) {
            AMAInternalEventsReporter *reporter = [AMAAppMetrica sharedInternalEventsReporter];
            [reporter reportSchemaInconsistencyWithDescription:inconsistencyDescription];
            [[AMAMetricaConfiguration sharedInstance] resetDetectedInconsistencyDescription];
        }
    }];
}

- (void)start
{
    [self startReporter];
    [self startReachability];
    [self startDispatcher];
    [self startStrategies];
    [self startLocationManager];
    [self reportDatabaseInconsistencyStateIfNeeded];
    [self notifyOnStartupCompleted];
    [self triggerSearchAdsRequest];
    [self reportPermissionsIfNeeded];
}

- (void)shutdown
{
    [self shutdownStrategies];
    [self shutdownDispatcher];
    [self shutdownReporter];
    [self shutdownReachability];
}

- (void)terminate
{
}

#pragma mark - start working

- (AMAReporter *)setupReporterWithConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    @synchronized (self) {
        AMAReporter *reporter = self.reporter;
        if (reporter != nil) {
            AMALogAssert(@"Reporter setup is expected to be called only once");
            return reporter;
        }

        reporter = [self.reportersContainer reporterForApiKey:self.apiKey];
        if (reporter != nil) {
            AMALogAssert(@"Synchronization error in AppMetrica class. "
                                 "Main reporter can't have other reporters' API key.");
            self.reporter = reporter;
            return reporter;
        }

        AMAReporterStorage *reporterStorage =
            [[AMAReporterStoragesContainer sharedInstance] storageForApiKey:self.apiKey];
        __weak __typeof(self) weakSelf = self;
        reporter = [self createReporterWithStorage:reporterStorage
                                              main:YES
                                 onStorageRestored:^(AMAEventBuilder *eventBuilder){
            // called on reporter.executor queue
            [weakSelf applyDeferedAppEnvironmentUpdatesWithStorage:reporterStorage];
            [weakSelf applyEventsFromPollingDelegatesWithStorage:reporterStorage eventBuilder:eventBuilder];
            [weakSelf applyUserProfileIDWithStorage:reporterStorage
                                      userProfileID:[self mergeUserProfileIDs:configuration.userProfileID]];
        } onSetupComplete:^{
            [weakSelf postSetupMainReporterWithStorage:reporterStorage];
        }];

        [self execute:^{
            self.reporter = reporter;
            [AMAAttributionController sharedInstance].mainReporter = reporter;
            [self triggerSessionStartIfNeeded];
        }];
        return reporter;
    }
}
// FIXME: (glinnik) manupulating storage in impl. Logic similar to Reporter. Move there later
- (void)applyEventsFromPollingDelegatesWithStorage:(AMAReporterStorage *)reporterStorage
                                      eventBuilder:(AMAEventBuilder *)eventBuilder;

{
    NSArray<AMAEvent *> *events = [AMACollectionUtilities flatMapArray:self.eventPollingDelegates
                                                             withBlock:^NSArray *(Class<AMAEventPollingDelegate> delegate) {
        return [AMACollectionUtilities mapArray:[delegate eventsForPreviousSession]
                                      withBlock:^id(AMACustomEventParameters *params) {
            return [eventBuilder eventWithInternalParameters:params error:NULL];
        }];
    }];
    
    if (events.count > 0) {
        AMASession *session = [reporterStorage.sessionStorage lastSessionWithError:NULL];
        if (session != nil) {
            for (AMAEvent *event in events) {
                event.sessionOid = session.oid;
                [reporterStorage.eventStorage addEvent:event toSession:session error:NULL];
            }
        }
    }
}

- (void)applyDeferedAppEnvironmentUpdatesWithStorage:(AMAReporterStorage *)reporterStorage
{
    @synchronized (self) {
        AMAEnvironmentContainerActionRedoManager *manager = [AMAEnvironmentContainerActionRedoManager new];
        [manager redoHistory:self.preactivationActionHistory.appEnvironment
                 inContainer:reporterStorage.stateStorage.appEnvironment];
        self.preactivationActionHistory.appEnvironment = nil;
    }
}

- (NSString *)mergeUserProfileIDs:(NSString *)fromConfiguration
{
    NSString *userProfileID = nil;
    if (fromConfiguration != nil) {
        userProfileID = fromConfiguration.copy;
    } else if (self.preactivationActionHistory.userProfileID != nil) {
        userProfileID = self.preactivationActionHistory.userProfileID.copy;
    }
    self.preactivationActionHistory.userProfileID = nil;
    return userProfileID;
}

- (void)applyUserProfileIDWithStorage:(AMAReporterStorage *)storage
                        userProfileID:(NSString *)userProfileID
{

    if (userProfileID != nil) {
        NSString *truncatedProfileID =
            [[AMATruncatorsFactory profileIDTruncator] truncatedString:userProfileID
                                                          onTruncation:^(NSUInteger bytesTruncated) {
                                                              [AMAUserProfileLogger logProfileIDTooLong:userProfileID];
                                                          }];
        storage.stateStorage.profileID = truncatedProfileID;
    }
}

- (void)postSetupMainReporterWithStorage:(AMAReporterStorage *)reporterStorage
{
    self.searchAdsController = [[AMASearchAdsController alloc] initWithApiKey:self.apiKey
                                                                     executor:self.executor
                                                         reporterStateStorage:reporterStorage.stateStorage];
    [self triggerSearchAdsRequest];

    if (@available(iOS 14.3, *)) {
        self.adServicesController = [[AMAAdServicesReportingController alloc] initWithApiKey:self.apiKey
                                                                        reporterStateStorage:reporterStorage.stateStorage];
        [self triggerASATokenReporting];
    }
}

- (void)triggerSessionStartIfNeeded
{
    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
    BOOL shouldStartSession =
        ([self.stateProvider hostState] == AMAHostAppStateForeground && configuration.inMemory.sessionsAutoTracking)
        || configuration.inMemory.handleActivationAsSessionStart;
    if (shouldStartSession) {
        [self.reporter start];
    }
}

- (void)startReachability
{
    [self execute:^{
        [[AMAReachability sharedInstance] start];
    }];
}

- (void)startDispatcher
{
    [self execute:^{
        [self.dispatchingController start];
    }];
}

- (void)startLocationManager
{
    [self execute:^{
        [[AMALocationManager sharedManager] updateAuthorizationStatus];
    }];
}

- (void)startStrategies
{
    [self execute:^{
        [self.strategiesContainer dispatchMoreIfNeeded];
    }];
}

- (void)shutdownReachability
{
    [self execute:^{
        [[AMAReachability sharedInstance] shutdown];
    }];
}

- (void)shutdownDispatcher
{
    [self execute:^{
        [self.dispatchingController shutdown];
    }];
}

- (void)shutdownReporter
{
    if ([AMAMetricaConfiguration sharedInstance].inMemory.sessionsAutoTracking) {
        [self execute:^{
            [self.reporter shutdown];
        }];
    }
}

- (void)shutdownStrategies
{
    [self execute:^{
        [self.strategiesContainer shutdown];
    }];
}

- (void)migrate
{
    [self execute:^{
        [[AMAMetricaConfiguration sharedInstance] handleMainApiKey:self.apiKey];
    }];
}

#pragma mark - AMADispatchStrategyDelegate Implementation

- (void)dispatchStrategyWantsReportingToHappen:(AMADispatchStrategy *)strategy
{
    [self execute:^{
        NSString *apiKey = strategy.storage.apiKey;
        AMALogInfo(@"Dispatch strategy %@ wants to report to apiKey %@", strategy, apiKey);
        if ([strategy canBeExecuted:self.startupController]) {
            [self.dispatchingController performReportForApiKey:apiKey forced:NO];
        }
    }];
}

#pragma mark - AMADispatcherDelegate

- (void)dispatcherDidPerformReport:(AMADispatcher *)dispatcher
{
    AMALogInfo(@"Report finished. Will send more if needed.");
    [self execute:^{
        [self.strategiesContainer dispatchMoreIfNeededForApiKey:dispatcher.apiKey];
    }];
}

- (void)dispatcher:(AMADispatcher *)dispatcher didFailToReportWithError:(NSError *)error
{
    AMALogInfo(@"Report failed with error: %@", error);
    [self execute:^{
        if (error.code == AMADispatcherReportErrorNoHosts || error.code == AMADispatcherReportErrorNoDeviceId) {
            NSString *apiKey = error.userInfo[kAMADispatcherErrorApiKeyUserInfoKey];
            if ([apiKey isEqualToString:kAMAMetricaLibraryApiKey] == NO) {
                [self.startupController update];
            }
        }
    }];
}

#pragma mark - AMAStartupControllerDelegate -

- (void)startupControllerDidFinishWithSuccess:(AMAStartupController *)controller
{
    AMALogInfo(@"Startup finished with success");
    [self notifyOnStartupCompleted];

    [self execute:^{
        [[AMALocationManager sharedManager] updateLocationManagerForCurrentStatus];
        [self.strategiesContainer dispatchMoreIfNeeded];
        [self reportPermissionsIfNeeded];
    }];
}

- (void)startupController:(AMAStartupController *)controller didFailWithError:(NSError *)error
{
    AMALogInfo(@"Startup failed with error: %@", error);
    [self notifyOnStartupFailedWithError:error];
}

#pragma mark - AMAExtendedStartupObservingDelegate -

- (void)startupUpdatedWithResponse:(NSDictionary *)response
{
    [self notifyOnAdditionalStartupCompleted:response];
}

#pragma mark - Startup observing -

- (void)notifyOnStartupCompleted
{
    [self execute:^{
        if (self.startupController.upToDate) {
            AMALogInfo(@"Notify about startup %lu observers",
                       (unsigned long)self.startupCompletionObservers.count);
            for (id<AMAStartupCompletionObserving> observer in self.startupCompletionObservers) {
                [observer startupUpdateCompletedWithConfiguration:[AMAMetricaConfiguration sharedInstance].startup];
            }
        }
    }];
}

- (void)notifyOnStartupFailedWithError:(NSError *)error
{
    [self execute:^{
        AMALogInfo(@"Notify about startup error %lu observers",
                           (unsigned long)self.startupCompletionObservers.count);
        for (id<AMAStartupCompletionObserving> delegate in self.startupCompletionObservers) {
            if ([delegate respondsToSelector:@selector(startupUpdateFailedWithError:)]) {
                [delegate startupUpdateFailedWithError:error];
            }
        }
    }];
}

- (void)notifyOnAdditionalStartupCompleted:(NSDictionary *)response
{
    [self execute:^{
        if (self.startupController.upToDate) {
            AMALogInfo(@"Notify about extended startup %lu observers",
                       (unsigned long)self.extendedStartupCompletionObservers.count);
            for (id<AMAExtendedStartupObserving> observer in self.extendedStartupCompletionObservers) {
                [observer startupUpdatedWithParameters:response];
            }
        }
    }];
}

- (void)setExtendedStartupObservers:(NSSet<id<AMAExtendedStartupObserving>> *)observers
{
    AMALogInfo(@"Setup extended startup observers: %@", observers);
    [self execute:^{
        if (observers != nil) {
            for (id<AMAExtendedStartupObserving> observer in observers) {
                [self.extendedStartupCompletionObservers addObject:observer];
                
                AMAStartupStorageProvider *startupStorageProvider = [[AMAStartupStorageProvider alloc] init];
                AMACachingStorageProvider *cachingStorageProvider = [[AMACachingStorageProvider alloc] init];
                [observer setupStartupProvider:startupStorageProvider
                        cachingStorageProvider:cachingStorageProvider];
                
                [self addAdditionalStartupParameters:observer.startupParameters];
            }
        }
    }];
}

- (void)addAdditionalStartupParameters:(NSDictionary *)parameters
{
    NSArray *hosts = parameters[@"hosts"];
    if (hosts != nil && [hosts isKindOfClass:NSArray.class]) {
        hosts = [AMACollectionUtilities filteredArray:hosts
                                        withPredicate:^BOOL(id  _Nonnull item) {
            return [item isKindOfClass:NSString.class] && [item length] > 0;
        }];
        [[AMAMetricaConfiguration sharedInstance].inMemory addAdditionalStartupHosts:hosts];
    }
    
    NSDictionary *request = parameters[@"request"];
    if (request != nil && [request isKindOfClass:NSDictionary.class]) {
        [self.startupController addAdditionalStartupParameters:request];
    }
}

- (void)addStartupCompletionObserver:(id<AMAStartupCompletionObserving>)observer
{
    AMALogInfo(@"Add startup observer: %@", observer);
    [self execute:^{
        if (observer != nil) {
            [self.startupCompletionObservers addObject:observer];
        }
    }];
}

- (void)removeStartupCompletionObserver:(id<AMAStartupCompletionObserving>)observer
{
    AMALogInfo(@"Remove startup observer: %@", observer);
    [self execute:^{
        [self.startupCompletionObservers removeObject:observer];
    }];
}

#pragma mark - Reporter Storage controlling -

- (void)setExtendedReporterStorageControllers:(NSSet<id<AMAReporterStorageControlling>> *)controllers
{
    AMALogInfo(@"Register extended reporter storage controllers: %@", controllers);
    [self execute:^{
        if (controllers != nil) {
            for (id<AMAReporterStorageControlling> controller in controllers) {
                [self.extendedReporterStorageControllersTable addObject:controller];
            }
        }
    }];
}

- (void)setupReporterWithExtendedReporterStorage:(id<AMAKeyValueStorageProviding>)storageProvider
                                            main:(BOOL)main
                                          apiKey:(NSString *)apiKey
{
    [self execute:^{
        AMALogInfo(@"Setup main reporter for extended reporter storage %lu controllers",
                   (unsigned long)self.extendedReporterStorageControllersTable.count);
        for (id<AMAReporterStorageControlling> controller in self.extendedReporterStorageControllersTable) {
            [controller setupWithReporterStorage:storageProvider main:main forAPIKey:apiKey];
        }
    }];
}

#pragma mark - Environment -

- (void)setAppEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    @synchronized (self) {
        if (self.preactivationActionHistory.appEnvironment != nil) {
            [self.preactivationActionHistory.appEnvironment trackAddValue:value forKey:key];
        }
        else {
            [self.reporter setAppEnvironmentValue:value forKey:key];
        }
    }
}

- (void)setSessionExtras:(nullable NSData *)data forKey:(nonnull NSString *)key
{
    [self execute:^{
        if (self.reporter == nil) {
            AMALogAssert(@"reporter should be not null");
        }
        
        [self.reporter setSessionExtras:data forKey:key];
    }];
}

- (void)clearSessionExtra
{
    [self execute:^{
        if (self.reporter == nil) {
            AMALogAssert(@"reporter should be not null");
        }

        [self.reporter clearSessionExtra];
    }];
}

+ (void)syncSetErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    [[AMAReporterStoragesContainer sharedInstance].errorEnvironment addValue:value forKey:key];
}

- (void)setErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    [self execute:^{
        [[self class] syncSetErrorEnvironmentValue:value forKey:key];
    }];
}

- (void)requestStartupIdentifiersWithCompletionQueue:(dispatch_queue_t)queue
                                     completionBlock:(AMAIdentifiersCompletionBlock)block
                                       notifyOnError:(BOOL)notifyOnError
{
    [self requestStartupIdentifiersWithKeys:[AMAStartupItemsChangedNotifier allIdentifiersKeys]
                            completionQueue:queue
                            completionBlock:block
                              notifyOnError:notifyOnError];
}

- (void)requestStartupIdentifiersWithKeys:(NSArray<NSString *> *)keys
                          completionQueue:(dispatch_queue_t)queue
                          completionBlock:(AMAIdentifiersCompletionBlock)block
                            notifyOnError:(BOOL)notifyOnError
{
    [self execute:^{
        NSString *callbackMode = kAMARequestIdentifiersOptionCallbackOnSuccess;
        if (notifyOnError) {
            callbackMode = kAMARequestIdentifiersOptionCallbackInAnyCase;
        }

        NSDictionary *options = @{ kAMARequestIdentifiersOptionCallbackModeKey : callbackMode };
        [self.startupItemsNotifier requestStartupItemsWithKeys:keys options:options queue:queue completion:block];
        [self.startupController update];
    }];
}

- (void)clearAppEnvironment
{
    [self execute:^{
        if (self.reporter != nil) {
            [self.reporter clearAppEnvironment];
        } else {
            [self.preactivationActionHistory.appEnvironment trackClearEnvironment];
        }
    }];
}

- (void)reportUrl:(NSURL *)url ofType:(NSString *)type isAuto:(BOOL)isAuto
{
    [self.deeplinkController reportUrl:url ofType:type isAuto:isAuto];
}

@end
