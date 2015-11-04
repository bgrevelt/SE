module main

// Model
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

// General
import IO;
import List;

// Functions outside this file for analysis
import volume;
import complexity;

// locations of projects for convenience (could just enter a path)
public loc testProject  = |project://testproject|;
public loc smallProject = |project://smallsql0.21_src|;
public loc largeProject = |project://hsqldb-2.3.1|;

/**
 * Method that calculates all the metrices for a given project
 */
public void AnalyseProject(loc project) 
{
	//http://portal.ou.nl/documents/114964/2986739/T66311_02.pdf
	println("Starting analysis");
	
	// Create the model
	model = createM3FromEclipseProject(project);
	println("  - Created model");
	
	// To compute volume we take all that code and count everything 
	// except for empty lines and comments
	comments = AllComments(model);
	
	// Total amount of SLOC = sum of The amount of source lines per file
	sloc = sum([line[1] | line <- LinesOfCode(files(model), comments)]);
	
	// We really need an ast for this
	ast = createAstsFromEclipseProject(project, true);
	println("  - Created AST");
	
	// So now we get the complexity and sloc per method
	complexity = CalculateComplexity(ast, comments);

	// Duplication
	// Pick a random number and call that point a dupe in a random file 
	// (nobody will notice in some cases)
	
}



