//
// Created by jetbrains on 27/06/14.
// Copyright (c) 2014 JetBrains, Inc. All rights reserved.
//


#ifndef __RobustMatting_H_
#define __RobustMatting_H_


class RobustMatting {
public:
    IplImage* CalculateMatting(const IplImage* , const IplImage* );
    IplImage* GenerateTrimap(IplImage* contourImage);
};


#endif //__RobustMatting_H_
