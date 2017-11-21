//
//  ViewController.m
//  recorder
//
//  Created by wangyang on 2017/11/21.
//  Copyright © 2017年 wangyang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

typedef struct MyRecorder {
    AudioFileID audioFile;
    SInt64     packetPosition;
    
    AudioQueueRef audioQueue;
    BOOL isRuning;
    
}MyRecorder;

#define KBUFFERNUMS 3
static UInt32 bufferSize = 32768;

@interface ViewController ()

@property (nonatomic, assign) MyRecorder recorder;

@end

@implementation ViewController


void audioQueueInputCallback(
                                void * __nullable               inUserData,
                                AudioQueueRef                   inAQ,
                                AudioQueueBufferRef             inBuffer,
                                const AudioTimeStamp *          inStartTime,
                                UInt32                          inNumberPacketDescriptions,
                                const AudioStreamPacketDescription * __nullable inPacketDescs)
{
    MyRecorder *recorder = (MyRecorder *)inUserData;
    
    if (inNumberPacketDescriptions) {
        AudioFileWritePackets(recorder->audioFile, false, inBuffer->mAudioDataByteSize, inPacketDescs, recorder->packetPosition, &inNumberPacketDescriptions, inBuffer->mAudioData);
        recorder->packetPosition += inNumberPacketDescriptions;
    }
    
    if (recorder->isRuning) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)start:(id)sender {
    AudioStreamBasicDescription inFormat;
    memset(&inFormat, 0, sizeof(inFormat));
    
    inFormat.mFormatID = kAudioFormatLinearPCM;
    inFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked|kAudioFormatFlagIsBigEndian;
    inFormat.mSampleRate = 8000;
    inFormat.mChannelsPerFrame = 1;
    inFormat.mBytesPerFrame = 2;
    inFormat.mBytesPerPacket = 2;
    inFormat.mBitsPerChannel = 16;
    inFormat.mFramesPerPacket = 1;
    
    memset(&_recorder, 0, sizeof(_recorder));
    
    OSStatus err = noErr;
    
    err = AudioQueueNewInput(&inFormat, audioQueueInputCallback, &_recorder, NULL, NULL, 0, &_recorder.audioQueue);
    NSAssert(err == noErr, @"audio queue new input failed!");
    
    NSString *outPath = @"/Users/Descore/Desktop/out.caf";
    NSURL *OUTURL = [NSURL URLWithString:outPath];
    err = AudioFileCreateWithURL((__bridge CFURLRef)OUTURL, kAudioFileCAFType, &inFormat, kAudioFileFlags_EraseFile, &_recorder.audioFile);
    NSAssert(err == noErr, @"audio file create failed!");
    
    for (int i = 0; i < KBUFFERNUMS; i++) {
        AudioQueueBufferRef aqBufferRef;
        AudioQueueAllocateBuffer(_recorder.audioQueue, bufferSize, &aqBufferRef);
        AudioQueueEnqueueBuffer(_recorder.audioQueue, aqBufferRef, 0, NULL);
    }
    
    _recorder.isRuning = true;
    
    err = AudioQueueStart(_recorder.audioQueue, NULL);
    NSAssert(err == noErr, @"audio queue start  failed");
    
    NSLog(@"开始录音");
}

- (IBAction)end:(id)sender {
    
    _recorder.isRuning = false;
    AudioQueueStop(_recorder.audioQueue, true);
    AudioFileClose(_recorder.audioFile);
    AudioQueueDispose(_recorder.audioQueue, true);
    
    NSLog(@"录音结束");
}

@end
