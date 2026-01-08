
bool a = false;

active proctype proc() {
    do
    ::
        a = true;
        printf("first branch\n");
    ::
        a = false;
        printf("if only this branch is executed\n");
    od
}


// wrong, due to the non-deterministic, there is a counterexample that only the second branch is executed.
//ltl p { <>a } 


// the search algorithm is to find counterexample. 
// if we negate the property and put it in invariance operator,
// the failure of verification means the original property holds!
ltl q { !([](!a))}