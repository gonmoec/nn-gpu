#include "hiddenlayer.h"
#include "activation.h"
#include <iostream>

using namespace mtk;

const int BLOCKS = 1 << 7;

template<class T>
__global__ void deviceMap(float *device_ptr_dst,float* device_ptr_src,int max_t){
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	if(max_t <= tid)
		return;
	device_ptr_dst[tid] = T()(device_ptr_src[tid]);
}
__global__ void devicePointwiseProduct(float *device_ptr_dst,float* device_ptr_src0,float* device_ptr_src1,int max_t){
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	if(max_t <= tid)
		return;
	device_ptr_dst[tid] = device_ptr_src0[tid] * device_ptr_src1[tid];
}




HiddenLayer::HiddenLayer(int input_size,int output_size,int batch_size,std::string layer_name,cublasHandle_t *cublas):
	BaseLayer(input_size,output_size,batch_size,layer_name,cublas)
{}

HiddenLayer::~HiddenLayer(){
	std::cout<<this->layer_name<<" is destructed"<<std::endl;
}
//HiddenLayer::~HiddenLayer(){}

void HiddenLayer::learningBackPropagation(mtk::MatrixXf &next_error, const mtk::MatrixXf &d2, const mtk::MatrixXf *w2){
	int u1_size = u1.getRows() * u1.getCols();
	const float one = 1.0f,zero = 0.0f;
	deviceMap<dActReLU><<<BLOCKS,(u1_size+BLOCKS-1)/BLOCKS>>>(u1.getDevicePointer(),u1.getDevicePointer(),u1_size);
	CUBLAS_HANDLE_ERROR(cublasSgemm(*cublas,CUBLAS_OP_T,CUBLAS_OP_N,
			output_size,batch_size,input_size,
			&one,
			w2->getDevicePointer(),w2->getRows(),
			d2.getDevicePointer(),d2.getRows(),
			&zero,
			u.getDevicePointer(),u.getRows()));
	//devicePointwiseProduct<<<BLOCKS,(u1_size+BLOCKS-1)/BLOCKS>>>(next_error.getDevicePointer(),u.getDevicePointer(),u1.getDevicePointer(),u1_size);
	CUBLAS_HANDLE_ERROR(cublasSsbmv(*cublas,CUBLAS_FILL_MODE_LOWER,
			u1_size,0,&one,
			u.getDevicePointer(),1,
			u1.getDevicePointer(),1,
			&zero,next_error.getDevicePointer(),1));
	float alpha = 1.0f/batch_size;
	CUBLAS_HANDLE_ERROR(cublasSgemm(*cublas,CUBLAS_OP_N,CUBLAS_OP_T,
			output_size,input_size,batch_size,
			&alpha,
			next_error.getDevicePointer(),next_error.getRows(),
			z0.getDevicePointer(),z0.getRows(),
			&zero,
			rdw1.getDevicePointer(),rdw1.getRows()));
	CUBLAS_HANDLE_ERROR(cublasSgemm(*cublas,CUBLAS_OP_N,CUBLAS_OP_T,
			output_size,input_size,batch_size,
			&alpha,
			next_error.getDevicePointer(),next_error.getRows(),
			all1_b.getDevicePointer(),z0.getRows(),
			&zero,
			rdb1.getDevicePointer(),rdb1.getRows()));
	
}

void HiddenLayer::activation(mtk::MatrixXf &output, const mtk::MatrixXf &input) const {
	int matrix_size = input.getCols() * input.getRows();
	deviceMap<dActReLU><<<BLOCKS,(matrix_size+BLOCKS-1)/BLOCKS>>>(output.getDevicePointer(),input.getDevicePointer(),matrix_size);
}
