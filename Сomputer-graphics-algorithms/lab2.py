import glfw
from OpenGL.GL import *
from OpenGL.GLU import *

a = 0
b = 0
mode = True
size = 0.4

def key_callback(window, key, scancode, action, mods):
    global a
    global b
    global mode
    global size
    if  action == glfw.REPEAT or action == glfw.PRESS:
        if key == glfw.KEY_UP:
            b += 3
        if key == glfw.KEY_DOWN:
            b -= 3
        if key == glfw.KEY_RIGHT:
            a += 3
        if key == glfw.KEY_LEFT:
            a -= 3
        if key == glfw.KEY_CAPS_LOCK:
            mode = not(mode)


def scroll_callback(window, xoffset, yoffset):
    global size
    if (xoffset > 0):
        size -= yoffset/10
    else:
        size += yoffset/10

def new (size):
    return [
        (size, -size, -size),
        (size, size, -size),
        (-size, size, -size),
        (-size, -size, -size),
        (size, -size, size),
        (size, size, size),
        (-size, -size, size),
        (-size, size, size),
    ]

edges = [
    (1,2), (2,7), (5,1), (7,5),
    (1,0), (0,4), (4,5), (5,1),
    (5,7), (7,6), (6,4), (4,5),
    (4,0), (0,3), (3,6), (6,4),
    (3,2), (2,7), (7,6), (6,3),
    (1, 2), (2, 3), (3,0), (0,1),]

colors = [
    # Голубой
    (0.0, 0.749, 1.0),  
    (0.0, 0.749, 1.0), 
    (0.0, 0.749, 1.0),  
    (0.0, 0.749, 1.0),  

    # Фиолетовый
    (0.502, 0.0, 0.502),  
    (0.502, 0.0, 0.502),  
    (0.502, 0.0, 0.502),
    (0.502, 0.0, 0.502),  

    # Розовый
    (1.0, 0, 0.5), 
    (1.0, 0, 0.5), 
    (1.0, 0, 0.5),
    (1.0, 0, 0.5),

    # Бирюзовый
    (0.251, 0.878, 0.816),  
    (0.251, 0.878, 0.816),  
    (0.251, 0.878, 0.816),  
    (0.251, 0.878, 0.816),  

    # Синий
    (0.0, 0.0, 1.0),  
    (0.0, 0.0, 1.0), 
    (0.0, 0.0, 1.0),  
    (0.0, 0.0, 1.0),  

    # Сиреневый
    (0.729, 0.333, 0.827),  
    (0.729, 0.333, 0.827), 
    (0.729, 0.333, 0.827),  
    (0.729, 0.333, 0.827),  
]

def Cube(window):

    global edges
    global colors
    global a
    global b
    global size

    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
    glClearColor(1.0, 1.0, 1.0, 1.0)

    glPushMatrix()
    glRotatef(a, 0, 1, 0)  
    glRotatef(b, 1, 1, 0)  

    ind = -1
    vertices = new(size)

    if mode:
        glLineWidth(3.0)
        glBegin(GL_LINES)
    else:
        glBegin(GL_QUADS)
    for edge in edges:
        ind += 1
        if not(mode):
            glColor3fv(colors[ind % len(colors)])
        else:
            glColor3fv(colors[5])

        for vertex in edge:
            glVertex3fv(vertices[vertex])
    glEnd()
    glPopMatrix()


    glPushMatrix()

    glTranslatef(1.7, 1.2, 0.0)  
    glRotatef(60, 1, 1, 0) 
    glRotatef(-30, 0, 1, 0)
    
    vertices = new(0.3)
    ind = -1
    
    if mode:
        glLineWidth(3.0)
        glBegin(GL_LINES)
    else:
        glBegin(GL_QUADS)
    for edge in edges:
        ind += 1
        if not(mode):
            glColor3fv(colors[ind % len(colors)])
        else:
            glColor3fv(colors[5])

        for vertex in edge:
            glVertex3fv(vertices[vertex])
    glEnd()
    glPopMatrix()

    glfw.swap_buffers(window)
    glfw.poll_events()


def main():
    if not glfw.init():
        return
    window = glfw.create_window(800, 600, "Lab2", None, None)
    if not window:
        glfw.terminate()
        return
    
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)
    glfw.set_scroll_callback(window, scroll_callback)


    glEnable(GL_DEPTH_TEST)
    gluPerspective(45, (800 / 600), 0.1, 50.0)
    glTranslatef(0.0, 0.0, -5)

    while not glfw.window_should_close(window):
        Cube(window)
 

    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()