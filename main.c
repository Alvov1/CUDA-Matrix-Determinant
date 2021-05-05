#include "stdio.h"
#include "stdlib.h"
#include "time.h"
#include "math.h"

int SIZE = 3;


void matrixSet(int** matrix, int size) {
    srand(time(NULL));

    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            matrix[i][j] = rand() % 100;
        }
    }
}


void matrixPrint(int** matrix, int size) {
    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            printf("%d ", matrix[i][j]);
        }
        printf("\n");
    }

    printf("\n");
}


int cycle(int index, int size) {
    if (index + 1 < size) {
        return index + 1;
    }
    else {
        return 0;
    }
}


int cycle_reverse(int index, int size) {
    if (index - 1 < 0) {
        return size - 1;
    }
    else {
        return index - 1;
    }
}


long find_determinant(int** matrix, int size) {
    long right_diagonal = 0;
    long left_diagonal = 0;

    if (size == 2) {
        right_diagonal = matrix[0][0] * matrix[1][1];
        left_diagonal = matrix[0][1] * matrix[1][0];
    }
    else {
        for (int i = 0; i < size; ++i) {
            long next_level = 1;
            long number = matrix[0][i];
            long new_elem = cycle(i, size);

            for (int j = 0; j < size - 1; ++j) {
                long next_element = matrix[next_level][new_elem];
                number *= next_element;
                next_level = cycle(next_level, size);
                new_elem = cycle(new_elem, size);
            }
            right_diagonal += number;
        }

        for (int i = size - 1; i >= 0; --i) {
            long next_level = 1;
            long number = matrix[0][i];
            long new_elem = cycle_reverse(i, size);

            for (int j = 0; j < size - 1; ++j) {
                long next_element = matrix[next_level][new_elem];
                number *= next_element;
                next_level = cycle(next_level, size);
                new_elem = cycle_reverse(new_elem, size);
            }
            left_diagonal += number;
        }
    }

    long result = right_diagonal - left_diagonal;

    return result;
}


int** create_minor(int** matrix) {
    int** temp_matrix = (int**)malloc((SIZE - 1) * sizeof(int*));
    int** minor_matrix = (int**)malloc(SIZE * sizeof(int*));

    for (int k = 0; k < SIZE; ++k) {
        minor_matrix[k] = (int *)malloc(SIZE * sizeof(int));
    }
    for (int k = 0; k < SIZE - 1; ++k) {
        temp_matrix[k] = (int*)malloc((SIZE - 1) * sizeof(int));
    }

    matrixSet(temp_matrix, SIZE - 1);

    for (int i = 0; i < SIZE; ++i) {
        int bad_raw = i;

        for (int j = 0; j < SIZE; ++j) {
            int bad_column = j;

            int temp_raw = 0;
            int temp_column = 0;
            for (int k = 0; k < SIZE; ++k) {
                for (int l = 0; l < SIZE; ++l) {
                    if (k != bad_raw && l != bad_column) {
                        temp_matrix[temp_raw][temp_column] = matrix[k][l];
                        temp_column++;
                    }
                }

                if (temp_column == SIZE - 1) {
                    temp_column = 0;
                    temp_raw++;
                }
            }

            for (int g = 0; g < SIZE - 1; ++g) {
                for (int f = 0; f < SIZE - 1; ++f) {
                    //                    printf("%d ", temp_matrix[g][f]);
                }
                //                printf("\n");
            }

            if (SIZE - 1 == 1) {
                for (int g = 0; g < SIZE - 1; ++g) {
                    for (int f = 0; f < SIZE - 1; ++f) {
                        if (i == j) {
                            minor_matrix[i][j] = pow(-1, bad_column + bad_raw + 2) * temp_matrix[g][f];
                        }
                        else {
                            minor_matrix[i][j] = pow(-1, bad_column + bad_raw + 2) * matrix[i][j];
                        }
                    }
                }
                //                printf("\nDelete raw: %d\nDelete column: %d\n", bad_raw + 1, bad_column + 1);
                //                printf("================================\n");
            }
            else {
                int temp_determinant = find_determinant(temp_matrix, SIZE - 1);
                temp_determinant *= pow(-1, bad_column + bad_raw + 2);
                minor_matrix[i][j] = temp_determinant;
                //                printf("\nDelete raw: %d\nDelete column: %d\nDeterminant: %d\n", bad_raw + 1, bad_column + 1, temp_determinant);
                //                printf("================================\n");
            }
        }
    }

    return (int**)minor_matrix;
}


int main() {
    int** matrix;
    matrix = (int**)malloc(SIZE * sizeof(int*));

    for (int i = 0; i < SIZE; ++i) {
        matrix[i] = (int*)malloc(SIZE * sizeof(int));
    }

    matrixSet(matrix, SIZE);
    matrixPrint(matrix, SIZE);

    clock_t first = clock();
    long long determinant = find_determinant(matrix, SIZE);
    clock_t second = clock();
    //printf("Time for det = %f\n", (double) (second - first) / CLOCKS_PER_SEC);

    float anti_determinant = 1;

    if (determinant == 0) {
        printf("Doesn't have reverse matrix");
        return 0;
    }
    printf("Determinant: %d\n", determinant);

    clock_t firstS = clock();
    int** minor_matrix = create_minor(matrix);
    clock_t secondS = clock();

    //printf("Time for inv = %f\n\n", (double) (secondS - firstS) / CLOCKS_PER_SEC);

    clock_t firstT = clock();
    for (int i = 0; i < SIZE; ++i) {
        for (int j = 0; j < SIZE; ++j) {
            //            printf("%d\t", minor_matrix[i][j]);
            printf("%f\t", minor_matrix[j][i] * (anti_determinant / determinant));
        }
        printf("\n");
    }
    clock_t secondT = clock();
    //printf("\nTime for print = %f\n", (double) (secondT - firstT) / CLOCKS_PER_SEC);

    return 0;
}

