
#define max 7 * 1000

int a, b;


inline func_1() {
    if
    :: a == 5 ->
        b = b + 7;
    :: else ->
        a = a + 1;
    fi
}


inline noAction() {
    skip;
}

inline func_2() {
    if
    :: a < 5 ->
        func_1();
    :: b < max ->
        func_1();
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