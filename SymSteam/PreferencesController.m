//
//  PreferencesController.m
//  SymSteam
//
//  Created by Alex Jackson on 15/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

static NSString * const steamAppsLocalPath = @"steamAppsLocalPath";
static NSString * const steamAppsSymbolicLinkPath = @"steamAppsSymbolicLinkPath";

@synthesize localPathTextField, symbolicPathTextField, growlNotificationsCheckBox;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(IBAction)toggleGrowlNotifications:(id)sender{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)chooseLocalSteamAppsPath:(id)sender{
    NSOpenPanel *oPanel = [[NSOpenPanel alloc] init];
    oPanel.canChooseFiles = NO;
    oPanel.canChooseDirectories = YES;
    oPanel.canCreateDirectories = YES;
    
    NSInteger result;
    result = [oPanel runModal];
    
    if(result != NSOKButton) 
        return;
    
    else if(result == NSOKButton){
        if([oPanel.URL.lastPathComponent isEqualToString:@"SteamApps"])
            [[NSUserDefaults standardUserDefaults] setValue:oPanel.URL.path forKey:steamAppsLocalPath];
        else {
            NSURL *newPath = [[NSURL alloc] initFileURLWithPath:[oPanel.URL.path stringByDeletingLastPathComponent]];
            newPath = [newPath URLByAppendingPathComponent:@"SteamApps" isDirectory:YES];
            
            NSFileManager *fManager = [[NSFileManager alloc] init];
            NSError *renameError;
            if(![fManager moveItemAtURL:oPanel.URL toURL:newPath error:&renameError]){
                NSAlert *renameFailAlert = [NSAlert alertWithMessageText:@"Error Renaming SteamApps Folder"
                                                           defaultButton:@"OK"
                                                         alternateButton:nil
                                                             otherButton:nil
                                               informativeTextWithFormat:[renameError localizedDescription]];
                [renameFailAlert runModal];
                return;
            }
            [[NSUserDefaults standardUserDefaults] setValue:newPath.path forKey:steamAppsLocalPath];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

-(IBAction)chooseSymbolicSteamAppsPath:(id)sender{
    NSOpenPanel *oPanel = [[NSOpenPanel alloc] init];
    oPanel.canChooseDirectories = YES;
    oPanel.canCreateDirectories = YES;
    
    NSInteger result;
    result = [oPanel runModal];
    
    if(result != NSOKButton)
        return;
    
    else if(result == NSOKButton){
        if([oPanel.URL.lastPathComponent isEqualToString:@"SteamAppsSymb"])
            [[NSUserDefaults standardUserDefaults] setValue:oPanel.URL.path forKey:steamAppsSymbolicLinkPath];
        else{
            NSURL *newPath = [[NSURL alloc] initFileURLWithPath:[oPanel.URL.path stringByDeletingLastPathComponent]];
            newPath = [newPath URLByAppendingPathComponent:@"SteamAppSymb" isDirectory:YES];
            
            NSFileManager *fManager = [[NSFileManager alloc] init];
            NSError *renameError;
            if (![fManager moveItemAtURL:oPanel.URL toURL:newPath error:&renameError]) {
                NSAlert *renameFailAlert = [NSAlert alertWithMessageText:@"Error Renaming Symbolic SteamApps Folder"
                                                           defaultButton:@"OK"
                                                         alternateButton:nil
                                                             otherButton:nil
                                               informativeTextWithFormat:[renameError localizedDescription]];
                [renameFailAlert runModal];
                return;
            }
            [[NSUserDefaults standardUserDefaults] setValue:newPath.path forKey:steamAppsSymbolicLinkPath];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

-(IBAction)quitApplication:(id)sender{
    [[NSApplication sharedApplication] terminate:self];
}

-(IBAction)aboutApplication:(id)sender{
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
}

@end