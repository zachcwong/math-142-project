import pygame

initial_fill_color = (255, 0, 255, 0xff)


def run(width, height, caption, render_cb=None, desired_updates_per_sec=60):
    #
    # Validating params:
    #

    if render_cb is None:
        # re-defining render_cb to overwrite previous,
        # un-callable definition.
        # - this way, we do not branch each loop iteration.
        def render_cb(screen):
            report = "Oops! Did you forget to pass a `render_cb` callback to `app.run`?"
            label = debug_font.render(report, True, (0x00, 0x00, 0x00, 0xff))
            screen.blit(label, (10, 10))

    #
    # Running the app:
    #

    pygame.init()
    pygame.display.set_caption(caption)

    debug_font = pygame.font.SysFont("monospace", 20)

    clock = pygame.time.Clock()

    screen: pygame.Surface = pygame.display.set_mode((width, height))

    # DEBUG: filling screen with magenta/fuchsia
    screen.fill(initial_fill_color)

    is_running = True
    while is_running:
        # Polling for user input:
        events = pygame.event.get()
        for event in events:
            # checking for 'quit' events:
            if event.type == pygame.QUIT:
                is_running = False

            # TODO: check for mouse input events

        # Rendering:
        screen.fill(initial_fill_color)
        render_cb(screen)
        pygame.display.flip()

        # Sleeping:
        clock.tick(desired_updates_per_sec)

    pygame.quit()
