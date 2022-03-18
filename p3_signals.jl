using Sound
using FFTW


#record guitar signals (one for each note)
tonic, S = record(2)
mediant, S = record(2)
dominant, S = record(2)

#