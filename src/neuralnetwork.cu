#include <iostream>
#include "neuralnetwork.h"
#include "cublas_common.h"
#include "matrix_function.h"

using namespace mtk;

NeuralNetwork::NeuralNetwork(int batch_size,cublasHandle_t cublas)
	: batch_size(batch_size),cublas(cublas)
{}

NeuralNetwork* NeuralNetwork::add(mtk::BaseUnit *network){
	networks.push_back(network);
	return this;
}

NeuralNetwork::~NeuralNetwork(){
	this->release();
}

NeuralNetwork* NeuralNetwork::calcError(mtk::MatrixXf &error,const mtk::MatrixXf &output,const mtk::MatrixXf& teacher){
	float minus_one = -1.0f;
	mtk::MatrixFunction::copy(cublas,error,output);
	CUBLAS_HANDLE_ERROR(cublasSaxpy(cublas,output.getSize(), &minus_one,
				teacher.getDevicePointer(),1,
				error.getDevicePointer(),1));
	return this;
}

NeuralNetwork* NeuralNetwork::construct(){
	for(int i = 0;i < networks.size()-1;i++){
		mtk::MatrixXf *layer = new mtk::MatrixXf;
		layer->setSize(networks[i]->getOutputSize(),batch_size)->allocateDevice()->initDeviceConstant(0.0f);
		layers.push_back(layer);
	}
	for(auto network : networks){
		mtk::MatrixXf *error = new mtk::MatrixXf;
		error->setSize(network->getOutputSize(),batch_size)->allocateDevice()->initDeviceConstant(0.0f);
		errors.push_back(error);
	}
	std::cout<<"Layers"<<std::endl;
	std::cout<<" - layers : "<<layers.size()<<std::endl;
	for(auto layer : layers)
		std::cout<<"	- ( "<<layer->getRows()<<" , "<<layer->getCols()<<" )"<<std::endl;
	std::cout<<" - errors : "<<errors.size()<<std::endl;
	for(auto error : errors)
		std::cout<<"	- ( "<<error->getRows()<<" , "<<error->getCols()<<" )"<<std::endl;
	return this;
}

NeuralNetwork* NeuralNetwork::learningForwardPropagation(mtk::MatrixXf& output,const mtk::MatrixXf& input){
	if(networks.size()==1){
		networks[0]->learningForwardPropagation(output,input);
	}else{
		networks[0]->learningForwardPropagation(*layers[0],input);
		for(int i = 1;i < networks.size()-1;i++){
			networks[i]->learningForwardPropagation((*layers[i]),(*layers[i-1]));
		}
		networks[networks.size()-1]->learningForwardPropagation(output,(*layers[networks.size()-2]));
	}
	return this;
}

NeuralNetwork* NeuralNetwork::learningBackPropagation(const mtk::MatrixXf &error){
	networks[networks.size()-1]->learningBackPropagation((*errors[errors.size()-1]),error,nullptr);
	for(int i = networks.size()-2;i >= 0;i--){
		networks[i]->learningBackPropagation(*errors[i],*errors[i+1],networks[i+1]->getWeightPointer());
	}
	for(auto network : networks)
		network->learningReflect();
	return this;
}

void NeuralNetwork::release(){
	for(auto layer : layers){
		delete layer;
	}
	for(auto error : errors){
		delete error;
	}
}

NeuralNetwork* NeuralNetwork::testInit(int test_batch_size){
	for(auto network : networks){
		network->testInit(test_batch_size);
	}
	for(int i = 0;i < networks.size()-1;i++){
		mtk::MatrixXf *layer = new mtk::MatrixXf;
		layer->setSize(networks[i]->getOutputSize(),test_batch_size)->allocateDevice()->initDeviceConstant(0.0f);
		test_layers.push_back(layer);
		std::cout<<"test layer ("<<layer->getRows()<<" , "<<layer->getCols()<<" )"<<std::endl;
	}
	return this;
}


NeuralNetwork* NeuralNetwork::testForwardPropagation(mtk::MatrixXf& output,const mtk::MatrixXf& input){
	/*if(networks.size()==1){
		networks[0]->testForwardPropagation(output,input);
	}else{
		//networks[0]->testForwardPropagation(*test_layers[0],input);
		networks[0]->learningForwardPropagation(*test_layers[0],input);
		for(int i = 1;i < networks.size()-1;i++){
			//networks[i]->testForwardPropagation((*test_layers[i]),(*test_layers[i-1]));
			networks[i]->learningForwardPropagation((*test_layers[i]),(*test_layers[i-1]));
		}
		//networks[networks.size()-1]->testForwardPropagation(output,(*test_layers[networks.size()-2]));
		networks[networks.size()-1]->learningForwardPropagation(output,(*test_layers[networks.size()-2]));
	}
	return this;*/
	if(networks.size()==1){
		networks[0]->testForwardPropagation(output,input);
	}else{
		networks[0]->testForwardPropagation(*test_layers[0],input);
		for(int i = 1;i < networks.size()-1;i++){
			networks[i]->testForwardPropagation((*test_layers[i]),(*test_layers[i-1]));
		}
		networks[networks.size()-1]->testForwardPropagation(output,(*test_layers[networks.size()-2]));
	}
	/*for(auto layer : test_layers){
		layer->allocateHost()->copyToHost()->print("layer"+std::to_string(layer->getRows())+"x"+std::to_string(layer->getCols()));
	}*/
	return this;
}
void NeuralNetwork::testRelease(){
	for(auto network : networks){
		network->testRelease();
	}
	for(auto layer : test_layers){
		delete layer;
	}
}
