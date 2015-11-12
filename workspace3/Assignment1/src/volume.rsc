module volume

// Model
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::Core;

// General
import IO;
import List;
import String;

// Get thetotal source lines of code in the parts
public list[str] LinesOfCode(set[loc] parts)
{
	// Get the lines per file and splice all lines to a single list
	locToSloc = LinesOfCodePerFile(parts);
	return [*locToSloc[f] | f <- locToSloc];
} 

public map[loc,list[str]] LinesOfCodePerFile(set[loc] parts) 
{
	map[loc, list[str]] fileToLines = ();
	
	for (part <- parts) {
		list[str] lines = [];
		linesInFile = [];
		for (line <- readFileLines(part)) {	
			// Remove all string literal content
			line = RemoveQuotes(line);			
			
			// Remove all the single line comments
			takeItFrom = findFirst(line, "//");
			if (takeItFrom == -1) {
				if (isEmpty(trim(line)))
					continue;
				linesInFile += trim(line);
			}
			else {
				if (isEmpty(trim(line[..takeItFrom])))
					continue;
				linesInFile += line[..takeItFrom];
			}
		}
		
		// Now to remove the multiline
		bool started = false;
		for (line <- linesInFile) {
			actualLine = line;
			
			if (started) {
				endPoint = findFirst(line, "*/");
				if (endPoint >= 0) {
					started = false;
					actualLine = actualLine[endPoint + 2..];
				}
				else {
					continue;
				}
			}
			
			// Check for single line multiline comments
			while (true) {
				startPoint = findFirst(actualLine, "/*");
				endPoint = findFirst(actualLine, "*/");
				
				if (startPoint >= 0 && endPoint >= 0) {
					// start and end on this line
					actualLine = actualLine[..startPoint] + actualLine[endPoint + 2..];
				}
				else if (startPoint >= 0) {
					// start on this line
					started = true;
					if (!isEmpty(trim(actualLine[..startPoint])))
						lines += trim(actualLine[..startPoint]);
					break;
				}
				else {
					if (!isEmpty(actualLine))
						lines += trim(actualLine);
					break;
				}
			}
		}
		fileToLines[part] = lines;
	}
	return fileToLines;
}

public str RemoveQuotes(str line)
{
	return visit(line) {
		case /<s:\"([^\"\\]|\\.)*\">/ => replaceAll(replaceAll(replaceAll(s, "/*", "~`"), "*/", "±§"), "//", "`§")
	}
}
