 using Plots

durations = []

fret_frequencies = [82.41,87.31,92.5,98.0,103.83,110,116.54,123.47,130.81,138.59,146.83,155.56,164.81,110,116.54,123.47,130.81,138.59,
                146.83,155.56,164.81,174.61,185.0,196.0,207.65,220,146.83,155.56,164.81,174.61,185.0,196.0,207.65,220,233.08,246.94,
                261.63,277.18,293.66,196.0,207.65,220,223.08,246.94,4,261.63,277.18,293.66,311.13,329.63,349.23,369.99,392.0,246.94,
                261.63,277.18,293.66,311.13,329.63,349.23,369.99,392.0,415.3,440.0,466.16,493.88,329.63,349.23,369.99,392.0,415.3,
                440.0,466.16,493.88,523.25,554.37,587.33,622.25,659.65]



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
                        push!(possible_indices, j)
                    end
                end
            end 

            last_s, last_f = 0, 0 #the string and fret of the last played note
            if i >= 3
                last_s, last_f = note_frets[i - 2][1], note_frets[i - 2][2]
            end
            
            index = possible_indices[1]
            for k in 2:length(possible_indices) #finds the closest index to the last played note
                old_s, old_f = ind_to_fret(index)
                new_s, new_f = ind_to_fret(possible_indices[k]) #string and fret of this index

                if (abs(new_f - last_f) < abs(old_f - last_f)) #prioritize closest fret
                    index = possible_indices[k]
                end

                #= This version gives prioritization to open strings
                if new_f == 0 || (abs(new_f - last_f) < abs(old_f - last_f)) #prioritize open string or closest fret
                    index = possible_indices[k]
                end
                =#
            end

            string, fret = ind_to_fret(index)

            push!(note_frets, [string, fret, note_beats])

        else
            push!(note_frets, [-1, -1, note_beats]) #string/fret for a rest is -1
        end                          
    end
end

#converts a frequencies-vector index to string and fret #s
function ind_to_fret(ind)
    string = floor(ind / 13) + 1
    fret = ind % 13
    return string, fret
end
