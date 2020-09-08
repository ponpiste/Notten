//
//  AppDelegate.h
//  Notten
//
//  Created by Sacha Bartholmé on 4/10/16.
//  Copyright © 2016 Sacha Bartholmé. All rights reserved.
//

@interface AppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate>

{
    NSMutableArray *marks;
    BOOL isPremiere;
}

@property (strong, nonatomic) UIWindow *window;

@end

