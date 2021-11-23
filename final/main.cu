/***********************************************************************************************************************
 *
 *   CMPE 214 Final Project: Optimized Breadth First Search     
 *   Samir Mohammed & Boxiang Guo                             		    
 *
 **********************************************************************************************************************/

/***********************************************************************************************************************
 *
 *                                     		    I N C L U D E S
 *
 **********************************************************************************************************************/
// CUDA includes
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cuda.h>
#include <cuda_runtime_api.h>

// Standard includes
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/***********************************************************************************************************************
 *
 *                                                   D E F I N E S
 *
 **********************************************************************************************************************/
#define NUMBER_OF_VERTICES 5

/***********************************************************************************************************************
 *
 *                                                  T Y P E D E F S
 *
 **********************************************************************************************************************/
typedef struct
{
	int index_of_first_adjacent_node_in_edge_array;    	
	int number_of_adjacent_nodes;    
} vertex;

/***********************************************************************************************************************
 *
 *                                     		     K E R N E L S
 *
 **********************************************************************************************************************/
__global__ void bfs_gpu (vertex *vertices, int *edges, bool *frontier, bool *visited, int *cost, bool *done)
{
	// generate global thread ID
	int gid = threadIdx.x + blockIdx.x * blockDim.x;

	// Loop thresholds
	int start, end;

	// Perform boundary check
	if (gid > NUMBER_OF_VERTICES)
	{
		*done = false;
	}
		
	// If vertex entry in frontier array is true and vertex has not been visited...
	if (frontier[gid] == true && visited[gid] == false)
	{
		// Print the order of the vertices in BFS
		printf("%d ", gid); 	

		// vertex has been visited
		frontier[gid] = false; // Remove vertex from frontier array
		visited[gid] = true; // Add vertex to visited array

		__syncthreads(); 

		// Initialize loop thresholds
		start = vertices[gid].index_of_first_adjacent_node_in_edge_array;
		end = start + vertices[gid].number_of_adjacent_nodes;

		// If neighbor has not been visited then add neighbor to frontier array
		for (int i = start; i < end; i++) 
		{
			int neighbor_id = edges[i];

			// If neighbor has not been visited...
			if (visited[neighbor_id] == false)
			{
				cost[neighbor_id] = cost[gid] + 1; // Update cost array
				frontier[neighbor_id] = true; // Add neighbor to frontier array
				*done = false;
			}
		}
	}
}

/***********************************************************************************************************************
 *
 *                                     			M A I N
 *
 **********************************************************************************************************************/
int main()
{
	vertex vertices[NUMBER_OF_VERTICES]; // Stores all vertices in graph
	int edges[NUMBER_OF_VERTICES]; // Stores all edges in graph

	bool done;
	
	vertex* device_vertices; // device_vertices stores the list of vertices
	int* device_edges; // device_edges stores the list of edges 
	bool* device_frontier; // device_frontier stores BFS frontier
	bool* device_visited; // device_visited stores visited vertices
	int* device_cost; // device_cost stores the mimimal number of edges from each vertex to source vertex
	bool* device_done;

	// Kernel parameters
	int grid, block;

	// Stores source vertex
	int source;

	int number_of_times_kernel_is_called;

	// Initialize vertices
	vertices[0].index_of_first_adjacent_node_in_edge_array = 0;
	vertices[0].number_of_adjacent_nodes = 2;

	vertices[1].index_of_first_adjacent_node_in_edge_array = 2;
	vertices[1].number_of_adjacent_nodes = 1;

	vertices[2].index_of_first_adjacent_node_in_edge_array = 3;
	vertices[2].number_of_adjacent_nodes = 1;

	vertices[3].index_of_first_adjacent_node_in_edge_array = 4;
	vertices[3].number_of_adjacent_nodes = 1;

	vertices[4].index_of_first_adjacent_node_in_edge_array = 5;
	vertices[4].number_of_adjacent_nodes = 0;

	// Initialize edges
	edges[0] = 1;
	edges[1] = 2;	
	edges[2] = 4;
	edges[3] = 3;
	edges[4] = 4;

	// Create and initialize frontier, visited and cost arrays
	bool frontier[NUMBER_OF_VERTICES] = { false };
	bool visited[NUMBER_OF_VERTICES] = { false };
	int cost[NUMBER_OF_VERTICES] = { 0 };

	// Initialize and insert source vertex into frontier array
	source = 0;
	frontier[source] = true;

	// Allocate device memory for necessary arrays
	cudaMalloc((void**)&device_vertices, sizeof(vertex) * NUMBER_OF_VERTICES);
	cudaMalloc((void**)&device_edges, sizeof(int) * NUMBER_OF_VERTICES);
	cudaMalloc((void**)&device_frontier, sizeof(bool) * NUMBER_OF_VERTICES);
	cudaMalloc((void**)&device_visited, sizeof(bool) * NUMBER_OF_VERTICES);
	cudaMalloc((void**)&device_cost, sizeof(int) * NUMBER_OF_VERTICES);
	cudaMalloc((void**)&device_done, sizeof(bool));

	// Transfer arrays from CPU memory to GPU global memory
	cudaMemcpy(device_vertices, vertices, sizeof(vertex) * NUMBER_OF_VERTICES, cudaMemcpyHostToDevice);
	cudaMemcpy(device_edges, edges, sizeof(int) * NUMBER_OF_VERTICES, cudaMemcpyHostToDevice);
	cudaMemcpy(device_frontier, frontier, sizeof(bool) * NUMBER_OF_VERTICES, cudaMemcpyHostToDevice);
	cudaMemcpy(device_visited, visited, sizeof(bool) * NUMBER_OF_VERTICES, cudaMemcpyHostToDevice);
	cudaMemcpy(device_cost, cost, sizeof(int) * NUMBER_OF_VERTICES, cudaMemcpyHostToDevice);

	// Set grid and block sizes
	grid = 1;
	block = 5;

	// Perform level order traversal until all vertices have been visited
	number_of_times_kernel_is_called = 0;
	printf("\n\nOrder: \n\n");
	do {
		number_of_times_kernel_is_called++;
		done = true;
		cudaMemcpy(device_done, &done, sizeof(bool), cudaMemcpyHostToDevice);
		bfs_gpu <<< grid, block >>> (device_vertices, device_edges, device_frontier, device_visited, device_cost, device_done);
		cudaMemcpy(&done, device_done, sizeof(bool), cudaMemcpyDeviceToHost);

	} while (!done); 

	// Transfer cost array back to host memory
	cudaMemcpy(cost, device_cost, sizeof(int) * NUMBER_OF_VERTICES, cudaMemcpyDeviceToHost);
	
	printf("Number of times the kernel is called : %d \n", number_of_times_kernel_is_called);

	printf("\nCost: ");
	for (int i = 0; i < NUMBER_OF_VERTICES; i++)
		printf( "%d    ", cost[i]);
	printf("\n");	

	// Return allocated memory back to device
	cudaFree(device_vertices);
	cudaFree(device_edges);
	cudaFree(device_frontier);
	cudaFree(device_visited);
	cudaFree(device_cost);
	cudaFree(device_done);
}
