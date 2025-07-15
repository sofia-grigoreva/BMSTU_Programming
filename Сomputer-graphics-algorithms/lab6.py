import glfw
from OpenGL.GL import *
from OpenGL.GLU import *
import random
import math
from PIL import Image
import numpy as np

alpha = 20
beta = 0
size = 0.5
h = 0.5
r = 0.3
run_mode = False
texture_mode = False 
speed = [0.001, 0, 0]

faces = [
    [0, 1, 2, 3],    # Передняя
    [4, 5, 6, 7],     # Задняя
    [8, 9, 10, 11],   # Правая
    [12, 13, 14, 15], # Левая
    [16, 17, 18, 19], # Верхняя
    [20, 21, 22, 23]  # Нижняя
]

verticies = [
    (size + h, size, size), (-size + h, size, size), (-size, -size, size), (size, -size, size),  # Передняя
    (size + r + h, size, -size), (size + r, -size, -size), (-size + r, -size, -size), (-size + r + h, size, -size),  # Задняя
    (size + h, size, size), (size, -size, size), (size + r, -size, -size), (size + r + h, size, -size),  # Правая
    (-size + r + h, size, -size), (-size + r, -size, -size), (-size, -size, size), (-size + h, size, size),  # Левая
    (size + r + h, size, -size), (-size + r + h, size, -size), (-size + h, size, size), (size + h, size, size),  # Верхняя
    (size, -size, size), (-size, -size, size), (-size + r, -size, -size), (size + r, -size, -size)  # Нижняя
]  

tex_coords = [
    [(1, 1), (0, 1), (0, 0), (1, 0)],  
    [(1, 1), (0, 1), (0, 0), (1, 0)],  
    [(1, 1), (0, 1), (0, 0), (1, 0)],  
    [(1, 1), (0, 1), (0, 0), (1, 0)],  
    [(1, 1), (0, 1), (0, 0), (1, 0)],  
    [(1, 1), (0, 1), (0, 0), (1, 0)]   
]

def key_callback(window, key, scancode, action, mods):
    global alpha, beta, run_mode, size, texture_mode
    if action == glfw.REPEAT or action == glfw.PRESS:
        if key == glfw.KEY_UP:
            alpha += 3
        if key == glfw.KEY_DOWN:
            alpha -= 3
        if key == glfw.KEY_RIGHT_SHIFT:
            texture_mode = not texture_mode
        if key == glfw.KEY_SPACE:
            run_mode = not run_mode

def load_texture(filename):
    try:
        img = Image.open(filename)
        img_data = np.array(list(img.getdata()), np.uint8)
        
        texture_id = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, texture_id)
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
        
        if img.mode == "RGB":
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, img.width, img.height, 
                         0, GL_RGB, GL_UNSIGNED_BYTE, img_data)
        elif img.mode == "RGBA":
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img.width, img.height, 
                         0, GL_RGBA, GL_UNSIGNED_BYTE, img_data)
        else:
            return None
        return texture_id
    except Exception as e:
        return None

def init_lighting():

    light_ambient = [0.2, 0.2, 0.2, 1.0]
    light_diffuse = [1.0, 1.0, 1.0, 1.0]  
    light_specular = [1.0, 1.0, 1.0, 1.0] 
    light_position = [0.0, 0.0, 5.0, 1.0] 
    light_direction = [0.0, 0.0, -1.0] 
    spot_cutoff = 20.0                 
    spot_exponent = 2.0  

    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)

    glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient)
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse)
    glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular)
    glLightfv(GL_LIGHT0, GL_POSITION, light_position)
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light_direction)
    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, spot_cutoff)
    glLightf(GL_LIGHT0, GL_SPOT_EXPONENT, spot_exponent)

def draw_prism():
    global verticies, faces, texture_mode
    
    mat_diffuse_textured = [1.0, 1.0, 1.0, 1.0] 
    mat_ambient = [0.1, 0.1, 0.1, 1.0]   
    mat_diffuse = [0.0, 0.749, 1.0, 1.0] 
    mat_specular = [1.0, 1.0, 1.0, 1.0] 
    mat_shininess = 50.0                 

    glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient)
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular)
    glMaterialf(GL_FRONT, GL_SHININESS, mat_shininess)
    if texture_mode:
        glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse_textured)
        glEnable(GL_TEXTURE_2D)
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
    else:
        glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse)
    for i, face in enumerate(faces):
        glBegin(GL_POLYGON)
        for j, vertex_idx in enumerate(face):
            glNormal3fv(calculate_normal(face))  
            if texture_mode:
                glTexCoord2fv(tex_coords[i][j])
            glVertex3fv(verticies[vertex_idx])
        glEnd()
    if texture_mode:
        glDisable(GL_TEXTURE_2D)

def calculate_normal(face):
    v1 = verticies[face[0]]
    v2 = verticies[face[1]]
    v3 = verticies[face[2]]
    edge1 = (v2[0] - v1[0], v2[1] - v1[1], v2[2] - v1[2])
    edge2 = (v3[0] - v1[0], v3[1] - v1[1], v3[2] - v1[2])
    normal = (
        edge1[1] * edge2[2] - edge1[2] * edge2[1],
        edge1[2] * edge2[0] - edge1[0] * edge2[2],
        edge1[0] * edge2[1] - edge1[1] * edge2[0]
    )
    length = math.sqrt(normal[0]**2 + normal[1]**2 + normal[2]**2)
    if length > 0:
        normal = (normal[0]/length, normal[1]/length, normal[2]/length)
    return normal

def check_boundaries():
    global verticies, speed
    min_x = min(v[0] for v in verticies)
    max_x = max(v[0] for v in verticies)
    boundary = 2.8  
    if min_x <= -boundary or max_x >= boundary:
        speed[0] = -speed[0]

def animation():
    global verticies, speed
    verticies = [(v[0] + speed[0], v[1] + speed[1], v[2] + speed[2]) for v in verticies]
    check_boundaries()

def draw(window):
    global alpha, beta, run_mode
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glLoadIdentity()
    glClearColor(1.0, 1.0, 1.0, 1.0)
    glPushMatrix()
    glTranslatef(0, 0, -5)
    glRotatef(alpha, 1, 0, 0)
    
    if run_mode:
        animation()
        
    draw_prism()

    glPopMatrix()
    glfw.swap_buffers(window)
    glfw.poll_events()


def main():
    if not glfw.init():
        return
    window = glfw.create_window(800, 600, "Lab6", None, None)
    if not window:
        glfw.terminate()
        return
    
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glEnable(GL_DEPTH_TEST)
    glMatrixMode(GL_PROJECTION)
    gluPerspective(45, 800/600, 0.1, 50)
    glMatrixMode(GL_MODELVIEW)

    wood_texture = load_texture("clouds.bmp")
    init_lighting()  

    while not glfw.window_should_close(window):
        draw(window)
 
    glfw.destroy_window(window)
    glfw.terminate()

if __name__ == "__main__":
    main()