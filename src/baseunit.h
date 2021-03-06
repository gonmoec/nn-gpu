#pragma once
#include <string>
#include "matrix_array.h"
#include "cublas_common.h"
namespace mtk{
	class BaseUnit{
	protected:
		std::string unit_name;
		int output_size,input_size;
		int batch_size,test_batch_size;
		float attenuation_rate,learning_rate,adagrad_epsilon;
		cublasHandle_t cublas;

		mtk::MatrixXf theta;

		mtk::MatrixXf w1;
		mtk::MatrixXf dw1;
		mtk::MatrixXf rdw1;
		mtk::MatrixXf b1;
		mtk::MatrixXf db1;
		mtk::MatrixXf rdb1;
		mtk::MatrixXf u1;
		mtk::MatrixXf z0;
		mtk::MatrixXf d1;
		mtk::MatrixXf adagrad_w1;
		mtk::MatrixXf adagrad_b1;

		mtk::MatrixXf all1_b; // 1がbatch_size個
		mtk::MatrixXf all1_o; // 1がoutput_size個
		mtk::MatrixXf all1_i; // 1がinput_size個
		mtk::MatrixXf u; // back propagatinで使用
		mtk::MatrixXf max_b_i; //重みが大きくなりすぎないようにするときに必要
		mtk::MatrixXf max_w_i; //重みが大きくなりすぎないようにするときに必要
		mtk::MatrixXf w1_tmp;
		mtk::MatrixXf b1_tmp;

		mtk::MatrixXf test_u;
		mtk::MatrixXf all1_t;

		virtual void learningActivation(mtk::MatrixXf& output,const mtk::MatrixXf& input) = 0;
		virtual void testActivation(mtk::MatrixXf& output,const mtk::MatrixXf& input) = 0;
	public:
		BaseUnit(int input_size,int output_size,int batch_size,std::string unit_name,cublasHandle_t cublas,float learning_rate,float adagrad_epsilon,float attenuation_rate);
		~BaseUnit();
		void learningForwardPropagation(mtk::MatrixXf &output,const mtk::MatrixXf &input);
		void learningReflect();
		virtual void learningBackPropagation(mtk::MatrixXf& next_error,const mtk::MatrixXf &d2,const mtk::MatrixXf* w2) = 0;
		void learningBackPropagation(mtk::MatrixXf& next_error,const mtk::MatrixXf &d2); //最終層にある時

		virtual void testInit(int test_batch_size);
		void testForwardPropagation(mtk::MatrixXf &output,const mtk::MatrixXf &input) ;
		virtual void testRelease();

		mtk::MatrixXf* getWeightPointer();
		mtk::MatrixXf* getBiasPointer();
		int getInputSize();
		int getOutputSize();
		std::string getNetworkName();
	};
}
