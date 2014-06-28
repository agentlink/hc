#include <fstream>
#include <deque>
#include <numeric>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/opencv.hpp>
#include <Eigen/Sparse>
#include <Eigen/LU>
#include "RobustMatting.h"

using namespace cv;
using namespace std;
using namespace Eigen;

// common things
struct Second
{
    template <typename T>
    typename T::second_type operator()(T p) const
    {
        return p.second;
    }
};
namespace std
{
    template <typename A,typename B>
    static pair<A,B> operator+(const pair<A,B>& a,const pair<A,B>& b)
    {
        return make_pair( a.first+b.first, a.second+b.second );
    }
};
template <typename T>
static inline Mat convertTo(const Mat& m, double a=1, double b=0 ){ Mat t; m.convertTo( t, CV_MAKETYPE(DataDepth<T>::value,m.channels()), a, b ); return t; }
static inline Mat dilate(const cv::Mat& m, const cv::Mat& kernel=Mat() ){ Mat t;  dilate(m,t,kernel);  return t; }
static inline Mat erode(const cv::Mat& m, const cv::Mat& kernel=Mat() ){ Mat t;  erode(m,t,kernel);  return t; }
static inline Mat transpose(const cv::Mat& m){ Mat t; transpose(m,t); return t; }
// end common
template <int window_size,class Triplets>
void BuildProblem( Triplets& triplets, const Mat& rgb, const Mat& Known, const double epsilon=1e-5 )
{
    typedef typename Triplets::value_type Trip;
    const int nc(3), half_window_size(window_size/2), neb_size ( window_size * window_size );
    const Mat known( erode( Known ) );
    const Size size( rgb.size() );
    const int lap_size ( size.area( ) );
    const MatrixXi indsM ( Map<MatrixXi> ( VectorXi(VectorXi::LinSpaced( lap_size, 0, lap_size-1 )).data( ),   size.height, size.width ) );
    typedef double cType;
    const Mat st(transpose(rgb).reshape(1));
    MatrixXd Rgbm( st.cols, st.rows );  std::copy( st.begin<uchar>(), st.end<uchar>(), Rgbm.data() );
    Rgbm /= 255;
    vector<cType> sum(lap_size,0);
    const Matrix< double, nc, nc > EpsEye (  (epsilon/neb_size) * Matrix< double, nc, nc >::Identity()  );
    for (int i( half_window_size ); i < size.height - half_window_size; ++i) {
        for (int j( half_window_size ); j < size.width - half_window_size; ++j) {
            if ( !known.at<uchar>(i, j) ){
                const Matrix< double, window_size*nc, window_size> wb ( Rgbm.block<window_size*nc, window_size>( (i-1)*nc, j-1 ) );
                const Matrix< double, nc, neb_size > Wk  ( wb.data() );
                const Matrix< double, nc, 1 > win_mu( Wk.rowwise( ).sum( )/neb_size );
                const Matrix< double, nc, nc > mi ( Wk*Wk.transpose()/neb_size - win_mu*win_mu.transpose() + EpsEye ) ,Win_var ( mi.inverse( ) );
                const Matrix< double, nc, neb_size > Wkm( Wk - win_mu.replicate<1,neb_size>() );
                const Matrix <double, neb_size, neb_size> tvals( ( Matrix <double, neb_size, neb_size>::Ones() + Wkm.transpose( ) * Win_var * Wkm )/neb_size );

                const Matrix <int, window_size, window_size> win_inds_block ( indsM.block<window_size, window_size>( i - half_window_size, j - half_window_size ) );
                const Matrix <int, neb_size, 1> win_inds( win_inds_block.data( ) );
                const Matrix <int, neb_size, neb_size> row_inds (win_inds. template replicate<1,neb_size>());
                for (int r(0); r < tvals.rows( ); ++r) {
                    for(int c(0); c < tvals.cols( ); ++c ) {
                        const cType v( -tvals.coeff(r,c) );
                        if( abs(v) > epsilon ){
                            const int cr( row_inds(c, r) ), rc( row_inds(r, c) );
                            const Trip tp( cr, rc, v );
                            sum[ rc ] -= v;
                            triplets.push_back(tp);
                        }
                    }
                }
            }
        }
    }
    for ( int i(0); i < lap_size; ++i ) {
        triplets.push_back( Trip( i, i, sum[i] ) );
    }
}

vector<Point> CollectSampleSet( const Point p, const vector<Point> &candidates )
{
    const int sample_number( 10 ), N( min( (int)candidates.size( ), sample_number ) );
    typedef std::pair<double,Point> SampleCandidate;
    vector<SampleCandidate> Candidates;  Candidates.reserve( candidates.size( ) );
    for( vector<Point>::const_iterator i(candidates.begin( )); i!=candidates.end( ); ++i ) {
        const Point ca(*i), d(ca-p);
        Candidates.push_back( make_pair( d.ddot(d), ca ) );
    }
    struct LT{ bool operator()( const SampleCandidate& a, const SampleCandidate& b ){ return a.first<b.first || a.first==b.first && a.second.dot(a.second) < b.second.dot(b.second) ; } };
    std::nth_element( Candidates.begin(), Candidates.begin() + N, Candidates.end( ), LT() );
    vector<Point> SampleSet( N );
    std::transform( Candidates.begin( ), Candidates.begin() + N, SampleSet.begin( ), Second() );
    return SampleSet;
}

vector<Point>   GetMaskPoints( const Mat& mask )
{
    deque<Point> dp;
    for( int y(0); y<mask.rows; ++y ){
        for( int x(0); x<mask.cols; ++x){
            if( mask.at<uchar>(y,x) )
                dp.push_back( Point(x,y) );
        }
    }
    return vector<Point>( dp.begin( ), dp.end( ) );
}

typedef vector< pair<cv::Vec3i, double> > SampleColorWeights_t;
SampleColorWeights_t GetSampleColorWeights( const Mat& rgb, const cv::Point& p, const vector<Point> &samp )
{
    SampleColorWeights_t scw; scw.reserve( samp.size( ) );
    double mindist ( std::numeric_limits<double>::max() );
    const Vec3i cp ( rgb.at<Vec3b>( p ) );
    for( vector<Point>::const_iterator i(samp.begin()); i != samp.end( ); ++i ) {
        const Vec3i ci ( rgb.at<Vec3b>( *i ) ), dc ( cp - ci ) ;
        const double distance ( dc.ddot( dc ) );
        if( distance < mindist ){
            mindist = distance;
        }
        scw.push_back( make_pair( ci, distance ) );
    }
    if( mindist == 0 )
        mindist=1 ;
    for( SampleColorWeights_t::iterator i( scw.begin( ) );  i!= scw.end( ); ++i ){
        i->second = 1 - exp( -i->second / mindist );
    }
    return scw;
}

enum { eUnknown=128, eFG=255, eBG=0 };

MatrixXd SolveRobustMatting( const Mat& src, const Mat& trimap, const double sigma=0.1, const double gamma=0.1  )
{
    const Size sz( src.size() );
    const Mat fg( trimap == eFG ), bg( trimap != eBG );
    const Mat Known( trimap != eUnknown ), Unknown( trimap == eUnknown ) ;
    const vector<Point> ctf( GetMaskPoints ( erode(fg)!=fg ) ), ctb( GetMaskPoints ( dilate(bg)!=bg ) );
    typedef Triplet<double> Trip;
    typedef deque< Trip > Trips;
    Trips triplets;
    BuildProblem<3>( triplets, src, Known );
    double SumWF(0), SumWB(0) ;
    const int N( sz.area( ) );
    MatrixXd Alpha(sz.height,sz.width);
# define Push(r,c,v) if(v!=0) triplets.push_back(Trip(r,c,v))
    for (int I(0), x(0); x < sz.width; ++x) for( int y(0); y < sz.height; ++y, ++I  ) {
            double &alpha( Alpha.coeffRef(y,x) ), conf(0);
            if( Unknown.at<uchar>( y, x ) ){
                const double sigma( 0.1 ), sigma2( sigma * sigma );
                const Point p(x,y);
                const Vec3i ucolor( src.at<Vec3b>( p ) ) ;
                const Vec3d dcolor( ucolor );
                const vector< Point > fg_samp ( CollectSampleSet(p,ctf) );
                const SampleColorWeights_t fg_scw( GetSampleColorWeights( src, p, fg_samp ) );
                const vector< Point > bg_samp( CollectSampleSet(p,ctb) );
                const SampleColorWeights_t bg_scw( GetSampleColorWeights( src, p, bg_samp ) );
                typedef std::pair< double, double > AE;
                std::vector< AE > ae; ae.reserve(  fg_scw.size( ) * bg_scw.size( ) );
                for( SampleColorWeights_t::const_iterator f(fg_scw.begin()); f != fg_scw.end( ); ++f ){
                    for( SampleColorWeights_t::const_iterator b(bg_scw.begin()); b != bg_scw.end( ); ++b ){
                        const Vec3i usubb( ucolor - b->first );
                        const Vec3i fsubb( f->first - b->first );
                        const double ff( fsubb.dot(fsubb) ), ffx( max(ff,1.) ), uf( usubb.dot(fsubb) ), alpha( uf/ffx ); // alpha = (usubb*fsubb')/max(fsubb*fsubb',DMin);
                        const Vec3d difference( dcolor - alpha*Vec3d(f->first) - (1-alpha)*Vec3d(b->first) ); //difference = ucolor - (alpha*fgsampcolors(i,:) + (1-alpha)*bgsampcolors(j,:));
                        const double distanceratio2( difference.ddot(difference)/ffx );  //(difference*difference')/max(fsubb*fsubb', DMin);
                        const double Exp( exp( -distanceratio2 * f->second * b->second / sigma2 ) );
                        const double Alpha( max(min( alpha, 1. ), 0. ) );
                        ae.push_back( std::make_pair( Exp, Alpha ) );
                    }
                }
                enum{ M=3 };
                struct LT{ bool operator()( const AE& a, const AE& b ){ return b<a; } };
                nth_element( ae.begin( ), ae.begin( )+M, ae.end( ), LT() );
                std::accumulate( ae.begin( ), ae.begin( )+M, AE(0,0) );
                const AE v( std::accumulate( ae.begin( ), ae.begin( )+M, AE(0,0) ) );
                conf=v.first/M;
                alpha=v.second/M;
            } else {
                alpha = fg.at<uchar>(y,x)? 1:0;
            }
            const double wf ( conf*alpha + (1-conf)*(alpha>0.5?1:0) ), WF(gamma*wf), WB(gamma*(1-wf)) ;
            SumWF += WF;
            SumWB += WB;
            Push( I,   I   , gamma );
            Push( I,   N   , -WF   );
            Push( N,   I   , -WF   );
            Push( I,   N+1 , -WB   );
            Push( N+1, I   , -WB   );
        }
    Push( N,   N   , SumWF );
    Push( N+1, N+1 , SumWB );
# undef Push
    //
    const int Total(N+2);
    typedef std::pair< int, bool > UIF;
    typedef deque<UIF> UIFS;
    UIFS unknowns, knowns, * const uk[]={ &unknowns, &knowns };
    for( int i=0; i<Total; ++i ){
        const uchar t( i<N? trimap.at<uchar>( i%sz.height, i/sz.height ):0 );
        const UIF uif( std::make_pair( i,  ( i<N? t == eFG : i==N) ) );
        uk[ ( i<N && t == eUnknown ) ? 0 : 1 ] -> push_back( uif );
    }
    const int last_unknown( unknowns.size( ) );
    VectorXi Ak( knowns.size( ) ), indmap(Total), Indeces(Total) ;
    transform( knowns.begin( ), knowns.end( ), Ak.data( ), Second( ) );
    for( int k(0), j(0); k<2; ++k ){
        const UIFS &uifs( *uk[k] );
        for( UIFS::const_iterator i( uifs.begin( ) ); i != uifs.end( ); ++i, ++j ){
            const UIF uif( *i );
            const int index( uif.first );
            Indeces.coeffRef(j) = index ;
            indmap.coeffRef(index) = j ;
        }
    }
    Trips lu, rt;
    for( Trips::const_iterator i( triplets.begin( ) ); i != triplets.end( ); ++i ){
        const int row( indmap[i->row()] ), col( indmap[i->col()] );
        const Trip t( indmap[i->row()], indmap[i->col()], i->value() );
        if( row < last_unknown ){
            if( col<last_unknown ){
                lu.push_back( Trip( row, col,i->value( ) ) );
            } else {
                rt.push_back( Trip( row, col-last_unknown,i->value( ) ) );
            }
        }
    }
    typedef SparseMatrix<double> SpMat;
    SpMat Lu(last_unknown,last_unknown);
    Lu.setFromTriplets( lu.begin( ), lu.end( ) );
    SpMat Rt(last_unknown,Total-last_unknown);
    Rt.setFromTriplets( rt.begin( ), rt.end( ) );
    const VectorXd Au( SimplicialCholesky<SpMat>(Lu).solve( -Rt*Ak.cast<double>() ) );
    for( int i(0); i< last_unknown; ++i ){
        const int ind( Indeces.coeff(i) );
        const double auki( Au.coeff( i ) ), alpha( min( 1., max(0., auki) ) );
        Alpha.coeffRef( ind % sz.height, ind / sz.height ) = alpha;
    }
    return Alpha;
}

void CreateAlphaMat(Mat &res, const Mat &src, const Mat &alpha)
{
    for (int i = 0; i < res.rows; ++i) {
        for (int j = 0; j < res.cols; ++j) {
            Vec4b& rgba = res.at<Vec4b>(i, j);
            const Vec3b& srcRgb = src.at<Vec3b>(i, j);
            rgba[0] = srcRgb[0];
            rgba[1] = srcRgb[1];
            rgba[2] = srcRgb[2];
            rgba[3] = alpha.at<uchar>(i, j);
//            rgba[0] = rgba[3];
//            rgba[1] = rgba[3];
//            rgba[2] = rgba[3];
        }
    }
}

Mat AddAlpha(const Mat &src, const Mat &alpha) {
    Mat ucharAlpha = convertTo<uchar>(alpha, 255);
    Mat srcWithAlpha(src.size(), CV_8UC4);

    CreateAlphaMat(srcWithAlpha, src, ucharAlpha);

    return srcWithAlpha;
}

Mat RobustMatting::CalculateMatting(const Mat& src, const Mat& trimap)
{
    const MatrixXd Alpha( SolveRobustMatting( src, trimap ) ), AlphaT( Alpha.transpose( ) );
    const Mat alpha( src.size( ), CV_MAKETYPE( DataDepth<double>::value,1 ), (void*)AlphaT.data( ) );

    return AddAlpha(src, alpha);
//    return alpha;
}


void RobustMatting::GenerateTrimap(Mat& contourImage)
{
    floodFill(contourImage, Point(0,0), Scalar(0,0,0,0));
}
//int main(int argc,char**argv)
//{
//    Mat src, mask, trimap;
//    src=imread(argv[1]);
//    trimap=imread(argv[2],0);
//    const MatrixXd Alpha( SolveRobustMatting( src, trimap ) ), AlphaT( Alpha.transpose( ) );
//    const Mat alpha( src.size( ), CV_MAKETYPE( DataDepth<double>::value,1 ), (void*)AlphaT.data( ) );
//    SaveToPng("Alpha.png", src, alpha);
//}
