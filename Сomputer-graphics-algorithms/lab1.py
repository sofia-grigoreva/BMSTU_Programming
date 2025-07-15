import glfw
import math
import random
from OpenGL.GL import *
angle = 0
size = 0
spikes = 4
def key_callback(window, key, scancode, action, mods):
    global spikes
    global angle

    if  action == glfw.REPEAT or action == glfw.PRESS:
        if key == glfw.KEY_UP:
            spikes += 1
        if key == glfw.KEY_DOWN and spikes >= 2:
            spikes -= 1
        if key == glfw.KEY_RIGHT:
            angle += 3
        if key == glfw.KEY_LEFT:
            angle -= 3


def scroll_callback(window, xoffset, yoffset):
    global size
    if (xoffset > 0):
        size -= yoffset/10
    else:
        size += yoffset/10

def drawstar(window) :
    global angle
    glClear(GL_COLOR_BUFFER_BIT)
    glLoadIdentity()
    glClearColor(1.0, 1.0, 1.0, 1.0)
    glPushMatrix()
    glRotatef(angle, 0, 0, 1)
    glBegin(GL_POLYGON)

    x = -1
    y = -1

    r = 1 + size;
    centerX = 0;
    centerY = 0;

    step = math.pi / spikes;
    rotation = (math.pi / 2) * 3;

    glColor3f(random.random(), random.random(), random.random())
    glVertex2f(centerX, centerY)

    for i in range (spikes + 1):
        x = centerX + math.cos(rotation) * (r / 2.5);
        y = centerY + math.sin(rotation) * (r / 2.5);
        glColor3f(random.random(), random.random(), random.random())
        glVertex2f(x, y)
        rotation += step;
        x = centerX + math.cos(rotation) * r;
        y = centerY + math.sin(rotation) * r;
        glColor3f(random.random(), random.random(), random.random())
        glVertex2f(x, y)
        rotation += step;

    glEnd()
    glPopMatrix()
    glfw.swap_buffers(window)
    glfw.poll_events()


def main():
    if not glfw.init():
        return
    window = glfw.create_window(800, 800, "Lab1", None, None)
    if not window:
        glfw.terminate()
        return
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)
    glfw.set_scroll_callback(window, scroll_callback)
    while not glfw.window_should_close(window):
        drawstar(window)
    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()