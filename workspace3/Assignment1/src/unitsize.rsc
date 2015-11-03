module unitsize

// Model
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

// General
import IO;
import List;
import String;

// For AllComments
import volume;

// Get all the Java methods
public list[loc] AllMethods(M3 model) 
	= [method | method <- model@containment.from, method.scheme == "java+method"];

// Get the total source lines of code in the project
// \todo: Could probably avoid a big copy here by sending comments 
// \todo: that belong to the specific method
public list[int] LinesOfCodeUnit(M3 model, list[str] comments) 
	= [LinesOfCodeUnit(method, comments) | method <- AllMethods(model)];

// Get the amount of source lines of code in a method
public int LinesOfCodeUnit(loc method, list[str] comments)
	= size([line | line <- readFileLines(method), 
	trim(line) notin comments && !isEmpty(trim(line))]);