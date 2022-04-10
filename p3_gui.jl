#=using Gtk
using Sound

win = GtkWindow("[Insert Song/Tab Title Here]", 600, 600)
g = GtkGrid()
set_gtk_property!(g, :column_homogeneous, true)
set_gtk_property!(g, :column_spacing, 15)  # introduce a 15-pixel gap between columns

entry_text = GtkLabel("Record or upload your song here: ")
record_button = GtkButton("Record")
upload_button = GtkButton("Upload")

function upload_file()
    song, S = wavread(open_dialog("Pick a .wav file", Null(), ("*.wav",)))
end

function on_record(w)
    song, S = record(100)
end

signal_connect(on_record, record_button, "clicked")
signal_connect(upload_file, upload_button, "clicked")

# for Gtk grid, cartesian coordinates, not row/col, and (0,0) is upper left


push!(win, g)
showall(win);=#

#using Gtk: GtkGrid, GtkButton, GtkWindow, GAccessor, TextView
#using Gtk: GtkCssProvider, GtkStyleProvider
#using Gtk: set_gtk_property!, signal_connect, showall
using Gtk
using PortAudio: PortAudioStream
using Sound: sound

#=
# initialize global variables that are used throughout
S = nothing # sampling rate (samples/second)
const N = 1024 # buffer length
const maxtime = 10 # maximum recording time 10 seconds (for demo)
recording = nothing # flag
nsample = 0 # count number of samples recorded
song = nothing # initialize "song"
=#


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
    global song = zeros(Float32, maxtime * S)
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
end


# callback function for "play" button
function call_play(w)
    println("Play")
    @async sound(song, S2) # play the entire recording
end

# callback function for "upload" button
function call_upload(w)
    song, S2 = wavread(open_dialog("Pick a .wav file", Null(), ("*.wav",)))
end


g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :column_spacing, 10) # gaps between buttons
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
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

# third row
btext = GtkTextView()
g[1:3,3] = btext

function display_tab()
    for string_num in 1:6
        for note in note_frets
            string, fret, duration = note[1], note[2], (note[3] / 0.25) # /.25 since duration is in beats and 16th note is smallest duration in our program
            if string == string_num
                fret = string(fret)
                set_gtk_property!(btext, :text, fret)
                for _ in 2:duration
                    set_gtk_property!(btext, :text, "*")
                end
            else
                for _ in 1:duration
                    set_gtk_property!(btext, :text, "-")
                end
            end  
        end
        set_gtk_property!(btext, :text, "\n")
    end
end

win = GtkWindow("gtk3", 600, 400) # 600×200 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win) # display the window full of buttons
display_tab()
nothing


