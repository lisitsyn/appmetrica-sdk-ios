
#import "AMAConfigurationDatabaseSchemeMigrationTo20.h"
#import "AMAMigrationUtils.h"
#import <AppMetrica_FMDB/AppMetrica_FMDB.h>

@implementation AMAConfigurationDatabaseSchemeMigrationTo20

- (NSUInteger)schemeVersion
{
    return 20;
}

- (BOOL)applyTransactionalMigrationToDatabase:(AMAFMDatabase *)db
{
    BOOL result = YES;

    result = result && [AMAMigrationUtils updateColumnTypes:@"k TEXT NOT NULL PRIMARY KEY, v TEXT NOT NULL DEFAULT ''"
                                            ofKeyValueTable:@"kv"
                                                         db:db];
    result = result && [db executeUpdate:@"DELETE FROM kv WHERE k = ?"
                                  values:@[@"fallback-keychain-AMAMetricaPersistentConfigurationDeviceIDHashStorageKey"]
                                   error:nil];

    return result;
}

@end
