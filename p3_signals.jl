using Sound
using FFTW
using WAV: wavread

global song, S = wavread("guitar_solo_f minor_100bpm.wav")

#compute note durations
function find_envelope(x; h::Int = 1000) # sliding window half-width
    x = abs.(x)
    return [zeros(h);
    [sum(x[(n-h):(n+h)]) / (2h+1) for n in (h+1):(length(x)-h)];
    zeros(h)]
end

function find_frequency(attack; release)
    x = song[attack:release]
    X = (2/length(x)) * abs.(fft(x))
end

threshold = 0.05;

global envelope = find_envelope(song)
#global durations = [zeros(3) for i in size(song)[1]]
global durations = []

function find_durations()
    note_attack_time = -1
    note_release_time = -1
    note_val = -1

    for t in 1:length(envelope)
        signal_val = envelope[t]
        if signal_val > threshold && note_attack_time == -1
            note_attack_time = t
            note_val = signal_val
        elseif signal_val < threshold && note_attack_time != -1
            note_release_time = t 
            push!(durations, [note_val, note_attack_time, note_release_time])
            note_attack_time = -1
            note_val = -1
        end
    end
end

#compute frequencies



