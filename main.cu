#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <cmath>

using namespace std;
const unsigned SIZE = 40;
const unsigned SCALE = 100;

void matrixSet(int* array, unsigned size) {
    srand(time(nullptr));

    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            *(array + i * size + j) = rand() % SCALE;
        }
    }
}


void matrixPrint(const int* matrix, unsigned size) {
    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j)
            cout << *(matrix + j + i * size) << ' ';
        cout << endl;
    }
    cout << endl;
}

__global__ void gpuDeterminant(const int* matrix, unsigned size, long long* diagonals) {
    unsigned threadNumber = blockIdx.x * blockDim.x + threadIdx.x;  // Номер текущего потока

    /* Для матрицы размера N имеем N*2 дианогалей:
     * N положительных, и N отрицательных. */
    if (threadNumber < (size * 2)) {

        long long temp = 1;
        unsigned ind = threadNumber;

        if (threadNumber < size) {
            /* Положительная диагональ. */
            for (unsigned i = 0; i < size; i++) {
                temp *= (*(matrix + i * size + ind));
                ind = (ind + 1) % size;
            }
        }   else    {
            ind = threadNumber % size;
            /* Отрицательная диагональ. */
            for (unsigned i = 0; i < size; i++) {
                temp *= (*(matrix + i * size + ind));
                ind = ((ind + size - 1) % size);
            }
            temp *= -1;
        }
        /* Фиксируем полученное значение. */
        *((long long*)((char*)diagonals + threadNumber * sizeof(long long))) = temp;
    }
}

__global__ void inverseByMinors(const int* matrix, unsigned size, double* inverseMatrix,
                                long long initialDeterminant) {
    /* Номер текущего потока. */
    unsigned threadNumber = blockIdx.x * blockDim.x + threadIdx.x;
    /* Текущее количество элементов в миноре. */
    unsigned count = 0;
    /* Номера вычеркнутых столбца и ряда в миноре. */
    const unsigned row = threadNumber / size;
    const unsigned col = threadNumber % size;
    /* Размер минора. */
    const unsigned minorSize = size - 1;

    int* minorMatrix;
    cudaMalloc((void**)&minorMatrix, sizeof(int) * minorSize * minorSize);

    if(minorMatrix == nullptr){
        printf("Not enough memory for minor matrix.\n");
        return;
    }

    /* Собираем минор из элементов основной матрицы. */
    for (int i = 0; i < size; i++)
        for (int j = 0; j < size; j++)
            if (i != row && j != col) {
                minorMatrix[count] = *(matrix + i * size + j);
                count++;
            }

    double minorDeterminant = 0;
    unsigned positiveInd = 0;
    unsigned negativeInd = minorSize - 1;

    /* Вычисляем определитель минора. */
    for (int i = 0; (minorSize != 2 && i < minorSize) || (minorSize == 2 && i < 1); i++) {
        long long temp = 1;
        for (int j = 0; j < minorSize; j++) {
            temp *= *(minorMatrix + j * minorSize + positiveInd);
            positiveInd = (positiveInd + 1) % minorSize;
        }
        positiveInd = (positiveInd + 1) % minorSize;
        minorDeterminant += temp;

        temp = 1;
        for (int j = 0; j < minorSize; j++) {
            temp *= *(minorMatrix + j * minorSize + negativeInd);
            negativeInd = ((negativeInd + minorSize - 1) % minorSize);
        }
        negativeInd = ((negativeInd + minorSize - 1) % minorSize);
        minorDeterminant -= temp;
    }
    cudaFree(minorMatrix);

    unsigned degree = (row + col) % 2;
    if (degree)
        minorDeterminant *= -1;

    /* Помещаем полученный элемент в обратную матрицу. */
    *(inverseMatrix + col * size + row) = minorDeterminant / initialDeterminant;
}

__global__ void gpuPrint(const double* matrix, const unsigned size){
    for(int i = 0; i < size; i++){
        for(int j = 0; j < size; j++)
            printf("%f ", *(matrix + i * size + j));
        printf("\n");
    }
    printf("\n");
}

__host__ int main() {
    int matrix[SIZE * SIZE];
    matrixSet(matrix, SIZE);
    matrixPrint(matrix, SIZE);

    /* Копируем матрицу на видеокарту. */
    int* matrixGpu;
    cudaMalloc((void**)&matrixGpu, sizeof(int) * SIZE * SIZE);
    cudaMemcpy(matrixGpu, &matrix, SIZE * SIZE * sizeof(int), cudaMemcpyHostToDevice);

    long long temp = 0;
    long long determinant = 0;

    /* Вычисляем определитель исходной матрицы. */
    long long* determinantDiagonals;
    cudaMalloc((void**)&determinantDiagonals, (SIZE * 2 * sizeof(long long)));
    gpuDeterminant <<<SIZE * 2, 1 >>> (matrixGpu, SIZE, determinantDiagonals);
    cudaThreadSynchronize();
    for (int i = 0; i < SIZE * 2; i++) {
        cudaMemcpy(&temp, determinantDiagonals + i, sizeof(long long), cudaMemcpyDeviceToHost);
        determinant += temp;
    }
    cout << "Determinant = " << determinant << endl << endl;

    cudaFree(determinantDiagonals);

    double* inverseMatrixGpu;
    cudaMalloc((void**)&inverseMatrixGpu, sizeof(double) * SIZE * SIZE);

    if(inverseMatrixGpu == nullptr){
        cout << "Not enough memory for inverse matrix." << endl;
        return 0;
    }

    /* Вычисляем обратную матрицу, если она существует. */
    if (determinant != 0) {
        inverseByMinors<<<SIZE, SIZE>>> (matrixGpu, SIZE, inverseMatrixGpu, determinant);
        cudaThreadSynchronize();
        cout << "Inverse matrix:" << endl << endl;
        gpuPrint<<<1, 1>>>(inverseMatrixGpu, SIZE);
    }   else {
        cout << "Inverse matrix not exists." << endl;
        cudaFree(inverseMatrixGpu);
        cudaFree(matrixGpu);
    }
    return 0;
}
