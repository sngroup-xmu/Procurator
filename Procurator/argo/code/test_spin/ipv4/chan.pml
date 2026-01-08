

#define MAX_BUF_SIZE 5

chan s1 = [MAX_BUF_SIZE] of {global_headers};

chan s2 = [MAX_BUF_SIZE] of {global_headers};

chan s3 = [MAX_BUF_SIZE] of {global_headers};

chan s4 = [MAX_BUF_SIZE] of {global_headers};

chan h1 = [MAX_BUF_SIZE] of {global_headers}; // h1 -> s1
chan h2 = [MAX_BUF_SIZE] of {global_headers}; // h2 -> s1
chan h3 = [MAX_BUF_SIZE] of {global_headers}; // h3 -> s2
chan h4 = [MAX_BUF_SIZE] of {global_headers}; // h4 -> s2