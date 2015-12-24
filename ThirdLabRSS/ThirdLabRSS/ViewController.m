//
//  ViewController.m
//  ThirdLabRSS
//
//  Created by Diana Volodchenko on 12/24/15.
//  Copyright © 2015 Diana Volodchenko. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

{
    NSURLConnection *_connection;
    NSMutableData *_data;
    NSArray *_topics;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.rssUrlInput.text = @"http://hizone.info/rss/science.xml";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSError *error = nil;
    SMXMLDocument *xmlDoc = [SMXMLDocument documentWithData :_data error: &error];
    
    _topics = [[xmlDoc childNamed:@"channel" ]childrenNamed:@"item"];
    [_tableView reloadData];
    _data = nil;
    _connection = nil;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _topics.count;
}

- (IBAction)downloadRss:(id)sender
{
    NSString *urlString = self.rssUrlInput.text;
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    _connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    SMXMLElement *item = _topics[indexPath.row]; cell.textLabel.text = [item childNamed:@"title"].value; return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMXMLElement *item = _topics[indexPath.row];
    NSString *urlString = [item childNamed:@"link"].value;
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.rssUrlInput.text = nil;
    _data = [NSMutableData data];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

@end
