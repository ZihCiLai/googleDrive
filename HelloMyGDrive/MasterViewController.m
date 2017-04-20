//
//  MasterViewController.m
//  HelloMyGDrive
//
//  Created by Lai Zih Ci on 2017/2/17.
//  Copyright © 2017年 ZihCi. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

#import <GoogleSignIn/GoogleSignIn.h>
#import <GTLDrive.h>
#import <GTMOAuth2ViewControllerTouch.h>

#define KEYCHAIN_ITEM_NAME @"ZIH_CI"
#define CLIENT_ID @"781344201403-dpf725smh2u7ajlvmf7ikhi1nsdme4va.apps.googleusercontent.com"

@interface MasterViewController () <GIDSignInDelegate, GIDSignInUIDelegate>
{
    GTLServiceDrive *drive;
}
@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    // Handle Google SignIn
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.delegate = self;
    signIn.uiDelegate = self;
    
    signIn.scopes = @[kGTLAuthScopeDriveFile];
    signIn.clientID = CLIENT_ID;
    
    // Prepare Googe Drive
    drive = [GTLServiceDrive new];
    drive.authorizer = signIn.currentUser.authentication.fetcherAuthorizer;
    
    // Check if we should sign-in or already sign-in.
    if ([drive.authorizer canAuthorize]) {
        // Already sign-in
        [self startGDriveFunctions];
    } else {
        // Need sign-in
        [signIn signIn];
    }
}

-(void) startGDriveFunctions {
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self downloadFilesList];
}

-(void) downloadFilesList {
    drive.shouldFetchNextPages = true;
    
    // Prepare query
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"'%@' IN parents", @"root"];
    
    [drive executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDriveFileList *fileList, NSError *error) {
        if (error) {
            NSLog(@"Query File List Fail: %@",error);
        }
        [_objects removeAllObjects];
        for (GTLDriveFile *file in fileList.files) {
            [_objects addObject:file];
            NSLog(@"File: %@", file.description);
            
        }
        [self.tableView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)insertNewObject:(id)sender {
    // Prepare url
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"image.jpg" withExtension:nil];
    // Prepare GTLDriveFile
    GTLDriveFile *file = [GTLDriveFile new];
    file.originalFilename = [NSString stringWithFormat:@"HelloMyIMG_%@", [NSDate date]];
    file.name = file.originalFilename;
    file.descriptionProperty = @"HelloMyIMG";
    file.mimeType = @"image/jpg";
    
    // Prepare parameter
    GTLUploadParameters *parameters = [GTLUploadParameters uploadParametersWithFileURL:fileURL MIMEType:file.mimeType];
    
    // Prepare and perform the query
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesCreateWithObject:file uploadParameters:parameters];
    
    GTLServiceTicket *ticket = [drive executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error) {
            NSLog(@"Upload Fail: %@",error);
            return;
        }
        NSLog(@"Upload OK");
        [self downloadFilesList];
    }];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        GTLDriveFile *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

//    NSDate *object = self.objects[indexPath.row];
//    cell.textLabel.text = [object description];
    
    GTLDriveFile *object = self.objects[indexPath.row];
    cell.textLabel.text = object.name;
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GTLDriveFile *file = _objects[indexPath.row];
        GTLQueryDrive *query = [GTLQueryDrive queryForFilesDeleteWithFileId:file.identifier];
        [drive executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                NSLog(@"Edlete File fail: %@",error);
            }
            NSLog(@"Delete File OK.");
            [self downloadFilesList];
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}
#pragma mark - Google signin support
-(void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (error) {
        // Auth Fail.
        NSLog(@"Auth Fail: %@", error);
        return;
    }
    // Auth OK.
    NSLog(@"Auth OK.");
    drive.authorizer = user.authentication.fetcherAuthorizer;
    
    [self startGDriveFunctions];
}

@end
