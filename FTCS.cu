#include <iostream>
#include <algorithm>
#include <cmath>
#include <vector>
#include <bits/stdc++.h>
#include <time.h>


using namespace std;

__global__ void compute(float *d_U_n, float *d_U_n1, int *d_M, int *d_N, float *d_d){
    int t= threadIdx.x+blockDim.x*blockIdx.x;
    d_U_n1[0]=0;
    d_U_n1[*d_N -1]=0;
    if (t < *d_N -2){
        d_U_n1[t+1]= (*d_d)*d_U_n[t]+(1-2*(*d_d))*d_U_n[t+1] +(*d_d)*d_U_n[t+2];
    }

}

int main(){
    int L=1;
    int T=1;
    float dx= 0.1;
    float dt=0.001;
    int alpha=1;
    float d=(alpha*dt)/(dx*dx);

    // space nodes
    int N= L/dx +1;
    cout<<N<<endl;
    // time nodes
    int M= T/dt +1;
    cout<<M<<endl;

    float x[N];
    float t[M];
    for (int i=0; i<N; i++){
        x[i]=0+(i-1)*dx;
    }
    for (int j=0; j<M; j++){
        t[j]= 0+(j-1)*dt;
    }
    float U[M][N];
    for (int i=0; i<M; i++){
        if (i==0){
            for (int j=0; j<N; j++){
                U[i][j]= sin(4*M_PI*x[j]);
            }
        } 

        else{
            for (int j=0; j<N; j++){
                U[i][j]=0;
            }
            
        }
    }
    float *h_U_n;
    h_U_n= (float*)malloc(N*sizeof(float));
    h_U_n[0]=0;
    h_U_n[N-1]=0;
    for (int i=1; i<N-1; i++){
        h_U_n[i-1]=U[0][i];
    }
    float *d_U_n;
    float *d_U_n1;
    int *d_M;
    int *d_N;
    float *d_d;
    
    cudaMalloc((void**) &d_M, sizeof(int));
    cudaMalloc((void**) &d_N, sizeof(int));
    cudaMalloc((void**) &d_d, sizeof(float));

    cudaMalloc((void**) &d_U_n, N*sizeof(float));
    cudaMalloc((void**) &d_U_n1, N*sizeof(float));
    cudaEvent_t start, stop; 
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milsec=0.0;
    cudaEventRecord(start);
    cudaMemcpy(d_M, &M, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_N, &N, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_d, &d, sizeof(float), cudaMemcpyHostToDevice);

    for (int i=0; i<M-1; i++){
        cudaMemcpy(d_U_n, h_U_n, N*sizeof(float), cudaMemcpyHostToDevice);
        compute <<< N/64 +1, 64>>> (d_U_n, d_U_n1, d_M, d_N, d_d);

        cudaMemcpy(h_U_n, d_U_n1, N*sizeof(float), cudaMemcpyDeviceToHost);
        for (int j=1; j<N-1; j++){
            U[i+1][j]=h_U_n[j];
        }
    }
    cudaEventRecord(stop);

    for (int i=0; i<M; i++){
        for (int j=0; j<N; j++){
            cout<<U[i][j]<<" ";
        }
        cout<<endl;
    }
    cudaEventElapsedTime(&milsec, start, stop);
    cout<< "Time taken by the GPU is : "<<milsec<<endl;
    
}
