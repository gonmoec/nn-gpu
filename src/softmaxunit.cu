#include "softmaxunit.h"
#include "matrix_function.h"
#include "cuda_common.h"

using namespace mtk;

class Exp{
public:
	__device__ float operator()(float a) const{
		return expf(a);
	}
};
class Inverse{
public:
	__device__ float operator()(float a) const{
		return 1.0f/a;
	}
};

SoftmaxUnit::SoftmaxUnit(int input_size,int output_size,int batch_size,std::string unit_name,cublasHandle_t cublas,float learning_rate,float adagrad_epsilon,float attenuation_rate):
	BaseUnit(input_size,output_size,batch_size,unit_name,cublas,learning_rate,adagrad_epsilon,attenuation_rate)
{
	input_row_0.setSize(1,batch_size)->allocateDevice()->initDeviceConstant(0.0f);
	inverse.setSize(output_size,batch_size)->allocateDevice()->initDeviceConstant(0.0f);
	output0.setSize(output_size,batch_size)->allocateDevice()->initDeviceConstant(0.0f);
}

SoftmaxUnit::~SoftmaxUnit(){}

void SoftmaxUnit::learningBackPropagation(mtk::MatrixXf& next_error,const mtk::MatrixXf& d2,const mtk::MatrixXf *w2){
	BaseUnit::learningBackPropagation(next_error,d2);
}
void SoftmaxUnit::learningBackPropagation(mtk::MatrixXf &next_error, const mtk::MatrixXf &d2){
	BaseUnit::learningBackPropagation(next_error,d2);
}

void SoftmaxUnit::testActivation(mtk::MatrixXf& output,const mtk::MatrixXf& input){
	//input行列の0行目を取り出す
	const float one = 1.0f,minus_one = -1.0f,zero = 0.0f;
	mtk::MatrixFunction::copy(cublas,output,input);
	// 全列の要素からその列の先頭要素の値を引く
	CUBLAS_HANDLE_ERROR( cublasScopy(cublas,test_batch_size,
				input.getDevicePointer(), output_size,
				test_input_row_0.getDevicePointer(),1));
	CUBLAS_HANDLE_ERROR( cublasSgemm(cublas,CUBLAS_OP_N,CUBLAS_OP_N,
				output_size,output.getCols(),1,
				&minus_one,
				all1_o.getDevicePointer(),output_size,
				test_input_row_0.getDevicePointer(),1,
				&one,
				output.getDevicePointer(),output_size) );
	mtk::MatrixFunction::map<Exp>(output,output);
	// 和を取る
	CUBLAS_HANDLE_ERROR( cublasSgemm(cublas,CUBLAS_OP_N,CUBLAS_OP_N,
				1,test_batch_size,output_size,
				&one,
				all1_o.getDevicePointer(),1,
				output.getDevicePointer(),output_size,
				&zero,
				test_input_row_0.getDevicePointer(),1));
	// 逆数を計算
	mtk::MatrixFunction::map<Inverse>(test_input_row_0,test_input_row_0);
	// 逆数の行列を計算
	CUBLAS_HANDLE_ERROR( cublasSgemm( cublas, CUBLAS_OP_N,CUBLAS_OP_N,
				output_size,test_batch_size,1,
				&one,
				all1_o.getDevicePointer(),output_size,
				test_input_row_0.getDevicePointer(),1,
				&zero,
				test_inverse.getDevicePointer(),output_size) );
	mtk::MatrixFunction::elementwiseProduct(cublas,test_output0,output,test_inverse);
	mtk::MatrixFunction::copy(cublas,output,test_output0);
}
void SoftmaxUnit::learningActivation(mtk::MatrixXf& output,const mtk::MatrixXf& input){
	//input行列の0行目を取り出す
	const float one = 1.0f,minus_one = -1.0f,zero = 0.0f;
	mtk::MatrixFunction::copy(cublas,output,input);
	// 全列の要素からその列の先頭要素の値を引く
	CUBLAS_HANDLE_ERROR( cublasScopy(cublas,batch_size,
				input.getDevicePointer(), output_size,
				input_row_0.getDevicePointer(),1));
	CUBLAS_HANDLE_ERROR( cublasSgemm(cublas,CUBLAS_OP_N,CUBLAS_OP_N,
				output_size,output.getCols(),1,
				&minus_one,
				all1_o.getDevicePointer(),output_size,
				input_row_0.getDevicePointer(),1,
				&one,
				output.getDevicePointer(),output_size) );
	mtk::MatrixFunction::map<Exp>(output,output);
	// 和を取る
	CUBLAS_HANDLE_ERROR( cublasSgemm(cublas,CUBLAS_OP_N,CUBLAS_OP_N,
				1,batch_size,output_size,
				&one,
				all1_o.getDevicePointer(),1,
				output.getDevicePointer(),output_size,
				&zero,
				input_row_0.getDevicePointer(),1));
	// 逆数を計算
	mtk::MatrixFunction::map<Inverse>(input_row_0,input_row_0);
	// 逆数の行列を計算
	CUBLAS_HANDLE_ERROR( cublasSgemm( cublas, CUBLAS_OP_N,CUBLAS_OP_N,
				output_size,batch_size,1,
				&one,
				all1_o.getDevicePointer(),output_size,
				input_row_0.getDevicePointer(),1,
				&zero,
				inverse.getDevicePointer(),output_size) );
	mtk::MatrixFunction::elementwiseProduct(cublas,output0,output,inverse);
	mtk::MatrixFunction::copy(cublas,output,output0);
}

void SoftmaxUnit::testInit(int b){
	BaseUnit::testInit(b);
	this->test_input_row_0.setSize(input_size,b)->allocateDevice()->initDeviceConstant(0.0f);
	this->test_inverse.setSize(output_size,b)->allocateDevice()->initDeviceConstant(0.0f);
	this->test_output0.setSize(output_size,b)->allocateDevice()->initDeviceConstant(0.0f);
}

void SoftmaxUnit::testRelease(){
	BaseUnit::testRelease();
	this->test_input_row_0.releaseDevice();
	this->test_inverse.releaseDevice();
	this->test_output0.releaseDevice();
}
