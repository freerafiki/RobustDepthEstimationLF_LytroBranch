# RobustDepthEstimationLF_LytroBranch

## WARNING: use at your own risk
This contains code I used back in 2019/20 to work on the LF data from the Lytro (mostly on the data for Figure 5 of the [paper](https://www.mdpi.com/1424-8220/19/3/500/htm), which comes from [this 2013 paper](https://ieeexplore.ieee.org/abstract/document/7335501) - they were Lytro images of the first generation).
It may be useful if you need to read Lytro images and convert it to the format you need for the main [RobustDepthEstimation](https://github.com/freerafiki/RobustDepthLFMicroscopy) approach, otherwise use it carefully, it's development and not production level code. It is basically an intermediate-old version of the main working code, so it may contain bugs or be unclear. 

If you are interesting in the reading/conversion of the images, check the code in the [`READ`](https://github.com/freerafiki/RobustDepthEstimationLF_LytroBranch/tree/master/READ) folder. 

If you need to use this, most likely the best thing to do would be to use the working code at [RobustDepthEstimation](https://github.com/freerafiki/RobustDepthLFMicroscopy) and modify and insert one or two scripts from the [`READ`](https://github.com/freerafiki/RobustDepthEstimationLF_LytroBranch/tree/master/READ) folder into the working code, more than using the rest of the code in this repo. 

A branch of the Robust Depth Estimation for Light Field Microscopy algorithm available here 
https://github.com/PlenopticToolbox/RobustDepthLFMicroscopy
