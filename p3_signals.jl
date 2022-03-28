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

threshold = 0.015;

global envelope = find_envelope(song)
#global durations = [zeros(3) for i in size(song)[1]]
global durations = []

function find_durations()
    note_attack_time = -1
    note_release_time = -1
    note_val = -1

    skip = -1

    for t in 1:length(envelope)
        if t >= skip
            signal_val = envelope[t]
            if signal_val > threshold && note_attack_time == -1
                note_attack_time = t
                note_val = signal_val
            elseif signal_val < threshold && note_attack_time != -1
                note_release_time = t 
                push!(durations, [note_val, note_attack_time, note_release_time])
                note_attack_time = -1
                note_val = -1
                skip = t + 3500
            end
        end
    end
end

global beats = []
global bpm = 100 # give the user the ability to input this later on
bps = bpm / 60

function calculate_beats()
    for i in 1:length(durations)
        note = durations[i]
        val = note[1]
        duration = (note[3] - note[2]) / S

        note_beats = duration * bps
        note_beats = round(Integer, note_beats * 4) / 4 #rounds to nearest 0.25

        push!(beats, [val, note_beats])

        if i != length(durations)

            next_note = durations[i + 1]
            rest_duration = (next_note[2] - note[3]) / S

            rest_beats = rest_duration * bps
            rest_beats = round(Integer, rest_beats * 4) / 4

            push!(beats, [-1, rest_beats])
        end
    end
end

global song_len = 0
function song_length()
    first = durations[1][2]
    last =  durations[length(durations)][3]
    song_len = (last - first) / S
    song_len *= bps
    song_len = round(Integer, song_len * 4) / 4
end

#compute frequencies

function compute_frequencies()
    for i in durations
        start_time = i[2]
        end_time = i[3]
        N_seg = end_time - start_time
        signal = song[start_time:end_time]
        Signal = 2/N_seg * abs.(fft(signal))
    end
end