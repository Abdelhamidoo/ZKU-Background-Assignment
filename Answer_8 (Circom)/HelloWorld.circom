pragma circom 2.0.3;     // Specify circom compiler version

template Multiplier2(){  // Declare a circuit (template) "Multiplier2()"
   signal input in1;     // Declare an input signal "in1"
   signal input in2;     // Declare an input signal "in2"
   signal output out;    // Declare an output signal "out"
   out <== in1 * in2;    // Assign the product of the "in1" and "in2" input signals to the "out" output signal
   log(out);             // Print the value of the output signal "out" on the console
}

component main {public [in1,in2]} = Multiplier2();  // Instantiate the "main" component with the template "Multiplier2()" and specify "in1" and "in2" input signals as public signals   

/* INPUT = {
    "in1": "5",
    "in2": "77"
} */