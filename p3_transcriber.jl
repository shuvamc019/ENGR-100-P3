#vector holding the frequency of every note in the first 12 frets of every string of the guitar
#each row represents 1 string of the guitar with lowest string first and each row has 13 values (open string and 12 frets)
fret_frequencies = [82.41,87.31,92.5,98.0,103.83,110,116.54,123.47,130.81,138.59,146.83,155.56,164.81,
                    110,116.54,123.47,130.81,138.59,146.83,155.56,164.81,174.61,185.0,196.0,207.65,220,
                    146.83,155.56,164.81,174.61,185.0,196.0,207.65,220,233.08,246.94,261.63,277.18,293.66,
                    196.0,207.65,220,223.08,246.94,261.63,277.18,293.66,311.13,329.63,349.23,369.99,392.0,246.94,
                     261.63,277.18,293.66,311.13,329.63,349.23,369.99,392.0,415.3,440.0,466.16,493.88,329.63,349.23,
                     369.99,392.0,415.3, 440.0,466.16,493.88,523.25,554.37,587.33,622.25,659.65] 

# converts each frequency to its corresponding string/fret combo
# prioritizes the string/fret combo that is closest to the last played note
function correlate(frequencies)
    note_frets = []
    last_s, last_f = 0, 0  #the string and fret of the last played note, will be set in loop

    for i in 1:length(frequencies) #looping through frequency vector
        frequency = frequencies[i][1]
        note_beats = frequencies[i][2]

        if frequency != -1 #this would be a rest
            possible_indices = [] #all possible locations for this frequency

            for j in 1:(length(fret_frequencies)-1)
                if frequency >= fret_frequencies[j] && frequency <= fret_frequencies[j + 1] #frequency is between these 2 values
                    if (frequency - fret_frequencies[j]) < (fret_frequencies[j + 1] - frequency) #finds which of the 2 values the frequency is closer to
                        push!(possible_indices, j - 1) #uses 0-based index for convenient computations in ind_to_fret()
                    else
                        push!(possible_indices, j)
                    end
                end
            end 

            if length(possible_indices) == 0
                push!(current_line, (-1, -1, num_beats)) #note not recognized so treat like a rest
                continue
            end

            if i >= 3
                last_s, last_f = note_frets[i - 2][1], note_frets[i - 2][2]
            end

            string, fret = find_best_note(possible_indices, last_s, last_f)
            push!(note_frets, (string, fret, note_beats))
            last_s, last_f = string, fret
        else
            push!(note_frets, (-1, -1, note_beats)) #string/fret for a rest is -1
        end                          
    end

    return equalize_lines(note_frets) #splits into equal-sized lines
end

#takes in note_frets from correlate() and splits it into several lines with equal numbers of beats
#this ensures that the outputted tablature will not be one long line and will look even to the user
function equalize_lines(note_frets)
    line_split_frets = [] #vector to hold all of the lines

    max_beats = 25 #max number of beats in any one line
    current_beats = 0 #how many beats are already in the current line
    current_line = [] #holds all of the notes in the current line

    for note in note_frets
        beats = note[3]
        if current_beats == max_beats #if the current line has exactly max_beats, just add the current line to line_split_frets and start a new line
            push!(line_split_frets, current_line)
            current_line = [note]
            current_beats = 0
        elseif current_beats + beats > max_beats  #if adding this note would put the line over max_beats, then we split it into two note
            difference = max_beats - current_beats
            note_1 = (note[1], note[2], difference) #this is the note to go on the current line
            note_2 = (note[1], note[2], beats - difference) #this note goes on the next line 

            push!(current_line, note_1)
            push!(line_split_frets, current_line)
            current_line = [note_2]
            current_beats = beats - difference
        else #this means that adding the current note would not put the line over max_beats
            push!(current_line, note)
            current_beats += beats
        end
    end
    
    push!(line_split_frets, current_line)
    println(line_split_frets)

    return line_split_frets
end

#converts a fret_frequencies vector index to string and fret #s
function ind_to_fret(ind)
    string = floor(Integer, ind / 13) + 1
    fret = round(Integer, ind % 13)
    return string, fret
end

#calculates distance between 2 string/fret pairs
function distance(s1, f1, s2, f2)
    return √((s2 - s1)^2 + (f2 - f1)^2)
end

#given the previously played note a vector of candidate notes, finds easiest one to play
function find_best_note(possible_indices, last_s, last_f)
    best_s, best_f = ind_to_fret(possible_indices[1])
    for k in 2:length(possible_indices) #finds the closest index to the last played note
        s, f = ind_to_fret(possible_indices[k]) #string and fret of this index

        if (distance(s, f, last_s, last_f) < distance(best_s, best_f, last_s, last_f)) #prioritize closest fret
            best_s, best_f = ind_to_fret(possible_indices[k])
        end
    end

    return best_s, best_f
end