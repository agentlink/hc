/*
 *  Shape.h
 *  HandCartoon
 *
 *  Created by Administrator on 05.01.11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef SHAPE_INCLUDED
#define SHAPE_INCLUDED

//#ifdef SINGLE
//#define REAL float
//#else /* not SINGLE */
//#define REAL double
//#endif /* not SINGLE */

//#define ANSI_DECLARATORS
//#define VOID int

#include <vector>
#include <iostream>

#include <Eigen/Sparse>
#include <unsupported/Eigen/SparseExtra>
#include <Wykobi/wykobi.hpp>
//#include <Eigen/SparseExtra>

extern "C" {
	#include "triangle.h"
}

using namespace std;
using namespace Eigen;
using namespace wykobi;

const int BORDERSTEP = 15;
const int W = 1000;

class Shape{
public:
	triangulateio shapeGeometry, triangulation, vout;
	int width, height;
	
    map<int, point2d<double>> handles;
	map<int, int*> handleTriangles;
	map<int, double*> handleBarCoords;
	double Eps;
	
	int *edge_1, *edge_2;
	double *G11, *G22;
	double *g00, *g01, *g10, *g11, *g20, *g21, *g30, *g31, *g40, *g41, *g50, *g51, *g60, *g61, *g70, *g71;
	
	double *pointsNew;
	double *lastRegistrationPoints;

///Eigen
	SparseMatrix<double> L_1,L_2, C_1, C_2, A1, A2;
	SimplicialLDLT<SparseMatrix<double> > LDLT_of_A1, LDLT_of_A2;
	SparseMatrix<double> C1_t, C2_t, L2_t;
	
public:
	Shape(CvSeq * borderContour, int w, int h);
	int addHandle(int, double, double);
    void updateHandle(int, double, double);
    void updateHandles(map<int, point2d<double>>);
    void releaseHandle(int);
    void releaseHandles(vector<int>);
	void registration();
    void reTreangulate(CvSeq *);
	void compilation();
    void updateTriangles();
//	bool setActiveHandle(double x, double y);
//	void modifyActiveHandle(double x, double y);
};

#endif