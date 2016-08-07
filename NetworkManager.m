//
//  NetworkManager.m
//  GenesisPlus
//
//  Created by Alistair Aitcheson on 05/08/2016.
//  Copyright 2016 __MyCompanyName__. All rights reserved.
//

#import "NetworkManager.h"

@implementation NetworkManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"init NetworkManager");
        self.cachedMessages = [NSMutableArray array];
        [self initNetworkCommunication];
        
//        FILE *testDoc = fopen([[[GenPlusGameCore PathString] stringByAppendingString:@"NETWORK_START.txt"] UTF8String], "w");
//        fclose(testDoc);
    }
    return self;
}

- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSDictionary *params = nil;
    NSString *host = (params[@"ip"])? params[@"ip"] : @"192.168.0.4";
    NSString *port = (params[@"port"])? params[@"port"] : @"3000";
    NSLog([NSString stringWithFormat:@"Connecting to host: %@, on port: %@", host, port]);

    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, [port intValue], &readStream, &writeStream);
    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream open];
    [self.outputStream open];
    
    NSLog(@"streams opened!");
}

-(void)SendMessage:(NSString*)message WithHeader:(NSString*)header
{
    NSString *response  = [NSString stringWithFormat:@"%@>%@", header, message];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [self.outputStream write:[data bytes] maxLength:[data length]];
    
    NSLog([NSString stringWithFormat:@"Sent network msg: %@", response]);
    NSLog([NSString stringWithFormat:@"Input stream state: %@", self.inputStream]);
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    NSLog([NSString stringWithFormat:@"(%@) stream event %i", (theStream == self.inputStream)? @"input" : (theStream == self.outputStream) ? @"output" : @"?", (uint)streamEvent]);
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"NSStreamEventHasBytesAvailable");
            if (theStream == self.inputStream)
            {
                uint8_t buffer[1024];
                int len;
                
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSString *logMsg = [NSString stringWithFormat:@"received from server: %@  -->  cache size: %i", output, [self.cachedMessages count]];
                            NSLog(logMsg);
                            [self.cachedMessages addObject:output];
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            break;
            
        default:
            NSLog(@"Unknown event");
    }
}

-(NSArray*)GetCachedMessages
{
    return self.cachedMessages;
}

-(void)ClearCachedMessages
{
    [self.cachedMessages removeAllObjects];
}


@end
