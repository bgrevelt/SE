package testCloneDetection;

public class B {
	
	private int a = 5;
	private int b = 6;
	private int c = 7;
	private int d = 8;
	private int e = 9;
	private int f = 10;
	private int g = 11;
	private int h = 12;
	
	public void func1()
	{
		// this 
		a = b / c;
		// is 
		b = 4 +5;
		// a 
		c = a * b;
		// function
		d = nonExistingFuncCall(5);
		// interspersed
		e = e;
		// with
		f = f * f;
		// comments		
	}	
}
