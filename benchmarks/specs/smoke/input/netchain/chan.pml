
#define MAX_BUF_SIZE 2

chan s1 = [MAX_BUF_SIZE] of {s1_headers};
chan s2 = [MAX_BUF_SIZE] of {s1_headers};
chan s3 = [MAX_BUF_SIZE] of {s1_headers};
chan client = [MAX_BUF_SIZE] of {s1_headers};
