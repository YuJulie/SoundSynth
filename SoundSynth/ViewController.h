//
//  ViewController.h
//  SoundSynth
//
//  Created by Julie Borgeot on 7/7/14.
//  Copyright (c) 2014 Julie Borgeot. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "METScopeView.h"    // Jeff Gregorio's scope view
#import "AudioOutput.h"     // Matt(s) old code from AcousticsAnalysis

#define kScopeUpdateRate 0.003
#define kFFTSize         1024

@interface ViewController : UIViewController{
    
    //uncategorized stuff
    float baseFrequency;

    //// Buffer
    float *audioBuffer;
    
    //// Audio
    /* Output */
    AudioOutput *audioOut;
    int   bufferLength;
    float bufferIndex;
    float thetaIncrement;
    float theta;
    
    /* FFT */
    
    //// ScopeViews
    IBOutlet METScopeView *timeDomainScopeView;
    IBOutlet METScopeView *frequencyDomainScopeView;
    
    
    //// Gesture recognizers
    
    bool tdHold, fdHold;
    
    /* Pinch zoom controls */
    UIPinchGestureRecognizer *timeViewPinchRecognizer;
    UIPinchGestureRecognizer *frequencyViewPinchRecognizer;
    CGFloat timeViewPreviousPinchScale;
    CGFloat frequencyViewPreviousPinchScale;
    
    /* Panning controls */
    UIPanGestureRecognizer *timeViewPanRecognizer;
    UIPanGestureRecognizer *frequencyViewPanRecognizer;
    CGPoint timeViewPreviousPanLoc;
    CGPoint frequencyViewPreviousPanLoc;
    
    /* Tap recognizer for pausing recording */
    UITapGestureRecognizer *timeViewTapRecognizer;
    
    
    //// Sliders for harmonics
    int numberOfSliders;
    NSMutableArray *sliderAmplitudes;
    NSMutableArray *sliders;
    NSMutableArray *harmonicLabels;
    
    
    bool paused;

    //// Fundamental frequency UI
    IBOutlet UISlider *frequencySlider;
    IBOutlet UILabel  *fundamentalFrequencyLabel;
    
    //// One button to play or stop the sound
    IBOutlet UIButton *playStopButton;
    
}


- (IBAction)playStopSound:(id)sender;

@end
