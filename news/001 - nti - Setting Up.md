# 001 - Setting Up

Author: nti

May 17-18

## Welcome

Hello, guys.
- in 1996, some researchers passed density fields through turbulent wind fields
- the result was a _stable_ turbulent fluid simulation, efficient enough to be run in real time 

Basic project architecture: several modules
- `simulator`, using `cython`: extremely efficient, implements a well-known algorithm
    - Mike Ash's demo for dummies good for reference
    - Read the paper (available in `doc/`)-- crucially, stable for long time steps.
    - JavaScript demo code quality is quite poor. We can do better.
    - exposes an interface.
- todo: use pygame to render this matrix as pixels
    - innovative rendering techniques can help make it look good
    - want to show...
        - frame time / frame rate
        - various fluid properties (e.g. velocity, by quiver plot)
    - want to implement...
        - sliders to change properties in real-time
        - toggles to turn things on/off, e.g.
            - gravity
            - cap simulation time to frame time (Vsync)
    
The reason it is designed this way:
- fluid simulation is slow and complex
- by writing all this in low-level code, we can export an interface to Python that is much less frequently called
- we can accomplish extremely good frame-times without compromising on user-options.

Outline of project:
- we implemented this model
- here are all the ways it can be made better
    - mainly substituting discrete versions for different solvers
    - make a table of combinatorial space, see how we do

Open to your help in:
1. implementing above 'consumer-level' code
2. parsing the mathematics
    - cf eqs: parse velocity and density components by semantics
3. support for internal boundaries
    - cf Stam: would require understanding the `set_bnd` function: I can provision a boolean grid.
    - mysterious 'b' parameter holds many secrets: cf periodic vs other