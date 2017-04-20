//
//  DetailViewController.h
//  HelloMyGDrive
//
//  Created by Lai Zih Ci on 2017/2/17.
//  Copyright © 2017年 ZihCi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GTLDrive.h>
#import <GoogleSignIn/GoogleSignIn.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) GTLDriveFile *detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

