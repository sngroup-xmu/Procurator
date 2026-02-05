// Procurator verification wrapper for DDOSD:
// - enables deterministic hash mode to make the bug trigger reproducible and fast.
//
// IMPORTANT: This file should only be used for verification specs; the original program
// remains in `ddosd.p4`.

#define PROCURATOR_DETERMINISTIC_HASH 1

#include "ddosd.p4"

