module main

// Model
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

// General imports
import IO;
import List;
import Boolean;
import Map;
import Set;
import util::Math;

// Helpers
import Preprocessing::Text::Volume;

// locations of projects for convenience (could just enter a path)
public loc testProject  = |project://testProject|;
public loc smallProject = |project://smallsql0.21_src|;
public loc largeProject = |project://hsqldb-2.3.1|;
public loc ppUnitTest 	= |project://TestPreprocessing|;

// Aliases
alias lineMatrix = list[list[bool]];			// A matrix of lines in two files. A 'true' in a cell indicates that both lines have the same content
alias filePair = tuple[loc first,loc second];				
alias fileMatrix = map[filePair, lineMatrix];	// A matrix of lineMatrices. Contains a lineMatrix for each filePair in the project

alias fileLine = tuple[loc file, int lineNr];
alias dupLine = tuple[fileLine x, fileLine y];

alias t1Pair  = tuple[loc file, int s, int end];
alias t1clone = tuple[t1Pair x, t1Pair y];
alias t3clone = list[t1clone];

alias coord = tuple[int x, int y];

/**
 * Main entry for the duplication function (Report)
 * @param the project you want to report the dupes of
 */
public void ReportDuplicates(loc project)
{
	println("-- Creation ----------------");
	
	// Create model
	model = createM3FromEclipseProject(project);
	println(" - Created model");
	
	// Get all the files
	set[loc] files = files(model);
	//\todo: Volume requires tests
	map[loc, list[str]] lines = LinesOfCode(files);
	
	matrix = CreateFileMatrix(lines);
	
	list[list[dupLine]] diagonals = [];
	
	for(filePair <- matrix)
	{				
		lm = matrix[filePair];
		
		height = size(lm);
		width = size(lm[0]);	// TODO: fucked if it's empty
		
		diagonals += GetDiagonals(filePair.first, filePair.second, width, height, lm);
	}
	
	clones = GetT1Clone(6, diagonals);
	//iprintln(clones);
	//println(size(clones));
	
	iprintln(GetT3Clones(6, clones));
}

fileMatrix CreateFileMatrix(map[loc, list[str]] files)
{
	fileMatrix mat = ();
	
	for(fx <- files)
	{
		for(fy <- files)
		{
			if(<fy,fx> notin mat)
				mat[<fx,fy>] = CreateLineMatrix(files[fx], files[fy]);
		}
	}
	return mat;
}

lineMatrix CreateLineMatrix(list[str] x, list[str] y)
{
	mat = [];
	for(lx <- x)
	{
		list[bool] row = [];
		for(ly <- y)
		{
			row += ly == lx;
		}
		mat += [row];
	}
		
	return mat;
}

list[list[dupLine]] GetDiagonals(loc fx, loc fy, int width, int height, lineMatrix matrix)
{
	list[list[dupLine]] diagonals = [];
	
	for(coords <- getAllDiags(matrix, fx == fy))
	{
		diagonal = [];
		
		for(c <- coords)
		{
			if(matrix[c.y][c.x])
				diagonal += <<fx,c.x>,<fy,c.y>>;
		}
		
		if(size(diagonal) > 0) diagonals += [diagonal];
	}
		
	return diagonals;	
}

list[list[tuple[int x,int y]]] getAllDiags(lineMatrix m, bool onlyBelowOrigin)
{
	try
	{
		height = size(m);	
		width = size(m[0]);
		
		/* Create all coordinates in the matrix to start diagonals from. 
		 * This is equal to the top row and the left column
		 * optionally omit all diagonals top-left of the origin. 
		 * This is used for when we want to compare clone matrices
		 * created by comparing a file with itself. In that case it makes
		 * no sense to look both beneath and above the matrix' diagonal
		 */
		 
		startCoords = [];
		if(onlyBelowOrigin) {
			startCoords = [0] * [1..height];
		}
		else {
			startCoords = [0] * [0..height] + [0..width] * [0];
		}
		
		// Use GetDiagonals to get diagonals starting at those coordinates
		return [GetDiagonal(c, width,height) | c <- dup(startCoords)];
	}
	catch IndexOutOfBounds(i) : return [];
}

/* Return a list of coordinates that form a diagonal line in a matrix of a specified width and height
 * from a specified starting point. */
list[coord]GetDiagonal(coord startCoord, int width, int height) =
	[<startCoord.x+i, startCoord.y+i> | i <- [0..min(width-startCoord.x, height - startCoord.y)]];

list[t1clone] GetT1Clone(int threshold, list[list[dupLine]] diagonals) = 
	[*GetT1ClonesInLine(threshold, diagonal) | diagonal <- diagonals];


/* Get all the clones from a single diagonal line in the 'duplication matrix'
 * Threshold: The minumum number of lines that a clone should have
 * Diagonal: A list of file-linenumber pairs. Each pair represents a duplicate line
 */
list[t1clone] GetT1ClonesInLine(int threshold, list[dupLine] diagonal)
{
	clones = [];	
	diagLen = size(diagonal);	
	cloneStart = 0;
	
	
	// Iterate over all the items in the diagonal line of the 'duplication matrix'
	for(i <- [0..diagLen])
	{
		curr = diagonal[i];
		
		// If we are not at the end of the line...
		if(i < diagLen-1)
		{				
			// Check if the next line is a 'continuation' of the current clone
			// If it is not, we have found the end of the current clone.			
			next = diagonal[i+1];			
			if(!succeedingLines(curr,next))  
			{
				// If the current clone is long enough, store it as a clone
				if(i - cloneStart >= threshold) clones += createClone(diagonal, cloneStart, i);
				
				// The next line will be the start of the next (possible) clone
				cloneStart = i+1;
			}
		}
		// If we are at the end of the line...
		else if(i > 0)
		{
			// Check to see if the current line is a continuation of the previous line. 
			// If it is, the last line is also the end of the current clone.
			prev = diagonal[i-1];
			if(succeedingLines(prev,curr) && (i - cloneStart >= threshold))	clones +=  createClone(diagonal, cloneStart, i);
		}		
	}
	return clones;
}

list[t3clone] GetT3Clones(int threshold, list[t1clone] t1Clones)
{
	if (threshold < 2)
		return [];

	list[t3clone] t3Clones = [];
	
	for (t1Clone <- t1Clones) {
		// alias t1Pair  = tuple[loc file, int s, int end];
		// alias t1clone = tuple[t1Pair x, t1Pair y];
		t3clone t3Clone = [t1Clone];
		
		list[t1clone] t1 = [t1Clone];
		while (true)
		{
			t1 = FindNextType1(threshold, t1[0], t1Clones);
			if (size(t1) == 0)
				break;
			t3Clone += t1;
		}
		
		if (size(t3Clone) > 1)
			t3Clones += [t3Clone];
	}
	
	return t3Clones;
}

list[t1clone] FindNextType1(int threshold, t1clone clone, list[t1clone] t1Clones)
{
	for (bound <- [2..threshold + 1]) {
		for (t1Clone2 <- t1Clones) {
			if (clone.x.end + bound == t1Clone2.x.s && (clone.y.end + bound == t1Clone2.y.s)){
				return [t1Clone2];
			}
		}
	}
	
	return [];
}


bool succeedingLines(dupLine first, dupLine second) =
	first.x.lineNr+1 == second.x.lineNr && first.y.lineNr+1 == second.y.lineNr; 

t1clone createClone(list[dupLine] diagonal, int startInx, int endInx)
{
	s = diagonal[startInx];
	e = diagonal[endInx];
	return <<s.x.file, s.x.lineNr, e.x.lineNr>,<s.y.file, s.y.lineNr, e.y.lineNr>>;
}

