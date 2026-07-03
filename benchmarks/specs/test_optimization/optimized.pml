#define max  7 * 1000


int a, b;


inline func_1() {
    if
    :: a == 5 ->
 label1:       b = b + 7;
    :: else ->
 label2:        a = a + 1;
    fi
}


inline noAction() {
    skip;
}

inline func_2() {
    if
    :: a < 5 ->
        func_1();
        //goto label2;
    :: b < max ->
        //func_1();
        goto label1;
    :: else ->
        noAction();
    fi
}

active proctype x() {
    do
    :: atomic {
        func_2();
    }
    od
}

ltl p {[] (a <= 5 && b <= max)}
