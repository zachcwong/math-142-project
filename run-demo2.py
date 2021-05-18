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
    sim = fluids.simulator.Simulator(256, 1.0, 1.0)

    for x in range(100, 110):
        for y in range(100, 110):
            sim.add_density((x, y), 1.0)
    #
    # for x in range(100, 110):
    #     for y in range(100, 110):
    #         sim.add_velocity((x, y), (1.0, 1.0))

    return sim


def main():
    # setting up initial state:
    sim = create_sim()

    def render_cb(screen):
        # running K steps:
        k = 0
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

    plt.quiver(sim.dump_vx_array(), sim.dump_vy_array())
    plt.show()


if __name__ == "__main__":
    main()
    exit(0)
