import javax.swing.*;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

public class PictureForm {
    private JPanel mainPanel;
    private JTextField areaField;
    private JSpinner aSpinner;
    private JLabel A;
    private CanvasPanel canvasPanel;
    private JSpinner bSpinner;
    private JLabel B;
    private JLabel x0;
    private JSpinner x0Spinner;

    public PictureForm() {
        x0Spinner.addChangeListener (new ChangeListener( ) {
            public void stateChanged (ChangeEvent e) {
                int x0 = (int) x0Spinner.getValue( );
                canvasPanel.setx0(x0);
            }
        });
        aSpinner.addChangeListener (new ChangeListener( ) {
            public void stateChanged (ChangeEvent e) {
                int a = (int) aSpinner.getValue( );
                canvasPanel.seta(a);
            }
        });
        bSpinner.addChangeListener (new ChangeListener( ) {
            public void stateChanged (ChangeEvent e) {
                int b = (int) bSpinner.getValue();
                canvasPanel.setb(b);
            }
        });
        x0Spinner.setValue(1);
        aSpinner.setValue(1);
        bSpinner.setValue(1);
    }

    public static void main(String[] args) {
        JFrame frame = new JFrame("Порабола");
        frame.setContentPane(new PictureForm().mainPanel);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }

}
