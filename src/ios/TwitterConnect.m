#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import "TwitterConnect.h"
// #import <Fabric/Fabric.h>
#import <TwitterKit/TWTRKit.h>
// #import "ListTimelineViewController.h"

@implementation TwitterConnect

- (void)pluginInitialize
{
    NSString* consumerKey = [self.commandDelegate.settings objectForKey:[@"TwitterConsumerKey" lowercaseString]];
    NSString* consumerSecret = [self.commandDelegate.settings objectForKey:[@"TwitterConsumerSecret" lowercaseString]];
    [[Twitter sharedInstance] startWithConsumerKey:consumerKey consumerSecret:consumerSecret];
    // [Fabric with:@[[Twitter sharedInstance]]];
    
    // [Fabric with:@[TwitterKit]];
}

BOOL authNotResolved = true;

- (void)login:(CDVInvokedUrlCommand*)command
{
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
		__block CDVPluginResult* pluginResult = nil;
		if (session){
            TWTRAPIClient *client = [TWTRAPIClient clientWithCurrentUser];

            [client requestEmailForCurrentUser:^(NSString *email, NSError *error) {
                NSString *requestedEmail = (email) ? email : @"";
                
                [client loadUserWithID:[session userID] completion:^(TWTRUser *user,
                                                                       NSError *error)
                {
                    // handle the response or error
                    if (![error isEqual:nil]) {
                        NSLog(@"signed in as %@", [session userName]);
                        NSString *urlString = [[NSString alloc]initWithString:user.profileImageLargeURL];
                        NSURL *url = [[NSURL alloc]initWithString:urlString];
                        
                        NSDictionary *body = @{@"authToken": session.authToken,
                                               @"authTokenSecret": session.authTokenSecret,
                                               @"userID": session.userID,
                                               @"email": requestedEmail,
                                               @"userName": session.userName,
                                               @"profileImage": url};

                        if(authNotResolved) {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:body];
                            authNotResolved = false;
                        }
                    } else {
                        NSLog(@"Twitter error getting profile : %@", [error localizedDescription]);
                    }
                }];
            }];
		} else {
			NSLog(@"error: %@", [error localizedDescription]);
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}];
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    TWTRSessionStore *store = [[Twitter sharedInstance] sessionStore];
    NSString *userID = store.session.userID;
    [store logOutUserID:userID];
	CDVPluginResult* pluginResult = pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end

#pragma mark - AppDelegate Overrides

@implementation AppDelegate (TwitterConnect)
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    NSLog(@"Twitter handle url using application:openURL:options:: %@", url);
  return [[Twitter sharedInstance] application:app openURL:url options:options];
}
@end
