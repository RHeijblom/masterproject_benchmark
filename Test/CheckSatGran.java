public class CheckSatGran {

	public static void main(String[] param){
		// Expected param: <N> <nGrps> <sat-granularity> [--matrix]
		boolean error = false;
		
		// Configuration
		int N = -1;
		int nGrps = -1;
		int sat_granularity = -1;
		// Read params
		try{
			N = Integer.parseInt(param[0]);
			error |= (N <= 0);
			nGrps = Integer.parseInt(param[1]);
			error |= (nGrps <= 0);
			sat_granularity = Integer.parseInt(param[2]);
			error |= (sat_granularity <= 0);
		} catch(NumberFormatException|ArrayIndexOutOfBoundsException e){
			error = true;
		}
			
		// Handle incorrect params
		if(error){
			System.out.println("The parameters are incorrect; cannot execute script");
			System.out.println("Expected paramaters: <x> <y> <g> [--matrix]");
			System.out.println("\tx = Number of values/columns/width of matrix");
			System.out.println("\ty = Number of groups/rows/witdth of matrix");
			System.out.println("\tg = Saturation granularity");
			System.out.println("\tIf --matrix is provided the dummy sparse matrix is displayed too.");
			System.exit(0);	
		}
		
		// Initialize sparse matrix
		boolean[][] matrix = new boolean[N][nGrps];
		for(int row = 0; row < nGrps; row++){
			int col = (row*N)/nGrps;
			matrix[col][row] = true;
		}
		
		// Draw matrix if necessary
		if(param.length > 3){ // Dirty check; any forth parameter forces to draw matrix
			for(int row = 0; row < nGrps; row++){
				String text = "";
				for(int col = 0; col < N; col++){
					text += matrix[col][row]? "# " : "- ";
				}
				System.out.println(text.trim());
			}
		}
		
		// Level algorithm from pins2lts-sym.c
		int[] level = new int[nGrps];
		for (int i = 0; i < nGrps; i++){
			level[i] = -1;

			for (int j = 0; j < N; j++) {
				if(matrix[j][i]){
					level[i] = (N - j - 1) / sat_granularity;
					break;
				}
			}

			if (level[i] == -1) level[i] = 0;
		}
		
		// Result
		for(int l = 0; l < level.length; l++){
			System.out.printf("Row %"+maxWidth(nGrps-1)+"d = level %"+ maxWidth(level[0])+"d %n", l, level[l]);
		}
	}
	
	private static int maxWidth(int maxVal){
		return maxVal == 0? 1:(int) Math.ceil(Math.log10(maxVal+1));
	}
	
}
