using Sound
using FFTW
using WAV: wavread
using Plots

song, S = wavread("guitar_solo_f minor_100bpm.wav")

#compute note durations
function find_envelope(x; h::Int = 1000) # sliding window half-width
    x = abs.(x)
    return [zeros(h);
    [sum(x[(n-h):(n+h)]) / (2h+1) for n in (h+1):(length(x)-h)];
    zeros(h)]
end

threshold = 0.015;

envelope = find_envelope(song)
durations = []

function find_durations()
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
                note_attack_time = -1
                skip = t + 3500
            end
        end
    end
end

#compute frequencies

bpm = 100 # give the user the ability to input this later on
bps = bpm / 60
global frequencies = []

function compute_frequencies()
    for i in 1:length(durations)
        note = durations[i]
        start_time = note[2]
        end_time = note[3] 
        duration_seconds = (end_time - start_time) / S

        signal = song[(start_time+3500):(end_time-3500)]
        global autocorr = real(ifft(abs2.(fft([signal; zeros(size(signal))])))) / sum(abs2, signal)

        #plot(0:length(autocorr)-1, autocorr, marker=:circle, markersize=3, color=:orange)

        idxs = [autocorr[k] > autocorr[k+1] && autocorr[k] > autocorr[k-1] && autocorr[k] > 0.75 for k in 2:length(autocorr) - 1]
        period = findall(idxs)[1]
        frequency = S/period

        note_beats = duration_seconds * bps
        note_beats = round(Integer, note_beats * 4) / 4 #rounds to nearest 0.25

        push!(frequencies, (frequency, note_beats))

        if i != length(durations)
            next_note = durations[i + 1]
            rest_duration = (next_note[2] - note[3]) / S

            rest_beats = rest_duration * bps
            rest_beats = round(Integer, rest_beats * 4) / 4

            push!(frequencies, (-1, rest_beats)) # "frequency" of rest is -1
        end
    end
end

# should consider making a song class so we can get song.frequencies, song.durations, etc... would make things easier
