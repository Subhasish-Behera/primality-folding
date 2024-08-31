pragma circom 2.0.0;
include "circomlib/comparators.circom";
include "circomlib/bitify.circom";

template ModPow() {
    signal input base;
    signal input exponent;
    signal input modulus;

    signal output result;

    signal acc[65];
    signal mult[64];
    signal newAcc[64];
    component n2b = Num2Bits_strict();

    n2b.in <== exponent;
    acc[0] <== 1;
    var b = base;

    for (var i = 0; i < 64; i++) {
        mult[i] <-- n2b.out[i] * b;
        newAcc[i] <== acc[i] * (mult[i] + (1 - n2b.out[i]));
        acc[i + 1] <-- newAcc[i] % modulus;
        b = (b * b) % modulus;
    }

    result <== acc[63];
}

template MillerRabinTest() {
    signal input n;
    signal input base;

    signal output isProbablyPrime;
    component isEven[64];

    signal d[64];
    var s = 0;

    d[0] <== n - 1;
    component num2lib[64];

    for (var i = 1; i < 64; i++) {
        num2lib[i] = Num2Bits_strict();
        num2lib[i].in <== d[i-1];
        var lastbit = num2lib[i].out[0];
        d[i] <-- d[i-1] % 2 == 0 ? (d[i - 1] / 2) : d[i-1];
        s += (1 - lastbit);
    }

    component modexp = ModPow();
    modexp.base <== base;
    modexp.exponent <== d[63];
    modexp.modulus <== n;

    signal x <== modexp.result;

    signal isPrimeResult[64];

    component iseq1 = IsEqual();
    component iseq2 = IsEqual();
    iseq1.in[0] <== x;
    iseq1.in[1] <== 1;
    iseq2.in[0] <== x;
    iseq2.in[1] <== n - 1;

    isPrimeResult[0] <== iseq1.out + iseq2.out;

    signal x_values[64];
    component iseq3[64];
    x_values[0] <== x;

    for (var r = 1; r < 64; r++) {
        x_values[r] <-- (x_values[r - 1] * x_values[r - 1]) % n;
        iseq3[r] = IsEqual();
        iseq3[r].in[0] <== x_values[r];
        iseq3[r].in[1] <== n - 1;
        isPrimeResult[r] <== iseq3[r].out + isPrimeResult[r-1];
    }

    component iszero = IsZero();
    iszero.in <== isPrimeResult[63];
    isProbablyPrime <== 1 - iszero.out;
}

template MillerRabinPrimalityTest64Bit() {
    signal input n;
    signal output isPrime;

    signal bases[12];
    bases[0] <== 2;
    bases[1] <== 3;
    bases[2] <== 5;
    bases[3] <== 7;
    bases[4] <== 11;
    bases[5] <== 13;
    bases[6] <== 17;
    bases[7] <== 19;
    bases[8] <== 23;
    bases[9] <== 29;
    bases[10] <== 31;
    bases[11] <== 37;

    signal result[12];

    component mrtest[12];
    mrtest[0] = MillerRabinTest();
    mrtest[0].n <== n;
    mrtest[0].base <== bases[0];
    result[0] <== mrtest[0].isProbablyPrime;

    for (var i = 1; i < 12; i++) {
        mrtest[i] = MillerRabinTest();
        mrtest[i].n <== n;
        mrtest[i].base <== bases[i];
        result[i] <== result[i-1] + mrtest[i].isProbablyPrime;
    }

    isPrime <== result[11];
}

component main = MillerRabinPrimalityTest64Bit();
/* INPUT = {
    "n": "7918"
    
   
} */