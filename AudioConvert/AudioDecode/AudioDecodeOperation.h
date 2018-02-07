//
//  AudioDecodeOperation.h
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioDefine.h"

@interface AudioDecodeOperation : NSOperation

/**
  参数:
 -spath   输入的原音频路径
 -opath   输出的音频路径
 -slr     输出的采样率(soundTouch 变声处理的 使用的采样率 目的 速度快)
 -ch      输出文件的通道数
 return   解码音频源
 */
- (id)initWithSourcePath:(NSString *)spath
         audioOutputPath:(NSString *)opath
        outputSampleRate:(Float64)slr
           outputChannel:(int)ch
          callBackTarget:(id)target
            callFunction:(SEL)action;
@end


