using Gtk
using Sound

win = GtkWindow("[Insert Song/Tab Title Here]")

g = GtkGrid()

a = GtkEntry()  # a widget for entering text
set_gtk_property!(a, :text, "This is Gtk!")
b = GtkCheckButton("Check me!")
c = GtkScale(false, 0:10)     # a slider

g[1,1] = a # cartesian coordinates, not row/col, and (0,0) is upper left)
g[2,1] = b
g[1:2,2] = c

set_gtk_property!(g, :column_homogeneous, true)
set_gtk_property!(g, :column_spacing, 15)  # introduce a 15-pixel gap between columns

push!(win, g)
showall(win);

#=
function on_button_clicked(w)
    println("The button has been clicked")
end
signal_connect(on_button_clicked, b, "clicked")


for each note vector in frequencies:



=#
