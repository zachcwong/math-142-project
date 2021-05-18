"""
Implements this module as a 'kernel' that can be used by the rest of the
application.
https://mikeash.com/pyblog/fluid-simulation-for-dummies.html
"""
import ctypes
from typing import *
from ctypes import *

import numpy as np

from libc.stdlib cimport malloc, calloc, free


#
#
# Python Wrapper:
#
#


cdef FluidGrid* singleton_fg = NULL;


class Simulator(object):
    def __init__(self, n: int, init_diffusion, init_viscosity, max_display_updates_per_sec=60.0, time_rate=1.0):
        global singleton_fg

        assert singleton_fg == NULL

        self.max_display_updates_per_sec = max_display_updates_per_sec
        self.internal_time_rate = time_rate
        singleton_fg = new_fg(n, init_diffusion, init_viscosity, self.dt)

    def ix(self, x, y):
        return ix(singleton_fg, x, y)

    def step(self):
        advance_fg_state_by_one_tick(singleton_fg)

    def dispose(self):
        global singleton_fg

        del_fg(singleton_fg)
        singleton_fg = NULL

    @property
    def cell_count(self):
        return singleton_fg.cell_count

    @property
    def size(self):
        return singleton_fg.size

    def dump_vx_array(self):
        return np.array([singleton_fg.vx[i] for i in range(singleton_fg.cell_count)])

    def dump_vy_array(self):
        return np.array([singleton_fg.vy[i] for i in range(singleton_fg.cell_count)])

    def dump_velocity_array(self):
        return np.array([
            np.array((vx, vy))
            for (vx, vy) in zip(self.dump_vy_array(), self.dump_vy_array())
        ])

    def dump_density_array(self):
        return np.array([singleton_fg.density[i] for i in range(singleton_fg.cell_count)])

    @property
    def dt(self):
        # keep simulation in lock-step with maximum display update-rate-- intended for interactive applications.
        return self.internal_time_rate * (1.0 / self.max_display_updates_per_sec)

    @property
    def time_rate(self):
        return self.internal_time_rate

    @time_rate.setter
    def time_rate(self, value):
        """
        updates the time rate
        :param value: new time rate (1 => real-time)
        """
        global singleton_fg
        self.internal_time_rate = value
        singleton_fg.dt = self.dt

    @property
    def diffusion(self):
        global singleton_fg
        return singleton_fg.diffusion

    @diffusion.setter
    def diffusion(self, new_diffusion):
        global singleton_fg
        singleton_fg.diffusion = new_diffusion

    @property
    def viscosity(self):
        global singleton_fg
        return singleton_fg.viscosity

    @viscosity.setter
    def viscosity(self, new_viscosity):
        global singleton_fg
        singleton_fg.viscosity = new_viscosity

    def add_density(self, pos_xy: Tuple[int, int], amount: float):
        x, y = pos_xy
        global singleton_fg
        fg_add_density(singleton_fg, x, y, amount)

    def add_velocity(self, pos_xy: Tuple[int, int], amount_xy: Tuple[float, float]):
        global singleton_fg
        x, y = pos_xy
        amount_x, amount_y = amount_xy
        fg_add_velocity(singleton_fg, x, y, amount_x, amount_y)


#
#
# `FluidGrid`: data for pressure & velocity of fluid
# in a dense-enough square grid.
# - exists in C-space only, designed to be maximally efficient
# - todo: consider if n = size (Ash) or n = size-2 (Stam) (using Stam)
#
#

cdef struct FluidGrid:
    # Voxel header data:
    int n;
    int size;
    int cell_count;
    float dt;
    float diffusion;
    float viscosity;

    # Per-voxel attribute arrays:
    float* density;
    float* vx;
    float* vy;

    # stores attributes of the last frame
    float* density_prev;
    float* vx_prev;
    float* vy_prev;


cdef inline ix(FluidGrid* fg, int x, int y):
    """
    Translates (x, y) tuple into a flat (index) that can be used to look up
    voxel attributes in an attribute list.
    Note that data is stored in COLUMN major order.
    :param fg: the grid whose encapsulated voxel attributes to look up. 
    :param x: the x-index of the voxel to query.
    :param y: the y-index of the voxel to query.
    :return: a unique integer index used to access the properties of the voxel at (x,y) in fg. 
    """

    assert fg.size == fg.n+2

    return (
        (x * fg.size) +
        (y * 1)
    )


cdef (FluidGrid*) new_fg(int n, int diffusion, int viscosity, float dt):
    """
    Creates a new fluid square. The method implemented is crucially stable over
    large time-steps, making it suitable for slow dt.
    :param n: number of non-border cells per edge
    :param diffusion: the simulation's diffusion constant
    :param viscosity: the fluid's viscosity constant
    :param dt: delta-time, a time-step used to simulate fluid movement.
    :return: the new FluidGrid instance
    """

    fg = <FluidGrid*>malloc(sizeof(FluidGrid))
    fg.n = n
    fg.size = n+2
    fg.cell_count = fg.size * fg.size
    fg.dt = dt
    fg.diffusion = diffusion
    fg.viscosity = viscosity

    voxel_count = fg.size * fg.size

    fg.density = <float*>calloc(voxel_count, sizeof(float))
    fg.vx = <float*>calloc(voxel_count, sizeof(float))
    fg.vy = <float*>calloc(voxel_count, sizeof(float))

    fg.density_prev = <float *> calloc(voxel_count, sizeof(float))
    fg.vx_prev = <float*>calloc(voxel_count, sizeof(float))
    fg.vy_prev = <float*>calloc(voxel_count, sizeof(float))

    z = fg.vx_prev[0]

    return fg


cdef del_fg(FluidGrid* fg):
    """
    Deletes the argument fluid square, relinquishing all memory resources
    used for it.
    :param fg: the fluid-square to de-initialize.
    """

    free(<void*>fg.density)
    free(<void*>fg.vx)
    free(<void*>fg.vy)

    free(<void*>fg.density_prev)
    free(<void*>fg.vx_prev)
    free(<void*>fg.vy_prev)

    free(<void*>fg)


cdef fg_add_density(FluidGrid* fg, int x, int y, float amount):
    """
    Add fluid density (as though from a source) at the specified cell. 
    :param fg: the container fluid-square to update
    :param x: the x-coordinate at which to add density
    :param y: the y-coordinate at which to add density
    :param amount: the amount of fluid to add per-cell
    """

    n = fg.n
    fg.density[ix(fg, x, y)] += amount


cdef fg_add_velocity(FluidGrid* fg, int x, int y, float amount_x, float amount_y):
    """
    Increment the velocity of all fluid-mass in a cell
    :param fg: the container fluid-square to update
    :param x: the X-coordinate at which to add velocity
    :param y: the Y-coordinate at which to add velocity
    :param amount_x: the amount of velocity to add along the X-axis
    :param amount_y: the amount of velocity to add along the Y-axis
    :return: 
    """

    n = fg.n
    index = ix(fg, x, y)
    fg.vx[index] += amount_x
    fg.vy[index] += amount_y


cdef advance_fg_state_by_one_tick(FluidGrid* fg):
    """
    Advances the FluidGrid state by one tick, accounting for all fluid flow within.
    :param fg: the FluidGrid instance within which fluid sloshes about.
    """

    velocity_step(fg, fg.vx, fg.vy, fg.vx_prev, fg.vy_prev, fg.viscosity, fg.dt)
    density_step(fg, fg.density, fg.density_prev, fg.vx, fg.vy, fg.diffusion, fg.dt)


cdef velocity_step(FluidGrid* fg, float* u, float* v, float* u0, float* v0, float visc, float dt):
    add_source(fg, u, u0, dt)
    add_source(fg, v, v0, dt)
    # print("VS: Add Source OK")

    swap(&u0, &u)
    diffuse(fg, 1, u, u0, visc, dt)
    # print("VS: Diffuse 1 OK")

    swap(&v0, &v)
    diffuse(fg, 2, v, v0, visc, dt)
    # print("VS: Diffuse 2 OK")

    project(fg, u, v, u0, v0)
    # print("VS: Project 1 OK")

    swap(&u0, &u)
    swap(&v0, &v)

    advect(fg, 1, u, u0, u0, v0, dt)
    # print("VS: Advect 1 OK")
    advect(fg, 2, v, v0, u0, v0, dt)
    # print("VS: Advect 2 OK")

    project(fg, u, v, u0, v0)
    # print("VS: Project 2 OK")


cdef density_step(FluidGrid* fg, float* x, float* x0, float* u, float* v, float diff, float dt):
    add_source(fg, x, x0, dt)
    # print("DS: Add Source OK")

    swap(&x0, &x)
    diffuse(fg, 0, x, x0, diff, dt)
    # print("DS: Diffuse 1 OK")

    swap(&x0, &x)
    advect(fg, 0, x, x0, u, v, dt)
    # print("DS: Diffuse 2 OK")


cdef inline add_source(FluidGrid* fg, float* x, float* s, float dt):
    for i in range(fg.cell_count):
        x[i] += dt * s[i]


cdef inline swap(float** xp, float** yp):
    # ptrs = <int>xp[0], <int>yp[0]
    # print(f"Swap Start: {ptrs}")

    tmp = <float*>(xp[0])
    xp[0] = <float*>(yp[0])
    yp[0] = <float*>tmp

    # ptrs = <int>xp[0], <int>yp[0]
    # print(f"Swap End: {ptrs}")


cdef inline set_boundary_cells(FluidGrid* fg, int n, int b, float* x):
    for i in range(1, 1+n):
        x[ix(fg, 0, i)] = (-x[ix(fg, 1, i)]) if b == 1 else (x[ix(fg, 1, i)])
        x[ix(fg, n+1, i)] = (-x[ix(fg, n, i)]) if b == 1 else (x[ix(fg, n, i)])
        x[ix(fg, i, 0)] = (-x[ix(fg, i, 1)]) if b == 2 else (x[ix(fg, i, 1)])
        x[ix(fg, i, n+1)] = (-x[ix(fg, i, n)]) if b == 2 else (x[ix(fg, i, n)])

    x[ix(fg, 0, 0)] = 0.5 * (x[ix(fg, 1, 0)] + x[ix(fg, 0, 1)])
    x[ix(fg, 0, n+1)] = 0.5 * (x[ix(fg, 1, n + 1)] + x[ix(fg, 0, n)])
    x[ix(fg, n+1, 0)] = 0.5 * (x[ix(fg, n, 0)] + x[ix(fg, n + 1, 1)])
    x[ix(fg, n+1, n+1)] = 0.5 * (x[ix(fg, n, n + 1)] + x[ix(fg, n + 1, n)])


cdef diffuse(FluidGrid* fg, int b, float* x, float* x0, float diff, float dt):
    """
    implements the `diffuse` operator, used by `advance_fg_state_by_one_tick`
    propagates velocities, simulating 'diffusion'.
     - this is an implementation of Gauss-Seidel relaxation (cf MATH 151AB)
     - note this is done in a non-energy-conserving way, so we must 'reproject' to rescale vectors
    """

    solver_iter_count = 20

    n = fg.n
    a = dt * diff * n * n

    for k in range(0, solver_iter_count):
        for i in range(1, 1+fg.n):
            for j in range(1, 1+fg.n):
                x[ix(fg, i, j)] = (1 / (1 + 4*a)) * (
                    x0[ix(fg, i, j)] + a * (
                        + x[ix(fg, i - 1, j)]
                        + x[ix(fg, i + 1, j)]
                        + x[ix(fg, i, j - 1)]
                        + x[ix(fg, i, j + 1)]
                    )
                )
        set_boundary_cells(fg, n, b, x)


cdef advect(FluidGrid* fg, int b, float* d, float* d0, float* u, float* v, float dt):
    """
    implements the `diffuse` operator, used by `advance_fg_state_by_one_tick`
    - uses `method of characteristics` to work out the starting position of a bulk cell given velocity, which is then
      written into the matrix
    - borne from Stam97, "where [authors] moved density fields through kinetic turbulent wind fields"
    """

    n = fg.n

    dt0 = dt*n
    for i in range(1, n+1):
        for j in range(1, n+1):
            x = i - dt0*u[ix(fg, i, j)]
            y = j - dt0*v[ix(fg, i, j)]

            # print(f"({i}, {j}) = {x, y}")

            if x < 0.5:
                x = 0.5
            if x > n + 0.5:
                x = n + 0.5
            i0 = <int>x
            i1 = 1 + i0

            if y < 0.5:
                y = 0.5
            if y > n + 0.5:
                y = n + 0.5
            j0 = <int>y
            j1 = 1 + j0

            s1 = x - i0
            s0 = 1 - s1
            t1 = y - j0
            t0 = 1 - t1

            d[ix(fg, i, j)] = (
                s0 * (t0 * d0[ix(fg, i0, j0)] + t1*d0[ix(fg, i0, j1)]) +
                s1 * (t0 * d0[ix(fg, i1, j0)] + t1*d0[ix(fg, i1, j1)])
            )

    set_boundary_cells(fg, n, b, d)


cdef project(FluidGrid* fg, float* u, float* v, float* p, float* div):
    """
    implements the `project` operator, using Gauss-Seidel relaxation
    - resizes vectors to preserve velocity components  
    """

    n = fg.n
    h = 1.0 / n

    for i in range(1, n+1):
        for j in range(1, n+1):
            div[ix(fg, i, j)] = (-0.5 * h) * (
                + u[ix(fg, i+1, j)] - u[ix(fg, i-1, j)]
                + v[ix(fg, i, j+1)] - v[ix(fg, i, j-1)]
            )
            p[ix(fg, i, j)] = 0

    set_boundary_cells(fg, n, 0, div)
    set_boundary_cells(fg, n, 0, p)

    for k in range(20):
        for i in range(1, n+1):
            for j in range(1, n+1):
                p[ix(fg, i, j)] = (1/4) * (
                    + div[ix(fg, i, j)]
                    + p[ix(fg, i-1, j)] + p[ix(fg, i+1, j)]
                    + p[ix(fg, i, j-1)] + p[ix(fg, i, j+1)]
                )
        set_boundary_cells(fg, n, 0, p)

    for i in range(1, n+1):
        for j in range(1, n+1):
            u[ix(fg, i, j)] -= (0.5/h) * (p[ix(fg, i+1, j)] - p[ix(fg, i-1, j)])
            v[ix(fg, i, j)] -= (0.5/h) * (p[ix(fg, i, j+1)] - p[ix(fg, i, j-1)])

    set_boundary_cells(fg, n, 1, u)
    set_boundary_cells(fg, n, 2, v)