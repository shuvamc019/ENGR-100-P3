using Sound
using FFTW
using WAV: wavread
using Plots

# creates the envelope of signal used in note duration calculation (take absolute value of average of sliding window across signal)
function find_envelope(x; h::Int = 1000) # sliding window half-width
    x = abs.(x)
    return [zeros(h);
    [sum(x[(n-h):(n+h)]) / (2h+1) for n in (h+1):(length(x)-h)];  ## FFTW could not create plan is caused by fft(Float32[]),
    zeros(h)]                                                     
end

# finds the start and attack time of each note via threshold, then stores them and their difference (i.e. the durations) in a vector
function find_durations(envelope, threshold::Float64 = 0.015)
    durations = []
    note_attack_time = -1
    note_release_time = -1

    skip = -1

    for t in 1:length(envelope)
        if t >= skip
            signal_val = envelope[t]
            if signal_val > threshold && note_attack_time == -1
                note_attack_time = t
            elseif signal_val < threshold && note_attack_time != -1
                note_release_time = t 
                push!(durations, (note_release_time - note_attack_time, note_attack_time, note_release_time))
                note_attack_time = -1 # so loop won't detect any attacks after the note signal has already started
                skip = t + 3500 # need to skip this interval since signal will both decay and oscillate around the threshold
            end
        end
    end

    return durations
end

# computes the fundamental frequency for each note via an autocorrelation of each signal segment
# also converts durations to beats with a bpm and stores in vector
function compute_frequencies(song, durations, sample, bpm::Float32, buffer::Int=150)
    frequencies = []
    
    if length(durations) == 0
        return frequencies
    end

    bps = bpm / 60  

    for j in 1:length(durations) 

        note = durations[j]
        start_time = note[2]
        end_time = note[3] 
        duration_seconds = (end_time - start_time) / sample

        signal = song[(start_time+buffer):(end_time-buffer)]
        
        if length(signal) == 0
            continue
        end
        
        autocorr = real((ifft(abs2.(fft([signal; zeros(size(signal))])))) / sum(abs2, signal))

        plot(autocorr, xlims=[0,1000])

        idxs = [autocorr[k] > autocorr[k+1] && autocorr[k] > autocorr[k-1] && autocorr[k] > 0.8 for k in 2:(length(autocorr) - 1)]
        all_idxs = findall(idxs)
        
        if length(all_idxs) == 0
            continue
        end
    
        period = all_idxs[1]
        frequency = sample/period

        note_beats = duration_seconds * bps
        note_beats = round(Integer, note_beats * 4) / 4 #rounds to nearest 0.25 for 16th notes

        push!(frequencies, (frequency, note_beats))

        if j != length(durations)
            next_note = durations[j + 1]
            rest_duration = (next_note[2] - note[3]) / sample

            rest_beats = rest_duration * bps
            rest_beats = round(Integer, rest_beats * 4) / 4

            push!(frequencies, (-1, rest_beats)) # "frequency" of rest is -1
        end
    end

    return frequencies
end