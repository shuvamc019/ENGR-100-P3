using Sound
using Gtk

S = 44100
song = Float32[]

g = GtkGrid()
set_gtk_property!(g, :row_homogeneous, true) 
set_gtk_property!(g, :column_homogeneous, true)

function click_record(w)
    println("recording...")
    song, S = record(1)
end

record_button = GtkButton("record")
signal_connect(click_record, record_button, "clicked")




