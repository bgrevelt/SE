module unitTestCloneDetection

import clones;
import List;
import IO;
import Set;
import volume;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

test bool tcIgnoreComments()
{
	lines = readFileLines(|java+compilationUnit:///Users/Bouke/Documents/SE/workspace3/MyTestJava/src/testCloneDetection/A.java|);
	return size(getDuplicateLines(lines)) == 16;
}

int IgnoreComments()
{
	lines = GetProjectLines(createM3FromEclipseProject(|project://MyTestJava|));
	return size(getDuplicateLines(lines));
}