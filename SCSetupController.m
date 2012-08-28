//
//  SCSetupController.m
//  SymSteam
//
//  Created by Alex Jackson on 25/08/2012.
//
//

#import "SCSetupController.h"

@implementation SCSetupController

- (DADiskRef)createDADiskFromDrivePath:(NSURL *)drive{
    DASessionRef session = DASessionCreate(kCFAllocatorDefault);
    DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, (__bridge CFURLRef)drive);
    CFRelease(session);
    return disk;
}

- (BOOL)driveFilesystemIsHFS:(DADiskRef)drive{
    CFDictionaryRef driveDetails = DADiskCopyDescription(drive);
    NSString *driveFileSystem = (__bridge NSString *)CFDictionaryGetValue(driveDetails, kDADiskDescriptionVolumeKindKey);
    CFRelease(driveDetails);
    
    if([driveFileSystem isEqualToString:@"hfs"])
        return YES;
    else
        return NO;
}

- (BOOL)folderIsOnExternalDrive:(NSURL *)pathToFolder{
    return (pathToFolder.pathComponents.count >= 3 && [pathToFolder.pathComponents[1] isEqualToString:@"Volumes"]);
}

- (BOOL)verifyProvidedFolderIsUsable:(NSURL *)folder{
    if(![self folderIsOnExternalDrive:folder]){
        NSAlert *invalidDestinationAlert = [NSAlert alertWithMessageText:@"Error"
                                                           defaultButton:@"OK"
                                                         alternateButton:nil
                                                             otherButton:nil
                                               informativeTextWithFormat:@"The folder you provided is not on an external drive."];
        if([NSApp mainWindow])
            [invalidDestinationAlert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        else
            [invalidDestinationAlert runModal];
        return NO;
    }
    
    DADiskRef drive = [self createDADiskFromDrivePath:[self getDrivePathFromFolderPath:folder]];
    if([self getDriveUUID:drive] == NULL){
        NSAlert *noUUIDFound = [NSAlert alertWithMessageText:@"Error"
                                               defaultButton:@"OK"
                                             alternateButton:nil
                                                 otherButton:nil
                                   informativeTextWithFormat:@"The drive which the SteamApps folder is on does not have a UUID. Please ensure that the drive is HFS formatted."];
        if([NSApp mainWindow])
            [noUUIDFound beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        else
            [noUUIDFound runModal];
        CFRelease(drive);
        return NO;
    }
    CFRelease(drive);
    return YES;
}

- (NSString *)getDriveUUID:(DADiskRef)drive{
    CFDictionaryRef driveDetails = DADiskCopyDescription(drive);
    
    if(CFDictionaryGetValue(driveDetails, kDADiskDescriptionVolumeUUIDKey) == NULL){
        CFRelease(driveDetails);
        return nil;
    }
    else{
        NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, CFDictionaryGetValue(driveDetails, kDADiskDescriptionVolumeUUIDKey));
        CFRelease(driveDetails);
        return uuid;
    }
}

- (NSURL *)getDrivePathFromFolderPath:(NSURL *)folderPath{
    if(folderPath == nil){
        NSLog(@"getDrivePathFromFolderPath: The provided folderPath was nil");
        return nil;
    }
    if(folderPath.pathComponents.count < 3){
        NSLog(@"getDrivePathFromFolderPath: The provided folderPath was too short to create a drive path");
        return nil;
    }
    return [NSURL fileURLWithPathComponents:(@[folderPath.pathComponents[0], folderPath.pathComponents[1], folderPath.pathComponents[2]])];
}

- (BOOL)createSymbolicLinkToFolder:(NSURL *)folder{ // Creates a symbolic link at /Application Support/Steam/SteamAppsSymb
    NSFileManager *fManager = [[NSFileManager alloc] init];
    
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDirectory, YES);
    NSString *symbolicLinkPath;
    if(![[SCSteamDiskManager steamDiskManager] steamDriveIsConnected])
        symbolicLinkPath = [[directories[0] stringByAppendingPathComponent:@"Steam"]  stringByAppendingPathComponent:@"SteamAppsSymb"];
    else
        symbolicLinkPath = [[directories[0] stringByAppendingPathComponent:@"Steam"]  stringByAppendingPathComponent:@"SteamApps"];
    
    if([fManager attributesOfItemAtPath:symbolicLinkPath error:nil] && [[fManager attributesOfItemAtPath:symbolicLinkPath error:nil] fileType] == NSFileTypeSymbolicLink){
        NSAlert *alert = [NSAlert alertWithMessageText:@"A Symbolic Link Already Exists!"
                                         defaultButton:@"Yes"
                                       alternateButton:@"No"
                                           otherButton:nil
                             informativeTextWithFormat:@"Can I delete it? I can't procede with setup while it's there."];
        if([alert runModal] == NSAlertDefaultReturn)
            [fManager removeItemAtPath:symbolicLinkPath error:nil];
        else{
            NSLog(@"There was a symbolic link already present at %@ and the user wouldn't let me remove it.", symbolicLinkPath);
            return NO;
        }
    }
    
    NSError *symbolicLinkCreationError;
    if([fManager createSymbolicLinkAtPath:symbolicLinkPath withDestinationPath:folder.path error:&symbolicLinkCreationError]){
        return YES;
    }
    else{
        NSLog(@"Unabled to create symbolic link to %@ because %@", folder.path, symbolicLinkCreationError.localizedDescription);
        return NO;
    }
}

- (void)saveSymbolicLinkDestinationToUserDefaults:(NSURL *)destination{
    [[NSUserDefaults standardUserDefaults] setValue:destination.path forKey:@"symbolicPathDestination"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveDriveUUIDToUserDefaults:(DADiskRef)drive{
    NSString *uuid = [self getDriveUUID:drive];
    if(uuid){
        [[NSUserDefaults standardUserDefaults] setValue:uuid forKey:@"steamDriveUUID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else{
        NSLog(@"Could not save the drive's UUID to the user defaults because the UUID returned by getDriveUUID: was nil");
    }
}

- (void)markSetupAsComplete{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"setupComplete"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end