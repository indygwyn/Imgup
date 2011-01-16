// Copyright (c) 2010, Nate Stedman <natesm@gmail.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#import <Carbon/Carbon.h>
#import "IUDropView.h"
#import "IUAppDelegate.h"
#import "IUUpload.h"

#define RECENT_COUNT 10

@implementation IUDropView

@synthesize item;
@synthesize uploads;

-(id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:NSMakeRect(0, 0, SIZE, SIZE)];
    if (self) {
        [self registerForDraggedTypes:
         [NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        
        uploads = [[NSOperationQueue alloc] init];
        [uploads setMaxConcurrentOperationCount:1];
        
        fileTypes = [[NSArray arrayWithObjects:@".png",
                                               @".jpg",
                                               @".jpeg",
                                               @".gif",
                                               @".apng",
                                               @".tiff",
                                               @".bmp",
                                               @".pdf",
                                               @".xcf",
                                               nil] retain];
    }
    return self;
}

-(void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"MenuBarIcon"]] set];
    [NSBezierPath fillRect:[self frame]];
}

-(void)mouseDown:(NSEvent *)theEvent {
    // create the recent uploads menu
    NSArray* history = [[NSApp delegate] history];
    if ([history count] == 0) {
        [[[NSApp delegate] recentUploads] setEnabled:NO];
    }
    else {
        [[[NSApp delegate] recentUploads] setEnabled:YES];
        
        NSMenu* menu = [[NSMenu alloc] init];
        for (int i = 0; i < RECENT_COUNT && i < [history count]; i++) {
            NSMenuItem* menuItem = [[NSMenuItem alloc] init];
            [menuItem setTitle:[[history objectAtIndex:i]
                                valueForKey:FILE_KEY]];
            [menuItem setImage:[[NSImage alloc]
                                initWithContentsOfFile:[[NSApp delegate]
                                                        imagePath:[menuItem
                                                                   title]]]];
            [menuItem setTarget:self];
            [menuItem setAction:@selector(onRecent:)];
            [menu addItem:menuItem];
        }
        
        [[[NSApp delegate] recentUploads] setSubmenu:menu];
    }

    [item popUpStatusItemMenu:[item menu]];
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *paste = [sender draggingPasteboard];
    
    if (![[paste types] containsObject:NSFilenamesPboardType]) {
        return NSDragOperationNone;
    }
    
    // we need at least one image file to continue (non-images will be ignored)
    NSArray* files = [paste propertyListForType:NSFilenamesPboardType];
    for (NSString* file in files) {
        NSString* down = [file lowercaseString];
        for (NSString* fileType in fileTypes) {
            if ([down hasSuffix:fileType]) {
                return NSDragOperationCopy;
            }
        }
    }
    
    return NSDragOperationNone;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *paste = [sender draggingPasteboard];
    NSArray* files = [paste propertyListForType:NSFilenamesPboardType];
    NSMutableArray* images = [[NSMutableArray alloc]
                              initWithCapacity:[files count]];
    
    // find the image files
    for (NSString* file in files) {
        NSString* down = [file lowercaseString];
        for (NSString* fileType in fileTypes) {
            if ([down hasSuffix:fileType]) {
                [images addObject:file];
            }
        }
    }
    
    // we need at least one image file to continue
    return [images count] > 0;
}

-(void)onRecent:(NSMenuItem*)sender {
    NSArray* history = [[NSApp delegate] history];
    for (NSDictionary* dict in history) {
        if ([[dict valueForKey:FILE_KEY] isEqualToString:[sender title]]) {
            [[NSWorkspace sharedWorkspace]
             openURL:[NSURL URLWithString:[dict valueForKey:URL_KEY]]];
            return;
        }
    }
}

@end

bool commandDown() {
    CGEventSourceStateID eventSource = kCGEventSourceStateCombinedSessionState;
    return CGEventSourceKeyState(eventSource, kVK_Command);
}
