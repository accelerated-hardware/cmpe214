#include <stdio.h>
#include <stdlib.h>

#define MAX_LEN 512

int main(int argc, char **argv)
{
    // assume the graph is order by vertex and has vertex and edge count at frist line
    FILE *g;
    g = fopen(argv[1], "r");
    if (g == NULL)
    {
        printf("Error! Could not open file\n");
        exit(-1);
    }

    //read vertex and edge count
    char snumofV[32];
    char snumofE[32];
    fscanf(g, "%s  %s", snumofV, snumofE);
    snumofV[0] = '0';
    int numofV = atoi(snumofV);
    int numofE = atoi(snumofE);

    int *csr;
    int *edge;
    csr = (int*)malloc(sizeof(int) * numofV);
    edge = (int*)malloc(sizeof(int) * numofE);
    int v, e;
    int v_index = 0;
    int e_index = 0;
    int outdegree = 0;
    int cur_v = -1;
    while (fscanf(g, "%d  %d", &v, &e) != EOF)
    {
        /**
         * @brief when readed vertex != last vertex
         * reset vertex and record startedgeindex in csr
         * 
         */
        if (cur_v != v)
        {
            cur_v = v;
            outdegree = 1;
            csr[v_index] = e_index;
            v_index += 1;
        }
        else
        {
            outdegree += 1;
        }
        edge[e_index] = e;
        e_index += 1;
    }

    //testing
    for (int i = 0; i < numofV; i++)
    {
        printf("%d ",csr[i]);
    }
    printf("\n");
    for (int i = 0; i < numofE; i++)
    {
        printf("%d ",edge[i]);
    }
    
    fclose(g);
    return 0;
}