//
//  StationsStore.h
//  BOMServations
//
//  Created by Patrick Quinn-Graham on 16/03/11.
//  Copyright 2011 Sharkey Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SQLDatabase;

@interface StationsStore : NSObject {
    
	SQLDatabase *db;
    
	BOOL dbIsOpen;
	
	NSLock *dbLock;
    
    dispatch_queue_t queue;
    
}

@property (nonatomic, retain) SQLDatabase *db;
@property (nonatomic, assign) dispatch_queue_t queue;

+storeWithFile:(NSString*)file;

-(BOOL)openDatabase:(NSString *)fileName;
-(void)closeDatabase;


@end
