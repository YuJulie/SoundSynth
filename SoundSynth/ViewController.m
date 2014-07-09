//
//  ViewController.m
//  SoundSynth
//
//  Created by Julie Borgeot on 7/7/14.
//  Copyright (c) 2014 Julie Borgeot. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

float randomFloat(float Min, float Max){
    return ((arc4random()%RAND_MAX)/(RAND_MAX*1.0))*(Max-Min)+Min;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"We are in ViewDidLoad");

    [[self view] setBackgroundColor:[UIColor whiteColor]];
	// Do any additional setup after loading the view, typically from a nib.
    
    /* ----------------- */
    /* == Audio Setup == */
    /* ----------------- */
    audioOut = [[AudioOutput alloc] initWithDelegate:self];
    audioBuffer = (float*)calloc(bufferLength, sizeof(float));
    
    
    
    /* ----------------------------------------------------- */
    /* == Setup for time and frequency domain scope views == */
    /* ----------------------------------------------------- */
    NSLog(@"Initializing the timedomainView...");
    [timeDomainScopeView setPlotResolution:456];
    [timeDomainScopeView setHardXLim:-0.00001 max:1.0];
    [timeDomainScopeView setVisibleXLim:-0.00001 max:1.0];
    [timeDomainScopeView setPlotUnitsPerXTick:0.005];
    [timeDomainScopeView setMinPlotRange:CGPointMake(0.0001, 0.1)];
    [timeDomainScopeView setMaxPlotRange:CGPointMake(0.0001, 2.0)];
    [timeDomainScopeView setXGridAutoScale:true];
    [timeDomainScopeView setYGridAutoScale:true];
    [timeDomainScopeView setXPinchZoomEnabled:false];
    [timeDomainScopeView setYPinchZoomEnabled:false];
    [timeDomainScopeView setXLabelPosition:kMETScopeViewXLabelsOutsideAbove];
    [timeDomainScopeView setYLabelPosition:kMETScopeViewYLabelsOutsideLeft];
    [timeDomainScopeView addPlotWithColor:[UIColor blueColor] lineWidth:2.0];
    NSLog(@"...Initialized");
    
    NSLog(@"Initializing the frequencyDomainView...");
    [frequencyDomainScopeView setPlotResolution:456];
    [frequencyDomainScopeView setUpFFTWithSize:kFFTSize];
    [frequencyDomainScopeView setDisplayMode:kMETScopeViewFrequencyDomainMode];
    [frequencyDomainScopeView setHardXLim:0.0 max:1000];
    [frequencyDomainScopeView setVisibleXLim:0.0 max:9300];
    [frequencyDomainScopeView setPlotUnitsPerXTick:2000];
    [frequencyDomainScopeView setXGridAutoScale:true];
    [frequencyDomainScopeView setYGridAutoScale:true];
    [frequencyDomainScopeView setXPinchZoomEnabled:false];
    [frequencyDomainScopeView setYPinchZoomEnabled:false];
    [frequencyDomainScopeView setXLabelPosition:kMETScopeViewXLabelsOutsideBelow];
    [frequencyDomainScopeView setYLabelPosition:kMETScopeViewYLabelsOutsideLeft];
    [frequencyDomainScopeView setAxisScale:kMETScopeViewAxesSemilogY];
    [frequencyDomainScopeView setHardYLim:-80 max:0];
    [frequencyDomainScopeView setPlotUnitsPerYTick:20];
    [frequencyDomainScopeView setAxesOn:true];
    [frequencyDomainScopeView addPlotWithColor:[UIColor blueColor] lineWidth:2.0];
    NSLog(@"...Initialized");
    
    /* ------------------------------------ */
    /* === External gesture recognizers === */
    /* ------------------------------------ */
    
    // Add the pinch recognizers and calls to functions
    timeViewPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleTimePinch:)];
    [timeDomainScopeView addGestureRecognizer:timeViewPinchRecognizer];
    frequencyViewPinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleFrequencyPinch:)];
    [frequencyDomainScopeView addGestureRecognizer:frequencyViewPinchRecognizer];
    
    // Add the dragging recognizers and calls to functions
    timeViewPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTimePan:)];
    [timeViewPanRecognizer setMinimumNumberOfTouches:1];
    [timeViewPanRecognizer setMaximumNumberOfTouches:1];
    [timeDomainScopeView addGestureRecognizer:timeViewPanRecognizer];
    frequencyViewPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFrequencyPan:)];
    [frequencyViewPanRecognizer setMinimumNumberOfTouches:1];
    [frequencyViewPanRecognizer setMaximumNumberOfTouches:1];
    [frequencyDomainScopeView addGestureRecognizer:frequencyViewPanRecognizer];
    
    timeViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTimeTap:)];
    [timeViewTapRecognizer setNumberOfTapsRequired:2];
    [timeDomainScopeView addGestureRecognizer:timeViewTapRecognizer];
    
    
    /* -------------------------*/
    /* === Fundamental Freq === */
    /* -------------------------*/
    [self freqSliderChanged:nil];
    
    /* ------------------------------- */
    /* === Harmonics Sliders setup === */
    /* ------------------------------- */

    // 10 sliders for harmonics
    // 1 slider for the noise
    numberOfSliders = 11;
    
    sliders             = [[NSMutableArray alloc] init];
    sliderAmplitudes    = [[NSMutableArray alloc] init];
    harmonicLabels      = [[NSMutableArray alloc] init];    // Unused for now but might change
    
    // 0.5 or -0.5 ?
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * -0.5);   // Transformation to make sliders vertical
    
    // Calculate positioning of the sliders
    CGFloat intervalBetweenSliders  = frequencyDomainScopeView.frame.size.width/numberOfSliders;
    CGFloat yPositionOfSliders      = frequencyDomainScopeView.frame.origin.y + frequencyDomainScopeView.frame.size.height + 50;
    
    
    for (int i=1; i<=numberOfSliders; i++) {
        NSLog(@"");
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake((i-1)*intervalBetweenSliders, yPositionOfSliders, 120, 24)];
        [slider setTag:i];
        
        // Define sliders min and max values
        [slider setMaximumValue:1.0];
        [slider setMinimumValue:0.0];
        
        // Set the slider value to be 1 for fundamental and 0 for the others
        if (i==1) {
            [slider setValue:1];
        } else {
            [slider setValue:0];
        }
        [slider addTarget:self action:@selector(harmonicSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:slider];
        slider.transform = trans;   // make the slider vertical
        slider.hidden = false;
        
        // Slider labels
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((i-1)*intervalBetweenSliders, yPositionOfSliders + 70, 120, 24)];
        label.textColor = [UIColor blackColor];
        label.textAlignment = UITextAlignmentCenter;
        if (i==1) {
            label.text = [NSString stringWithFormat:@"Fund"];
        }
        else if (i==11) {
            label.text = [NSString stringWithFormat:@"Noise"];
        }else{
            label.text = [NSString stringWithFormat:@"H %d",(i-1)];
        }
        
        label.backgroundColor = [UIColor clearColor];
        [label setTag:i];
        label.hidden = NO;
        [self.view addSubview:label];
        
        [harmonicLabels addObject:label];
        [sliderAmplitudes addObject:[NSNumber numberWithFloat:[slider value]]];
        [sliders addObject:slider]; // Add the slider to the array of sliders
        
    }
    
    
    
    /* Set update rate of the scopes */
    // can use kscopeupdaterate
    [self setTimeDomainUpdateRate:kScopeUpdateRate];
    [self setFrequencyDomainUpdateRate:kScopeUpdateRate];
    tdHold = fdHold = paused = false;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setTimeDomainUpdateRate:(float)rate {
    
//    if ([tdScopeClock isValid])
//        [tdScopeClock invalidate];
//    
//    tdScopeClock = [NSTimer scheduledTimerWithTimeInterval:rate
//                                                    target:self
//                                                  selector:@selector(tdPlotCurrent)
//                                                  userInfo:nil
//                                                   repeats:YES];
}

- (void)setFrequencyDomainUpdateRate:(float)rate {
    
//    if ([fdScopeClock isValid])
//        [fdScopeClock invalidate];
//    
//    fdScopeClock = [NSTimer scheduledTimerWithTimeInterval:rate
//                                                    target:self
//                                                  selector:@selector(fdPlotCurrent)
//                                                  userInfo:nil
//                                                   repeats:YES];
}


- (IBAction)updateFundamentalFrequency:(id)sender {
    // Update the fund frequency of the signal
    fundamentalFrequencyLabel.text = [NSString stringWithFormat:@"Fundamental Frequency : %.01f",frequencySlider.value];
    
}

- (void)handleTimePinch:(UIPinchGestureRecognizer *)sender {
    
//    if (sender.state == UIGestureRecognizerStateBegan) {
//        
//        /* Save the initial pinch scale */
//        tdPreviousPinchScale = sender.scale;
//        
//        /* Throttle spectrum plot */
//        tdHold = true;
//        float rate = 1000 * [fdScopeClock timeInterval];
//        [self setFDUpdateRate:rate];
//        
//    }
//    
//    else if (sender.state == UIGestureRecognizerStateEnded) {
//        
//        /* Restart time domain plot and revert spectrum update rate to the default */
//        tdHold = false;
//        
//        [self setFDUpdateRate:kScopeUpdateRate];
//        
//        if (paused) {
//            [self tdPlotVisible];
//            [self fdPlotVisible];
//        }
//    }
//    
//    else {
//        
//        CGFloat scaleChange;
//        scaleChange = sender.scale - tdPreviousPinchScale;
//        
//        /* If we're recording, zoom into the future */
//        if (!paused)
//            [tdScopeView setVisibleXLim:tdScopeView.visiblePlotMin.x
//                                    max:(tdScopeView.visiblePlotMax.x - scaleChange*tdScopeView.visiblePlotMax.x)];
//        
//        /* Otherwise, we're paused; zoom into the past */
//        else
//            [tdScopeView setVisibleXLim:(tdScopeView.visiblePlotMin.x + scaleChange*tdScopeView.visiblePlotMin.x)
//                                    max:tdScopeView.visiblePlotMax.x];
//        
//        tdPreviousPinchScale = sender.scale;
//    }
}

- (void)handleFrequencyPinch:(UIPinchGestureRecognizer *)sender {
    
//    if (sender.state == UIGestureRecognizerStateBegan) {
//        
//        /* Save the initial pinch scale */
//        fdPreviousPinchScale = sender.scale;
//        
//        /* Stop the spectrum plot updates */
//        fdHold = true;
//        return;
//    }
//    
//    else if (sender.state == UIGestureRecognizerStateEnded) {
//        
//        /* Restart the spectrum plot updates */
//        fdHold = false;
//    }
//    
//    else {
//        
//        /* Scale the frequency axis upper bound */
//        CGFloat scaleChange;
//        scaleChange = sender.scale - fdPreviousPinchScale;
//        
//        [fdScopeView setVisibleXLim:fdScopeView.visiblePlotMin.x
//                                max:(fdScopeView.visiblePlotMax.x - scaleChange*fdScopeView.visiblePlotMax.x)];
//        
//        fdPreviousPinchScale = sender.scale;
//    }
}


- (void)handleTimePan:(UIPanGestureRecognizer *)sender {
    
//    /* Location of current touch */
//    CGPoint touchLoc = [sender locationInView:sender.view];
//    
//    if (sender.state == UIGestureRecognizerStateBegan) {
//        
//        /* Save initial touch location */
//        tdPreviousPanLoc = touchLoc;
//        
//        /* Stop the time-domain plot updates */
//        tdHold = true;
//    }
//    
//    else if (sender.state == UIGestureRecognizerStateEnded) {
//        
//        /* Restart time-domain plot updates */
//        tdHold = false;
//        
//        if (paused) {
//            [self tdPlotVisible];
//            [self fdPlotVisible];
//        }
//    }
//    
//    else {
//        
//        /* Get the relative change in location; convert to plot units (time) */
//        CGPoint locChange;
//        locChange.x = tdPreviousPanLoc.x - touchLoc.x;
//        locChange.y = tdPreviousPanLoc.y - touchLoc.y;
//        
//        /* Shift the plot bounds in time */
//        locChange.x *= tdScopeView.unitsPerPixel.x;
//        [tdScopeView setVisibleXLim:(tdScopeView.visiblePlotMin.x + locChange.x)
//                                max:(tdScopeView.visiblePlotMax.x + locChange.x)];
//        
//        tdPreviousPanLoc = touchLoc;
//    }
}

- (void)handleFrequencyPan:(UIPanGestureRecognizer *)sender {
//    
//    /* Location of current touch */
//    CGPoint touchLoc = [sender locationInView:sender.view];
//    
//    if (sender.state == UIGestureRecognizerStateBegan) {
//        
//        /* Save initial touch location */
//        fdPreviousPanLoc = touchLoc;
//        
//        /* Throttle time and spectrum plot updates */
//        float rate = 500 * (tdScopeView.visiblePlotMax.x - tdScopeView.visiblePlotMin.x) * [tdScopeClock timeInterval] + 30 * [tdScopeClock timeInterval];
//        [self setTDUpdateRate:rate];
//        [self setFDUpdateRate:rate/2];
//    }
//    
//    else if (sender.state == UIGestureRecognizerStateEnded) {
//        
//        /* Return time and spectrum plot updates to default rate */
//        [self setTDUpdateRate:kScopeUpdateRate];
//        [self setFDUpdateRate:kScopeUpdateRate];
//    }
//    
//    else {
//        
//        /* Get the relative change in location; convert to plot units (frequency) */
//        CGPoint locChange;
//        locChange.x = fdPreviousPanLoc.x - touchLoc.x;
//        locChange.y = fdPreviousPanLoc.y - touchLoc.y;
//        locChange.x *= fdScopeView.unitsPerPixel.x;
//        
//        /* Shift the plot bounds in frequency */
//        [fdScopeView setVisibleXLim:(fdScopeView.visiblePlotMin.x + locChange.x)
//                                max:(fdScopeView.visiblePlotMax.x + locChange.x)];
//        
//        fdPreviousPanLoc = touchLoc;
//    }
}

- (void)handleTimeTap:(UITapGestureRecognizer *)sender {
    
    // Get the location of the Tap
    CGPoint location = [sender locationInView:[sender.view self]];

    // Do different things depending where the Tap is located
    if (location.x > 600) {    // if tap on the left
        NSLog(@"The time view has been tapped on the left");
        // Switch to draw waveform mode
    }
    else if(location.x < 160){ // if tap on the right
        NSLog(@"The time view has been tapped on the right");
        // Switch to draw amplitude mode (envelope on 3 secs of the signal)
    }
    
    
//    if ([audioController isRunning]) {
//        
//        paused = true;
//        [audioController stopAUGraph];
//        [inputEnableSwitch setOn:false animated:true];
//        
//        /* Show one audio buffer at the end of the reocording buffer */
//        //        [tdScopeView setVisibleXLim:((audioController.recordingBufferLength - audioController.audioBufferLength) / kAudioSampleRate)
//        //                                max:audioController.recordingBufferLength / kAudioSampleRate];
//        //        [tdScopeView setPlotUnitsPerTick:0.005 vertical:0.5];
//        
//        /* Keep the current plot range, but shift it to the end of the recording buffer */
//        [tdScopeView setVisibleXLim:(audioController.recordingBufferLength / kAudioSampleRate) - (tdScopeView.visiblePlotMax.x - tdScopeView.visiblePlotMin.x)
//                                max:audioController.recordingBufferLength / kAudioSampleRate];
//        
//        [self tdPlotVisible];
//    }
//    else {
//        
//        paused = false;
//        [audioController startAUGraph];
//        [inputEnableSwitch setOn:true animated:true];
//        
//        [tdScopeView setVisibleXLim:-0.00001
//                                max:audioController.audioBufferLength / kAudioSampleRate];
//        
//        [tdScopeView setPlotUnitsPerTick:0.005 vertical:0.5];
//    }
//    
//    /* Flash animation */
//    UIView *flashView = [[UIView alloc] initWithFrame:tdScopeView.frame];
//    [flashView setBackgroundColor:[UIColor blackColor]];
//    [flashView setAlpha:0.5f];
//    [[self view] addSubview:flashView];
//    [UIView animateWithDuration:0.5f
//                     animations:^{
//                         [flashView setAlpha:0.0f];
//                     }
//                     completion:^(BOOL finished) {
//                         [flashView removeFromSuperview];
//                     }
//     ];
}



-(void) AudioDataToOutput:(float *)buffer bufferLength:(int)bufferSize {
    free(audioBuffer);
    audioBuffer = (float*)calloc(bufferSize, sizeof(float));
    bufferLength = bufferSize;
    thetaIncrement = 2.0 * M_PI * baseFrequency / kOutputSampleRate;
    
    for (int i = 0;i<bufferLength;i++) {
        buffer[i] = 0;
        for (int j = 0;j<numberOfSliders-2;j++) { // for all sliders except from noise slider
            buffer[i] += [[sliderAmplitudes objectAtIndex:j] floatValue]*sin(theta*(j+1));
        }
        buffer[i] += randomFloat((-1.0)*[[sliderAmplitudes objectAtIndex:(numberOfSliders-2)] floatValue], (1.0)*[[sliderAmplitudes objectAtIndex:(numberOfSliders-2)] floatValue]);
//        buffer[i] *= timeEnvelope[timeEnvelopeIndex];
        audioBuffer[i] = buffer[i];
        theta += thetaIncrement;
        if (theta > 2*M_PI) {
            theta -= 2*M_PI;
        }
//        timeEnvelopeIndex++;
//        if (timeEnvelopeIndex > kOutputSampleRate*numSeconds) {
//            timeEnvelopeIndex -= kOutputSampleRate*numSeconds;
//        }
        
    }
//    if (!fftCalled) {
//        [self performSelectorOnMainThread:@selector(drawFFT) withObject:nil waitUntilDone:NO];
//    }
}

-(IBAction)freqSliderChanged:(id)sender {
    //in progress
////    fftCalled = NO;
//    baseFrequency = [frequencySlider value];
//    fundamentalFrequencyLabel.text = [NSString stringWithFormat:@"%.1f",baseFrequency];
//    //FINISH THIS HERE I STOPPED RIGHT IN THE MIDDLE
//    freqLabel.textColor = [UIColor whiteColor];
//    freqLabel.font = [UIFont fontWithName:@"Helvetica" size:24];
//    
//    indexStepSize = ((float)graphWidth/(kOutputSampleRate/baseFrequency));
//    for (UIView *subView in self.view.subviews) {
//        if ([subView isKindOfClass:[UILabel class]]) {
//            if ([subView tag] > 100 && subView.tag < 100+numSliders) {
//                UILabel *tempLabel = (UILabel*)subView;
//                tempLabel.text = [NSString stringWithFormat:@"%.0fHz",(tempLabel.tag-100)*baseFrequency];
//            } else if ([subView tag] > 1000 && [subView tag] < 1000+(numSliders-1)) {
//                UILabel *tempLabel = (UILabel*)subView;
//                tempLabel.text = [NSString stringWithFormat:@"%.0f",(tempLabel.tag-1000)*baseFrequency];
//            } else  if ([subView tag] > 2000 && [subView tag] <= 2008) {
//                UILabel *tempLabel = (UILabel*)subView;
//                tempLabel.text = [NSString stringWithFormat:@"%.0f",(tempLabel.tag-2000)*(1000.0/baseFrequency)];
//            }
//        }
//    }
//    thetaIncrement = 2.0 * M_PI * baseFrequency / kOutputSampleRate;
//    [self updateAudioWaveform];
//    
//    [frequencyEnvelopeController setBaseFrequency:baseFrequency];
//    [frequencyEnvelopeController updateFrequencyLabels];
//    minFrequency = baseFrequency;
//    maxFrequency = (numSliders-1)*baseFrequency;
//    
//    
}

-(IBAction)harmonicSliderChanged:(id)sender {
    
    // Gets called when sliders are touched
    
    for (UIView *subView in self.view.subviews) {
        if ([subView isKindOfClass:[UILabel class]]) {
            if ([subView tag] == [sender tag]) {
                UILabel *tempLabel = (UILabel*)subView;
                UISlider *tempSlider = (UISlider*)sender;
                NSLog(@"value of the slider %ld is : %f",(long)[sender tag], tempSlider.value);
//                tempLabel.text = [NSString stringWithFormat:@"%.2f",[tempSlider value]]; // Shows slider value
                [sliderAmplitudes replaceObjectAtIndex:([subView tag]-1) withObject:[NSNumber numberWithFloat:[tempSlider value]]];
                
                break;
            }
        }
    }

}

- (IBAction)playStopSound:(id)sender {
    
    // Change the button image
    playStopButton.selected = !playStopButton.selected;
    
    if(playStopButton.selected){    // we want to play the sound
        NSLog(@"Playing synthetic signal");
        [audioOut startOutput];
    }else{                          // we want to stop the sound
        NSLog(@"Stopping the sound");
        [audioOut stopOutput];
    }
}


@end
