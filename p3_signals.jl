using Sound
using FFTW

#compute note durations
for i in 1:(length(song) / 100)
    mean_point = mean(abs.(song[i:i+100]))
    
end
#compute frequencies



