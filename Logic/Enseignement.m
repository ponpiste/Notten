//
//  Enseignement.m
//  Notten
//
//  Created by Sacha Bartholmé on 3/18/17.
//  Copyright © 2017 Sacha Bartholmé. All rights reserved.
//

#import "Enseignement.h"

@implementation Enseignement

- (void)viewDidLoad{
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Classes"];
    
    folders = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]];
    [folders removeObject:@".DS_Store"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didEditClassique:(NSString *)fileName path:(NSString *)filePath{
    [_delegate didEditEnseignement:fileName path:filePath];
}

- (void)didEditTechnique:(NSString *)fileName path:(NSString *)filePath{
    [_delegate didEditEnseignement:fileName path:filePath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Classes"];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    Classique *classique = segue.destinationViewController;
    classique.delegate=self;
    classique.path = [path stringByAppendingPathComponent:folders[indexPath.row]];
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
