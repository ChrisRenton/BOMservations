//
//  RootViewController.m
//  BOMServations
//
//  Created by Patrick Quinn-Graham on 20/02/11.
//  Copyright 2011 Patrick Quinn-Graham. All rights reserved.
//

#import "RootViewController.h"

#import "ObservationRetriever.h"
#import "PersistStore.h"
#import "SQLDatabase.h"
#import "BOMServationsAppDelegate.h"
#import "StationsStore.h"
#import "NSDateJSON.h"


@implementation RootViewController

@synthesize observations, choiceID=_choiceID;

+stationWithStationID:(NSInteger)choiceID {
    RootViewController *rvc = [[[RootViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    rvc.choiceID = choiceID;
    return rvc;
}

- (void)populateBOM {
    BOMServationsAppDelegate *del = (BOMServationsAppDelegate*)[[UIApplication sharedApplication] delegate];
    PersistStore *store = [del.store retain];
    SQLDatabase *db = store.db;
    SQLResult *res = [db performQueryWithFormat:@"SELECT name, aifstime_utc, air_temp FROM observations WHERE choice_id = %d ORDER BY sort_order ASC", self.choiceID];
    NSMutableArray *newObservations = [NSMutableArray arrayWithCapacity:10];
    for(SQLRow *row in [res rowEnumerator]) {
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate dateWithSQLString:[row stringForColumn:@"aifstime_utc"]], @"aifstime_utc", 
            [row stringForColumn:@"air_temp"], @"air_temp", 
            [row stringForColumn:@"name"], @"name", 
            nil];
        [newObservations addObject:result];
    }
    self.observations = newObservations;
}

- (void)updateBOM:(void (^)())callback {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[BOMServationsAppDelegate shared].store stationIDForChoiceID:self.choiceID callback:^(long long stationID){
        [retriever fetchObservations:stationID callback:^{
            [self populateBOM];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];        
            callback();
        }];        
    }];
}

- (void)triggerReload:(id)sender {
    refresh.enabled = NO;
    [self updateBOM:^(){
        if([self.observations count] > 0) {
            self.title = [[self.observations objectAtIndex:0] objectForKey:@"name"];
        }
        [self.tableView reloadData];
        refresh.enabled = YES;            
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    retriever = [[ObservationRetriever alloc] init];
    self.observations = [NSArray array];

    worker = dispatch_queue_create("worker1", nil);
    self.title = @"BOMservations";
    
    refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(triggerReload:)];
    self.navigationItem.rightBarButtonItem = refresh;
    [refresh release];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    dispatch_async(worker, ^{
        [self populateBOM];
        dispatch_async(dispatch_get_main_queue(), ^{
            if([self.observations count] > 0) {
                self.title = [[self.observations objectAtIndex:0] objectForKey:@"name"];
            }
            [self.tableView reloadData];
        });
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [observations count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *observation = [observations objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dateFormatter stringFromDate:[observation objectForKey:@"aifstime_utc"]];
    
    cell.detailTextLabel.text = [observation objectForKey:@"air_temp"];

    // Configure the cell.
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
	*/
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [dateFormatter release];
    [retriever release];

    self.observations = nil;
    
    if(worker) {
        dispatch_release(worker);
        worker = nil;
    }

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
}

@end
