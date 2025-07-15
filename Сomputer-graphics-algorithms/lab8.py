import glfw
from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader
import numpy as np
from PIL import Image
import glm

vertex_shader = """
#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 texCoord;

out vec3 Normal;
out vec3 FragPos;
out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(position, 1.0);
    FragPos = vec3(model * vec4(position, 1.0));
    Normal = mat3(transpose(inverse(model))) * normal;
    TexCoord = texCoord;
}
"""

fragment_shader = """
#version 330 core
in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoord;

out vec4 FragColor;

uniform vec3 lightPos;
uniform vec3 viewPos;
uniform vec3 lightColor;
uniform vec3 objectColor;
uniform bool useTexture;
uniform sampler2D texture1;

void main()
{
    float ambientStrength = 0.2;
    vec3 ambient = ambientStrength * lightColor;
    
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;
    
    float specularStrength = 0.5;
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);  
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor;  
    
    vec3 result;
    if (useTexture) {
        vec4 texColor = texture(texture1, TexCoord);
        result = (ambient + diffuse + specular) * texColor.rgb;
    } else {
        result = (ambient + diffuse + specular) * objectColor;
    }
    FragColor = vec4(result, 1.0);
}
"""

alpha = 20
beta = 0
size = 0.9
h = 0.7
r = 0.5
run_mode = False
texture_mode = False
speed = 0.001
direction = 1
prism_pos_x = 0.0

def create_prism_vertices(pos_x=0.0):
    vertices = [
        (size + h + pos_x, size, size), (-size + h + pos_x, size, size), 
        (-size + pos_x, -size, size), (size + pos_x, -size, size),
        (size + r + h + pos_x, size, -size), (size + r + pos_x, -size, -size), 
        (-size + r + pos_x, -size, -size), (-size + r + h + pos_x, size, -size),
        (size + h + pos_x, size, size), (size + pos_x, -size, size), 
        (size + r + pos_x, -size, -size), (size + r + h + pos_x, size, -size),
        (-size + r + h + pos_x, size, -size), (-size + r + pos_x, -size, -size), 
        (-size + pos_x, -size, size), (-size + h + pos_x, size, size),
        (size + r + h + pos_x, size, -size), (-size + r + h + pos_x, size, -size), 
        (-size + h + pos_x, size, size), (size + h + pos_x, size, size),
        (size + pos_x, -size, size), (-size + pos_x, -size, size), 
        (-size + r + pos_x, -size, -size), (size + r + pos_x, -size, -size)
    ]
    
    normals = []
    faces = [
        [0, 1, 2, 3],
        [4, 5, 6, 7],
        [8, 9, 10, 11],
        [12, 13, 14, 15],
        [16, 17, 18, 19],
        [20, 21, 22, 23]
    ]
    
    for face in faces:
        v1 = vertices[face[0]]
        v2 = vertices[face[1]]
        v3 = vertices[face[2]]
        edge1 = np.array([v2[0]-v1[0], v2[1]-v1[1], v2[2]-v1[2]])
        edge2 = np.array([v3[0]-v1[0], v3[1]-v1[1], v3[2]-v1[2]])
        normal = np.cross(edge1, edge2)
        normal = normal / np.linalg.norm(normal)
        for _ in range(4):
            normals.append(normal)
    
    tex_coords = []
    for _ in range(6):
        tex_coords.extend([(1, 1), (0, 1), (0, 0), (1, 0)])
    
    vertices_data = []
    for i in range(24):
        vertices_data.extend(vertices[i])
        vertices_data.extend(normals[i])
        vertices_data.extend(tex_coords[i])
    
    return np.array(vertices_data, dtype=np.float32)

def key_callback(window, key, scancode, action, mods):
    global alpha, beta, run_mode, texture_mode
    if action == glfw.REPEAT or action == glfw.PRESS:
        if key == glfw.KEY_UP:
            alpha += 3
        if key == glfw.KEY_DOWN:
            alpha -= 3
        if key == glfw.KEY_RIGHT_SHIFT:
            texture_mode = not texture_mode
        if key == glfw.KEY_SPACE:
            run_mode = not run_mode

def load_texture(path):
    img = Image.open(path)
    img_data = np.array(list(img.getdata()), np.uint8)
    
    texture_id = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, texture_id)
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    
    if img.mode == "RGB":
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, img.width, img.height, 0, GL_RGB, GL_UNSIGNED_BYTE, img_data)
    elif img.mode == "RGBA":
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img.width, img.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, img_data)
    
    return texture_id

def update_animation():
    global prism_pos_x, direction, speed
    boundary = 3.0
    
    prism_pos_x += speed * direction
    
    if prism_pos_x >= boundary:
        direction = -1
    elif prism_pos_x <= -boundary:
        direction = 1
    
    return create_prism_vertices(prism_pos_x)

def main():
    global prism_pos_x
    
    if not glfw.init():
        return
    
    window = glfw.create_window(800, 600, "Lab8", None, None)
    if not window:
        glfw.terminate()
        return
    
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)
    
    shader = compileProgram(
        compileShader(vertex_shader, GL_VERTEX_SHADER),
        compileShader(fragment_shader, GL_FRAGMENT_SHADER)
    )
    glUseProgram(shader)
    
    prism_data = create_prism_vertices()
    
    VAO = glGenVertexArrays(1)
    VBO = glGenBuffers(1)
    
    glBindVertexArray(VAO)
    glBindBuffer(GL_ARRAY_BUFFER, VBO)
    glBufferData(GL_ARRAY_BUFFER, prism_data.nbytes, prism_data, GL_DYNAMIC_DRAW)
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * 4, ctypes.c_void_p(0))
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * 4, ctypes.c_void_p(3 * 4))
    glEnableVertexAttribArray(1)
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * 4, ctypes.c_void_p(6 * 4))
    glEnableVertexAttribArray(2)
    
    texture = load_texture("clouds.bmp")
    
    glEnable(GL_DEPTH_TEST)
    glClearColor(1.0, 1.0, 1.0, 1.0)
    
    model_loc = glGetUniformLocation(shader, "model")
    view_loc = glGetUniformLocation(shader, "view")
    proj_loc = glGetUniformLocation(shader, "projection")
    light_pos_loc = glGetUniformLocation(shader, "lightPos")
    view_pos_loc = glGetUniformLocation(shader, "viewPos")
    light_color_loc = glGetUniformLocation(shader, "lightColor")
    object_color_loc = glGetUniformLocation(shader, "objectColor")
    use_texture_loc = glGetUniformLocation(shader, "useTexture")
    
    light_pos = glm.vec3(0.0, 0.0, 5.0)
    light_color = glm.vec3(1.0, 1.0, 1.0)
    object_color = glm.vec3(0.0, 0.749, 1.0)
    view_pos = glm.vec3(0.0, 0.0, 5.0)
    
    projection = glm.perspective(glm.radians(45.0), 800/600, 0.1, 50.0)
    
    while not glfw.window_should_close(window):
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        
        if run_mode:
            prism_data = update_animation()
            glBindBuffer(GL_ARRAY_BUFFER, VBO)
            glBufferData(GL_ARRAY_BUFFER, prism_data.nbytes, prism_data, GL_DYNAMIC_DRAW)
        
        view = glm.lookAt(glm.vec3(0.0, 0.0, 5.0), glm.vec3(0.0, 0.0, 0.0), glm.vec3(0.0, 1.0, 0.0))
        
        model = glm.mat4(1.0)
        model = glm.translate(model, glm.vec3(0.0, 0.0, -5.0))
        model = glm.rotate(model, glm.radians(alpha), glm.vec3(1.0, 0.0, 0.0))
        
        glUniformMatrix4fv(model_loc, 1, GL_FALSE, glm.value_ptr(model))
        glUniformMatrix4fv(view_loc, 1, GL_FALSE, glm.value_ptr(view))
        glUniformMatrix4fv(proj_loc, 1, GL_FALSE, glm.value_ptr(projection))
        glUniform3fv(light_pos_loc, 1, glm.value_ptr(light_pos))
        glUniform3fv(view_pos_loc, 1, glm.value_ptr(view_pos))
        glUniform3fv(light_color_loc, 1, glm.value_ptr(light_color))
        glUniform3fv(object_color_loc, 1, glm.value_ptr(object_color))
        glUniform1i(use_texture_loc, texture_mode)
        
        if texture_mode:
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, texture)
        
        glBindVertexArray(VAO)
        for i in range(0, 6):
            glDrawArrays(GL_TRIANGLE_FAN, i*4, 4)
        glBindVertexArray(0)
        
        glfw.swap_buffers(window)
        glfw.poll_events()
    
    glDeleteVertexArrays(1, [VAO])
    glDeleteBuffers(1, [VBO])
    glDeleteProgram(shader)
    glfw.terminate()

if __name__ == "__main__":
    main()