using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Math;

class MiniTRAILDashView extends WatchUi.DataField {

	// Set CONSTANTS
	hidden var FONT_HEIGHT_XTINY = Gfx.getFontHeight(Gfx.FONT_XTINY);
	hidden var FONT_HEIGHT_TINY = Gfx.getFontHeight(Gfx.FONT_TINY);
	hidden var FONT_HEIGHT_SMALL = Gfx.getFontHeight(Gfx.FONT_SMALL);
	hidden var FONT_HEIGHT_MEDIUM = Gfx.getFontHeight(Gfx.FONT_MEDIUM);
    
    // Settings
    hidden var hrZones;
    
    // Variables
    hidden var hr = 0;
    hidden var hrZone;
    hidden var avgHr;
    hidden var maxHr;
    
    hidden var cadence = 0;

    function initialize() {
        DataField.initialize();
        
        // get current Sport's Heart Rate Zones
        hrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
        
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	// Current Values
    	hr = (info.currentHeartRate != null) ? info.currentHeartRate : 0;
    	avgHr = (info.averageHeartRate != null) ? info.averageHeartRate : 0;
    	maxHr = (info.maxHeartRate != null) ? info.maxHeartRate : 0;
    	cadence = (info.currentCadence != null) ? info.currentCadence : 0;
    	
    	// Calculate HR Zone
    	if (hr != null) {
	    	for (var i = 0; i < hrZones.size(); i += 1) {
	    		if (hr <= hrZones[i]) {
	    			hrZone = i;
	    			break;
	    		}
	    	}
	    } else {
	    	hrZone = null;
	    }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    	var bgColor = getBackgroundColor();
    	var width = dc.getWidth();
    	var height = dc.getHeight();
    	var x;
    	var y;
    	var arc;
    	var penWidth;
    	var font;
    	var justification;

    	
    	// Draw hrZones Bar
    	x = width/2;
    	y = height/2;
    	arc = width/2;
    	var minHR = hrZones[0];
    	var hrRange = (hrZones[5] - minHR).toFloat();
    	var hrPenWidth = 8;
    	var hrZonesPenWidth = 5;
    	var degreeStart = 225;
    	for (var i=1; i<=5; i+=1) {
	    	// Set hrZone Variables
	    	var degreeEnd = 225 - (hrZones[i] - minHR) / hrRange * 90;
	    	
	    	// Set hrZone Color
	    	var hrZoneColor = Gfx.COLOR_DK_GRAY;
	    	if (i == 1) { hrZoneColor = Gfx.COLOR_LT_GRAY; }
	    	else if (i == 2) { hrZoneColor = Gfx.COLOR_BLUE; }
	    	else if (i == 3) { hrZoneColor = Gfx.COLOR_GREEN; }
	    	else if (i == 4) { hrZoneColor = 0xF79D0C; } // Orange
	    	else if (i == 5) { hrZoneColor = Gfx.COLOR_RED; }
	    	
	    	penWidth = (i == hrZone) ? hrPenWidth : hrZonesPenWidth;
	    	dc.setPenWidth(penWidth);
	    	dc.setColor(hrZoneColor, Gfx.COLOR_TRANSPARENT);
	    	dc.drawArc(x, y, arc - penWidth/2, Gfx.ARC_CLOCKWISE, degreeStart, degreeEnd);
	    	degreeStart = degreeEnd;
	    }
	    
	    // Draw current [0], average [1] and max [2] HR @ Bar
	    for (var i = 2; i >= 0; i -= 1) {
	    	var hrDotValue = hr;
	    	var hrDotColor = Gfx.COLOR_DK_GRAY;
	    	if (i == 1) {
	    		hrDotValue = avgHr;
	    		hrDotColor = Gfx.COLOR_DK_BLUE;
	    	} else if (i == 2) {
	    		hrDotValue = maxHr;
	    		hrDotColor = Gfx.COLOR_RED;
	    	}
		    
		    // Draw Dot
		    if (hrDotValue >= minHR) {
		    	var dotRadius = ((i == 0) ? hrPenWidth/2 : hrZonesPenWidth/2);
		    	var hrDegree = 135 + (hrDotValue - minHR) / hrRange * 90;
	    		var hrDot = new CircleDegreesToCoordinates(arc - dotRadius, x, y, hrDegree);
				
				dc.setColor(hrDotColor, Gfx.COLOR_TRANSPARENT);
				dc.fillCircle(hrDot.getX(), hrDot.getY(), dotRadius);
				// Draw contrasting circle around Dot
				dc.setPenWidth(1);
				dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
				dc.drawCircle(hrDot.getX(), hrDot.getY(), dotRadius);
			}
		}
	    
	    // Draw HR values
	    font = Gfx.FONT_XTINY;
	    justification = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
	    dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    dc.drawText(45, height / 2 - (FONT_HEIGHT_XTINY/2 - 3), font, (hr != 0) ? hr : "-", justification);
	    dc.drawText(45, height / 2 + (FONT_HEIGHT_XTINY/2 - 3), font, (cadence != 0) ? cadence : "-", justification);
    }
}
