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
#song = nothing # initialize "song"  ##commented out since it was causing issues in analyze_signals
global initial_tab = ""


function analyze_signals(song, S, bpm)
    envelope = find_envelope(song) # find envelope needs song vector
    durations = find_durations(envelope) # this is fine
    print(durations)
    bpm = convert(Float32, bpm)
    frequencies = compute_frequencies(song, durations, S, bpm) # here is the problem child
    note_frets = correlate(frequencies)
    print(note_frets)
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
    #bpm = convert(Float, bpm)

    note_frets = analyze_signals(song, S2, bpm)
    display_tab(note_frets)
end

#callback function to upload a file
function upload_file(w)
    filename = open_dialog("Pick a file", GtkNullContainer(), ("*.wav",))
    song, S = wavread(string(filename))

    #println(size(song))

    bpm = input_dialog("Enter BPM", "")
    bpm = parse(Int64, bpm[2])
    #bpm = convert(Float, bpm)

    note_frets = analyze_signals(song, S, bpm)

    println(note_frets)
    
    display_tab(note_frets)
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


function make_button(string, callback, column, row, stylename, styledata)
    b = GtkButton(string)
    signal_connect((w) -> callback(w), b, "clicked")
    g[column,row] = b
    s = GtkCssProvider(data = "#$stylename {$styledata}")
    push!(GAccessor.style_context(b), GtkStyleProvider(s), 600)
    set_gtk_property!(b, :name, stylename)
    return b
end

## create buttons with appropriate callbacks, positions, and styles

# first row
#bu = make_button("Upload", call_upload, 1:3, 1) 

# second row
br = make_button("Record", call_record, 1, 2, "wr", "color:white; background:red;")
bs = make_button("Stop", call_stop, 2, 2, "yb", "color:yellow; background:blue;")
bp = make_button("Play", call_play, 3, 2, "wg", "color:white; background:green;")
bu = make_button("Upload", upload_file, 4, 2, "by", "color:blue; background:yellow;")

# third row
btext = GtkTextView()
bbuffer = get_gtk_property(btext, :buffer, GtkTextBufferLeaf)

string_names = ["E ", "A ", "D ", "G ", "B ", "e "]

function display_tab(note_frets)
    initial_tab = ""
    for line in note_frets
        
        for string_num in 6:-1:1  # 6th string is the lowest on the guitar
            initial_tab *= string_names[string_num]
            for note in line
                stringN, fret, duration = note[1], note[2], (note[3] / 0.25) # /.25 since duration is in beats and 16th note is smallest duration in our program
                if stringN == string_num
                    initial_tab *= string(fret) # insert fret number
                    for _ in 2:duration
                        initial_tab *= "_"
                    end
                else
                    for _ in 1:duration
                        initial_tab *= "-"  # insert -
                    end
                end  
            end
            initial_tab *= "\n" # insert newline
        end
        initial_tab *= "\n"
    end

    set_gtk_property!(bbuffer, :text, initial_tab)
    set_gtk_property!(btext, :monospace, true)
end




## NEED AN UPDATE TAB BUTTON FASHO##

g[1:4,3] = btext

win = GtkWindow("gtk3", 600, 400) # 600×200 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win) # display the window full of buttons
nothing

