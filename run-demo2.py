#!/usr/bin/env python3.9

"""
This demo just prints the result of a fluid simulation
using the console.
"""

import app
import sys

import matplotlib.pyplot as plt

import fluids


def print_density_array(sim):
    print('\n===BEG===', file=sys.stderr)

    density_array = sim.dump_density_array()
    for x in range(sim.size):
        for y in range(sim.size):
            z = int(255.0 * density_array[sim.ix(x, y)])
            z = min(max(z, 0), 255)
            print(z, end=' ', file=sys.stderr)

        print(file=sys.stderr)

    print('===END===', file=sys.stderr)


def create_sim():
    sim = fluids.simulator.Simulator(
        256, 1.0, 1.0
    )

    # enable slow-mo for debug:
    sim.time_rate = 0.001

    # adding a solid square of fluid with constant velocity
    square_density = 1.0
    square_x_velocity = 0.5
    square_y_velocity = 0.5
    square_x_offset = 100
    square_y_offset = 100
    square_size = 64

    for x in range(square_x_offset, square_size + square_x_offset):
        for y in range(square_y_offset, square_size + square_y_offset):
            sim.add_density((x, y), square_density)

    for x in range(square_x_offset, square_size + square_x_offset):
        for y in range(square_y_offset, square_size + square_y_offset):
            sim.add_velocity((x, y), (square_x_velocity, square_y_velocity))

    return sim


def main():
    # setting up initial state:
    sim = create_sim()

    def render_cb(screen):
        # running K simulation steps:
        k = 1
        for i in range(k):
            sim.step()

        # presenting:
        density_array = sim.dump_density_array()
        vx_array = sim.dump_vx_array()
        vy_array = sim.dump_vy_array()
        for x in range(sim.size):
            for y in range(sim.size):
                # converting the density to a constant in [0,255]:
                try:
                    z = int(255.0 * density_array[sim.ix(x, y)])
                    z = min(max(z, 0), 255)
                    color = (z, z, z)
                except ValueError:
                    color = (255, 0, 0)

                # setting the color:
                screen.set_at((x, y), color)

        # debug: ensure we actually render
        # screen.fill((255, 0, 0))

    app.run(256, 256, "demo-2", render_cb)

    # TODO: move this to config
    display_quiver_plot_after_completion = False
    if display_quiver_plot_after_completion:
        plt.quiver(sim.dump_vx_array(), sim.dump_vy_array())
        plt.show()


if __name__ == "__main__":
    main()
    exit(0)
