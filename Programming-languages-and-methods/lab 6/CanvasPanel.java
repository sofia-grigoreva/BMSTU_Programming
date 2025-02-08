import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
public class CanvasPanel extends JPanel {
    private int x0 = 1;
    private int a = 1;
    private int b = 1;
    private Color color = Color.RED;
    public CanvasPanel() {
        JComboBox<String> colorComboBox = new JComboBox<>(new String[]{"Red", "Blue", "Green"});
        colorComboBox.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                String selectedColor = (String) colorComboBox.getSelectedItem();
                switch (selectedColor) {
                    case "Red":
                        color = Color.RED;
                        break;
                    case "Blue":
                        color = Color.BLUE;
                        break;
                    case "Green":
                        color = Color.GREEN;
                        break;
                    case "Black":
                        color = Color.BLACK;
                        break;
                }
                repaint();
            }
        });
        add(colorComboBox);
    }
    public void setx0(int x) {
        x0 = x;
        repaint();
    }
    public void seta(int a) {
        this.a = a;
        repaint();
    }
    public void setb(int b) {
        this.b = b;
        repaint();
    }
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.setColor(Color.BLUE);
        for (int x = 0; x <= 10; x++) {
            int y = (int) ((a*x * x) / b);
            g.fillRect(x*70+50, 1000-y*10, 4, 4);

        }
        g.setColor(color);
        int y = (int) ((x0 * a * x0) / b);
        int y1 = (int) ((a * (50+x0) * 2*x0) / b - (a * x0 * 2*x0) / b  + (a * x0 * x0) / b);
        g.drawLine(x0*70+50, 1000-y*10,(x0+50)*70+50 , 1000-y1*10);
    }
}
