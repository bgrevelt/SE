module volume

// Model
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

// General
import IO;
import List;
import String;

// Get all the comments
public list[str] AllComments(M3 model)
	= [trim(comment) | comment <- [*readFileLines(line) | line <- 
	[doc.comments | doc <- model@documentation]]];

// Get the total source lines of code in the project
public list[int] LinesOfCode(set[loc] parts, list[str] comments) 
	= [LinesOfCodeInPart(part, comments) | part <- parts];

// Get the amount of source lines of code in a file
public int LinesOfCodeInPart(loc part, list[str] comments)
	= size([line | line <- readFileLines(part), 
	trim(line) notin comments && !isEmpty(trim(line))]);	//\todo: real men never double trim
