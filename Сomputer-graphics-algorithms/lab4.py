import glfw
from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *
from collections import defaultdict

vertices = []
mode = 0
width, height = 800, 600

def key_callback(window, key, scancode, action, mods):
    global mode
    global vertices
    if action == glfw.PRESS:
        if key == glfw.KEY_SPACE:
            mode = (mode + 1) % 3
        if key == glfw.KEY_0:
            vertices = []

def mouse_button_callback(window, button, action, mods):
    global vertices, width, height
    if button == glfw.MOUSE_BUTTON_LEFT and action == glfw.PRESS:
        width, height = glfw.get_window_size(window)
        x_pos, y_pos = glfw.get_cursor_pos(window)
        x = (x_pos / width) * 2 - 1
        y = ((y_pos / height) * 2 - 1) 
        vertices.append((x, y))

def window_size_callback(window, new_width, new_height):
    global width, height
    width, height = new_width, new_height
    glViewport(0, 0, width, height)

def find_intersections():
    intersections = defaultdict(list)
    if len(vertices) < 3:
        return intersections
    
    min_y = min(v[1] for v in vertices)
    max_y = max(v[1] for v in vertices)
    y = min_y
    
    while y <= max_y:
        for i in range(len(vertices)):
            x1, y1 = vertices[i]
            x2, y2 = vertices[(i + 1) % len(vertices)]
            
            if (y1 <= y <= y2) or (y2 <= y <= y1):
                if y1 != y2:
                    x = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
                    intersections[y].append(x)
        y += 0.001
    
    for y in intersections:
        intersections[y].sort()
    
    return intersections

def create_buffer():
    return bytearray([255] * width * height * 3)

def set_pixel(buffer, x, y, r, g, b, alpha):
    if 0 <= x < width and 0 <= y < height:
        index = (y * width + x) * 3
        buffer[index] = int(buffer[index] * (1 - alpha) + r * alpha)
        buffer[index + 1] = int(buffer[index + 1] * (1 - alpha) + g * alpha)
        buffer[index + 2] = int(buffer[index + 2] * (1 - alpha) + b * alpha)
        
def draw_polygon(buffer):
    intersections = find_intersections()
    if not intersections:
        return
    for y, x_coords in intersections.items():
        py = int((-y + 1) * height / 2)
        for i in range(0, len(x_coords), 2):
            if i + 1 >= len(x_coords):
                continue
            x_start = x_coords[i]
            x_end = x_coords[i + 1]
            px_start = int((x_start + 1) * width / 2)
            px_end = int((x_end + 1) * width / 2)
            for px in (px_start, px_end + 1):
                set_pixel(buffer, px, py, 0, 0, 255, 1)

def fill_polygon(buffer):
    if len(vertices) < 3:
        return
    intersections = find_intersections()
    for y, x_coords in intersections.items():
        for i in range(0, len(x_coords), 2):
            if i + 1 >= len(x_coords):
                break
            x1 = x_coords[i]
            x2 = x_coords[i + 1]
            px1 = int((x1 + 1) * width / 2)
            px2 = int((x2 + 1) * width / 2)
            py = int((-y + 1) * height / 2)
            draw_line_bresenham(buffer, x1, y, x2, y, 0, 0, 255)

def draw_polygon_clear(buffer):
    for i in range(len(vertices)):
        x1, y1 = vertices[i]
        x2, y2 = vertices[(i + 1) % len(vertices)]
        draw_line_bresenham(buffer, x1, y1, x2, y2, 0, 0, 255)

def draw_line_bresenham(buffer, x1, y1, x2, y2, r, g, b):
    px1 = int((x1 + 1) * width / 2)
    py1 = int((-y1 + 1) * height / 2)
    px2 = int((x2 + 1) * width / 2)
    py2 = int((-y2 + 1) * height / 2)
    dx = abs(px2 - px1)
    dy = abs(py2 - py1)
    if dx > dy:
        if px1 > px2:
            px1, px2 = px2, px1
            py1, py2 = py2, py1
        grad = (py2 - py1) / dx if dx != 0 else 0
        yend = py1 + grad * (round(px1) - px1)
        gap = 1 - (px1 + 0.5) % 1
        set_pixel(buffer, round(px1), int(yend), r, g, b, (1 - (yend % 1)) * gap)
        set_pixel(buffer, round(px1), int(yend) + 1, r, g, b, (yend % 1) * gap)
        y = yend + grad
        yend = py2 + grad * (round(px2) - px2)
        gap = (px2 + 0.5) % 1
        set_pixel(buffer, round(px2), int(yend), r, g, b, (1 - (yend % 1)) * gap)
        set_pixel(buffer, round(px2), int(yend) + 1, r, g, b, (yend % 1) * gap)
        for x in range(round(px1) + 1, round(px2)):
            set_pixel(buffer, x, int(y), r, g, b, 1 - (y % 1))
            set_pixel(buffer, x, int(y) + 1, r, g, b, y % 1)
            y += grad
    else:
        if py1 > py2:
            px1, px2 = px2, px1
            py1, py2 = py2, py1
        grad = (px2 - px1) / dy if dy != 0 else 0
        xend = px1 + grad * (round(py1) - py1)
        gap = 1 - (py1 + 0.5) % 1
        set_pixel(buffer,int(xend), round(py1),  r, g, b, (1 - (xend % 1)) * gap)
        set_pixel(buffer, int(xend),round(py1) + 1, r, g, b, (xend % 1) * gap)
        x = xend + grad
        yend = round(py2)
        xend = px2 + grad * (round(py2) - py2)
        gap = (py2 + 0.5) % 1
        set_pixel(buffer, int(xend), round(py2), r, g, b, (1 - (xend % 1)) * gap)
        set_pixel(buffer, int(xend) + 1, round(py2), r, g, b, (xend % 1) * gap)
        for y in range(round(py1) + 1, round(py2)):
            set_pixel(buffer, int(x), y, r, g, b, 1 - (x % 1))
            set_pixel(buffer, int(x) + 1, y, r, g, b, x % 1)
            x += grad

def display(window):
    buffer = create_buffer()
    
    if len(vertices) >= 3:
        if mode == 0:
            draw_polygon(buffer)
        elif mode == 1:  
            fill_polygon(buffer)
        elif mode == 2: 
            fill_polygon(buffer)
            draw_polygon_clear(buffer)
    
    glClear(GL_COLOR_BUFFER_BIT)
    glRasterPos2f(-1, -1)
    glDrawPixels(width, height, GL_RGB, GL_UNSIGNED_BYTE, buffer)
    glfw.swap_buffers(window)
    glfw.poll_events()

def main():
    global width, height
    
    if not glfw.init():
        return
    
    window = glfw.create_window(width, height, "Lab4 - Scanline Algorithm", None, None)
    if not window:
        glfw.terminate()
        return
    
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)
    glfw.set_mouse_button_callback(window, mouse_button_callback)
    glfw.set_window_size_callback(window, window_size_callback)
    
    while not glfw.window_should_close(window):
        display(window)
    
    glfw.destroy_window(window)
    glfw.terminate()

if __name__ == "__main__":
    main()