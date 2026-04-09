#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <mach-o/dyld.h>
#include <limits.h>

#define OBJC_OLD_DISPATCH_PROTOTYPES 1
#define WEBVIEW_IMPLEMENTATION
#include "webview.h"
#include <string>
#include <unistd.h>

// --- Robust Path Finder ---
std::string get_executable_dir() {
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) == 0) {
        char real_path[PATH_MAX];
        if (realpath(path, real_path) != NULL) {
            std::string fullPath(real_path);
            size_t lastSlash = fullPath.find_last_of("/");
            if (lastSlash != std::string::npos) {
                return fullPath.substr(0, lastSlash);
            }
        }
    }
    return ""; // Return empty if failed
}

void force_navigation(NSString *targetUrl) {
    for (NSWindow *window in [NSApp windows]) {
        if ([[window title] containsString:@"CatBrowser"]) {
            for (NSView *subview in [[window contentView] subviews]) {
                if ([subview isKindOfClass:[WKWebView class]]) {
                    [(WKWebView *)subview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:targetUrl]]];
                    return;
                }
            }
        }
    }
}

@interface CatDelegate : NSObject <NSApplicationDelegate>
@property (copy) NSString* homeUrl;
@property (copy) NSString* aboutPath;
@end

@implementation CatDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Only try to open if the path actually exists to prevent crashes
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.aboutPath]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.aboutPath]];
    }
}
- (void)goHome:(id)sender {
    force_navigation(self.homeUrl);
}
- (void)showAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.aboutPath]];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}
@end

int main() {
    std::string exeDir = get_executable_dir();
    if (exeDir.empty()) exeDir = "."; // Safety fallback
    
    std::string homePath = "file://" + exeDir + "/cathome.html";
    
    struct webview w;
    memset(&w, 0, sizeof(w));
    
    w.title = "CatBrowser - better for your computer";
    w.width = 1200;
    w.height = 800;
    w.resizable = 1;
    w.url = homePath.c_str();

    if (webview_init(&w) != 0) return 1;

    CatDelegate *delegate = [[CatDelegate alloc] init];
    delegate.homeUrl = [NSString stringWithUTF8String:homePath.c_str()];
    delegate.aboutPath = [NSString stringWithFormat:@"%s/about.rtfd", exeDir.c_str()];
    [NSApp setDelegate:delegate];

    // Status Bar Button
    NSStatusItem *si = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [si.button setTitle:@"CAT"];
    [si.button setTarget:delegate];
    [si.button setAction:@selector(goHome:)];

    // --- CRASH PREVENTION FOR SEQUOIA ---
    // We check if the mainMenu exists and has items before accessing them
    NSMenu *mainMenu = [NSApp mainMenu];
    if (mainMenu && [mainMenu numberOfItems] > 0) {
        NSMenuItem *appMenuItem = [mainMenu itemAtIndex:0];
        if ([appMenuItem hasSubmenu]) {
            NSMenu *appMenu = [appMenuItem submenu];
            if ([appMenu numberOfItems] > 0) {
                NSMenuItem *aboutItem = [appMenu itemAtIndex:0];
                [aboutItem setTitle:@"About CatBrowser"];
                [aboutItem setTarget:delegate];
                [aboutItem setAction:@selector(showAbout:)];
            }
        }
    }

    std::string js = "window.oncontextmenu=function(e){e.preventDefault();"
                     "var c=prompt('1:HOME, 2:GOOGLE, 3:OIIA, 4:BACK');"
                     "if(c=='1')location.href='"+homePath+"';"
                     "if(c=='2')location.href='https://google.com';"
                     "if(c=='3')location.href='https://www.youtube.com/watch?v=r7-K-Z_H0mU';"
                     "if(c=='4')history.back();};";
    webview_eval(&w, js.c_str());

    [NSApp run];
    webview_exit(&w);
    return 0;
}