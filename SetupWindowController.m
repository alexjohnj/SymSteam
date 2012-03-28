//
//  SetupWindowController.m
//  SymSteam
//
//  Created by Alex Jackson on 03/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SetupWindowController.h"

@implementation SetupWindowController
@synthesize pathToSymLinkField, pathToNonSymLinkField, continueButton;
@synthesize symLinkPathProvided, nonSymLinkPathProvided, formComplete;

static NSString * const steamAppsSymbolicLinkPath = @"steamAppsSymbolicLinkPath";
static NSString * const steamAppsLocalPath = @"steamAppsLocalPath";
static NSString * const setupComplete = @"setupComplete";

#pragma mark - Window Lifecycle methods

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        symLinkPathProvided = NO;
        nonSymLinkPathProvided = NO;
        formComplete = NO;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSLog(@"Loaded");
}

#pragma mark - UI Code

-(IBAction)choosePathToSymLink:(id)sender{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.resolvesAliases = NO;
    
    NSArray *libArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    openPanel.directoryURL = [NSURL fileURLWithPath:[libArray objectAtIndex:0]];
    
    NSInteger result = [openPanel runModal];
    if(result == NSOKButton){
        self.pathToSymLinkField.stringValue = openPanel.URL.path;
        self.symLinkPathProvided = YES;
        [self checkPathsProvided];
    }
    
    else{
        if(self.symLinkPathProvided == YES)
            self.symLinkPathProvided = NO;
        [self checkPathsProvided];
    }
}
-(IBAction)choosePathToNonSymLink:(id)sender{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    
    NSArray *libArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    openPanel.directoryURL = [NSURL fileURLWithPath:[libArray objectAtIndex:0]];
    
    NSInteger result = [openPanel runModal];
    if(result == NSOKButton){
        self.pathToNonSymLinkField.stringValue = openPanel.URL.path;
        self.nonSymLinkPathProvided = YES;
        [self checkPathsProvided];
    }
    else{
        if(self.nonSymLinkPathProvided == YES)
            self.nonSymLinkPathProvided = NO;
        [self checkPathsProvided];
    }
}

-(IBAction)doneButtonPressed:(id)sender{
    NSString *providedLocalPath = [[NSString alloc] initWithString:self.pathToNonSymLinkField.stringValue];
    NSString *providedLocalSymbolicPath = [[NSString alloc] initWithString:self.pathToSymLinkField.stringValue];
    NSFileManager *fManager = [[NSFileManager alloc] init];
    
    NSString *finalLocalPath = [[NSString alloc] init];
    NSString *finalSymbolicPath = [[NSString alloc] init];
    
    if(![providedLocalPath.lastPathComponent isEqualToString:@"SteamApps"]){
        NSError *moveLocalFolderError;
        
        NSURL *newLocalPath = [[NSURL alloc] initFileURLWithPath:providedLocalPath isDirectory:YES];
        newLocalPath = [newLocalPath URLByDeletingLastPathComponent];
        newLocalPath = [newLocalPath URLByAppendingPathComponent:@"SteamApps" isDirectory:YES];
        
        if(![fManager moveItemAtPath:providedLocalPath toPath:newLocalPath.path error:&moveLocalFolderError]){
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error Renaming SteamApps Folder" defaultButton:@"Choose New Path" alternateButton:@"Quit" otherButton:nil informativeTextWithFormat:[moveLocalFolderError localizedDescription]];
            NSInteger result = [alert runModal];
            if(result != NSOKButton)
                [[NSApplication sharedApplication] terminate:self];
        }
        finalLocalPath = newLocalPath.path;
    }
    
    else{
        finalLocalPath = providedLocalPath;
    }
    
    if(![providedLocalSymbolicPath.lastPathComponent isEqualToString:@"SteamAppsSymb"]){
        NSURL *newSymbPath = [[NSURL alloc] initFileURLWithPath:providedLocalSymbolicPath isDirectory:YES];
        newSymbPath = [newSymbPath URLByDeletingLastPathComponent];
        newSymbPath = [newSymbPath URLByAppendingPathComponent:@"SteamAppsSymb"];
        
        NSError *renameSymbolicFolderError;
        if (![fManager moveItemAtPath:providedLocalSymbolicPath toPath:newSymbPath.path error:&renameSymbolicFolderError]) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error Renaming SteamApps Symbolic Folder" defaultButton:@"Choose New Path" alternateButton:@"Quit" otherButton:nil informativeTextWithFormat:[renameSymbolicFolderError localizedDescription]];
            NSInteger result = [alert runModal];
            if(result != NSOKButton)
                [[NSApplication sharedApplication] terminate:self];
        }
        finalSymbolicPath = newSymbPath.path;  
    }
    else{
        finalSymbolicPath = providedLocalSymbolicPath;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:finalLocalPath forKey:steamAppsLocalPath];
    [[NSUserDefaults standardUserDefaults] setValue:finalSymbolicPath forKey:steamAppsSymbolicLinkPath];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:setupComplete];
    
    NSAlert *successAlert = [NSAlert alertWithMessageText:@"Success!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Successfully setup SymSteam"];
    NSInteger result = [successAlert runModal];
    if(result == NSOKButton)
        [self close];
}

-(void)checkPathsProvided{
    if(self.symLinkPathProvided == YES && self.nonSymLinkPathProvided == YES)
        self.formComplete = YES;
    
    else
        self.formComplete = NO;
}
@end