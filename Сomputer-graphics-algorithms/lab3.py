import glfw
from OpenGL.GL import *
from OpenGL.GLU import *
import random
import math

alpha = 20
beta = 0
size = 0.5
h = 0.5
r = 0.3
tr_count = 2
solid_mode = False


def key_callback(window, key, scancode, action, mods):
    global alpha
    global beta
    global size
    global solid_mode
    global tr_count

    if  action == glfw.REPEAT or action == glfw.PRESS:
        if key == glfw.KEY_UP:
            tr_count += 1
        if key == glfw.KEY_DOWN:
            tr_count -= 1
            if tr_count == 0:
                tr_count = 1
        if key == glfw.KEY_RIGHT:
            alpha += 3
        if key == glfw.KEY_LEFT:
            alpha -= 3
        if key == glfw.KEY_Q:
            beta += 1
        if key == glfw.KEY_SPACE:
            solid_mode = not solid_mode
        

def scroll_callback(window, xoffset, yoffset):
    global size
    if (xoffset > 0):
        size -= yoffset/10
    else:
        size += yoffset/10


def draw_prism(f):

    global h
    global r
    global tr_count
    global solid_mode
    global size

    if f:
        s = 0.3
    else:
        s = size 

    faces = [
        [(s + h, s, s), (-s + h, s, s), (-s, -s, s), (s, -s, s)],  # Передняя
        [(s + r + h, s, -s), (s+ r, -s, -s), (-s+ r, -s, -s), (-s+ r + h, s, -s)],  # Задняя
        [(s + h, s, s), (s, -s, s), (s+ r, -s, -s), (s+ r + h, s, -s)],  # Правая
        [(-s+ r + h, s, -s), (-s+ r, -s, -s), (-s, -s, s), (-s + h, s, s)],  # Левая
        [(s+ r + h, s, -s), (-s+ r + h, s, -s), (-s + h, s, s), (s + h, s, s)],  # Верхняя
        [(s, -s, s), (-s, -s, s), (-s+ r, -s, -s), (s+ r, -s, -s)]  # Нижняя
    ]    

    for face in faces:
        v0, v1, v2, v3 = face
        for i in range(tr_count):
            for j in range(tr_count):
                x00 = v1[0] + (v0[0] - v1[0]) * (i / tr_count)
                y00 = v1[1] + (v0[1] - v1[1]) * (i / tr_count)
                z00 = v1[2] + (v0[2] - v1[2]) * (i / tr_count)

                x10 = v1[0] + (v0[0] - v1[0]) * ((i + 1) / tr_count)
                y10 = v1[1] + (v0[1] - v1[1]) * ((i + 1) / tr_count)
                z10 = v1[2] + (v0[2] - v1[2]) * ((i + 1) / tr_count)

                x01 = v2[0] + (v3[0] - v2[0]) * (i / tr_count)
                y01 = v2[1] + (v3[1] - v2[1]) * (i / tr_count)
                z01 = v2[2] + (v3[2] - v2[2]) * (i / tr_count)

                x11 = v2[0] + (v3[0] - v2[0]) * ((i + 1) / tr_count)
                y11 = v2[1] + (v3[1] - v2[1]) * ((i + 1) / tr_count)
                z11 = v2[2] + (v3[2] - v2[2]) * ((i + 1) / tr_count)

                if solid_mode:

                    glBegin(GL_POLYGON)
        
        
                    glColor3f(random.random(), random.random(), random.random())
                    glVertex3f(x10, y10, z10)
                    glVertex3f(x01, y01, z01)
                    glVertex3f(x00, y00, z00)
                    
                    glColor3f(random.random(), random.random(), random.random())
                    glVertex3f(x10, y10, z10)
                    glVertex3f(x11, y11, z11)
                    glVertex3f(x01, y01, z01)
                    glVertex3f(x10, y10, z10)
                    glEnd()

                else:
                    glColor3f(0.729, 0.333, 0.827)
                    glBegin(GL_LINES)
                    glVertex3f(x00, y00, z00)
                    glVertex3f(x11, y11, z11)
                    glVertex3f(x00, y00, z00)
                    glVertex3f(x01, y01, z01)
                    glVertex3f(x01, y01, z01)
                    glVertex3f(x11, y11, z11)
                    glVertex3f(x11, y11, z11)
                    glVertex3f(x10, y10, z10)
                    glVertex3f(x10, y10, z10)
                    glVertex3f(x00, y00, z00)
                    glEnd()


def draw(window):

    global alpha
    global beta

    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
    glLoadIdentity()
    glClearColor(1.0, 1.0, 1.0, 1.0)

    glPushMatrix()
    glTranslatef(0, 0, -5)
    glRotatef(alpha, 0, 1, 0)  
    glRotatef(beta, 1, 1, 0) 
    draw_prism(False)
    glPopMatrix()

    glPushMatrix()
    glTranslatef(1.5, 1.4, -5)  
    glRotatef(40, 0, 1, 0)
    draw_prism(True)
    glPopMatrix()

    glfw.swap_buffers(window)
    glfw.poll_events()


def main():
    if not glfw.init():
        return
    window = glfw.create_window(800, 600, "Lab3", None, None)
    if not window:
        glfw.terminate()
        return
    
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)
    glfw.set_scroll_callback(window, scroll_callback)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluPerspective(45, 800/600, 0.1, 50)
    glMatrixMode(GL_MODELVIEW)
    glEnable(GL_DEPTH_TEST)

    while not glfw.window_should_close(window):
        draw(window)
 
    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()