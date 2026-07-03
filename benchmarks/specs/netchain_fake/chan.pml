// #include "s1_type.pml"
// #include "s2_type.pml"
// #include "s3_type.pml"

#define MAX_BUF_SIZE 2

chan client_s1 = [MAX_BUF_SIZE] of {s1_headers};
chan s1_s2 = [MAX_BUF_SIZE] of {s1_headers};
chan s2_s3 = [MAX_BUF_SIZE] of {s1_headers};
chan s3_client = [MAX_BUF_SIZE] of {s1_headers};
