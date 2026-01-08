

chan ch1 = [2] of {int};
chan ch2 = [2] of {int};
chan middle_ch = [2] of {int};
chan middle2_ch = [2] of {int};

int cnt1 = 0, cnt2 = 0;

proctype h1() {
    int flag;
    #define TIMES 50
    do
    //手动计数
    :: cnt1 < TIMES -> atomic {
        middle_ch ! 1;
        cnt1 = cnt1 + 1;
        printf("cnt1=%d\n", cnt1);
    }
   
    // // 无条件：
    // :: atomic {
    //     ch2 ! 1;
    //     cnt1 = cnt1 + 1;
    //     ch1 ? flag; //等待回应
    //     printf("h1 receive response %d\n", flag);
    // }
    
    //  // timeout关键字：没用，本质还是死循环（能保证的只是，每次接收方处理完后，才发下一个包）
    // :: timeout -> atomic {
    //     middle_ch ! 1;
    //     cnt1 = cnt1 + 1;
    //     ch1 ? flag; //等待回应
    // }
    
    // :: ch1 ? flag -> atomic {
    //     printf("h1 receive %d\n", flag);
    // }
    od
}




proctype h2() {
    int flag;
    do
    :: ch2 ? flag -> atomic {
        printf("h2 receive %d\n", flag);
        //cnt2 = cnt2 + 1; //用<>[](cnt1 == cnt2)可以发现这个错误！！！但是[]( cnt1 > cnt2 -> <>(cnt1 == cnt2) )发现不了
        if
        :: flag == 1 ->
             cnt2 = cnt2 + 1; // 对
            printf("cnt2=%d\n", cnt2);
        :: else -> skip;
        fi
    }
    od
}


// 中转
proctype middle() {
    int flag;
    do
    :: middle_ch ? flag -> atomic {
        // if
        ch2 ! flag;
        // :: ch3 ! flag;
        // fi
    }
    od
}


proctype middle2() {
    int flag;
    do
    :: middle2_ch ? flag -> atomic {
        ch2 ! flag;
    }
    od
}



proctype h3() {
    #define TIMES 50
    int cnt3 = 0;
    do
    // 手动计数
    :: cnt3 < TIMES -> atomic {
        middle_ch ! 3;
        cnt3 = cnt3 + 1;
    }
    // :: timeout -> atomic {
    //     middle_ch ! 3;
    //     cnt3 = cnt3 + 1;
    // }
    //  :: ch3 ? flag -> atomic {

    //  }
    od
}

//ltl a {[]( <>(cnt1 > cnt2) -> <>(cnt1 == cnt2) ) }
// ltl a {[]( cnt1 > cnt2 -> <>(cnt1 == cnt2) ) } // response
ltl a {<>[](cnt1 == cnt2) }

// ltl a {[]<>(cnt1 == cnt2) }

init {
    atomic {
        run h1();
        run middle();
        run h2();
        //run h3();
    }
}

// trace {
//     do 
//     :: middle_ch!1; ch2?1 // 每次往middle_ch发一个1，之后 ch2 就会收到一个 1（注意，发两次1，ch2才收到第一个，是不满足这个要求的）
//     :: middle_ch!3; ch2?3;
//     od
// }

// trace {
//     do
//     :: middle_ch ! 1
//     :: ch2 ? 1
//     :: middle_ch ! 3
//     :: ch2 ? 3
//     // :: break;
//     :: 
//     od
// }

