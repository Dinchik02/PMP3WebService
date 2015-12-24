//
//  ViewController.h
//  ThirdLabRSS
//
//  Created by Diana Volodchenko on 12/24/15.
//  Copyright © 2015 Diana Volodchenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMXMLDocument.h"

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UITextField *rssUrlInput;

@property (weak, nonatomic) IBOutlet UIButton *downloadRssButton;
@end

