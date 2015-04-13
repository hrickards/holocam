http://kelinginc.net/KL23H51-24-8B.pdf
Stepper drivers unipolar. Connect them to drivers as bipolar.
Can do this either in series or parallel, Pololu recommends bipolar series.

See datasheet and https://www.pololu.com/product/2132/faqs for wiring.


Turning the 8-wire stepper into a bipolar series (4-wire) stepper is done at the motor. (Two sets of common leads are tied together).
The four relevant leads then come out, and each lead is turned into a twisted pair (i.e. blue -> blue & blue-white). Colours are kept the same, apart from white which goes to orange & orange-white.
