using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.Math;


class MiniDashView extends WatchUi.DataField {
		
	// Set CONSTANTS
	hidden var FONT_HEIGHT_XTINY = Gfx.getFontHeight(Gfx.FONT_XTINY);
	hidden var FONT_HEIGHT_TINY = Gfx.getFontHeight(Gfx.FONT_TINY);
	hidden var FONT_HEIGHT_SMALL = Gfx.getFontHeight(Gfx.FONT_SMALL);
	hidden var FONT_HEIGHT_MEDIUM = Gfx.getFontHeight(Gfx.FONT_MEDIUM);
    
	// Settings
    hidden var climbCat3 = 3;
    hidden var climbCat2 = 6;
    hidden var climbCat1 = 9;
    hidden var climbCatHc = 12;
    hidden var metricDistanceUnits = true;
    hidden var distanceConversion = 0.001f;
    hidden var speedConversion = 3.6f;
    hidden var altitudeConversion = 1;
    hidden var hrZones;
	
	// Left Section Variables
	hidden var elapsedDistance = 0;
	hidden var timerTime;
	hidden var startTime;
	hidden var currentTime;
	
	hidden var distToDest = 0;
	hidden var routeProgress = 0.5f;
	hidden var timeToDest;
	hidden var timeAtDest;
	
	// Center Section Variables
	hidden var hr;
	hidden var hrZone;
	hidden var cadence = 0;
	hidden var blink = true;
	
	// Right Section Variables
	hidden var index = 0;
	hidden var altitude = 0;
	hidden var lastElapsedDistance = 0;
	hidden var altitudeKalmanFilter;
	hidden var distanceKalmanFilter;
	hidden var speed = 0;
	hidden var avgSpeed = 0;
	hidden var maxSpeed = 0;
	hidden var ascent = 0;
	hidden var descent = 0;
	hidden var grade = 0;
	hidden var vam;

    function initialize() {
        DataField.initialize();
        hrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
        
        var errMeasure = Properties.getValue("AltErrMeasure").toFloat();
        var errEstimate = Properties.getValue("AltErrEstimate").toFloat();
        var maxProcessNoise = Properties.getValue("AltMaxProcessNoise").toFloat();
        altitudeKalmanFilter = new SimpleKalmanFilter(errMeasure, errEstimate, maxProcessNoise);
        
        errMeasure = Properties.getValue("DistErrMeasure").toFloat();
        errEstimate = Properties.getValue("DistErrEstimate").toFloat();
        maxProcessNoise = Properties.getValue("DistMaxProcessNoise").toFloat();
        distanceKalmanFilter = new SimpleKalmanFilter(errMeasure, errEstimate, maxProcessNoise);
    }
    
    function onTimerStart() {
    	altitudeKalmanFilter.setInitialState(altitude);
    	distanceKalmanFilter.setInitialState(elapsedDistance - lastElapsedDistance);
    }
    
    function onTimerResume() {
    	altitudeKalmanFilter.setInitialState(altitude);
    	distanceKalmanFilter.setInitialState(elapsedDistance - lastElapsedDistance);
    }
    
    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	
    	getSettings();
        
        var timerState = info.timerState;
    	
    	// Current Values
    	hr = info.currentHeartRate;
    	cadence = (info.currentCadence != null) ? (info.currentCadence) : (0);
    	speed = (info.currentSpeed != null) ? (info.currentSpeed) : (0);
    	currentTime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	altitude = info.altitude;
    	
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
    	    	
    	// Active Timer Values
    	if (timerState == Activity.TIMER_STATE_ON) {
    	    elapsedDistance = (info.elapsedDistance != null) ? (info.elapsedDistance) : (0);
    	    avgSpeed = (info.averageSpeed != null) ? (info.averageSpeed) : (0);
    	    maxSpeed = (info.maxSpeed != null) ? (info.maxSpeed) : (0);
    		ascent = (info.totalAscent != null) ? (info.totalAscent) : (0);
    	    descent = (info.totalDescent != null) ? (info.totalDescent) : (0);
    		timerTime = new Time.Duration(info.timerTime / 1000);
    		if (info.startTime != null) { startTime = Time.Gregorian.info(info.startTime, Time.FORMAT_SHORT); }
    		
    		// Calculate smooth Gradient and VAM, applying Simple Kalman Filter
    		if (elapsedDistance != 0) {
	    		var lastAltitude = altitudeKalmanFilter.getLastEstimate();
	    		var lastDistance = distanceKalmanFilter.getLastEstimate();
	    		var currentAltitude = altitudeKalmanFilter.updateEstimate(altitude);
    			var currentDistance = distanceKalmanFilter.updateEstimate(elapsedDistance - lastElapsedDistance);
				if (currentDistance != 0) { grade = (currentAltitude - lastAltitude) / currentDistance * 100;}
				vam = ((currentAltitude - lastAltitude) * 3600).toNumber();
			}
			lastElapsedDistance = elapsedDistance;
    		
    		// Route Values
    		distToDest = (info.distanceToDestination != null) ? (info.distanceToDestination) : (0);
    		if (distToDest != 0) {
    			routeProgress = elapsedDistance / (elapsedDistance + distToDest);
    			if (avgSpeed != 0) {
    				timeToDest = new Time.Duration(distToDest / avgSpeed);
    				timeAtDest = Time.Gregorian.info(Time.now().add(timeToDest), Time.FORMAT_SHORT);
    			}
    		}
    	}
    }
    
    // Get application Settings and Set Variables accordingly
    function getSettings() {		
		// Set distance/speed and altitude conversion factors
		metricDistanceUnits = (System.getDeviceSettings().distanceUnits == System.UNIT_METRIC) ? true : false;
		System.println(metricDistanceUnits);
	    distanceConversion = metricDistanceUnits ? 0.001 : 1/1609.344;
	    speedConversion = metricDistanceUnits ? 3.6 : (3600/1609.344);
	    var metricElevationUnits = (System.getDeviceSettings().elevationUnits == System.UNIT_METRIC) ? true : false;
	    altitudeConversion = metricElevationUnits ? 1 : 0.3048; 
		
		// Set lower bound percentage of Climb Categories
		climbCat3 = Properties.getValue("ClimbCat3").toFloat();
	    climbCat2 = Properties.getValue("ClimbCat2").toFloat();
	    climbCat1 = Properties.getValue("ClimbCat1").toFloat();
	    climbCatHc = Properties.getValue("ClimbCatHc").toFloat();
	}
    
    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    	// Get Generic Variables
    	var bgColor = getBackgroundColor();
    	var width = dc.getWidth();
    	var height = dc.getHeight();
    	var x;
    	var x2;
    	var y1 = height / 6;
    	var y2 = height / 2;
    	var y3 = height * 5 / 6;
    	var penWidth;
    	var justification;
    	var font;
    	
    	// Display error if data field has less than 200px to display
    	if (width < 200) {
    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    		dc.drawText(width/2, height/2, Gfx.FONT_TINY,
    					"Set wider format", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    		return;
    	}
    	
    ///////////////////////
    // Draw Left Section //
    ///////////////////////
    	
    	var elapsedDistanceStr = (elapsedDistance != 0) ? (elapsedDistance * distanceConversion).format("%.1f") : "-.-";
    	var timerTimeStr = (timerTime != null) ? toHMS(timerTime.value()) : "-:--";
    	var timeToDestStr = (timeToDest != null) ? toHMS(timeToDest.value().toLong()) : "-:--";
    	var timeAtDestStr = (timeAtDest != null) ? Lang.format("$1$:$2$",[timeAtDest.hour.format("%2i"), timeAtDest.min.format("%02i")]) : "-:--";
    	var currentTimeStr = (currentTime != null) ? Lang.format("$1$:$2$", [currentTime.hour.format("%2i"), currentTime.min.format("%02i")]) : "-:--";
    	var startTimeStr = "-:--";
    	if (startTime != null) {
    		startTimeStr = Lang.format("$1$:$2$", [startTime.hour.format("%2i"), startTime.min.format("%02i")]);
    	} else {
    		startTimeStr = currentTimeStr;
    	}
    
    	// Draw Progress Bar
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_DK_GREEN : Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    	if(distToDest != 0) {
    		dc.fillRectangle(0, 0, width * 2/5 * routeProgress, height);
    	}
    	
    	// Draw Left Values
    	x = width/5 -7;
    	font = Gfx.FONT_TINY;
    	justification = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
	    
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    	dc.drawText(x + 2, y1, font, elapsedDistanceStr, justification);
    	dc.drawText(x + 2, y2, font, timerTimeStr, justification);
    	dc.drawText(x + 2, y3, font, startTimeStr, justification);
    	
    	// Draw Right Values
    	x = x + width/5 + 2;
    	justification = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    	if (distToDest != 0) {
    		dc.drawText(x, y1, font, (distToDest * distanceConversion).format("%.1f"), justification);
    		dc.drawText(x, y2, font, timeToDestStr, justification);
    		dc.drawText(x, y3, font, timeAtDestStr, justification);
    	} else {
    		if (startTime != null) {dc.drawText(x, y3, font, currentTimeStr, justification);}
    	}
    	
    	// Draw Units / Bridge Characters
    	x = width / 5;
    	font = Gfx.FONT_XTINY;
    	justification = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    	if (metricDistanceUnits) {
    		dc.drawText(x, y1 - (FONT_HEIGHT_XTINY - 3), font, "k", Gfx.TEXT_JUSTIFY_CENTER);
    		dc.drawText(x, y1 - 3, font, "m", Gfx.TEXT_JUSTIFY_CENTER);
    	} else {
    		dc.drawText(x, y1, font, "m", justification);
    	}
    	if (distToDest != 0) {
    		dc.drawText(x, y2, font, "~", justification);
    	}
    	if (timeAtDest != null or startTime != null) {
    		dc.drawText(x, y3, font, "~", justification);
    	}
    
    /////////////////////////
    // Draw Center Section //
    /////////////////////////
    	
    	// Draw Values
    	x = width * 3/5 - 20;
    	font = Gfx.FONT_TINY;
    	justification = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    	dc.drawText(x, y1, font, (hr != null) ? hr : "-", justification);
    	dc.drawText(x, y2, font, (cadence != 0) ? cadence : "-", justification);
    	var speedStr = (speed != 0) ? (speed * speedConversion).toNumber() : "-";
    	
    	if ((grade == 0 and speed == 0) or grade.abs() >= climbCat3) {
    		dc.drawText(x, y3, font, speedStr, justification);
    	} else {
    		dc.drawText(x, y3, font, grade.format("%.1f"), justification);
    	}
    	
    	// Draw Units
    	x = width * 3/5 - 10;
    	font = Gfx.FONT_XTINY;
    	justification = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    	if ((grade == 0 and speed == 0) or grade.abs() >= climbCat3) {
    		dc.drawText(x, y3 + 1, font, (metricDistanceUnits) ? "kmh" : "mph", justification);
    	} else {
	    	if (grade >= 0) {
	    		dc.fillPolygon([[x - 8, y3 - 1 + FONT_HEIGHT_XTINY/2],
	    						[x + 8, y3 - 1 + FONT_HEIGHT_XTINY/2],
	    						[x + 8, y3 - 1 - FONT_HEIGHT_XTINY/2]]);
	    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	    		dc.drawText(x + 8, y3, font, "%", Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
	    	} else {
	    		dc.fillPolygon([[x - 8, y3 - 1 + FONT_HEIGHT_XTINY/2],
	    						[x + 8, y3 - 1 + FONT_HEIGHT_XTINY/2],
	    						[x - 8, y3 - 1 - FONT_HEIGHT_XTINY/2]]);
	    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	    		dc.drawText(x - 8, y3, font, "%", Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    		}
    	}
    	
	    	// Draw Pedals
	    penWidth = 2;
	    dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
	    if (blink or cadence == 0) {
	    	dc.fillCircle(x, y2, penWidth * 2.5);
	    	dc.setPenWidth(penWidth);
	    	dc.drawLine(x - penWidth * 3, y2 - penWidth * 3, x + penWidth * 3, y2 + penWidth * 3);
    		dc.drawLine(x - penWidth * 4, y2 - penWidth * 2.7, x - penWidth * 2, y2 - penWidth * 3.3);
    		dc.drawLine(x + penWidth * 4, y2 + penWidth * 2.7, x + penWidth * 2, y2 + penWidth * 3.3);
	    }
	    
    		// Set Heart Color
    	var heartColor = (bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY;
    	if (hrZone != null) {
	    	if (hrZone == 0) {
	    		heartColor = Gfx.COLOR_DK_GRAY;
	    	} else if (hrZone == 1) {
	    		heartColor = Gfx.COLOR_LT_GRAY;
	    	} else if (hrZone == 2) {
	    		heartColor = Gfx.COLOR_BLUE;
	    	} else if (hrZone == 3) {
	    		heartColor = Gfx.COLOR_GREEN;
	    	} else if (hrZone == 4) {
	    		heartColor = 0xF79D0C; // Orange
	    	} else {
	    		heartColor = Gfx.COLOR_RED;
	    	}
	    }
	    
	    	// Draw Heart
	    penWidth = 6;
	    var heartY = y1 - 4;
	    if (blink or hrZone == null) {
	    	dc.setPenWidth(penWidth);
	    	dc.setColor(heartColor, Gfx.COLOR_TRANSPARENT);
	    	dc.fillCircle(x - penWidth / 2.1, heartY, penWidth / 2);
	    	dc.fillCircle(x + penWidth / 2.1, heartY, penWidth / 2);
	    	dc.fillPolygon([[x - 0.96 * penWidth, heartY + penWidth / 6],
	    					[x, heartY],
	    					[x + 0.96 * penWidth, heartY + penWidth / 6],
	    					[x, heartY + penWidth * 1.5]]);
	    }
	    
	    blink = blink ? false : true;
	    
	////////////////////////
	// Draw Right Section //
	////////////////////////
	    
	    // If Gradient is less than a Cat 3 Climb, draw Speedometer, otherwise, draw Gradient visuals
	    if (grade.abs() < climbCat3) {
	    
	    //////////////////////
	    // Draw Speedometer //
	    //////////////////////

	    	x = width * 4/5;
	    	var speedDegree = 0;
	    	var avgSpeedDegree = 0;
	    	var arc = width / 5 - 10;
	    	var h;
	    	var v;
	    	if (maxSpeed != 0) {
	    		if (speed != 0) {speedDegree = 180 - speed / maxSpeed * 180;}
	    		if (avgSpeed != 0) {
	    			avgSpeedDegree = 180 - avgSpeed / maxSpeed * 180;
		    		// Given a radius length r and an angle t in radians and a circle's center (h,v),
		    		// you can calculate the coordinates of a point on the circumference as follows
		    		// h = r*cos(t) + x
		    		// v = r*sin(t) + y
		    		// radians = degrees * PI/180
	    			var t = (avgSpeed / maxSpeed * 180 - 180) * Math.PI/180;
	    			h = (arc * Math.cos(t) + x).toNumber();
	    			v = (arc * Math.sin(t) + height).toNumber();
	    		}
	    	}
	    	
	    	
	    	// Draw Speedometer
	    	dc.setPenWidth(arc);
	    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	    	dc.drawArc(x, height, arc / 2, Gfx.ARC_CLOCKWISE, 180, 0);
	    	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
	    	dc.drawArc(x, height, arc / 2, Gfx.ARC_CLOCKWISE, 180, speedDegree);
	    	
	    	dc.setPenWidth(2);
	    	// Draw line around Speedometer until Maximum Speed
	    	dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
	    	dc.drawArc(x, height, arc, Gfx.ARC_CLOCKWISE, 180, 0);
	    	// Draw line around Speedometer until Average Speed
	    	dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
	    	dc.drawArc(x, height, arc, Gfx.ARC_CLOCKWISE, 180, avgSpeedDegree);
	    	// Draw Average Speed marker on the Arc of the Speedometer
	    	dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
	    	if (h != null and v != null) {dc.fillCircle(h, v, 3);}
	    	
	    	// Draw values
	    	// Draw Current Speed value
	    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	speedStr = (speed != 0) ? (speed * speedConversion).format("%.1f") : "-";
	    	dc.drawText(x, height - FONT_HEIGHT_MEDIUM,
	    				Gfx.FONT_MEDIUM, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
	    	// Draw Average Speed value
	    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(width * 3/5 + 2, 0, Gfx.FONT_SMALL, (avgSpeed * speedConversion).format("%.1f"), Gfx.TEXT_JUSTIFY_LEFT);
	    	// Draw Max Speed value
	    	dc.drawText(width - 2, 0, Gfx.FONT_SMALL, (maxSpeed * speedConversion).format("%.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
	    	// Draw Average Speed label
	    	dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(width * 3/5 + 2, FONT_HEIGHT_SMALL - 3, Gfx.FONT_XTINY, "avg", Gfx.TEXT_JUSTIFY_LEFT);
	    	// Draw Max Speed label
	    	dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(width - 2, FONT_HEIGHT_SMALL - 3, Gfx.FONT_XTINY, "max", Gfx.TEXT_JUSTIFY_RIGHT);
	    	// Draw Speed unit
	    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(x + 1, 0, Gfx.FONT_XTINY, (metricDistanceUnits) ? "km/h" : "mph", Gfx.TEXT_JUSTIFY_CENTER);
	    } else {
	    
	    	///////////////////////////////////////////
	    	// Draw Ascent & Descent Bars and Values //
	    	///////////////////////////////////////////
	    	
	    	// Get Variables for Ascent/Descent
	    	x = width * 3/5;
	    	font = Gfx.FONT_TINY;
	    	var ascDescHeight = FONT_HEIGHT_TINY;
	    	var ascDescY = height - ascDescHeight;
	    	var ascDescSplit = width / 5;
	    	var ascentStr = (ascent / altitudeConversion).format("%i");
	    	var descentStr = "-" + (descent / altitudeConversion).format("%i");
	    	if (ascent != 0 and descent != 0) {
	    		ascDescSplit = (ascent / (ascent + descent) * width * 2/5);
	    	}
	    	// Draw Ascent Bar
	    	dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_DK_BLUE);
	    	dc.fillRectangle(x, ascDescY, ascDescSplit, ascDescHeight);
	    	// Draw Descent Bar
	    	dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_BLUE);
	    	dc.fillRectangle(x + ascDescSplit, ascDescY, width * 2/5 - ascDescSplit + 5, ascDescHeight);
	    	// Draw Ascent value
	    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(x + 3, ascDescY, font, ascentStr, Gfx.TEXT_JUSTIFY_LEFT);
	    	// Draw Separator / Units Symbol
	    	dc.fillPolygon([[width * 4/5, ascDescY + ascDescHeight / 4],
	    					[width * 4/5 - 4, ascDescY + ascDescHeight * 3/4],
	    					[width * 4/5 + 4, ascDescY + ascDescHeight * 3/4]]);
	    	// Draw Descent value
	    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(width - 2, ascDescY, font, descentStr, Gfx.TEXT_JUSTIFY_RIGHT);
	    	
	    	///////////////////////////////////////
	    	// Draw Gradient Triangle and Values //
	    	///////////////////////////////////////
	    	
	    	// Get Variables for Gradient Field
	    	var gradeStr = grade.format("%+.1f");
	    	var gradeHeight = height - ascDescHeight;
	    	
	    	// Set Triangle Color
	    	var gradeColor = Gfx.COLOR_TRANSPARENT;
	    	if (grade < climbCat3 and grade >= -climbCat3) {
	    		gradeColor = Gfx.COLOR_GREEN;
	    	} else if ((grade >= climbCat3 and grade < climbCat2) or (grade > -climbCat2 and grade <= -climbCat3)) {
	    		gradeColor = 0xF6E700; // Yellow
	    	} else if ((grade >= climbCat2 and grade < climbCat1) or (grade > -climbCat1 and grade <= -climbCat2)) {
	    		gradeColor = 0xEFA606; // Orange
	    	} else if ((grade >= climbCat1 and grade < climbCatHc) or (grade > -climbCatHc and grade <= -climbCat1)) {
	    		gradeColor = 0xC80317; // Red
	    	} else if (grade >= climbCatHc or grade <= -climbCatHc) {
	    		gradeColor = 0x4D0600; // Dark Red
	    	}
	    	
	    	// Draw Triangle
	    	dc.setColor(gradeColor, gradeColor);
	    	var gradeAngle = (grade.abs() / (climbCatHc + 3) * gradeHeight).toNumber();
	    	var triangleY = [0, gradeHeight - gradeAngle];
	    	dc.fillPolygon([[x,gradeHeight],[width,gradeHeight],[(grade >= 0) ? width : x, gradeHeight - gradeAngle]]);
	    	// Draw Value
	    	if (grade >= climbCat3) {
	    	// When Gradient >= Cat3 climb, draw VAM
	    	    dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	    dc.drawText(x + 3, 2, Gfx.FONT_SMALL, (vam != null) ? vam : "-", Gfx.TEXT_JUSTIFY_LEFT);
	    	    // When Gradient >= Cat1 climb, change drawing color (for Gradient)
	    	    // to WHITE to remain visible in RED or DK_RED area
	    	    if (grade >= climbCat1) {dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);}
				// Draw Gradient in the bottom of the triangle
	    		dc.drawText(width - 2, gradeHeight - FONT_HEIGHT_SMALL, Gfx.FONT_SMALL, gradeStr + "%", Gfx.TEXT_JUSTIFY_RIGHT);
	    		// Draw VAM unit
	    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
	    		dc.drawText(x + 3, FONT_HEIGHT_SMALL - 3, Gfx.FONT_XTINY, "vam", Gfx.TEXT_JUSTIFY_LEFT);
	    	} else if (grade <= -climbCat3) {
	    	// When Gradient <= Cat3 descent, draw Speed
	    	    dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	    dc.drawText(width - 2, 2, Gfx.FONT_SMALL, speedStr, Gfx.TEXT_JUSTIFY_RIGHT);
	    	    // When Gradient <= Cat1 descent, change drawing color (for Gradient)
	    	    // to WHITE to remain visible in RED or DK_RED area
	    	    if (grade <= -climbCat1) {dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);}
	    		// Draw Gradient in the bottom of the triangle
	    		dc.drawText(x + 3, gradeHeight - FONT_HEIGHT_SMALL, Gfx.FONT_SMALL, gradeStr + "%", Gfx.TEXT_JUSTIFY_LEFT);
	    		// Draw Speed unit
	    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
	    		dc.drawText(width - 2, FONT_HEIGHT_SMALL - 3, Gfx.FONT_XTINY, (metricDistanceUnits) ? "km/h" : "mph", Gfx.TEXT_JUSTIFY_RIGHT);
	    	} else {
	    		// Draw Gradient in the top middle
	    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	    dc.drawText(width * 4/5, 2, Gfx.FONT_SMALL, gradeStr + "%", Gfx.TEXT_JUSTIFY_CENTER);
	    	}
	    }
    
    /////////////////////
    // Draw Separators //
    /////////////////////
    	
    	dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
	    dc.setPenWidth(1);
	    dc.drawLine(width * 2/5 - 3, 0, width * 2/5 - 3, height);
	    dc.drawLine(width * 3/5, 0, width * 3/5, height);
    }
    
    // Translate a value in seconds to "H:MM" or "M:SS" format
    function toHMS(secs) {
    	var hr = secs / 3600;
    	var min = (secs - (hr * 3600)) / 60;
    	var sec = secs % 60;
    	return (hr >= 1) ? 
    		(hr.format("%1i") + ":" + min.format("%02i")) : 
    		(min.format("%1i") + ":" + sec.format("%02i"));
    }
}