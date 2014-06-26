/*
 *  Shape.h
 *  HandCartoon
 *
 *  Created by Administrator on 05.01.11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

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
	
	vector<point2d<double>> handles;
	vector<int*> handleTriangles;
	vector<double*> handleBarCoords;
	double Eps;
	
	
	int *edge_1, *edge_2;
	double *G11, *G22;
	double *g00, *g01, *g10, *g11, *g20, *g21, *g30, *g31, *g40, *g41, *g50, *g51, *g60, *g61, *g70, *g71;
	vector<int> L1x, L1y;
	vector<double> L1Val;
	int *L1Ap, *L1Ai;
	double *L1Ax;
	
	vector<int> C1x, C1y;
	vector<double> C1Val;

	vector<int> L2x, L2y;
	vector<double> L2Val;
	int *L2Ap, *L2Ai;
	double *L2Ax;
	
	vector<int> C2x, C2y;
	vector<double> C2Val;
	vector<point2d<double>>::iterator activeHandle;
	
	double *pointsNew;

///Eigen
	SparseMatrix<double> L_1,L_2, C_1, C_2, A1, A2;
	SimplicialLDLT<SparseMatrix<double> > LDLT_of_A1, LDLT_of_A2;
	DynamicSparseMatrix<double> C1_t, C2_t, L2_t;

	
public:
	Shape(CvSeq * borderContour, int w, int h);
	int addHandle(double, double);
	void registration();
	void compilation();
	bool setActiveHandle(double x, double y);
	void modifyActiveHandle(double x, double y);
};