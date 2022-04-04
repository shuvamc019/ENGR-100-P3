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
        for j in 1:length(fret_frequencies)
            if frequencies[i] > fret_frequencies[j] && frequencies[i] < fret_frequencies[j + 1] #frequency is between these 2 values
                index = -1
                if (fret_frequencies[j + 1] - frequencies[i]) > (fret_frequencies[j] - frequencies[i])
                    index = j - 1
                else
                    index = j
                end

                fret = round(Integer, index % 13)
                string = round(Integer, floor(index / 13))

                push!(note_frets, [string, fret])
            end
        end                                 
    end
end
