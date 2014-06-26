/*
 *  ShapeTriangulator.cpp
 *  HandCartoon
 *
 *  Created by Administrator on 05.01.11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "Shape.h"
#include "stdio.h"

//Конструктор бы надо по уму переписать, чтобы он принимал нормальные входные значения

Shape::Shape(CvSeq * borderContour, int w, int h):width(w),height(h)
{
	Eps = std::min(width, height)/25;
	
	shapeGeometry.numberofpoints = (borderContour->total)/BORDERSTEP + 1;
	shapeGeometry.pointlist = new REAL[2*shapeGeometry.numberofpoints];
	shapeGeometry.numberofpointattributes = 0;
	shapeGeometry.pointmarkerlist = 0;
	shapeGeometry.segmentlist = new int[2*shapeGeometry.numberofpoints];
	shapeGeometry.segmentmarkerlist = 0;
	shapeGeometry.numberofsegments = shapeGeometry.numberofpoints;
	shapeGeometry.numberofholes = 0;
	shapeGeometry.numberofregions = 0;
	
	triangulation.edgelist = NULL;
	triangulation.edgemarkerlist = NULL;
	triangulation.holelist = NULL;
	triangulation.neighborlist = NULL;
	triangulation.normlist = NULL;
	triangulation.numberofcorners = 0;
	triangulation.numberofedges = 0;
	triangulation.numberofholes = 0;
	triangulation.numberofpointattributes = 0;
	triangulation.numberofpoints = 0;
	triangulation.numberofregions = 0;
	triangulation.numberofsegments = 0;
	triangulation.numberoftriangleattributes = 0;
	triangulation.numberoftriangles = 0;
	triangulation.pointattributelist = NULL;
	triangulation.pointlist = NULL;
	triangulation.pointmarkerlist = NULL;
	triangulation.regionlist = NULL;
	triangulation.segmentlist = NULL;
	triangulation.segmentmarkerlist = NULL;
	triangulation.trianglearealist = NULL;
	triangulation.triangleattributelist = NULL;
	triangulation.trianglelist = NULL;
		
	vout.edgelist = NULL;
	vout.edgemarkerlist = NULL;
	vout.holelist = NULL;
	vout.neighborlist = NULL;
	vout.normlist = NULL;
	vout.numberofcorners = 0;
	vout.numberofedges = 0;
	vout.numberofholes = 0;
	vout.numberofpointattributes = 0;
	vout.numberofpoints = 0;
	vout.numberofregions = 0;
	vout.numberofsegments = 0;
	vout.numberoftriangleattributes = 0;
	vout.numberoftriangles = 0;
	vout.pointattributelist = NULL;
	vout.pointlist = NULL;
	vout.pointmarkerlist = NULL;
	vout.regionlist = NULL;
	vout.segmentlist = NULL;
	vout.segmentmarkerlist = NULL;
	vout.trianglearealist = NULL;
	vout.triangleattributelist = NULL;
	vout.trianglelist = NULL;
	
	CvSeqReader reader;
	cvStartReadSeq( borderContour, &reader, 0);
	
	int index = 0;
	
	CvPoint val;
	for (int i=0; i < borderContour->total; i++) {
		CV_READ_SEQ_ELEM( val, reader );
		if (i % BORDERSTEP == 0){
			shapeGeometry.pointlist[index++] = val.x;
			shapeGeometry.pointlist[index++] = val.y;
		}
	}
	
	for (int i = 0; i < shapeGeometry.numberofpoints; i++){
		shapeGeometry.segmentlist[2*i]=i;
		shapeGeometry.segmentlist[2*i+1]=(i+1)%shapeGeometry.numberofpoints;
	}
	
	triangulate("pq25eza500v", &shapeGeometry, &triangulation, &vout);
	registration();

	//trifree();
} /**/


void Shape::registration()
{
	
	cout << "REGISTRATION STARTED" << endl;
	int Ne = triangulation.numberofedges;
    DynamicSparseMatrix<float> L1(2*Ne, 2*triangulation.numberofpoints);
    DynamicSparseMatrix<float> L2(Ne, triangulation.numberofpoints);
	
	edge_1 = new int[Ne];
	edge_2 = new int[Ne];
	G11 = new double[Ne];
	G22 = new double[Ne];
	int t1, t2, pi, pj, pl, pr;
	double vix, viy, vjx, vjy, vlx, vly, vrx, vry, E11, E12, E21, E22;
	
	cout << "Registration part1" << Ne << endl;
	flush(cout);
	g00 = new double[Ne];
	g01 = new double[Ne];
	g10 = new double[Ne];
	g11 = new double[Ne];
	g20 = new double[Ne];
	g21 = new double[Ne];
	g30 = new double[Ne];
	g31 = new double[Ne];
	g40 = new double[Ne];
	g41 = new double[Ne];
	g50 = new double[Ne];
	g51 = new double[Ne];
	g60 = new double[Ne];
	g61 = new double[Ne];
	g70 = new double[Ne];
	g71 = new double[Ne];
	for (int i = 0; i < Ne; i++)
	{
		t1 = vout.edgelist[2*i];
		t2 = vout.edgelist[2*i+1];
		pi = triangulation.edgelist[2*i];
		pj = triangulation.edgelist[2*i+1];
		pl = edge_1[i]=triangulation.trianglelist[t1*3]+triangulation.trianglelist[t1*3+1]+triangulation.trianglelist[t1*3+2]-pi-pj;

		vix = triangulation.pointlist[pi*2];
		viy = triangulation.pointlist[pi*2+1];
		vjx = triangulation.pointlist[pj*2];
		vjy = triangulation.pointlist[pj*2+1];
		vlx = triangulation.pointlist[pl*2];
		vly = triangulation.pointlist[pl*2+1];
		
		L2x.push_back(pi); L2y.push_back(i); L2Val.push_back(-1);
		L2x.push_back(pj); L2y.push_back(i); L2Val.push_back(1);
		
		//////
		L2.coeffRef(i,pi) -= 1;
		L2.coeffRef(i,pj) += 1;
		//////
		
		cout << pi << " " <<  pj << " " << pl << endl;
		
		E11 = vjx - vix;
		E22 = -E11;
		E21 = E12 = vjy - viy;

		
		if (t2 >= 0){
			pr = edge_2[i]=triangulation.trianglelist[t2*3]+triangulation.trianglelist[t2*3+1]+triangulation.trianglelist[t2*3+2]-pi-pj;
			vrx = triangulation.pointlist[pr*2];
			vry = triangulation.pointlist[pr*2+1];
			
			G11[i] = 1/4.0/(vix*vix+vjx*vjx+viy*viy+vjy*vjy+vlx*vlx+vly*vly+vrx*vrx+vry*vry
						          -vlx*vix-vlx*vjx-vly*viy-vly*vjy-vrx*vix-vrx*vjx-vry*viy-vry*vjy);
			
			g11[i] = -(g00[i] = (4*vix-2*vlx-2*vrx)*G11[i]); g10[i] = g01[i] = (4*viy-2*vly-2*vry)*G11[i];
			g31[i] = -(g20[i] = (4*vjx-2*vlx-2*vrx)*G11[i]); g30[i] = g21[i] = (4*vjy-2*vly-2*vry)*G11[i];
			g51[i] = -(g40[i] = (4*vlx-2*vix-2*vjx)*G11[i]); g50[i] = g41[i] = (4*vly-2*viy-2*vjy)*G11[i];
			g71[i] = -(g60[i] = (4*vrx-2*vix-2*vjx)*G11[i]); g70[i] = g61[i] = (4*vry-2*viy-2*vjy)*G11[i];
			
			cout << pr << endl;
		}else/**/ {
			edge_2[i] = -1;
			G11[i] = 1/(3*(viy*viy+vjy*vjy+vix*vix+vjx*vjx)-2*(viy*vjy+vjx*vix)+
								 +4*vly*vly-4*vly*viy-4*vly*vjy-4*vlx*vix-4*vlx*vjx+4*vlx*vlx);
			
			g11[i] = -(g00[i] = (3*vix-vjx-2*vlx)*G11[i]); g10[i] = g01[i] = (3*viy-vjy-2*vly)*G11[i];
			g31[i] = -(g20[i] = (3*vjx-vix-2*vlx)*G11[i]); g30[i] = g21[i] = (3*vjy-viy-2*vly)*G11[i];
			g51[i] = -(g40[i] = (4*vlx-2*vix-2*vjx)*G11[i]); g50[i] = g41[i] = (4*vly-2*viy-2*vjy)*G11[i];

		}
		
		//////////////////////Eigen
		L1.coeffRef(2*i, 2*pi)		+= -1-E11*g00[i]-E12*g01[i];
		L1.coeffRef(2*i, 2*pi+1)	+=   -E11*g10[i]-E12*g11[i];
		L1.coeffRef(2*i+1, 2*pi)	+=   -E21*g00[i]-E22*g01[i];
		L1.coeffRef(2*i+1, 2*pi+1)	+= -1-E21*g10[i]-E22*g11[i];
		
		L1.coeffRef(2*i, 2*pj)		+= 1 -E11*g20[i]-E12*g21[i];
		L1.coeffRef(2*i, 2*pj+1)	+=   -E11*g30[i]-E12*g31[i];
		L1.coeffRef(2*i+1, 2*pj)	+=   -E21*g20[i]-E22*g21[i];
		L1.coeffRef(2*i+1, 2*pj+1)	+= 1 -E21*g30[i]-E22*g31[i];

		L1.coeffRef(2*i, 2*pl)		+= -E11*g40[i]-E12*g41[i];
		L1.coeffRef(2*i, 2*pl+1)	+= -E11*g50[i]-E12*g51[i];
		L1.coeffRef(2*i+1, 2*pl)	+= -E21*g40[i]-E22*g41[i];
		L1.coeffRef(2*i+1, 2*pl+1)	+= -E21*g50[i]-E22*g51[i];
		
		if(edge_2[i] != -1){
			L1.coeffRef(2*i, 2*pr)		+= -E11*g60[i]-E12*g61[i];
			L1.coeffRef(2*i, 2*pr+1)	+= -E11*g70[i]-E12*g71[i];
			L1.coeffRef(2*i+1, 2*pr)	+= -E21*g60[i]-E22*g61[i];
			L1.coeffRef(2*i+1, 2*pr+1)	+= -E21*g70[i]-E22*g71[i];
		}
		
		//////////////////////
	}
	
	int Tn = L1x.size();
	cout << "L1 size " <<	2*Ne << Tn << endl;
	int *Ti = new int[Tn], *Tj = new int[Tn];
	double *Tx = new double[Tn];
	
	L1Ap = new int[2*triangulation.numberofpoints+1];
	L1Ai = new int[Tn];
	L1Ax = new double[Tn];
	
	for (int i = 0; i < Tn; i++){
		Ti[i] = L1x[i];
		Tj[i] = L1y[i];
		Tx[i] = L1Val[i];
		cout << Tx[i] << endl;
	}
	
	////Eigen
	L_1 = L1.transpose()*L1;
	////
	
	
	/////////////////////////
	// REGISTRATION PART 2///
	/////////////////////////
	
	////Eigen
	L2_t = DynamicSparseMatrix<double>(L2.transpose());
	L_2 = L2_t*L2;
	////
	
	pointsNew = new double[triangulation.numberofpoints*2];

	for (int i = 0; i < 2*triangulation.numberofpoints; i++){
		pointsNew[i] = triangulation.pointlist[i];
	}
/**/
}

int Shape::addHandle(double x, double y)
{
	cout << "ADD HANDLE: " << x << ", " << y << endl;
	vector<int*>::iterator tt = handleTriangles.begin();
	vector<double*>::iterator c = handleBarCoords.begin();
	for (vector<point2d<double>>::iterator h = handles.begin(); h != handles.end(); h++, tt++,c++) {
		if (distance(x, y, h->x, h->y) < Eps){
			handles.erase(h);
			handleBarCoords.erase(c);
			handleTriangles.erase(tt);
            
			compilation();
			return -1;
		}
	}
    
	int t = -1;
	int p1, p2, p3;
	double x1, x2, x3, y1, y2, y3;
	for (long i = 0; i < triangulation.numberoftriangles; i++) {
		p1 = triangulation.trianglelist[3*i];
		p2 = triangulation.trianglelist[3*i+1];
		p3 = triangulation.trianglelist[3*i+2];
		x1 = triangulation.pointlist[2*p1];
		y1 = triangulation.pointlist[2*p1+1];
		x2 = triangulation.pointlist[2*p2];
		y2 = triangulation.pointlist[2*p2+1];
		x3 = triangulation.pointlist[2*p3];
		y3 = triangulation.pointlist[2*p3+1];
		if (point_in_triangle(x, y, x1, y1, x2, y2, x3, y3)){
			t = i;
			break;
		}
	}
	
	if (t >= 0){
        point2d<double> h;
		h.x = x;
		h.y = y;
		handles.push_back(h);
		double l1 = ((y2-y3)*(x-x3)+(x3-x2)*(y-y3))/((y2-y3)*(x1-x3)+(x3-x2)*(y1-y3));
		double l2 = ((y3-y1)*(x-x3)+(x1-x3)*(y-y3))/((y3-y1)*(x2-x3)+(x1-x3)*(y2-y3));
		double l3 = 1 - l1 - l2;
		
		double *coords = new double[3];
		coords[0] = l1; coords[1] = l2; coords[2] = l3;
		int *triangle = new int[3];
		triangle[0] = p1; triangle[1] = p2; triangle[2] = p3;
		
		handleBarCoords.push_back(coords);
		handleTriangles.push_back(triangle);
		
		compilation();
	}
    return 0;
}

bool Shape::setActiveHandle(double x, double y)
{
	for (vector<point2d<double>>::iterator h = handles.begin(); h != handles.end(); h++) {
		if (distance(x, y, h->x, h->y) < Eps){
			activeHandle = h;
			return true;
		}
	}
	return false;
}

void Shape::modifyActiveHandle(double x, double y)
{
	activeHandle->x = x;
	activeHandle->y = y;
	
	double *tmpPoints = new double[2*triangulation.numberofpoints];
	
	///////////////////////////
	///   Part 1 /////////////
	/////////////////////////
	
	double *b1 = new double[handles.size()*2], *b1m = new double[2*triangulation.numberofpoints];
	
	for (int i=0;i<2*triangulation.numberofpoints;i++){
		b1m[i]=0;
	}
	
	int i=0;
	for (vector<point2d<double>>::iterator h = handles.begin(); h != handles.end(); h++) {
		b1[i++] = h->x*W;
		b1[i++] = h->y*W;
	}
	
	///Eigen
	VectorXd B1(2*handles.size());
	
	i=0;
	for (vector<point2d<double>>::iterator h = handles.begin(); h != handles.end(); h++) {
		B1(i++) = h->x*W;
		B1(i++) = h->y*W;
	}
	VectorXd tmpPoints_E(2*triangulation.numberofpoints);
	tmpPoints_E = LDLT_of_A1.solve(VectorXd(C1_t*B1));
	
	////////////
	
	///////////////////////////
	///   Part 2 /////////////
	/////////////////////////
	
	double *b2x = new double[handles.size()], *b2mx = new double[triangulation.numberofpoints];
	double *b2y = new double[handles.size()], *b2my = new double[triangulation.numberofpoints];
	double *d2x = new double[triangulation.numberofedges], *d2mx = new double[triangulation.numberofpoints];
	double *d2y = new double[triangulation.numberofedges], *d2my = new double[triangulation.numberofpoints];
	double *bx = new double[triangulation.numberofpoints];
	double *by = new double[triangulation.numberofpoints];
	double *tmpPointsx = new double[triangulation.numberofpoints];
	double *tmpPointsy = new double[triangulation.numberofpoints];
	
	
	/////////Eigen
	for (int i=0;i<2*triangulation.numberofpoints;i++){
		tmpPoints[i]=tmpPoints_E(i);
	}
	/////////
	
	for (int i=0;i<triangulation.numberofpoints;i++){
		b2mx[i]=0;
		b2my[i]=0;
		d2mx[i]=0;
		d2my[i]=0;
	}
	
	i=0;
	for (vector<point2d<double>>::iterator h = handles.begin(); h != handles.end(); h++,i++) {
		b2x[i] = h->x*W;
		b2y[i] = h->y*W;
	}
	
	int pi, pj, pl, pr;
	double ck, sk, n, vix, viy, vjx, vjy;

	for (i=0; i<triangulation.numberofedges; i++) {
		pi = triangulation.edgelist[2*i];
		pj = triangulation.edgelist[2*i+1];
		pl = edge_1[i];
		pr = edge_2[i];
		
		if (pr != -1){
			ck =	g00[i]*tmpPoints[pi*2]+g10[i]*tmpPoints[pi*2+1]+
					g20[i]*tmpPoints[pj*2]+g30[i]*tmpPoints[pj*2+1]+
					g40[i]*tmpPoints[pl*2]+g50[i]*tmpPoints[pl*2+1]+
					g60[i]*tmpPoints[pr*2]+g70[i]*tmpPoints[pr*2+1];
			
			sk =	g01[i]*tmpPoints[pi*2]+g11[i]*tmpPoints[pi*2+1]+
					g21[i]*tmpPoints[pj*2]+g31[i]*tmpPoints[pj*2+1]+
					g41[i]*tmpPoints[pl*2]+g51[i]*tmpPoints[pl*2+1]+
					g61[i]*tmpPoints[pr*2]+g71[i]*tmpPoints[pr*2+1];/**/
			
		}else{
			ck =	g00[i]*tmpPoints[pi*2]+g10[i]*tmpPoints[pi*2+1]+
					g20[i]*tmpPoints[pj*2]+g30[i]*tmpPoints[pj*2+1]+
					g40[i]*tmpPoints[pl*2]+g50[i]*tmpPoints[pl*2+1];
			
			sk =	g01[i]*tmpPoints[pi*2]+g11[i]*tmpPoints[pi*2+1]+
					g21[i]*tmpPoints[pj*2]+g31[i]*tmpPoints[pj*2+1]+
					g41[i]*tmpPoints[pl*2]+g51[i]*tmpPoints[pl*2+1];
		}
		
		//ck=100000;sk=0;
		
		//cout << "Ck Sk " << ck << " " << sk << endl;

		vix = triangulation.pointlist[pi*2];
		viy = triangulation.pointlist[pi*2+1];
		vjx = triangulation.pointlist[pj*2];
		vjy = triangulation.pointlist[pj*2+1];
		
		n = 1/pow((ck*ck + sk*sk),0.5);
		ck *= n; sk *= n;
		d2x[i]= ck*(vjx-vix) + sk*(vjy-viy);			
		d2y[i]=-sk*(vjx-vix) + ck*(vjy-viy);
	}
	
	////////////Eigen
	VectorXd B2x(handles.size()), B2y(handles.size());
	i=0;
	for (vector<point2d<double>>::iterator h = handles.begin(); h != handles.end(); h++,i++) {
		B2x(i) = h->x*W;
		B2y(i) = h->y*W;
	}
	
	VectorXd D2x(triangulation.numberofedges), D2y(triangulation.numberofedges);
	for (i=0; i<triangulation.numberofedges; i++) {
		D2x(i) = d2x[i];
		D2y(i) = d2y[i];
	}
	
	VectorXd tmpPoints_X(triangulation.numberofpoints), tmpPoints_Y(triangulation.numberofpoints);
	tmpPoints_X = LDLT_of_A2.solve(VectorXd(C2_t*B2x+L2_t*D2x));
	tmpPoints_Y = LDLT_of_A2.solve(VectorXd(C2_t*B2y+L2_t*D2y));/**/
	////////////

	
	//////Eigen
	for (i=0; i<triangulation.numberofpoints; i++) {
		pointsNew[2*i]=tmpPoints_X(i);
		pointsNew[2*i+1]=tmpPoints_Y(i);
	}
	/**/
}

void Shape::compilation()
{
	C1x.clear();
	C1y.clear();
	C1Val.clear();
	
	C2x.clear();
	C2y.clear();
	C2Val.clear();
	
	
	vector<int*>::iterator tt = handleTriangles.begin();
	vector<double*>::iterator c = handleBarCoords.begin();
	int Np = triangulation.numberofpoints;
	DynamicSparseMatrix<float> C1(2*handles.size(),2*Np), C2(handles.size(),Np);

	
	int i=0;
	for (vector<point2d<double> >::iterator h = handles.begin(); h != handles.end(); h++, tt++,c++, i++) {
		cout << "Handle "<< i << ": " << (*tt)[0] << " " << (*tt)[1] << " " << (*tt)[2] << endl;
		C1x.push_back(2*((*tt)[0])); C1y.push_back(2*i); C1Val.push_back((*c)[0]*W);
		C1x.push_back(2*((*tt)[0])+1); C1y.push_back(2*i+1); C1Val.push_back((*c)[0]*W);
		C1x.push_back(2*((*tt)[1])); C1y.push_back(2*i); C1Val.push_back((*c)[1]*W);
		C1x.push_back(2*((*tt)[1])+1); C1y.push_back(2*i+1); C1Val.push_back((*c)[1]*W);
		C1x.push_back(2*((*tt)[2])); C1y.push_back(2*i); C1Val.push_back((*c)[2]*W);
		C1x.push_back(2*((*tt)[2])+1); C1y.push_back(2*i+1); C1Val.push_back((*c)[2]*W);
		
		C2x.push_back((*tt)[0]); C2y.push_back(i); C2Val.push_back((*c)[0]*W);
		C2x.push_back((*tt)[1]); C2y.push_back(i); C2Val.push_back((*c)[1]*W);
		C2x.push_back((*tt)[2]); C2y.push_back(i); C2Val.push_back((*c)[2]*W);
		
		//////Eigen
		C1.coeffRef(2*i,	2*((*tt)[0]))	+= (*c)[0]*W;
		C1.coeffRef(2*i+1,	2*((*tt)[0])+1)	+= (*c)[0]*W;
		C1.coeffRef(2*i,	2*((*tt)[1]))	+= (*c)[1]*W;
		C1.coeffRef(2*i+1,	2*((*tt)[1])+1)	+= (*c)[1]*W;
		C1.coeffRef(2*i,	2*((*tt)[2]))	+= (*c)[2]*W;
		C1.coeffRef(2*i+1,	2*((*tt)[2])+1)	+= (*c)[2]*W;
		
		C2.coeffRef(i,	(*tt)[0])	+= (*c)[0]*W;
		C2.coeffRef(i,	(*tt)[1])	+= (*c)[1]*W;
		C2.coeffRef(i,	(*tt)[2])	+= (*c)[2]*W;
		//////
	}
	
	/////////////////////////
	/// Compilation part1 ///
	/////////////////////////
	
	///Eigen
	C1_t = DynamicSparseMatrix<double>(C1.transpose());
	C_1 = C1_t*C1;
	A1 = C_1 + L_1;
	LDLT_of_A1.compute(A1);
	//////////
	
	/////////////////////////
	/// Compilation part2 ///
	/////////////////////////

	///Eigen
	C2_t = DynamicSparseMatrix<double>(C2.transpose());
	C_2 = C2_t*C2;
	A2 = C_2 + L_2;
	LDLT_of_A2.compute(A2);
	//////////
}