 using Plots

durations = []

#=
fretboard = [["E2",82.41],["F2",87.31],["F#2",92.5],["G2",98.0],["G#2",103.83],["A2",110],["A#2",116.54],["B2",123.47],["C3",130.81],["C#3",138.59],["D3",146.83],["D#3",155.56],["E3",164.81];
             ["A2",110],["A#2",116.54],["B2",123.47],["C3",130.81],["C#3",138.59],["D3",146.83],["D#3",155.56],["E3",164.81],["F3",174.61],["F#3",185.0],["G3",196.0],["G#3",207.65],["A3",220];
             ["D3",146.83],["D#3",155.56],["E3",164.81],["F3",174.61],["F#3",185.0],["G3",196.0],["G#3",207.65],["A3",220],["A#3",233.08],["B3",246.94],["C4",261.63],["C#4",277.18],["D4",293.66];
             ["G3",196.0],["G#3",207.65],["A3",220],["A#3",223.08],["B3",246.94],["C4",261.63],["C#4",277.18],["D4",293.66],["D#4",311.13],["E4",329.63],["F4",349.23],["F#4",369.99],["G4",392.0];
             ["B3",246.94],["C4",261.63],["C#4",277.18],["D4",293.66],["D#4",311.13],["E4",329.63],["F4",349.23],["F#4",369.99],["G4",392.0],["G#4",415.3],["A4",440.0],["A#4",466.16],["B4",493.88];
             ["E4",329.63],["F4",349.23],["F#4",369.99],["G4",392.0],["G#4",415.3],["A4",440.0],["A#4",466.16],["B4",493.88],["C5",523.25],["C#5",554.37],["D5",587.33],["D#5",622.25],["E5",659.65]]

# could use midi numbers... although it would be an extra step and somewhat unnecessary since we're simply correlating

fret_frequencies = [["E2",82.41],["F2",87.31],["F#2",92.5],["G2",98.0],["G#2",103.83],["A2",110],["A#2",116.54],["B2",123.47],
                    ["C3",130.81],["C#3",138.59],["D3",146.83],["D#3",155.56],["E3",164.81],["F3",174.61],["F#3",185.0],["G3",196.0],
                    ["G#3",207.65],["A3",220],["A#3",233.08],["B3",246.94],["C4",261.63],["C#4",277.18],["D4",293.66],["D#4",311.13],
                    ["E4",329.63],["F4",349.23],["F#4",369.99],["G4",392.0],["G#4",415.3],["A4",440.0],["A#4",466.16],["B4",493.88],
                    ["C5",523.25],["C#5",554.37],["D5",587.33],["D#5",622.25],["E5",659.65]]
=#


fret_frequencies = [82.41, 87.31, 92.5, 98.0,103.83,110,116.54, 123.47,130.81,138.59,146.83,155.56,164.81,174.61,185.0,196.0,
                    207.65 ,220,233.08,246.94,261.63,277.18,293.66, 311.13, 329.63,349.23,369.99,392.0,415.3,440.0,466.16,
                    493.88,523.25,554.37,587.33,622.25,659.65]

#=
fret_frequencies = []
for j in 1:length(fretboard) # compare note with each note on the fretboard
    if fretboard[j][2] in fret_frequencies

    push!(fret_frequencies, fretboard[j][2])
end
=#

corr = 0.0

#=
function correlate()
    for i in 1:length(frequencies) # loop through each note (fund. freq.) in the song
        corr = sum(frequencies[i] .* fret_frequencies[[:][2]]) # want to correlate with the second elements of each vector in fret_frequencies...
                                       # is there an efficient way to do this?
    end
end
=#

global note_frets = []
function correlate()
    for i in 1:length(frequencies) 
        frequency = frequencies[i][1]
        note_beats = frequencies[i][2]

        if frequency != -1 #this would be a rest
            possible_indices = [] #all possible locations for this frequency

            for j in 1:length(fret_frequencies)
                if frequency > fret_frequencies[j] && frequency < fret_frequencies[j + 1] #frequency is between these 2 values
                    if (fret_frequencies[j + 1] - frequency) > (fret_frequencies[j] - frequency)
                        push!(possible_indices, j - 1) #uses 0-based index for convenient computations
                    else
                        push!(possible_indices, j - 1)
                    end
                end
            end 

            last_s, last_f = 0, 0 #the string and fret of the last played note
            if i >= 3
                last_s, last_f = note_frets[i - 2][1], note_frets[i - 2][2]
            end
            
            index = possible_indices[1]
            for k in 2:length(possible_indices) #finds the closest index to the last played note
                old_s, old_f = ind_to_fret
                new_s, new_f = ind_to_fret(possible_indices[k]) #string and fret of this index

                old_dist = calculate_distance(last_s, last_f, old_s, old_f)
                new_dist = calculate_distance(last_s, last_f, new_s, new_f)

                if(new_dist < old_dist)
                    index = cur_ind
                end
            end

            string, fret = ind_to_fret(index)

            push!(note_frets, [string, fret, note_beats])

        else
            push!(note_frets, [-1, -1, note_beats]) #string/fret for a rest is -1
        end                          
    end
end

#finds distance between 2 string/fret pairs
function calculate_distance(s1, f1, s2, f2)
    return sqrt((s2 - s1)^2 + (f2 - f1)^2)
end

#converts a frequencies-vector index to string and fret #s
function ind_to_fret(ind)
    string = floor(ind / 13) + 1
    fret = ind % 13
    return string, fret
end
