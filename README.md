# f256_life
An implementation of Conway's game of life for the Foenix F256K (and the Jr. if your setup allows to use a mouse). You can start either with a random
configuration, draw one manually using a mouse or look at a demo of Gosper's glider gun. The simulated world has a size of 128x64 cells and is toroidal 
in shape, i.e. it would look like a donut, if you would create a 3D model of the 2D playing field.

The chosen parameters for mouse control work well for my mouse. If they don't work for you, you can have a look at the threshold values in the file 
`select.asm` and change them. In this file you can also make the right mouse button the primary button if you prefer to use your mouse in that
fashion.
