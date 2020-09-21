//
//  Classique.m
//  Notten
//
//  Created by Sacha Bartholmé on 3/18/17.
//  Copyright © 2017 Sacha Bartholmé. All rights reserved.
//

#import "Classique.h"
@implementation Classique

- (void)viewDidLoad{
    [super viewDidLoad];
    
    folders = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:nil]];
    [folders removeObject:@".DS_Store"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didEditClassname:(NSString *)fileName path:(NSString *)filePath{
    [_delegate didEditClassique:fileName path:filePath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    Classname *classname = segue.destinationViewController;
    classname.delegate=self;
    
    NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
    
    classname.path=[_path stringByAppendingPathComponent:folders[indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text=NSLocalizedString(folders[indexPath.row], nil);
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [folders count];
}

@end
