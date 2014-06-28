//
// Created by jetbrains on 27/06/14.
// Copyright (c) 2014 JetBrains, Inc. All rights reserved.
//


#ifndef __RobustMatting_H_
#define __RobustMatting_H_

using namespace cv;

class RobustMatting {
public:
    Mat CalculateMatting(const Mat& , const Mat& );
    void GenerateTrimap(Mat& contourImage);
};


#endif //__RobustMatting_H_
