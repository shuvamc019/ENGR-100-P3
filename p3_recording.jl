using Sound
using Gtk

g = GtkGrid()

record_button = GtkButton("record")
signal_connect(click_record, record_button, "clicked")
#style to come later

S = 44100
song = Float32[]

function click_record(w)
    println("recording...")
    song, S = record(1)
    return nothing
end
