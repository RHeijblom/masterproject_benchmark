/**
 * Quick script to generate testcases for gen_experiments_alt.sh
 */ 
public class BatchGen {

	private static final String[] order = new String[]{"bfs","bfs-prev","chain","chain-prev"};
	private static final String[] saturation = new String[]{"none","sat-like","sat-loop"};
	private static final int[] sat_gran = new int[]{1,5,10,20,40,80,2147483647};
	
	public static void main(String[] argh){
		String[] sat_strat = initSatStrat();
		String strat_out = "";
		String perf_out = "";
		int index = 1;
		for(String sat: sat_strat){
			for(String ord: order){
				// First entry mod
				String assign = index == 1? "=": "+=";
				assign += "$'";
				// Last entry mod
				String trail = index == sat_strat.length*order.length? "'": "\\n'";
				String testCase = "--order=" + ord + " " + sat;
				// Record testcases
				strat_out += "POPTS_VERBOSE"+ assign + testCase + " --peak-nodes --graph-metrics"+ trail;
				strat_out += "\n"; // Delimiter
				perf_out += "POPTS"+ assign + testCase + trail;
				perf_out += "\n"; // Delimiter
				index++;
			}
		}
		System.out.println("# START GENERATED CODE");
		System.out.println("# Statistics testcases:");
		System.out.println(strat_out);
		System.out.println("\n# Performance testcases:");
		System.out.println(perf_out);
		System.out.println("# END GENERATED CODE");
	}

	// Generate all saturation strategies
	private static String[] initSatStrat(){
		String[] sat_strat = new String[(saturation.length-1)*sat_gran.length+1];
		final String sat_txt = "--saturation=";
		sat_strat[0] = ""+ sat_txt + saturation[0];
		int index = 1;
		for(int sat = 1; sat < saturation.length; sat++){
			for(int gran = 0; gran < sat_gran.length; gran++){
				sat_strat[index++] = "" + sat_txt + saturation[sat] + " --sat-granularity="+ sat_gran[gran];
			}
		}
		return sat_strat;
	}
}