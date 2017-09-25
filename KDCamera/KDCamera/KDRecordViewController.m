//
//  KDRecordViewController.m
//  KDCamera
//
//  Created by qihan02 on 2017/9/18.
//  Copyright © 2017年 kd666. All rights reserved.
//

#import "KDRecordViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface KDRecordViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic,strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic,strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewlayer;
@property (nonatomic,strong) AVCaptureConnection *videoConnection;
@property (nonatomic,strong) AVCaptureConnection *audioConnection;
@property (nonatomic,strong) AVAssetWriter *assetWriter;
@property (nonatomic,strong) AVAssetWriterInput *videoWriteInput;
@property (nonatomic,strong) AVAssetWriterInput *audioWriteInput;
@property (nonatomic,assign) CMFormatDescriptionRef videoFormat;
@property (nonatomic,assign) CMFormatDescriptionRef audioFormat;
@property (nonatomic,strong) NSDictionary *videoComproessionSetting;
@property (nonatomic,strong) NSDictionary *audioComproessionSetting;
@end

@implementation KDRecordViewController


- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        }
    }
    return _captureSession;
}

- (AVCaptureDevice *)kd_getCameraWithPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *currentCamera = nil;
    currentCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
    return currentCamera;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AVCaptureDevice *camera = [self kd_getCameraWithPosition:AVCaptureDevicePositionBack];
    AVCaptureDevice *audio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *videoError = nil;
    AVCaptureDeviceInput *cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&videoError];
    if (videoError) {
        NSLog(@"cameraInput error");
    }
    NSError *audioError = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audio error:&audioError];
    if (audioError) {
        NSLog(@"audioInput error");
    }
    if ([self.captureSession canAddInput:cameraInput]) {
        [self.captureSession addInput:cameraInput];
    }else{
        NSLog(@"add cameraInput failed");
    }
    if ([self.captureSession canAddInput:audioInput]) {
        [self.captureSession addInput:audioInput];
    }else{
        NSLog(@"add audioInput failed");
    }
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t sessionQueue = dispatch_queue_create("com.kidil.niubi", nil);
    [videoOutput setSampleBufferDelegate:self queue:sessionQueue];
    self.videoOutput = videoOutput;
    
    if ([_captureSession canAddOutput:videoOutput]) {
        [_captureSession addOutput:videoOutput];
    }else{
        NSLog(@"add videoOutPut failed");
    }
    
    self.videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:sessionQueue];
    self.audioOutput = audioOutput;
    
    if ([_captureSession canAddOutput:audioOutput]) {
        [_captureSession addOutput:audioOutput];
    }else{
        NSLog(@"audioOutput add failed");
    }
    
    self.audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    self.previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.previewlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewlayer];

    [self.captureSession startRunning];
    
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(30, 30, 30, 30);
    closeButton.backgroundColor = [UIColor redColor];
    [closeButton addTarget:self action:@selector(closeClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];

    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"recordVideo"];
    NSLog(@"ddd -- %@",savePath);
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL URLWithString:savePath] fileType:AVFileTypeQuickTimeMovie error:nil];
    
    
    self.audioComproessionSetting = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
    
    
    NSInteger numPixels = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height;
    
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    self.videoComproessionSetting = @{ AVVideoCodecKey : AVVideoCodecH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @([UIScreen mainScreen].bounds.size.height),
                                       AVVideoHeightKey : @([UIScreen mainScreen].bounds.size.width),
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (captureOutput == self.videoOutput) {
        NSLog(@"this is a vedioBuffer");
        if (!self.videoFormat) {
            self.videoFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
        }
    }else if (captureOutput == self.audioOutput){
        NSLog(@"this is a audioBuffer");
        if (!self.audioFormat) {
            self.audioFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
        }
    }else{
        NSLog(@"nothing");
    }
}

- (void)closeClick
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"%s delloc",__FILE__);
}


@end
