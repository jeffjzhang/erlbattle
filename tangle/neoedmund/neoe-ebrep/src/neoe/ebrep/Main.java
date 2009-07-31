package neoe.ebrep;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;

public class Main {

	/**
	 * @param args
	 */
	public static void main(String[] args) throws Exception {
		new Main().run();
		System.out.println("program end.");

	}

	final static String picDir = "warpic";
	int picid;
	Pic pic;

	private void run() throws Exception {
		picid = 1;
		new File(picDir).mkdirs();
		pic = new Pic();
		BufferedReader in = new BufferedReader(new FileReader("warfield.txt"));
		int st = 0;
		while (true) {
			String line = in.readLine();
			if (line == null) {
				outputText();
				break;
			}

			String[] w = line.split(",");
			if (w.length == 8) {
				if (st == 0) {
					addCell(w);
				} else {// st==1
					outputText();
					st = 0;
					addCell(w);
				}
			} else if (w.length == 3) {
				st = 1;
				addPlan(w);
			}
		}
	}

	private void outputText() throws Exception {
		String fn = picDir + "/t" + (picid++) + ".png";
		System.out.println(fn);
		// BufferedWriter out = new BufferedWriter(new FileWriter(fn));
		// for (String[] w : cell) {
		// out.write(Arrays.toString(w));
		// out.write("\n");
		// }
		// for (String[] w : plan) {
		// out.write(Arrays.toString(w));
		// out.write("\n");
		// }
		// out.close();
		// JFrame f = new JFrame();
		// f.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		// f.add(new P2(new ArrayList<String[]>(cell),new
		// ArrayList<String[]>(plan)));
		// f.pack();
		// f.setVisible(true);
		pic.write(cell, plan, fn);
		cell.clear();
		plan.clear();
	}

	private void addPlan(String[] w) {
		plan.add(w);
	}

	List<String[]> plan = new ArrayList<String[]>();
	List<String[]> cell = new ArrayList<String[]>();

	private void addCell(String[] w) {
		cell.add(w);
	}

}
