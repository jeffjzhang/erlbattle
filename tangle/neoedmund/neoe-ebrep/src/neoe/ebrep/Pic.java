package neoe.ebrep;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JComponent;
import javax.swing.JFrame;

public class Pic {
	static int R = 30;
	static int R2 = 30 * 15;
	private static Image ICON_STOP;
	private static Image ICON_MOVE;
	private static Image ICON_ATTACK;
	private static Image ICON_NONE;
	private static Font Font12=new Font("Serif", Font.PLAIN, 12);
	private static Font Font24=new Font("Serif", Font.BOLD, 24);
	static {
		ICON_STOP = new ImageIcon("icon/E_Wood03.png").getImage();
		ICON_MOVE = new ImageIcon("icon/A_Shoes04.png").getImage();
		ICON_ATTACK = new ImageIcon("icon/S_Bow08.png").getImage();
		ICON_NONE = new ImageIcon("icon/S_Ice07.png").getImage();
	}

	public static class P2 extends JComponent {
		Map m;

		public P2(List<String[]> cell, List<String[]> plan) {
			m = toMap(new HashMap(), cell, plan);
		}

		private Dimension dim = new Dimension(R2, R2);

		@Override
		public int getHeight() {
			return R2;
		}

		@Override
		public Dimension getPreferredSize() {
			return dim;
		}

		@Override
		public int getWidth() {
			return R2;
		}

		protected void paintComponent(Graphics g) {
			xdraw2(g, m, "0");
		}

	}

	private static void xdraw2(Graphics g, Map m, String time) {
		// S/ystem.out.println("draw " + m.keySet().size());
		for (Object id : m.keySet()) {
			Object[] r = (Object[]) m.get(id);
			String[] w1 = (String[]) r[0];
			String[] w2 = (String[]) r[1];
			if (w1 == null) {
				System.out.println("invalid plan for " + id
						+ " maybe already dead.");
				continue;
			}
			int x = i(w1[2]), y = i(w1[3]);
			// S/ystem.out.println("x"+x+",y"+y);
			g.translate(R * x, R * y);
			xdraw((Graphics2D) g, w1[5],
					i(w1[4]) > 10 ? Color.BLUE : Color.RED, i(id), i(w1[6]),
					i(w1[7]), w1[1]);
			g.translate(-R * x, -R * y);
		}
		g.setFont(Font24);
		g.setColor(Color.WHITE);		
		g.drawString("Time:"+time, 10+1, 30+1);
		g.setColor(Color.BLACK);		
		g.drawString("Time:"+time, 10, 30);
	}

	public static Map toMap(Map m, List<String[]> cell, List<String[]> plan) {
		for (String[] w : cell) {
			setv1(m, w[4], w);
		}
		for (String[] w : plan) {
			setv2(m, w[1], w);
		}
		return m;
	}

	private static void setv2(Map m, String id, String[] w) {
		setv(m, id, null, w);
	}

	private static void setv1(Map m, String id, String[] w) {
		setv(m, id, w, null);
	}

	private static void setv(Map m, String id, String[] w1, String[] w2) {
		Object o = m.get(id);
		Object[] r;
		if (o == null) {
			r = new Object[2];
			m.put(id, r);
		} else {
			r = (Object[]) o;
		}
		if (w1 != null) {
			r[0] = w1;
		}
		if (w2 != null) {
			r[1] = w2;
		}
	}

	static int i(Object o) {
		return Integer.parseInt(o.toString());
	}

	public static class P extends JComponent {

		private Dimension dim = new Dimension(R, R);

		@Override
		protected void paintComponent(Graphics g) {
			xdraw((Graphics2D) g, "w", Color.RED, 3, 90, 10, "walk");
		}

		@Override
		public int getHeight() {
			return 2 * R;
		}

		@Override
		public Dimension getPreferredSize() {
			return dim;
		}

		@Override
		public int getWidth() {
			return 2 * R;
		}

	}

	private static void xdraw(Graphics2D g, String dir, Color color, int id,
			int hp, int damage, String act) {
		if (hp<=0){
			return;
		}
		g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
				RenderingHints.VALUE_ANTIALIAS_ON);
		g.setColor(Color.BLACK);
		g.drawOval(0, 0, R, R);
		g.setColor(color);
		int a = 30;
		int a2 = 15;
		if ("n".equals(dir)) {
			g.fillArc(0, 0, R, R, 90 - a2, a);
		} else if ("w".equals(dir)) {
			g.fillArc(0, 0, R, R, 180 - a2, a);
		} else if ("e".equals(dir)) {
			g.fillArc(0, 0, R, R, -a2, a);
		} else if ("s".equals(dir)) {
			g.fillArc(0, 0, R, R, 270 - a2, a);
		}
		Image img;
		if ("walk".equals(act)) {
			img = ICON_MOVE;
		} else if ("fight".equals(act)) {
			img = ICON_ATTACK;
		} else if ("stand".equals(act)) {
			img = ICON_STOP;
		} else {
			img = ICON_NONE;
		}
		g.drawImage(img, 1, 1, 15, 15, null);
		int x = R / 2;
		int y = R / 2;
		g.setFont(Font12);
		g.setColor(Color.BLACK);
		g.drawString("" + hp, x - 1, y - 1);
		g.setColor(Color.GREEN);
		g.drawString("" + hp, x, y);
		y += R / 2 - 2;
		g.setColor(Color.BLACK);
		g.drawString("" + damage, x - 1, y - 1);
		g.setColor(Color.RED);
		g.drawString("" + damage, x, y);
	}

	public Pic() {
		bfm = new HashMap();
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		new Pic().run();

	}

	private Map bfm;

	private void run() {
		test1();
		test2();

	}

	private void test2() {
		BufferedImage im = new BufferedImage(R, R, BufferedImage.TYPE_INT_ARGB);
		xdraw((Graphics2D) im.getGraphics(), "w", Color.BLUE, 2, 99, 88,
				"fight");
		try {
			ImageIO.write(im, "PNG", new File("test2.png"));
		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	private void test1() {
		JFrame f = new JFrame();
		f.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		f.add(new P());
		f.pack();
		f.setVisible(true);
	}

	public void write(List<String[]> cell, List<String[]> plan, String fn) {
		BufferedImage im = new BufferedImage(R2, R2,
				BufferedImage.TYPE_INT_ARGB);
		String time=null;
		if (cell.size()>0){
			time=cell.get(0)[0];
		}
		xdraw2(im.getGraphics(), toMap(bfm, cell, plan), time);
		try {
			ImageIO.write(im, "PNG", new File(fn));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}
