//
//  SqliteManager.h
//  SQliteManager
//
//  Created by Suniket on 8/30/13.
//  Copyright (c) 2013 Suniket . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "TopStoriesDataModel.h"
@interface SqliteManager : NSObject
{
    sqlite3 *dBObject;
}

+(SqliteManager *)StaticObject;
//Create
- (void)close;

-(void) createTables;
-(void)createAllTables;
-(void)createTestsTables;
-(void)createTestDetailsTables;

//Delete
-(BOOL)deleteRecorFromTabel:(NSString  *)tabelName;
-(BOOL)deleteRecorFromTabel:(NSString  *)tabelName second:(NSString*)fromTest;

////Get Rank of Test
//-(int)GetRank;
//
//-(int)GetRankForInterchangeTests:(NSString*) pipeName;
//
////Interchange Test Order
//-(BOOL)InterchangeTests:(int)Rank and:(int)Test_ID;

//For Notification

-(void)createNotificationTables;
-(BOOL) InsertToNotificationTable:(NSArray*) arrList;
-(NSMutableArray*)selectfromNotificationTable:(NSString *)tabelName;
-(BOOL)deleteNotificationFromTabel:(NSString  *)str_TestName;


//Test Table


//-(BOOL) InsertToTestTable:(NSString*) pipeName;

-(BOOL)UpdateLastUpdatedDate:(NSString *)Date TestName:(NSString *)str_TestName;
-(BOOL)UpdateLastImg_urlToTestTable:(NSString *)str_img_url and:(NSString *)TestName;
#pragma mark Get img_url From Test Table for Push Redirection with Image

-(NSString*)selectimg_urlFromTestTable:(NSString *)TestName;

-(BOOL) InsertToTestTable:(NSArray*) arrList;
-(BOOL)UpdateDataToTableTest:(NSMutableArray *)arrData update:(NSString*)name;


-(NSMutableArray*)selectImageUrlsfromTestTable:(NSString *)tabelName;

-(NSMutableArray*)selectfromTestTable:(NSString *)tabelName;
//TestDetails

-(NSMutableArray*)selectLatUpdatedDatefromTestsDetailsTable;
//-(NSString*)selectLatUpdatedDatefromTestsDetailsTable:(NSString*)pipeName;

-(NSMutableArray*)selectDetailsfromTestsDetailsTable:(NSString*)pipeName;


-(BOOL) InsertToTestDetailsTable:(NSArray*) arrList;
-(BOOL)UpdateDataToTableTestDetails:(TopStoriesDataModel *)model;
-(BOOL)UpdateSavedTestDetails:(NSString *)savedID and:(NSString *)issaved;
//Save Test
-(BOOL) InsertToSaveTestTable:(TopStoriesDataModel*) model;
-(NSMutableArray*)selectresultfromSaveTestTable:(NSString *)tabelName;
-(int)selectRecordTestTable:(NSString *)pipeName;
-(int)CheckTestIsAvailableInSavedTest:(NSString *)pid and:(NSString *)ptitle;
-(BOOL)deleteRecorFromSaveTest:(NSString*)pid and:(NSString*)ptitle;
//Common Test
-(BOOL) InsertToCommonTestTable:(NSArray*) arrList;
-(NSMutableArray*)selectfromCommonTestTable:(NSString *)tabelName;
-(BOOL)UpdateCommonTestTable:(int)TestAdded and:(NSString *)TestName;


//Test Items
-(BOOL) InsertTopStoriesInTestItemsTable:(NSArray*) arrList;
-(NSMutableArray*)selectresultfromCTestsItemTable:(NSString *)tabelName;
-(BOOL)UpdateDataTestItemDetails:(TopStoriesDataModel *)model;
-(BOOL)UpdateIsSavedTestItemDetails:(NSString *)savedID and:(NSString *)issaved;

#pragma mark Get Last Sync Date From Test Details Table

-(NSString*)selectLastSyncFromTestDetailsTable:(NSString *)TestName;
#pragma mark Get Last Sync Date From Test Item Table

-(NSString*)selectLastSyncFromTestItemTable;

@end
