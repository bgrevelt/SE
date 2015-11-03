module volume

// Model
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

// General
import IO;
import List;
import String;

// Get all the Java files
public set[loc] AllFiles(M3 model) 
	= {file | file <- model@containment.from, file.scheme == "java+compilationUnit"};

// Get all the comments
public list[str] AllComments(M3 model)
	= [trim(comment) | comment <- [*readFileLines(line) | line <- 
	[doc.comments | doc <- model@documentation]]];

// Get the total source lines of code in the project
// \todo: Could probably avoid a big copy here by sending comments 
// \todo: that belong to the specific file
public int LinesOfCodeProject(M3 model, list[str] comments) 
	= sum([LinesOfCodeFile(file, comments) | file <- AllFiles(model)]);

// Get the amount of source lines of code in a file
public int LinesOfCodeFile(loc file, list[str] comments)
	= size([line | line <- readFileLines(file), 
	trim(line) notin comments && !isEmpty(trim(line))]);