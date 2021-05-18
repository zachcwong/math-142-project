# 001 - Setting Up

Author: nti

May 18

## Crappy Sim

I got a crappy (low-frame-rate) simulation working.

You can test this out by running demo 2.

The biggest improvement to frame-rate would be
**not mapping pixels to grid-cells 1:1**.

Frame-rate can be further improved using parallelization, and a deeper 
understanding of the algorithm once we establish correctness.
- We can use `Cython.parallel` to multiplex cell calculation to threads
- Must take special consideration of boundaries
- May carve space into `N x N` 'chunks' that we can tile
    - requires boundary information to propagate
    - e.g., a 'web' of FluidGrids of varying resolution based on distance to camera

Furthermore, we need to write 'brushes' such that density and velocity can be
added/changed effectively.
- this is as much a UI problem as it is a solver problem
- want to consult with other group members
- strongly advise against per-pixel mutation within Python (though OK for prototyping)

What are the physical meanings of...
1. diffusion constant
2. velocity

## What about multiple fluids?

How do we model two different fluids, say of different colors?

Is this an additive sum?
