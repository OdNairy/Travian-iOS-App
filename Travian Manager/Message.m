//
//  Message.m
//  Travian Manager
//
//  Created by Matej Kramny on 27/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Message.h"
#import "AppDelegate.h"
#import "Storage.h"
#import "Account.h"
#import "HTMLParser.h"
#import "HTMLNode.h"
#import "TPIdentifier.h"
#import "NSString+HTML.h"

@interface Message () {
	NSString *tempRecipient; // Temporary recipient holder while sendParameter is being retrieved
}

@end

@implementation Message

@synthesize sender, title, content, href, when, read, accessID, sendParameter, sent;

- (void)parsePage:(TravianPages)page fromHTMLNode:(HTMLNode *)node {
	// TODO test this
	HTMLNode *divMessage = [node findChildWithAttribute:@"id" matchingName:@"message" allowPartial:NO];
	if (!divMessage) {
		NSLog(@"No div#message present");
		return;
	}
	
	NSString *raw = [[divMessage rawContents] substringFromIndex:[@"<div id=\"message\">" length]];
	raw = [[[[[raw substringToIndex:[raw length]-6] stringByReplacingOccurrencesOfString:@"\r\n" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"] stringByDecodingHTMLEntities];
	
	[self setContent:raw];
}

- (void)parseSendParameter:(HTMLNode *)node {
	HTMLNode *idSend = [node findChildWithAttribute:@"id" matchingName:@"send" allowPartial:NO];
	if (idSend) {
		HTMLNode *input = [idSend findChildTag:@"input"];
		[self setSendParameter:[input getAttributeNamed:@"value"]];
	}
}

- (void)downloadAndParse {
	Account *account = [[(AppDelegate *)[UIApplication sharedApplication].delegate storage] account];
	
	NSString *url = [NSString stringWithFormat:@"http://%@.travian.%@/%@", account.world, account.server, href];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:60];
	[request setHTTPShouldHandleCookies:YES];
	
	messageConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)delete {
	Account *account = [[(AppDelegate *)[UIApplication sharedApplication].delegate storage] account];
	
	NSString *data = [NSString stringWithFormat:@"delmsg=Delete&s=0&n1=%@", accessID];
	
	NSData *myRequestData = [NSData dataWithBytes: [data UTF8String] length: [data length]];
	NSString *stringUrl = [NSString stringWithFormat:@"http://%@.travian.%@/nachrichten.php", [account world], [account server]];
	NSURL *url = [NSURL URLWithString: stringUrl];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:60];
	
	// Set POST HTTP Headers if necessary
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody: myRequestData];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	
	// Preserve any cookies received
	[request setHTTPShouldHandleCookies:YES];
	
	@autoreleasepool {
		NSURLConnection *c __unused = [[NSURLConnection alloc] initWithRequest:request delegate:nil startImmediately:YES];
	}
}

- (void)send:(NSString *)recipient {
	Account *account = [[(AppDelegate *)[UIApplication sharedApplication].delegate storage] account];
	[self setSent:NO];
	
	if (!sendParameter) {
		// Retrieve it
		NSString *url = [NSString stringWithFormat:@"http://%@.travian.%@/nachrichten.php?t=1", account.world, account.server];
		NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
		[req setHTTPShouldHandleCookies:YES];
		sendParameterConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
		
		tempRecipient = recipient;
		[self addObserver:self forKeyPath:@"sendParameter" options:NSKeyValueObservingOptionNew context:nil];
		
		return;
	}
	
	NSString *url = [NSString stringWithFormat:@"http://%@.travian.%@/nachrichten.php", account.world, account.server];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:60];
	
	NSString *postData = [[NSString alloc] initWithFormat:@"an=%@&be=%@&message=%@&s1=send&c=%@", recipient, title, content, sendParameter];
	NSData *myRequestData = [NSData dataWithBytes: [postData UTF8String] length: [postData length]];
	
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody: myRequestData];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	
	// Preserve any cookies received
	[request setHTTPShouldHandleCookies:YES];
	
	NSURLConnection *conn __unused = [[NSURLConnection alloc] initWithRequest:request delegate:nil startImmediately:YES];
	
	[self setSent:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"sendParameter"]) {
		if ([change objectForKey:NSKeyValueChangeNewKey] != nil) {
			[self removeObserver:self forKeyPath:@"sendParameter"];
			[self send:tempRecipient];
		}
	}
}

#pragma mark - NSCoder

- (id)initWithCoder:(NSCoder *)aDecoder {
	title = [aDecoder decodeObjectForKey:@"title"];
	content = [aDecoder decodeObjectForKey:@"content"];
	href = [aDecoder decodeObjectForKey:@"href"];
	when = [aDecoder decodeObjectForKey:@"when"];
	NSNumber *n = [aDecoder decodeObjectForKey:@"read"];
	read = [n boolValue];
	accessID = [aDecoder decodeObjectForKey:@"accessID"];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:title forKey:@"title"];
	[aCoder encodeObject:content forKey:@"content"];
	[aCoder encodeObject:href forKey:@"href"];
	[aCoder encodeObject:when forKey:@"when"];
	[aCoder encodeObject:[NSNumber numberWithBool:read] forKey:@"read"];
	[aCoder encodeObject:accessID forKey:@"accessID"];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {  }
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection	{	return NO;	}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error { NSLog(@"Report Connection failed %@ - %@ - %@ - %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoveryOptions], [error localizedRecoverySuggestion]); }

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (connection == messageConnection)
		[messageData appendData:data];
	else if (connection == sendParameterConnection)
		[sendParameterData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	if (connection == messageConnection)
		messageData = [[NSMutableData alloc] initWithLength:0];
	else if (connection == sendParameterConnection)
		sendParameterData = [[NSMutableData alloc] initWithLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// Parse data
	if (connection == messageConnection || connection == sendParameterConnection)
	{
		NSError *error;
		NSData *data;
		
		if (connection == messageConnection)
			data = messageData;
		else if (connection == sendParameterConnection)
			data = sendParameterData;
		
		HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];
		HTMLNode *body = [parser body];
		
		if (!parser) {
			NSLog(@"Cannot parse message data. Reason: %@, recovery options: %@", [error localizedDescription], [error localizedRecoveryOptions]);
			return;
		}
		
		TravianPages travianPage = [TPIdentifier identifyPage:body];
		
		if (connection == messageConnection)
			[self parsePage:travianPage fromHTMLNode:body];
		else if (connection == sendParameterConnection)
			[self parseSendParameter:body];
	}
}

@end
