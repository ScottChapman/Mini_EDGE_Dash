using Toybox.Math;
// Given a radius length r and an angle t in radians and a circle's center (x,y),
// you can calculate the coordinates of a point on the circumference as follows:
// h = r*cos(t) + x
// v = r*sin(t) + y
// radians = t = degrees * PI / 180

class CircleDegreesToCoordinates {
	
	hidden var x_;
	hidden var y_;
	
	function initialize(_r, _x, _y, _deg) {
		var t = _deg * Math.PI / 180;
		x_ = _r * Math.cos(t) + _x;
		y_ = _r * Math.sin(t) + _y; 
	}
	
	function getX() { return x_; }
	
	function getY() { return y_; }

}