using Gtk
using PortAudio: PortAudioStream
using Sound: sound
include("p3_signals.jl")
include("p3_transcriber.jl")

# initialize global variables that are used throughout
S2 = 48000 # sampling rate (samples/second)
const N = 1024 # buffer length
const maxtime = 100 # maximum recording time 10 seconds (for demo)
recording = nothing # flag
nsample = 0 # count number of samples recorded

#calls all functions needed to translate a raw song into a vector of string/fret for each note in song
function analyze_signals(song, S, bpm)
    envelope = find_envelope(song) 
    durations = find_durations(envelope)
    bpm = convert(Float32, bpm)
    frequencies = compute_frequencies(song, durations, S, bpm)
    note_frets = correlate(frequencies)
    return note_frets
end


# callbacks

"""
    record_loop!(in_stream, buf)
Record from input stream until maximum duration is reached,
or until the global "recording" flag becomes false.
"""
function record_loop!(in_stream, buf)
    global maxtime
    global S2
    global N
    global recording
    global song
    global nsample
    Niter = floor(Int, maxtime * S2 / N)
    println("\nRecording up to Niter=$Niter ($maxtime sec).")
    for iter in 1:Niter
        if !recording
            break
        end
        read!(in_stream, buf)
        song[(iter-1)*N .+ (1:N)] = buf # save buffer to song
        nsample += N
        print("\riter=$iter/$Niter nsample=$nsample")
    end
    nothing
end


# callback function for "record" button
# The @async below is important so that the Stop button can work!
function call_record(w)
    global N
    in_stream = PortAudioStream(1, 0) # default input device
    buf = read(in_stream, N) # warm-up
    global recording = true
    global song = zeros(Float32, maxtime * S2)
    @async record_loop!(in_stream, buf)
    nothing
end


# callback function for "stop" button
function call_stop(w)
    global recording = false
    global nsample

    duration = round(nsample / S2, digits=2)
    sleep(0.1) # ensure the async record loop finished
    flush(stdout)
    println("\nStop at nsample=$nsample, for $duration out of $maxtime sec.")
    global song = song[1:nsample] # truncate song to the recorded duration

    bpm = input_dialog("Enter BPM", "")
    bpm = parse(Int64, bpm[2])

    note_frets = analyze_signals(song, S2, bpm) #creates vector of string/fret for each subsequent note
    display_tab(note_frets) #displays the strings and frets to user
end

#callback function to upload a file
function upload_file(w)
    filename = open_dialog("Pick a file", GtkNullContainer(), ("*.wav",))
    song, S = wavread(string(filename))

    bpm = input_dialog("Enter BPM", "")
    bpm = parse(Int64, bpm[2])

    note_frets = analyze_signals(song, S, bpm) #creates vector of string/fret for each subsequent note
    display_tab(note_frets) #displays the strings and frets to user
end


# callback function for "play" button
function call_play(w)
    println("Play")
    @async sound(song, S2) # play the entire recording
end


g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :column_spacing, 10) # gaps between buttons
set_gtk_property!(g, :row_homogeneous, false) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)


function make_button(string, callback, column, row, stylename, styledata) # modified to include grid column / row
    b = GtkButton(string)
    signal_connect((w) -> callback(w), b, "clicked")
    g[column,row] = b 
    s = GtkCssProvider(data = "#$stylename {$styledata}")
    push!(GAccessor.style_context(b), GtkStyleProvider(s), 600)
    set_gtk_property!(b, :name, stylename)
    return b
end

br = make_button("Record", call_record, 1, 1, "wr", "color:white; background:red;")
bs = make_button("Stop", call_stop, 2, 1, "yb", "color:yellow; background:blue;")
bp = make_button("Play", call_play, 3, 1, "wg", "color:white; background:green;")
bu = make_button("Upload", upload_file, 4, 1, "by", "color:blue; background:yellow;")

btext = GtkTextView()
bbuffer = get_gtk_property(btext, :buffer, GtkTextBufferLeaf)

string_names = ["E ", "A ", "D ", "G ", "B ", "e "] # to display to the left

# displays the tab to the Gtk text window (textview). goes line by line to avoid having to constantly translate the iterator in Gtk
function display_tab(note_frets)
    initial_tab = ""
    for line in note_frets
        for string_num in 6:-1:1  # reverse since 6th string is the lowest on the guitar
            initial_tab *= string_names[string_num]
            for note in line
                stringN, fret, duration = note[1], note[2], (note[3] / 0.25) # /.25 since duration is in beats and 16th note is smallest duration in our program...
                if stringN == string_num                                     # each character/dashed-line represents a 16th note
                    initial_tab *= string(fret) # insert fret number
                    for _ in 2:duration
                        initial_tab *= "_" # implies sustained duration after a note is played
                    end
                else
                    for _ in 1:duration
                        initial_tab *= "-"  # implies a rest
                    end
                end  
            end
            initial_tab *= "\n" # insert newline for next string
        end
        initial_tab *= "\n"  # insert newline before making the next tab block below this one
    end

    set_gtk_property!(bbuffer, :text, initial_tab) # apply the text into the buffer
    set_gtk_property!(btext, :monospace, true) # monospaced text so durations all line up
end

g[1:4,2] = btext # push the text buffer into the grid

win = GtkWindow("gtk3", 600, 400) # 600×200 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win) # display the window full of buttons
nothing

