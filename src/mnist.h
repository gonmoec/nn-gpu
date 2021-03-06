#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <random>
#include "matrix_array.h"

namespace mtk{
	class MNISTLoader{
		// MNIST のデータ変数
		// いつかファイルから読み込みたい
		const static int train_data_amount = 60000;
		const static int test_data_amount = 10000;
		const static int data_dim = 28;
		mtk::MatrixXf image_data,label_data;
		mtk::MatrixXf test_image_data,test_label_data;
		std::mt19937 mt;

		//データ格納関係
		class MNISTData{
		public:
			float data[data_dim*data_dim];
			int label;
		};
		std::vector<MNISTData*> train_data_vector;
		std::vector<MNISTData*> test_data_vector;
		int reverse(int n);
		int loadMNISTData(std::string image_filename,std::string label_filename,std::vector<MNISTData*> &data_vector);
	public:
		MNISTLoader();
		~MNISTLoader();
		void setTrainDataToMatrix(mtk::MatrixXf& input,mtk::MatrixXf& teacher,int batch_size);
		void setTestDataToMatrix(mtk::MatrixXf& input,mtk::MatrixXf& teacher,int start,int batch_size);
		void setTrainDataToMatrixBC(mtk::MatrixXf& input,mtk::MatrixXf& teacher,int batch_size);
		int loadMNISTTrainData(std::string image_filename,std::string label_filename);
		int loadMNISTTestData(std::string image_filename,std::string label_filename);
		void printTestImage(int n);
	};
}
