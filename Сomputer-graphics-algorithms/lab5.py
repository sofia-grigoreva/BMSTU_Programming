import glfw
from OpenGL.GL import *
import math

figure_vertices = []
o_vertices = []
draw_mode = True
show_result = False
width, height = 800, 600

def key_callback(window, key, scancode, action, mods):
    global draw_mode, show_result, figure_vertices, o_vertices, draw_mode, show_result
    if action == glfw.PRESS:
        if key == glfw.KEY_SPACE:
            show_result = not show_result
        if key == glfw.KEY_0:
            figure_vertices = []
            o_vertices = []
            draw_mode = True
            show_result = False
        if key == glfw.KEY_RIGHT:
            draw_mode = not draw_mode

def mouse_button_callback(window, button, action, mods):
    if button == glfw.MOUSE_BUTTON_LEFT and action == glfw.PRESS:
        x_pos, y_pos = glfw.get_cursor_pos(window)
        x = (x_pos / width) * 2 - 1
        y = -((y_pos / height) * 2 - 1)
        
        if draw_mode:
            figure_vertices.append((x, y))
        else:
            o_vertices.append((x, y))

def window_size_callback(window, new_width, new_height):
    global width, height
    width, height = new_width, new_height
    glViewport(0, 0, width, height)

def draw_polygon(vertices, color):
    glLineWidth(3.0)
    glColor(color)
    glBegin(GL_LINE_LOOP)
    for v in vertices:
        glVertex(v)
    glEnd()

def sort_vertices_clockwise(vertices):
    points = vertices
    n = len(points)
    cx = sum(p[0] for p in points) / n
    cy = sum(p[1] for p in points) / n
    def get_angle(point):
        dx = point[0] - cx
        dy = point[1] - cy
        return math.atan2(dy, dx)  
    a = list(sorted(points, key=get_angle, reverse=True))
    return a


def is_righter(p, edge_start, edge_end):
    cross = (edge_end[0] - edge_start[0]) * (p[1] - edge_start[1]) - (edge_end[1] - edge_start[1]) * (p[0] - edge_start[0])
    return cross < 0

def find_intersection(p1, p2, edge_start, edge_end):
    x1, y1 = p1
    x2, y2 = p2
    x3, y3 = edge_start
    x4, y4 = edge_end
    denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if denom == 0:
        return None 
    ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    if ua < 0 or ua > 1:
        return None 
    x = x1 + ua * (x2 - x1)
    y = y1 + ua * (y2 - y1)
    return (x, y)
    
def clipper():
    global figure_vertices, o_vertices
    arr = []

    for i in range(len(o_vertices)):
        start = o_vertices[i]
        end = o_vertices[(i + 1) % len(o_vertices)]
        output = []
        prev = figure_vertices[-1]
        
        for v in figure_vertices:
            if not is_righter(v, start, end):
                if is_righter(prev, start, end):
                    intersection = find_intersection(prev, v, start, end)
                    if intersection:
                        output.append(intersection)
                output.append(v)
            elif not is_righter(prev, start, end):
                intersection = find_intersection(prev, v, start, end)
                if intersection:
                    output.append(intersection)
            prev = v
        arr.append(output)
    return arr

def display(window):
    global  figure_vertices, o_vertices
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glClearColor(1.0, 1.0, 1.0, 1.0)
    
    if not show_result:
        draw_polygon(figure_vertices, (0.0, 0.749, 1.0)) 
        draw_polygon(o_vertices, (1.0, 0, 0.5))       
    else:
        o_vertices = sort_vertices_clockwise(o_vertices)
        for new in clipper():
            draw_polygon(new, (0.502, 0.0, 0.502))
    
    glfw.swap_buffers(window)
    glfw.poll_events()

def main():
    global width, height
    
    if not glfw.init():
        return
    
    window = glfw.create_window(width, height, "Lab5", None, None)
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