import pygame

initial_fill_color = (255, 0, 255)


def run(width, height, caption, render_cb=None):
    pygame.init()
    pygame.display.set_caption(caption)

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
        pygame.display.flip()

    pygame.quit()
