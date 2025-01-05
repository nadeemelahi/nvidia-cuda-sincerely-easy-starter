
#include <stdio.h>
/* #include <stdlib.h> */ /* malloc() */
#include <time.h>


//https://developer.nvidia.com/blog/even-easier-introduction-cuda

// make it a CUDA kernel function using __global__ keyword
//
__global__ 
void add_on_gpu ( int lim 
		, float *xaxis 
		, float *yaxis
		, float *sumxy
		
		){

	int idx ;

	//int trdidx = blockIdx.x * blockDim.x + threadIdx.x ;
	//int stride = blockDim.x * gridDim.x ;

	//int trdidx = threadIdx.x ;
	//int stride = blockDim.x ;

	//for ( idx = trdidx ; idx < lim ; idx += stride ){

	for ( idx = 0; idx < lim ; idx += 1 ){

		sumxy[idx] = xaxis[idx] + yaxis[idx] ;

	}

}

void add_on_cpu ( int lim 
		, float *xaxis 
		, float *yaxis
		, float *sumxy
		
		){

	int idx;

	for ( idx = 0 ; idx < lim ; idx ++ ){

		sumxy[idx] = xaxis[idx] + yaxis[idx] ;

	}

}

void printFloatArray( int lim
		, float *arr
		
		){
	int idx;

	for ( idx = 0 ; idx < lim ; idx ++ ) {
		printf("arr[idx] = %f\n", arr [ idx ] );
	}
}

void initializeData ( int lim
		, float *xaxis
		, float *yaxis
		, float *sumxy

		){

	int idx ;

	for ( idx = 0 ; idx < lim ; idx ++ ) {

		xaxis[idx] = 1.0;
		yaxis[idx] = 1.0;
		sumxy[idx] = 0.0;
	}

}

int main(void){

	int idx 
	    , lim  = 1e8 // data size - max 9 for int
	    // 9 will compile but wont run, max 8
	    , loopCnt = 1e7
	    , threadCnt = 1 // geforce gt 1030 has 384 cores - no difference after 2000 
	    , blockCnt = 1 //( lim + threadCnt - 1 ) / threadCnt // pretty much does not work so leave it at one
	    ;

	printf("lim: %d , loopCnt: %d \n", lim , loopCnt);

	float *xaxis ; 
	float *yaxis ; 
	float *sumxy ; 

	//xaxis = malloc( sizeof(float) * lim );
	//yaxis = malloc( sizeof(float) * lim );
	//sumxy = malloc( sizeof(float) * lim );

	// Allocate Unified Memory -- accessible from CPU or GPU
	cudaMallocManaged( &xaxis , lim * sizeof(float) ) ;
	cudaMallocManaged( &yaxis , lim * sizeof(float) ) ;
	cudaMallocManaged( &sumxy , lim * sizeof(float) ) ;

	// time since jan 1st 1970
	time_t ct, lt, dt;
	ct = time(NULL); lt = ct; dt = 0;	

	printf("starting timer\n");
	printf("lt: %d , ct: %d , dt: %d\n", lt, ct, dt );
	lt = ct; ct = time(NULL); dt = ct - lt; printf("lt: %d , ct: %d , dt: %d\n", lt, ct, dt );

	
	// initialize data
	printf("\ninitializing data for add on cpu\n");
	initializeData( lim , xaxis , yaxis , sumxy ) ;
	lt = ct; ct = time(NULL); dt = ct - lt; printf("lt: %d , ct: %d , dt: %d\n", lt, ct, dt );

	// add on cpu
	/*
	printf("adding on cpu\n");
	for ( idx = 0 ; idx < loopCnt ; idx ++ ) {
		add_on_cpu ( lim , xaxis , yaxis , sumxy ) ;
	}
	lt = ct; ct = time(NULL); dt = ct - lt; printf("lt: %d , ct: %d , dt: %d\n", lt, ct, dt );
	*/

	// re-initialize data
	printf("\nre-initializing data for add on gpu\n");
	initializeData( lim , xaxis , yaxis , sumxy ) ;
	lt = ct; ct = time(NULL); dt = ct - lt; printf("lt: %d , ct: %d , dt: %d\n", lt, ct, dt );

	//add on gpu
	printf("adding on gpu\n");
	for ( idx = 0 ; idx < loopCnt ; idx ++ ) {
		add_on_gpu <<< blockCnt , threadCnt >>> ( lim , xaxis , yaxis , sumxy ) ;
	}
	// wait for device(gpu) to finish before accessing on host(cpu)
	cudaDeviceSynchronize() ;
	lt = ct; ct = time(NULL); dt = ct - lt; printf("lt: %d , ct: %d , dt: %d\n", lt, ct, dt );
	
	//printf("printing out data\n"); printFloatArray( lim , sumxy ) ;


	cudaFree( xaxis ) ;
	cudaFree( yaxis ) ;
	cudaFree( sumxy ) ;


	return 0 ;
}
