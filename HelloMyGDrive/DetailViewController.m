//
//  DetailViewController.m
//  HelloMyGDrive
//
//  Created by Lai Zih Ci on 2017/2/17.
//  Copyright © 2017年 ZihCi. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
{
    GTLServiceDrive *drive;
}
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;

@end

@implementation DetailViewController

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem && drive) {
        self.title = _detailItem.name;
        NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v2/files/%@?alt=media",_detailItem.identifier];
        GTMSessionFetcher *fetcher = [drive.fetcherService fetcherWithURLString:url];
        [fetcher beginFetchWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Download Fail: %@",error);
                return;
            }
            _resultImageView.image = [UIImage imageWithData:data];
        }];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Prepare drive
    drive = [GTLServiceDrive new];
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    drive.authorizer = signIn.currentUser.authentication.fetcherAuthorizer;
    
    [self configureView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Managing the detail item

- (void)setDetailItem:(GTLDriveFile *)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
    }
}


@end
