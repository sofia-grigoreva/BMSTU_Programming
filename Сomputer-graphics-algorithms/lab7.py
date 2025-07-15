import glfw
from OpenGL.GL import *
from OpenGL.GLU import *
import math
from PIL import Image
import numpy as np
import time

alpha = 20
size = 0.5
h = 0.5
r = 0.3
run_mode = False
texture_mode = False
speed = [0.001, 0, 0]

fps_counter = 0
fps_time = 0
last_print_time = 0

vertices = np.array([
    [size + h, size, size], [-size + h, size, size], [-size, -size, size], [size, -size, size],
    [size + r + h, size, -size], [size + r, -size, -size], [-size + r, -size, -size], [-size + r + h, size, -size],
    [size + h, size, size], [size, -size, size], [size + r, -size, -size], [size + r + h, size, -size],
    [-size + r + h, size, -size], [-size + r, -size, -size], [-size, -size, size], [-size + h, size, size],
    [size + r + h, size, -size], [-size + r + h, size, -size], [-size + h, size, size], [size + h, size, size],
    [size, -size, size], [-size, -size, size], [-size + r, -size, -size], [size + r, -size, -size]
], dtype=np.float32)

faces = np.array([
    [0, 1, 2, 3],
    [4, 5, 6, 7],
    [8, 9, 10, 11],
    [12, 13, 14, 15],
    [16, 17, 18, 19],
    [20, 21, 22, 23]
], dtype=np.uint8)

tex_coords = np.array([
    [(1, 1), (0, 1), (0, 0), (1, 0)] for _ in range(6)
], dtype=np.float32)

precomputed_normals = None
prism_display_list = None
vertex_vbo = None
normal_vbo = None
texcoord_vbo = None
index_vbo = None
texture_id = None

def key_callback(window, key, scancode, action, mods):
    global alpha, run_mode, texture_mode
    if action == glfw.PRESS or action == glfw.REPEAT:
        if key == glfw.KEY_UP:
            alpha = (alpha + 3) % 360
        elif key == glfw.KEY_DOWN:
            alpha = (alpha - 3) % 360
        elif key == glfw.KEY_RIGHT_SHIFT:
            texture_mode = not texture_mode
            update_display_list()
        elif key == glfw.KEY_SPACE:
            run_mode = not run_mode

def load_texture(filename):
    try:
        img = Image.open(filename)
        img_data = np.array(list(img.getdata()), np.uint8)
        texture_id = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, texture_id)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        format = GL_RGB if img.mode == "RGB" else GL_RGBA if img.mode == "RGBA" else None
        if format:
            glTexImage2D(GL_TEXTURE_2D, 0, format, img.width, img.height, 
                         0, format, GL_UNSIGNED_BYTE, img_data)
            glGenerateMipmap(GL_TEXTURE_2D)
            return texture_id
    except Exception as e:
        print(f"Error loading texture: {e}")
        return None

def init_lighting():
    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)
    glLightfv(GL_LIGHT0, GL_AMBIENT, (GLfloat * 4)(0.2, 0.2, 0.2, 1.0))
    glLightfv(GL_LIGHT0, GL_DIFFUSE, (GLfloat * 4)(1.0, 1.0, 1.0, 1.0))
    glLightfv(GL_LIGHT0, GL_SPECULAR, (GLfloat * 4)(1.0, 1.0, 1.0, 1.0))
    glLightfv(GL_LIGHT0, GL_POSITION, (GLfloat * 4)(0.0, 0.0, 5.0, 1.0))
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, (GLfloat * 3)(0.0, 0.0, -1.0))
    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 20.0)
    glLightf(GL_LIGHT0, GL_SPOT_EXPONENT, 2.0)

def precompute_normals():
    global faces, vertices, precomputed_normals
    normals = []
    for face in faces:
        v1 = vertices[face[0]]
        v2 = vertices[face[1]]
        v3 = vertices[face[2]]
        edge1 = v2 - v1
        edge2 = v3 - v1
        normal = np.cross(edge1, edge2)
        normals.append(normal)
    precomputed_normals = np.array(normals, dtype=np.float32)

def init_vbos():
    global vertex_vbo, normal_vbo, texcoord_vbo, index_vbo
    
    vertex_vbo = glGenBuffers(1)
    glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
    glBufferData(GL_ARRAY_BUFFER, vertices.nbytes, vertices, GL_DYNAMIC_DRAW)
    
    normal_data = np.zeros_like(vertices)
    for i, face in enumerate(faces):
        for vertex_idx in face:
            normal_data[vertex_idx] = precomputed_normals[i]
    
    normal_vbo = glGenBuffers(1)
    glBindBuffer(GL_ARRAY_BUFFER, normal_vbo)
    glBufferData(GL_ARRAY_BUFFER, normal_data.nbytes, normal_data, GL_STATIC_DRAW)
    
    texcoord_data = np.zeros((len(vertices), 2), dtype=np.float32)
    for i, face in enumerate(faces):
        for j, vertex_idx in enumerate(face):
            texcoord_data[vertex_idx] = tex_coords[i][j]
    
    texcoord_vbo = glGenBuffers(1)
    glBindBuffer(GL_ARRAY_BUFFER, texcoord_vbo)
    glBufferData(GL_ARRAY_BUFFER, texcoord_data.nbytes, texcoord_data, GL_STATIC_DRAW)
    
    indices = faces.flatten()
    index_vbo = glGenBuffers(1)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.nbytes, indices, GL_STATIC_DRAW)
    
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

def update_display_list():
    global prism_display_list, texture_mode
    
    if prism_display_list is not None:
        glDeleteLists(prism_display_list, 1)
    
    prism_display_list = glGenLists(1)
    glNewList(prism_display_list, GL_COMPILE)
    
    mat_diffuse = [1.0, 1.0, 1.0, 1.0] if texture_mode else [0.0, 0.749, 1.0, 1.0]
    glMaterialfv(GL_FRONT, GL_AMBIENT, (GLfloat * 4)(0.1, 0.1, 0.1, 1.0))
    glMaterialfv(GL_FRONT, GL_SPECULAR, (GLfloat * 4)(1.0, 1.0, 1.0, 1.0))
    glMaterialf(GL_FRONT, GL_SHININESS, 50.0)
    glMaterialfv(GL_FRONT, GL_DIFFUSE, (GLfloat * 4)(*mat_diffuse))
    
    if texture_mode and texture_id is not None:
        glEnable(GL_TEXTURE_2D)
        glBindTexture(GL_TEXTURE_2D, texture_id)
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
    
    glEnableClientState(GL_VERTEX_ARRAY)
    glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
    glVertexPointer(3, GL_FLOAT, 0, None)
    
    glEnableClientState(GL_NORMAL_ARRAY)
    glBindBuffer(GL_ARRAY_BUFFER, normal_vbo)
    glNormalPointer(GL_FLOAT, 0, None)
    
    if texture_mode and texture_id is not None:
        glEnableClientState(GL_TEXTURE_COORD_ARRAY)
        glBindBuffer(GL_ARRAY_BUFFER, texcoord_vbo)
        glTexCoordPointer(2, GL_FLOAT, 0, None)
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo)
    glDrawElements(GL_QUADS, len(faces) * 4, GL_UNSIGNED_BYTE, None)
    
    if texture_mode and texture_id is not None:
        glDisableClientState(GL_TEXTURE_COORD_ARRAY)
        glDisable(GL_TEXTURE_2D)
    
    glDisableClientState(GL_VERTEX_ARRAY)
    glDisableClientState(GL_NORMAL_ARRAY)
    
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    
    glEndList()

def check_boundaries():
    global vertices, speed
    min_x = np.min(vertices[:, 0])
    max_x = np.max(vertices[:, 0])
    if min_x <= -2.8 or max_x >= 2.8:
        speed[0] = -speed[0]

def animation():
    global vertices, speed, vertex_vbo
    vertices[:, 0] += speed[0]
    vertices[:, 1] += speed[1]
    vertices[:, 2] += speed[2]
    check_boundaries()
    
    glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
    glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.nbytes, vertices)
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    
    update_display_list()

def draw(window):
    global fps_counter, fps_time, last_print_time
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glLoadIdentity()
    glClearColor(1.0, 1.0, 1.0, 1.0)
    
    glPushMatrix()
    glTranslatef(0, 0, -5)
    glRotatef(alpha, 1, 0, 0)
    
    if run_mode:
        animation()
    
    glCallList(prism_display_list)
    
    glPopMatrix()
    
    glfw.swap_buffers(window)
    glfw.poll_events()

    fps_counter += 1
    current_time = time.time()
    if current_time - last_print_time >= 1.0:
        print(f"FPS: {fps_counter}")
        fps_counter = 0
        last_print_time = current_time

def main():
    global prism_display_list, fps_time, texture_id
    
    if not glfw.init():
        return
    
    glfw.window_hint(glfw.DOUBLEBUFFER, True)
    glfw.window_hint(glfw.DEPTH_BITS, 24)
    glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 2)
    glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 1)
    
    window = glfw.create_window(800, 600, "Lab7", None, None)
    if not window:
        glfw.terminate()
        return
    
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glDisable(GL_NORMALIZE)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_BACK)
    
    glMatrixMode(GL_PROJECTION)
    gluPerspective(45, 800/600, 0.1, 50)
    glMatrixMode(GL_MODELVIEW)
    
    precompute_normals()
    texture_id = load_texture("clouds.bmp")
    init_lighting()
    init_vbos()
    update_display_list()
    
    fps_time = last_print_time = time.time()
    while not glfw.window_should_close(window):
        draw(window)
    
    if prism_display_list is not None:
        glDeleteLists(prism_display_list, 1)
    if vertex_vbo is not None:
        glDeleteBuffers(1, [vertex_vbo])
    if normal_vbo is not None:
        glDeleteBuffers(1, [normal_vbo])
    if texcoord_vbo is not None:
        glDeleteBuffers(1, [texcoord_vbo])
    if index_vbo is not None:
        glDeleteBuffers(1, [index_vbo])
    if texture_id is not None:
        glDeleteTextures([texture_id])
    
    glfw.destroy_window(window)
    glfw.terminate()

if __name__ == "__main__":
    main()