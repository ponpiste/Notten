//
//  Classname.m
//  Notten
//
//  Created by Sacha Bartholmé on 3/18/17.
//  Copyright © 2017 Sacha Bartholmé. All rights reserved.
//

#import "Classname.h"


@implementation Classname

- (void)viewDidLoad {
    [super viewDidLoad];

    files = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:nil]];
    [files removeObject:@".DS_Store"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text=[files[indexPath.row]stringByReplacingOccurrencesOfString:@".plist" withString:@""];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [files count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    _path = [_path stringByAppendingPathComponent:files[indexPath.row]];
    [_delegate didEditClassname:[_path.lastPathComponent stringByReplacingOccurrencesOfString:@".plist" withString:@""] path:_path];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
