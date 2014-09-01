 //
//  SqliteManager.m
//  SQliteManager
//
//  Created by Suniket on 8/30/13.
//  Copyright (c) 2013 Suniket . All rights reserved.
//

#import "SqliteManager.h"
#import "AppDelegate.h"
#import "TopStoriesDataModel.h"

static SqliteManager *sqliteObject = nil;

@implementation SqliteManager

static sqlite3_stmt *statement=nil;

-(id)init
{
    return self;
}
+(SqliteManager *)StaticObject
{
    if (sqliteObject == nil)
        sqliteObject = [[SqliteManager alloc] init];
    //    NSLog(@"Create object");
    return sqliteObject;
    
}
-(void)createAllTables
{
    [self createTables];
    [self createTestsTables];
    [self createTestDetailsTables];
    [self createSaveTestTable];
    [self createCommonTestTables];
    //    NSLog(@"Create table");
}

#pragma mark Get File Path
-(NSString *)filePath
{
	NSString *documentsDir=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	return [documentsDir stringByAppendingPathComponent:@"Test.sqlite"];
}


#pragma mark Open Db
-(void)openDB
{
	if(sqlite3_open([[self filePath]UTF8String],&dBObject)!= SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    //    NSLog(@"Open DB");
    
}
#pragma mark CLose Db
- (void)close
{
    if (dBObject)
    {
        int rc = sqlite3_close(dBObject);
        //       NSLog(@"close rc=%d", rc);
        
        if (rc == SQLITE_BUSY)
        {
            
            sqlite3_stmt *stmt;
            while ((stmt = sqlite3_next_stmt(dBObject, 0x00)) != 0)
            {
                //                NSLog(@"finalizing stmt");
                sqlite3_finalize(stmt);
            }
            
            rc = sqlite3_close(dBObject);
        }
        
        if (rc != SQLITE_OK)
        {
            //            NSLog(@"close not OK.  rc=%d", rc);
        }
        sqlite3_close(dBObject);
        dBObject = NULL;
    }
    //    NSLog(@"Close DB");
    
}

#pragma mark Create TopStories Test Table

-(void)createTables
{
	[self openDB];
	char *err;
	NSString *sql2=@"CREATE TABLE IF NOT EXISTS TestItem (_Id integer primary key autoincrement,itemId varchar(255), itemTitle varchar(255), itemContent text,itmePublishDate varchar(255),itemVisitURL varchar(255),itemImageUrl varchar(255),itemPageNo varchar(255),itemDomain varchar(255),itemAuther varchar(255),itemSaved varchar(255),LastSync DATE);";
    
	if (sqlite3_exec(dBObject, [sql2 UTF8String], NULL,NULL,&err)!=SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    sqlite3_close(dBObject);
}

// SQL Transaction  It store a bunch of record within a second.
-(BOOL) InsertTopStoriesInTestItemsTable:(NSArray*) arrList
{
    
 	[self openDB];
    sqlite3 *masterDB = dBObject;
    static sqlite3_stmt *init_statement = nil;
    
    {
        NSString* statement;
        
        statement = @"BEGIN EXCLUSIVE TRANSACTION";
        
        if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &init_statement, NULL) != SQLITE_OK) {
            printf("db error: %s\n",  (masterDB));
            return NO;
        }
        if (sqlite3_step(init_statement) != SQLITE_DONE) {
            sqlite3_finalize(init_statement);
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            return NO;
        }
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateString=[dateFormat stringFromDate:[NSDate date]];
        
        statement =[NSString stringWithFormat: @"Insert into TestItem (itemId,itemTitle,itemContent,itmePublishDate,itemVisitURL,itemImageUrl,itemPageNo,itemDomain,itemAuther,itemSaved,LastSync) values(?,?,?,?,?,?,?,?,?,?,?)"];
        sqlite3_stmt *compiledStatement;
        NSString *dummyStr=@"ABC";
        if(sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            @autoreleasepool {
                for(int i = 0; i < [arrList count]; i++){
                    TopStoriesDataModel * entityObj=(TopStoriesDataModel *)[arrList objectAtIndex:i];
                    sqlite3_bind_text(compiledStatement,1, [entityObj.pId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,2, [entityObj.title UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,3, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,4, [entityObj.publish_date UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,5, [entityObj.visit_url UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,6, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,7, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,8, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,9, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,10, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,11, [dateString UTF8String], -1, SQLITE_TRANSIENT);

                    while(YES){
                        NSInteger result = sqlite3_step(compiledStatement);
                        if(result == SQLITE_DONE){
                            break;
                        }
                        else if(result != SQLITE_BUSY){
                            printf("db error: %s\n", sqlite3_errmsg(masterDB));
                            break;
                        }
                    }
                    sqlite3_reset(compiledStatement);
                    
                }
            }
            
            // COMMIT
            statement = @"COMMIT TRANSACTION";
            sqlite3_stmt *commitStatement;
            if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &commitStatement, NULL) != SQLITE_OK) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            if (sqlite3_step(commitStatement) != SQLITE_DONE) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            
            //     sqlite3_finalize(beginStatement);
            sqlite3_finalize(compiledStatement);
            sqlite3_finalize(commitStatement);
            sqlite3_close(dBObject);
            
            return YES;
        }
        
        return YES;
    }
    
}

-(NSMutableArray*)selectresultfromCTestItemTable:(NSString *)tabelName
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    tabelName=@"companylist";
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"select  * from TestItem"];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    TopStoriesDataModel *obj=[[TopStoriesDataModel alloc]init];
                    obj.uniqueTopStoriesAutoIncrementId = sqlite3_column_int(statement, 0);
                    obj.pId=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,1)];
                    obj.title=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,2)];
                    obj.content=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,3)];
                    obj.publish_date=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,4)];
                    obj.visit_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,5)];
                    obj.image_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,6)];
                    obj._id=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,7)];
                    obj.domain_name=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,8)];
                    obj.auther=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,9)];
                    obj.isSaved=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,10)];
                    [arr addObject:obj];
                }
                
            }
            
            
		}
        sqlite3_finalize(statement);
        
	}
	sqlite3_close(dBObject);
    return arr;
}

-(BOOL)UpdateIsSavedTestItemDetails:(NSString *)savedID and:(NSString *)issaved
{
    NSString *strQuery=[NSString stringWithFormat:@"UPDATE TestItem set itemSaved='%@' where itemId='%@';",issaved,savedID];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}

-(BOOL)UpdateDataTestItemDetails:(TopStoriesDataModel *)model
{
    
    [self openDB];
    sqlite3 *masterDB = dBObject;
    sqlite3_stmt *state = nil;
    
    NSString* strQuery=[NSString stringWithFormat: @"UPDATE TestItem set itemContent=?,itemImageUrl=?,itemAuther=? ,itemSaved=? where _Id=%d;",model.uniqueTopStoriesAutoIncrementId];
    
    char *sql = (char *) [strQuery UTF8String];
    
    sqlite3_prepare_v2(masterDB, sql, -1, &state, NULL);
    sqlite3_bind_text(state, 1, [model.content UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 2, [model.image_url UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 3, [model.auther UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 4, [model.isSaved UTF8String], -1, SQLITE_TRANSIENT);
    
    if (sqlite3_step(state) ==  SQLITE_DONE)
    {
        //NSLog(@"item inserted in DB!");
        sqlite3_finalize(state);
        sqlite3_close(dBObject);
        return YES;
    }
    else
    {
        // NSLog(@"item not inserted in DB!");
        //
        
        NSLog(@"%s", sqlite3_errmsg(masterDB));
        sqlite3_close(dBObject);
        return NO;
    }
    
    
    
}

#pragma mark Create CREATE Saved Test Table

-(void)createSaveTestTable
{
	[self openDB];
	char *err;
	NSString *sql2=@"CREATE TABLE IF NOT EXISTS SaveTest (_Id integer primary key autoincrement,itemId varchar(255), itemTitle varchar(255), itemContent text,itmePublishDate varchar(255),itemVisitURL varchar(255),itemImageUrl varchar(255),itemPageNo varchar(255),itemDomain varchar(255) );";
    
	if (sqlite3_exec(dBObject, [sql2 UTF8String], NULL,NULL,&err)!=SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    sqlite3_close(dBObject);
}

//-(BOOL) InsertToSaveTestTable:(TopStoriesDataModel*) model
//{
//    NSString *strQuery=[NSString stringWithFormat:@"Insert into SaveTest (itemId, itemTitle, itemContent ,itmePublishDate ,itemVisitURL ,itemImageUrl ,itemPageNo ,itemDomain) values('%@','%@','%@','%@','%@','%@','%@','%@');",model.pId,model.title, model.content, model.publish_date, model.visit_url, model.image_url, model._id, model.domain_name];
//    BOOL flag=[self excuteQuery:strQuery];
//    return flag;
//}

-(BOOL) InsertToSaveTestTable:(TopStoriesDataModel*) model
{
    
 	[self openDB];
    sqlite3 *masterDB = dBObject;
    static sqlite3_stmt *init_statement = nil;
    
    {
        NSString* statement;
        
        statement = @"BEGIN EXCLUSIVE TRANSACTION";
        
        if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &init_statement, NULL) != SQLITE_OK) {
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            sqlite3_close(dBObject);
            return NO;
        }
        if (sqlite3_step(init_statement) != SQLITE_DONE) {
            sqlite3_finalize(init_statement);
            sqlite3_close(dBObject);
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            return NO;
        }
        
        statement =[NSString stringWithFormat: @"Insert into SaveTest (itemId, itemTitle, itemContent ,itmePublishDate ,itemVisitURL ,itemImageUrl ,itemPageNo ,itemDomain) values(?,?,?,?,?,?,?,?)"];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            @autoreleasepool {
                    sqlite3_bind_text(compiledStatement,1, [model.pId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,2, [model.title UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,3, [model.content UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,4, [model.publish_date UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,5, [model.visit_url UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,6, [model.image_url UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,7, [model._id UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,8, [model.domain_name UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while(YES){
                        NSInteger result = sqlite3_step(compiledStatement);
                        if(result == SQLITE_DONE){
                            break;
                        }
                        else if(result != SQLITE_BUSY){
                            printf("db error: %s\n", sqlite3_errmsg(masterDB));
                            break;
                        }
                    }
                    sqlite3_reset(compiledStatement);
                    
                }
            }
            
            // COMMIT
            statement = @"COMMIT TRANSACTION";
            sqlite3_stmt *commitStatement;
            if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &commitStatement, NULL) != SQLITE_OK) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            if (sqlite3_step(commitStatement) != SQLITE_DONE) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            
            //     sqlite3_finalize(beginStatement);
            sqlite3_finalize(compiledStatement);
            sqlite3_finalize(commitStatement);
            sqlite3_close(dBObject);
            
            return YES;
        }
        
        return YES;
}


-(int)CheckTestIsAvailableInSavedTest:(NSString *)pid and:(NSString *)ptitle
{
    
    [self openDB];
    sqlite3 *masterDB = dBObject;
    sqlite3_stmt *state = nil;
    int check=0;
    NSString* strQuery=[NSString stringWithFormat:@"SELECT COUNT(*) FROM SaveTest where itemId='%@' AND itemTitle='%@';",pid,ptitle];
    char *sql = (char *) [strQuery UTF8String];
    
    sqlite3_prepare_v2(masterDB, sql, -1, &state, NULL);
    sqlite3_bind_text(state, 1, [pid UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 2, [ptitle UTF8String], -1, SQLITE_TRANSIENT);
    
    
        if(sqlite3_prepare_v2(dBObject, [strQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                        check = sqlite3_column_int(statement, 0);
                }
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(dBObject);
    return check;
}



-(BOOL)deleteRecorFromSaveTest:(NSString*)pid and:(NSString*)ptitle
{
    NSString *strQuery=[NSString stringWithFormat:@"delete FROM SaveTest where itemTitle='%@';",ptitle];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}


-(NSMutableArray*)selectresultfromSaveTestTable:(NSString *)tabelName
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"select  * from SaveTest order by _Id desc;"];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    TopStoriesDataModel *obj=[[TopStoriesDataModel alloc]init];
                    
                    obj.pId=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,1)];
                    obj.title=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,2)];
                    obj.content=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,3)];
                    obj.publish_date=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,4)];
                    obj.visit_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,5)];
                    obj.image_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,6)];
                   // obj._id=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,7)];
                    obj.domain_name=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,8)];
                    [arr addObject:obj];
                }
                
            }
            
            
		}
        sqlite3_finalize(statement);
        
	}
	sqlite3_close(dBObject);
    return arr;
}
#pragma mark Create CREATE Notification Table

-(void)createNotificationTables
{
	[self openDB];
	char *err;
	NSString *sql2=@"CREATE TABLE IF NOT EXISTS Notification (pipe_Id integer primary key autoincrement,TestName varchar(255),NotificationNumber integer);";
    
	if (sqlite3_exec(dBObject, [sql2 UTF8String], NULL,NULL,&err)!=SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    sqlite3_close(dBObject);
}


#pragma mark Create CREATE Test Table


-(void)createTestsTables
{
	[self openDB];
	char *err;
	NSString *sql2=@"CREATE TABLE IF NOT EXISTS Test (pipe_Id integer primary key autoincrement,itemName varchar(255),img_url varchar(255),Last_img_url varchar(255),NotificationNumber integer,LastUpdatedDate varchar(255))";
    
	if (sqlite3_exec(dBObject, [sql2 UTF8String], NULL,NULL,&err)!=SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    sqlite3_close(dBObject);
}



// SQL Transaction  It store a bunch of record within a second.
-(BOOL) InsertToTestTable:(NSArray*) arrList
{
	[self openDB];
    sqlite3 *masterDB = dBObject;
    static sqlite3_stmt *init_statement = nil;
    
    {
        NSString* statement;
        
        statement = @"BEGIN EXCLUSIVE TRANSACTION";
        
        if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &init_statement, NULL) != SQLITE_OK) {
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            sqlite3_close(dBObject);
            return NO;
        }
        if (sqlite3_step(init_statement) != SQLITE_DONE) {
            sqlite3_finalize(init_statement);
            sqlite3_close(dBObject);
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            return NO;
        }
        
        statement =[NSString stringWithFormat: @"Insert into Test (itemName,img_url,Last_img_url,NotificationNumber,LastUpdatedDate) values(?,?,?,?,?)"];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            @autoreleasepool {
                for(int i = 0; i < [arrList count]; i++){
                    
                    Test * entityObj=(Test *)[arrList objectAtIndex:i];
                    
                    sqlite3_bind_text(compiledStatement,1, [entityObj.pipeName UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,2, [entityObj.img_url UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,3, [entityObj.Last_img_url UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(compiledStatement, 4, entityObj.NotificationNumber);
                    sqlite3_bind_text(compiledStatement,5, [entityObj.LastUpdatedDate UTF8String], -1, SQLITE_TRANSIENT);

                  
                    while(YES){
                        NSInteger result = sqlite3_step(compiledStatement);
                        if(result == SQLITE_DONE){
                            break;
                        }
                        else if(result != SQLITE_BUSY){
                            printf("db error: %s\n", sqlite3_errmsg(masterDB));
                            break;
                        }
                    }
                    sqlite3_reset(compiledStatement);
                    
                }
            }
            
            // COMMIT
            statement = @"COMMIT TRANSACTION";
            sqlite3_stmt *commitStatement;
            if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &commitStatement, NULL) != SQLITE_OK) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            if (sqlite3_step(commitStatement) != SQLITE_DONE) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            
            //     sqlite3_finalize(beginStatement);
            sqlite3_finalize(compiledStatement);
            sqlite3_finalize(commitStatement);
            sqlite3_close(dBObject);
            
            return YES;
        }
        
        return YES;
    }

}

#pragma mark Get img_url From Test Table for Push Redirection with Image

-(NSString*)selectimg_urlFromTestTable:(NSString *)TestName
{
    NSString *img_url=[[NSString alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        
        sqlStatement = [ NSString stringWithFormat:@"SELECT img_url FROM Test where itemName='%@'",TestName];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    
                    img_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,0)];
                }
                
            }
		}
        sqlite3_finalize(statement);
	}
	sqlite3_close(dBObject);
    return img_url;
}

-(BOOL)UpdateLastUpdatedDate:(NSString *)Date TestName:(NSString *)str_TestName
{
    NSString *strQuery=[NSString stringWithFormat:@"UPDATE Test set LastUpdatedDate='%@' where itemName='%@';",Date,str_TestName];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}

-(BOOL)UpdateLastImg_urlToTestTable:(NSString *)str_img_url and:(NSString *)TestName
{
    NSString *strQuery=[NSString stringWithFormat:@"UPDATE Test set Last_img_url='%@' where itemName='%@';",str_img_url,TestName];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}
-(BOOL)UpdateDataToTableTest:(NSMutableArray *)arrData update:(NSString*)name
{
    
    [self openDB];
    BOOL flag;
    @autoreleasepool
    {
        for(int i = 0; i < [arrData count]; i++)
        {
            
            Test * entityObj=(Test *)[arrData objectAtIndex:i];
    
            NSString* strQuery;
            if ([name isEqualToString:@"image"]) {
                strQuery=[NSString stringWithFormat: @"update Test set img_url='%@',Last_img_url='%@'where itemName='%@'",entityObj.img_url,entityObj.Last_img_url,entityObj.pipeName];
            }
            else
            {
                strQuery=[NSString stringWithFormat: @"update Test set NotificationNumber='%d'where itemName='%@'",entityObj.NotificationNumber,entityObj.pipeName];
            }
    
            flag=[self excuteQuery:strQuery];
            
        }
    
    }
    [self close];
    return flag;
}

-(NSMutableArray*)selectfromTestTable:(NSString *)tabelName
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"SELECT * FROM Test where pipe_Id =1 UNION ALL select * from (SELECT * FROM Test   where pipe_Id !=1 order by pipe_id desc )  "];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    Test *obj=[[Test alloc]init];
                    
                    obj.pipeId=sqlite3_column_int(statement, 0);
                    obj.pipeName=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,1)];
                    obj.img_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,2)];
                    obj.Last_img_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,3)];
                    obj.NotificationNumber=sqlite3_column_int(statement, 4);
                    obj.LastUpdatedDate=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,5)];

                    [arr addObject:obj];
                }
    
            }
            
		}
        sqlite3_finalize(statement);
        
	}
	sqlite3_close(dBObject);
    return arr;
}


-(NSMutableArray*)selectImageUrlsfromTestTable:(NSString *)tabelName
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"SELECT img_url FROM Test where pipe_Id =1 UNION ALL select * from (SELECT * FROM Test   where pipe_Id !=1 order by pipe_id desc )  "];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    Test *obj=[[Test alloc]init];
                    
                    obj.pipeId=sqlite3_column_int(statement, 0);
                    obj.pipeName=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,1)];
                    obj.img_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,2)];
                    obj.NotificationNumber=sqlite3_column_int(statement, 3);
                    obj.LastUpdatedDate=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,4)];
                    
                    [arr addObject:obj];
                }
                
            }
            
		}
        sqlite3_finalize(statement);
        
	}
	sqlite3_close(dBObject);
    return arr;
}

-(int)selectRecordTestTable:(NSString *)pipeName
{
    int pipe_id=0;
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"select pipe_id from pipe where itemName='%@';",pipeName];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    pipe_id=sqlite3_column_int(statement, 0);
                    
                }
                
            }
            
		}
        sqlite3_finalize(statement);
        
	}
	sqlite3_close(dBObject);
    return pipe_id;
}
#pragma mark Get Last Sync Date From Test Details Table

-(NSString*)selectLastSyncFromTestDetailsTable:(NSString *)TestName
{
    NSString *LastSyncDate=[[NSString alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"SELECT LastSync FROM TestDetails where itemName='%@' LIMIT 1",TestName];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    
                    LastSyncDate=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,0)];
                }
                
            }
		}
        sqlite3_finalize(statement);
	}
	sqlite3_close(dBObject);
    return LastSyncDate;
}

#pragma mark Get Last Sync Date From Test Item Table

-(NSString*)selectLastSyncFromTestItemTable
{
    NSString *LastSyncDate=[[NSString alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"SELECT LastSync FROM TestItem  LIMIT 1"];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    
                    LastSyncDate=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,0)];
                }
                
            }
		}
        sqlite3_finalize(statement);
	}
	sqlite3_close(dBObject);
    return LastSyncDate;
}


#pragma mark Create CREATE Common Test Table

-(void)createCommonTestTables
{
	[self openDB];
	char *err;
	NSString *sql2=@"CREATE TABLE IF NOT EXISTS CommonTest (pipe_Id integer primary key autoincrement,itemName varchar(255),TestAdded integer );";
    
	if (sqlite3_exec(dBObject, [sql2 UTF8String], NULL,NULL,&err)!=SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    sqlite3_close(dBObject);
}


-(BOOL) InsertToCommonTestTable:(NSArray*) arrList
{
    
 	[self openDB];
    sqlite3 *masterDB = dBObject;
    static sqlite3_stmt *init_statement = nil;
    
    {
        NSString* statement;
        
        statement = @"BEGIN EXCLUSIVE TRANSACTION";
        
        if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &init_statement, NULL) != SQLITE_OK) {
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            sqlite3_close(dBObject);
            return NO;
        }
        if (sqlite3_step(init_statement) != SQLITE_DONE) {
            sqlite3_finalize(init_statement);
            sqlite3_close(dBObject);
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            return NO;
        }
        
        statement =[NSString stringWithFormat: @"Insert into CommonTest (itemName,TestAdded) values(?,?)"];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            @autoreleasepool {
                for(int i = 0; i < [arrList count]; i++)
                {
                    sqlite3_bind_text(compiledStatement,1, [[arrList objectAtIndex:i] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(compiledStatement, 2, 0);

                    while(YES){
                        NSInteger result = sqlite3_step(compiledStatement);
                        if(result == SQLITE_DONE){
                            break;
                        }
                        else if(result != SQLITE_BUSY){
                            printf("db error: %s\n", sqlite3_errmsg(masterDB));
                            break;
                        }
                    }
                    sqlite3_reset(compiledStatement);
                    
                }
            }
            
            // COMMIT
            statement = @"COMMIT TRANSACTION";
            sqlite3_stmt *commitStatement;
            if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &commitStatement, NULL) != SQLITE_OK) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            if (sqlite3_step(commitStatement) != SQLITE_DONE) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            
            //     sqlite3_finalize(beginStatement);
            sqlite3_finalize(compiledStatement);
            sqlite3_finalize(commitStatement);
            sqlite3_close(dBObject);
            
            return YES;
        }
        
        return YES;
    }
    
}

-(BOOL)UpdateCommonTestTable:(int)TestAdded and:(NSString *)TestName
{
    NSString *strQuery=[NSString stringWithFormat:@"UPDATE CommonTest set TestAdded='%d' where itemName='%@';",TestAdded,TestName];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}



-(NSMutableArray*)selectfromCommonTestTable:(NSString *)tabelName
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];

    NSString *pipeName=[[NSString alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"SELECT itemName FROM CommonTest where TestAdded=0 order by random()"];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    
                    pipeName=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,0)];
                    
                    [arr addObject:pipeName];
                }
                
            }
		}
        sqlite3_finalize(statement);
	}
	sqlite3_close(dBObject);
    return arr;
}




#pragma mark Create CREATE TestDetails Table


-(void)createTestDetailsTables
{
	[self openDB];
	char *err;
    
   
	NSString *sql2=@"CREATE TABLE TestDetails (_Id integer primary key autoincrement,pipe_Id integer,itemId varchar(255), itemTitle varchar(255), itemContent text,itemSummary text,itmePublishDate varchar(255),itemVisitURL varchar(255),itemImageUrl varchar(255),itemPageNo varchar(255),itemDomain varchar(255),itemAuther varchar(255),itemSaved varchar(255),itemName varchar(255),LastSync DATE,DisplayName varchar(255),Logo varchar(255));";
    
	if (sqlite3_exec(dBObject, [sql2 UTF8String], NULL,NULL,&err)!=SQLITE_OK)
	{
		sqlite3_close(dBObject);
	}
    sqlite3_close(dBObject);
}

-(BOOL) InsertToTestDetailsTable:(NSArray*) arrList
{
    
 	[self openDB];
    sqlite3 *masterDB = dBObject;
    static sqlite3_stmt *init_statement = nil;
    
    {
        NSString* statement;
        
        statement = @"BEGIN EXCLUSIVE TRANSACTION";
        
        if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &init_statement, NULL) != SQLITE_OK) {
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            return NO;
        }
        if (sqlite3_step(init_statement) != SQLITE_DONE) {
            sqlite3_finalize(init_statement);
            printf("db error: %s\n", sqlite3_errmsg(masterDB));
            return NO;
        }
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateString=[dateFormat stringFromDate:[NSDate date]];

        statement =[NSString stringWithFormat: @"Insert into TestDetails (pipe_Id,itemId,itemTitle,itemContent,itemSummary,itmePublishDate,itemVisitURL,itemImageUrl,itemPageNo,itemDomain,itemAuther,itemSaved,itemName,LastSync,DisplayName,Logo) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"];
        sqlite3_stmt *compiledStatement;
        NSString *dummyStr=@"ABC";
        if(sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
            @autoreleasepool {
                for(int i = 0; i < [arrList count]; i++){
                    TopStoriesDataModel * entityObj=(TopStoriesDataModel *)[arrList objectAtIndex:i];
                    sqlite3_bind_int(compiledStatement, 1, entityObj.pipeId);
                    sqlite3_bind_text(compiledStatement,2, [entityObj.pId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,3, [entityObj.title UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,4, [entityObj.content UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if ([entityObj.Summary UTF8String]==nil)
                    {
                        sqlite3_bind_text(compiledStatement,5, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                        
                    }
                    else
                    {
                        sqlite3_bind_text(compiledStatement,5, [entityObj.Summary UTF8String], -1, SQLITE_TRANSIENT);
                    }


                    sqlite3_bind_text(compiledStatement,6, [entityObj.publish_date UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,7, [entityObj.visit_url UTF8String], -1, SQLITE_TRANSIENT);
                    if ([entityObj.image_url UTF8String]==nil)
                    {
                    sqlite3_bind_text(compiledStatement,8, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);

                    }
                    else
                    {
                    sqlite3_bind_text(compiledStatement,8, [entityObj.image_url UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    sqlite3_bind_text(compiledStatement,9, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,10, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,11, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,12, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,13, [entityObj.pipeName UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(compiledStatement,14, [dateString UTF8String], -1, SQLITE_TRANSIENT);
                    if ([entityObj.DisplayName UTF8String]==nil)
                    {
                        sqlite3_bind_text(compiledStatement,15, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                        
                    }
                    else
                    {
                        sqlite3_bind_text(compiledStatement,15, [entityObj.DisplayName UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    if ([entityObj.Logo UTF8String]==nil)
                    {
                        sqlite3_bind_text(compiledStatement,16, [dummyStr UTF8String], -1, SQLITE_TRANSIENT);
                        
                    }
                    else
                    {
                        sqlite3_bind_text(compiledStatement,16, [entityObj.Logo UTF8String], -1, SQLITE_TRANSIENT);
                    }


                    while(YES){
                        NSInteger result = sqlite3_step(compiledStatement);
                        if(result == SQLITE_DONE){
                            break;
                        }
                        else if(result != SQLITE_BUSY){
                            printf("db error: %s\n", sqlite3_errmsg(masterDB));
                            break;
                        }
                    }
                    sqlite3_reset(compiledStatement);
                    
                }
            }
            
            // COMMIT
            statement = @"COMMIT TRANSACTION";
            sqlite3_stmt *commitStatement;
            if (sqlite3_prepare_v2(masterDB, [statement UTF8String], -1, &commitStatement, NULL) != SQLITE_OK) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            if (sqlite3_step(commitStatement) != SQLITE_DONE) {
                printf("db error: %s\n", sqlite3_errmsg(masterDB));
                return NO;
            }
            
            //     sqlite3_finalize(beginStatement);
            sqlite3_finalize(compiledStatement);
            sqlite3_finalize(commitStatement);
            sqlite3_close(dBObject);
            
            return YES;
        }
        
        return YES;
    }
    
}


-(NSMutableArray*)selectDetailsfromTestsDetailsTable:(NSString*)pipeName
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK) {
        NSString *sqlStatement =NULL;
        sqlStatement = [ NSString stringWithFormat:@"select  * from TestDetails where itemName='%@'",pipeName];
		
        if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            @autoreleasepool {
                while(sqlite3_step(statement) == SQLITE_ROW) {
                    TopStoriesDataModel *obj=[[TopStoriesDataModel alloc]init];
                    obj.pipeId=sqlite3_column_int(statement, 1);
                    obj.pId=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,2)];
                    obj.title=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,3)];
                    obj.content=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,4)];
                    obj.Summary=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,5)];
                    obj.publish_date=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,6)];
                    obj.visit_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,7)];
                    obj.image_url=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,8)];
                    obj._id=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,9)];
                    obj.domain_name=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,10)];
                    obj.auther=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,11)];
                    obj.isSaved=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,12)];
                    obj.pipeName=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,13)];
                    obj.LastSync=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,14)];

                    obj.DisplayName=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,15)];
                    obj.Logo=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,16)];
                    [arr addObject:obj];
                }
                
            }
            
            
		}
        sqlite3_finalize(statement);
        
	}
	sqlite3_close(dBObject);
    return arr;
}

-(NSMutableArray*)selectLatUpdatedDatefromTestsDetailsTable
{
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    if(sqlite3_open([[self filePath] UTF8String], &dBObject) == SQLITE_OK)
    {
        int i=1;
        NSString *sqlStatement =NULL;
        for( i = 1; i < [arrayDataSectionTwo count]; i++)
        {
            Test *model= (Test *)[arrayDataSectionTwo objectAtIndex:i];
            
          NSString  *Name=model.pipeName;
            
            sqlStatement = [ NSString stringWithFormat:@"SELECT itmePublishDate FROM TestDetails where itemName='%@' LIMIT 1",Name];
            
            if(sqlite3_prepare_v2(dBObject, [sqlStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
            {
                @autoreleasepool {
                    while(sqlite3_step(statement) == SQLITE_ROW)
                    {
                        TopStoriesDataModel *lastUpdatedModel=[[TopStoriesDataModel alloc]init];
                        NSString *str=[NSString stringWithUTF8String:(char *) sqlite3_column_text(statement,0)];
                        lastUpdatedModel.publish_date=str;
                        lastUpdatedModel.pipeName=Name;
                        if (str==nil)
                        {
                            str=@"This Test is yet to be explored";
                        }
                        [arr addObject:str];
                    }
                    
                }
                
                
            }
            sqlite3_finalize(statement);
        }
	}
	sqlite3_close(dBObject);
    
    return arr;
    
}
-(BOOL)UpdateSavedTestDetails:(NSString *)savedID and:(NSString *)issaved
{
    NSString *strQuery=[NSString stringWithFormat:@"UPDATE TestDetails set itemSaved='%@' where itemId='%@';",issaved,savedID];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}

-(BOOL)UpdateDataToTableTestDetails:(TopStoriesDataModel *)model
{
    
    [self openDB];
    sqlite3 *masterDB = dBObject;
    sqlite3_stmt *state = nil;
    
    NSString* strQuery=[NSString stringWithFormat: @"UPDATE TestDetails set itemContent=?,itemImageUrl=? , itemAuther=? ,itemSaved=? where itemId='%@' AND pipe_Id=%d;",model.pId,model.pipeId];
    char *sql = (char *) [strQuery UTF8String];
    
    sqlite3_prepare_v2(masterDB, sql, -1, &state, NULL);
    sqlite3_bind_text(state, 1, [model.content UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 2, [model.image_url UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 3, [model.auther UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(state, 4, [model.isSaved UTF8String], -1, SQLITE_TRANSIENT);
    
    if (sqlite3_step(state) ==  SQLITE_DONE)
    {
        //NSLog(@"item inserted in DB!");
        sqlite3_finalize(state);
        sqlite3_close(dBObject);
        return YES;
    }
    else
    {
        // NSLog(@"item not inserted in DB!");
        NSLog(@"%s", sqlite3_errmsg(masterDB));
        sqlite3_close(dBObject);
        return NO;
    }
    
    
    
}


#pragma mark Delete row from Table


-(BOOL)deleteRecorFromTabel:(NSString  *)tabelName second:(NSString*)fromTest
{
    NSString *strQuery=[NSString stringWithFormat:@"delete from %@ where itemName=\"%@\";",tabelName, fromTest];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}


#pragma mark Delete TABLE From DB
-(BOOL)deleteRecorFromTabel:(NSString  *)tabelName
{
    NSString *strQuery=[NSString stringWithFormat:@"delete from %@;",tabelName ];
    BOOL flag=[self excuteQuery:strQuery];
    return flag;
}

-(BOOL)excuteQuery:(NSString *)queryString
{
	[self openDB];
	char *err;
	if (sqlite3_exec(dBObject, [queryString UTF8String], NULL,NULL, &err)!= SQLITE_OK)
	{
		sqlite3_close(dBObject);
        NSLog(@"%s",err);
		return NO;
	}
	else
	{
        sqlite3_close(dBObject);
        
		return YES;
	}
}





@end