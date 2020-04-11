using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Math;


class MiniDashView extends WatchUi.DataField {
		
	// CONSTANTS
	hidden var SECONDS_OF_HISTORY = 5;
    hidden var CLIMB_CAT_3 = 3;
    hidden var CLIMB_CAT_2 = 6;
    hidden var CLIMB_CAT_1 = 9;
    hidden var CLIMB_CAT_Hc = 12;
    hidden var metricDistanceUnits = true;
    hidden var speedConversion = 3.6f;
    hidden var mFeetConversion = 1;
	
	// Left Section Variables
	hidden var elapsedDistanceStr = "-.-";
	hidden var timerTimeStr = "-:--";
	hidden var startTimeStr = "-:--";
	
	hidden var distToDest = 0;
	hidden var routeProgress = 0.5f;
	hidden var distToDestStr = "-.-";
	hidden var timeToDestStr = "-:--";
	hidden var timeAtDestStr = "-:--";
	hidden var currentTimeStr = "-:--";
	
	// Center Section Variables
	hidden var hr;
	hidden var hrZone;
	hidden var heartBeat = true;
	hidden var cadence;
	hidden var pedaling = true;
	
	// Right Section Variables
	hidden var index = 0;
	hidden var altitudes = new[SECONDS_OF_HISTORY];
	hidden var elapsedDistances = new[SECONDS_OF_HISTORY];
	hidden var speed;
	hidden var avgSpeed;
	hidden var avgSpeedStr = "-";
	hidden var maxSpeed;
	hidden var ascent;
	hidden var descent;
	hidden var grade = 0;
	hidden var vam;

    function initialize() {
        DataField.initialize();

        SECONDS_OF_HISTORY = (Properties.getValue("SecsHistory") == null) ? 5 : Properties.getValue("SecsHistory");
    }
    
    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	
    	// Get Settings
    	metricDistanceUnits = (System.getDeviceSettings().distanceUnits == System.UNIT_METRIC) ? true : false;
        speedConversion = metricDistanceUnits ? 3.6 : (3600/1609.344);
        var metricElevationUnits = (System.getDeviceSettings().elevationUnits == System.UNIT_METRIC) ? true : false;
        mFeetConversion = metricElevationUnits ? 1 : 0.3048; 
    	CLIMB_CAT_3 = (Properties.getValue("ClimbCat3") == null) ? 3 : Properties.getValue("ClimbCat3");
        CLIMB_CAT_2 = (Properties.getValue("ClimbCat2") == null) ? 6 : Properties.getValue("ClimbCat2");
        CLIMB_CAT_1 = (Properties.getValue("ClimbCat1") == null) ? 9 : Properties.getValue("ClimbCat1");
        CLIMB_CAT_Hc = (Properties.getValue("ClimbCatHc") == null) ? 12 : Properties.getValue("ClimbCatHc");
        
        var timerState = info.timerState;
    	
    	// Current Values
    	hr = info.currentHeartRate;
    	cadence = info.currentCadence;
    	speed = (info.currentSpeed != null) ? (info.currentSpeed * speedConversion) : (null);
    	var currentTime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	currentTimeStr = Lang.format("$1$:$02$",
    						[currentTime.hour.format("%02i"), currentTime.min.format("%02i")]);
    	
    	// Calculate HR Zone
    	var hrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
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
    	
    	// Store (historical) values for calculation
        altitudes[index] = info.altitude;
        elapsedDistances[index] = info.elapsedDistance;
        var nextIndex = (index + 1) % altitudes.size();
    	
    	// Active Timer Values
    	if (timerState > Activity.TIMER_STATE_OFF) {
    		ascent = info.totalAscent;
    	    descent = info.totalDescent;
    	    maxSpeed = (info.maxSpeed != null) ? (info.maxSpeed * speedConversion) : (null);
    	    var elapsedDistance = 0;
    		if (info.elapsedDistance != null) {
    			elapsedDistance = info.elapsedDistance;
    			elapsedDistanceStr = (elapsedDistance / 1000).format("%.1f");
    		}
    		var timerTime = new Time.Duration(info.timerTime / 1000);
    		timerTimeStr = toHMS(timerTime.value());
    		if (info.startTime != null) {
	    		var startTime = Time.Gregorian.info(info.startTime, Time.FORMAT_SHORT);
	    		startTimeStr = Lang.format("$1$:$2$",
	    						[startTime.hour.format("%02i"), startTime.min.format("%02i")]);
	    	}
    		if (info.averageSpeed != null) {
    			avgSpeed = info.averageSpeed;
    			avgSpeedStr = (avgSpeed * speedConversion).format("%.1f");
    		}
    		
    		var historyReady = (altitudes[index] != null and
    							altitudes[nextIndex] != null and
        						elapsedDistances[index] != null and 
        						elapsedDistances[nextIndex] != null and
        						elapsedDistances[index] != 0 and
        						elapsedDistances[index] != elapsedDistances[nextIndex]);
        	if (historyReady){
        		grade = (altitudes[index] - altitudes[nextIndex]) / (elapsedDistances[index] - elapsedDistances[nextIndex]) * 100;
	        	vam = ((altitudes[index] - altitudes[nextIndex]) * 3600 / SECONDS_OF_HISTORY).toNumber();
	        }
    		
    		// Route Values
    		distToDest = info.distanceToDestination;
    		if (distToDest != null and distToDest != 0) {
    			routeProgress = elapsedDistance / (elapsedDistance + distToDest);
    			distToDestStr = (distToDest / 1000).format("%.1f");
    			if (avgSpeed != null and avgSpeed != 0) {
    				var timeToDest = new Time.Duration(distToDest / avgSpeed);
    				timeToDestStr = toHMS(timeToDest.value().toLong());
    				var timeAtDest = Time.Gregorian.info(Time.now().add(timeToDest), Time.FORMAT_SHORT);
    				timeAtDestStr = Lang.format("$1$:$02$",
    								[timeAtDest.hour.format("%02i"), timeAtDest.min.format("%02i")]);
    			}
    		}
    	}
    	index = nextIndex;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    	// Set CONSTANTS
    	var FONT_HEIGHT_XTINY = Gfx.getFontHeight(Gfx.FONT_XTINY);
    	var FONT_HEIGHT_TINY = Gfx.getFontHeight(Gfx.FONT_TINY);
    	var FONT_HEIGHT_SMALL = Gfx.getFontHeight(Gfx.FONT_SMALL);
    	var FONT_HEIGHT_MEDIUM = Gfx.getFontHeight(Gfx.FONT_MEDIUM);
    	
    	// Get Generic Variables
    	var bgColor = getBackgroundColor();
    	var width = dc.getWidth();
    	var height = dc.getHeight();
    	var x;
    	var y1 = height / 6;
    	var y2 = height / 2;
    	var y3 = height * 5 / 6;
    	var penWidth;
    	var justification;
    	var font;
    	
    	// Display error if data field has less than 240px to display
    	if (width < 200) {
    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    		dc.drawText(width/2, height/2, Gfx.FONT_TINY,
    					"Set wider format", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    		return;
    	}
    
    /////////////////////
    // Draw Separators //
    /////////////////////
    	
    	dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
	    dc.setPenWidth(1);
	    dc.drawLine(width * 2/5 - 3, 0, width * 2/5 - 3, height);
	    dc.drawLine(width * 3/5, 0, width * 3/5, height);
    	
    ///////////////////////
    // Draw Left Section //
    ///////////////////////
    
    	// Draw Progress Bar
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_DK_GREEN : Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    	if(distToDest != null and distToDest != 0) {
    		dc.fillRectangle(0, 0, width * 2/5 * routeProgress, height);
    	}
    	
    	// Draw Left Values
    	x = width / 5 -7;
    	font = Gfx.FONT_TINY;
    	justification = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    	
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    	dc.drawText(x + 2, y1, font, elapsedDistanceStr, justification);
    	dc.drawText(x + 2, y2, font, timerTimeStr, justification);
    	dc.drawText(x + 2, y3, font, startTimeStr, justification);
    	
    	// Draw Right Values
    	x = width / 5 + 6;
    	justification = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
    	if (distToDest != null and distToDest != 0) {
    		dc.drawText(x - 2, y1, font, distToDestStr, justification);
    		dc.drawText(x - 2, y2, font, timeToDestStr, justification);
    		dc.drawText(x - 2, y3, font, timeAtDestStr, justification);
    	} else {
    		dc.drawText(x - 2, y3, font, currentTimeStr, justification);
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
    	if (distToDest != null and distToDest != 0) {
    		dc.drawText(x, y2, font, "~", justification);
    	}
    	if (!startTimeStr.equals("-:--")) {
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
    	dc.drawText(x, y2, font, (cadence != null) ? cadence : "-", justification);
    	var speedStr;
    	if (speed != null and speed != 0) {
    		speedStr = speed.toNumber();
    	} else {
    		speedStr = "-";
    	} 
    	
    	if ((grade == 0 and speed == 0) or grade.abs() >= CLIMB_CAT_3) {
    		dc.drawText(x, y3, font, speedStr, justification);
    	} else {
    		dc.drawText(x, y3, font, grade.format("%.1f"), justification);
    	}
    	
    	// Draw Units
    	x = width * 3/5 - 10;
    	font = Gfx.FONT_XTINY;
    	justification = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    	if ((grade == 0 and speed == 0) or grade.abs() >= CLIMB_CAT_3) {
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
	    if (pedaling or cadence == null) {
	    	dc.fillCircle(x, y2, penWidth * 2.5);
	    	dc.setPenWidth(penWidth);
	    	dc.drawLine(x - penWidth * 3, y2 - penWidth * 3, x + penWidth * 3, y2 + penWidth * 3);
    		dc.drawLine(x - penWidth * 4, y2 - penWidth * 2.7, x - penWidth * 2, y2 - penWidth * 3.3);
    		dc.drawLine(x + penWidth * 4, y2 + penWidth * 2.7, x + penWidth * 2, y2 + penWidth * 3.3);
	    }
	    pedaling = pedaling ? false : true;
	    
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
	    if (heartBeat or hrZone == null) {
	    	dc.setPenWidth(penWidth);
	    	dc.setColor(heartColor, Gfx.COLOR_TRANSPARENT);
	    	dc.fillCircle(x - penWidth / 2.1, heartY, penWidth / 2);
	    	dc.fillCircle(x + penWidth / 2.1, heartY, penWidth / 2);
	    	dc.fillPolygon([[x - 0.96 * penWidth, heartY + penWidth / 6],
	    					[x, heartY],
	    					[x + 0.96 * penWidth, heartY + penWidth / 6],
	    					[x, heartY + penWidth * 1.5]]);
	    }
	    heartBeat = heartBeat ? false : true;
	    
	////////////////////////
	// Draw Right Section //
	////////////////////////
	    
	    // If Gradient is less than a Cat 3 Climb, draw Speedometer, otherwise, draw Gradient visuals
	    if (grade.abs() < CLIMB_CAT_3) {
	    
	    //////////////////////
	    // Draw Speedometer //
	    //////////////////////

	    	x = width * 4/5;
	    	var speedDegree = 0;
	    	var avgSpeedDegree = 0;
	    	var arc = width / 5 - 10;
	    	var h;
	    	var v;
	    	if (maxSpeed != null and maxSpeed != 0) {
	    		if (speed != null) {speedDegree = 180 - speed / maxSpeed * 180;}
	    		if (avgSpeed != null) {
	    			avgSpeedDegree = 180 - (avgSpeed * speedConversion) / maxSpeed * 180;
	    			var t = ((avgSpeed * speedConversion) / maxSpeed * 180 - 180) * Math.PI/180;
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
	    		// Given a radius length r and an angle t in radians and a circle's center (h,v),
	    		// you can calculate the coordinates of a point on the circumference as follows
	    		// h = r*cos(t) + x
	    		// v = r*sin(t) + y
	    		// radians = degrees * PI/180
	    	dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
	    	if (h != null and v != null) {dc.fillCircle(h, v, 3);}
	    	
	    	// Draw values
	    	// Draw Current Speed value
	    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	if (speed != null and speed != 0) {
    			speedStr = speed.format("%.1f");
    		} else {
    			speedStr = "-";
    		}
	    	dc.drawText(x, height - FONT_HEIGHT_MEDIUM,
	    				Gfx.FONT_MEDIUM, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
	    	// Draw Average Speed value
	    	dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	dc.drawText(width * 3/5 + 2, 0, Gfx.FONT_SMALL, avgSpeedStr, Gfx.TEXT_JUSTIFY_LEFT);
	    	// Draw Max Speed value
	    	dc.drawText(width - 2, 0, Gfx.FONT_SMALL, (maxSpeed != null) ? maxSpeed.format("%.1f") : "-", Gfx.TEXT_JUSTIFY_RIGHT);
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
	    	var ascentStr = "0";
	    	var descentStr = "-0";
	    	if (ascent != 0 and descent != 0 and ascent != null and descent != null) {
	    		ascDescSplit = (ascent / (ascent + descent) * width * 2/5).toNumber();
	    	}
	    	if (ascent != null and ascent !=0) {ascentStr = (ascent / mFeetConversion).format("%i");}
	    	if (descent != null and descent != 0) {descentStr = "-" + (descent / mFeetConversion).format("%i");}
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
	    	if (grade < CLIMB_CAT_3 and grade >= -CLIMB_CAT_3) {
	    		gradeColor = Gfx.COLOR_GREEN;
	    	} else if ((grade >= CLIMB_CAT_3 and grade < CLIMB_CAT_2) or (grade > -CLIMB_CAT_2 and grade <= -CLIMB_CAT_3)) {
	    		gradeColor = 0xF6E700; // Yellow
	    	} else if ((grade >= CLIMB_CAT_2 and grade < CLIMB_CAT_1) or (grade > -CLIMB_CAT_1 and grade <= -CLIMB_CAT_2)) {
	    		gradeColor = 0xEFA606; // Orange
	    	} else if ((grade >= CLIMB_CAT_1 and grade < CLIMB_CAT_Hc) or (grade > -CLIMB_CAT_Hc and grade <= -CLIMB_CAT_1)) {
	    		gradeColor = 0xC80317; // Red
	    	} else if (grade >= CLIMB_CAT_Hc or grade <= -CLIMB_CAT_Hc) {
	    		gradeColor = 0x4D0600; // Dark Red
	    	}
	    	
	    	// Draw Triangle
	    	dc.setColor(gradeColor, gradeColor);
	    	var gradeAngle = (grade.abs() / (CLIMB_CAT_Hc + 3) * gradeHeight).toNumber();
	    	var triangleY = [0, gradeHeight - gradeAngle];
	    	dc.fillPolygon([[x + 1,gradeHeight],[width,gradeHeight],[(grade >= 0) ? width : x + 1, gradeHeight - gradeAngle]]);
	    	// Draw Value
	    	if (grade >= CLIMB_CAT_3) {
	    	// When Gradient >= Cat3 climb, draw VAM
	    	    dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	    dc.drawText(x + 3, 2, Gfx.FONT_SMALL, vam, Gfx.TEXT_JUSTIFY_LEFT);
	    	    // When Gradient >= Cat1 climb, change drawing color (for Gradient)
	    	    // to WHITE to remain visible in RED or DK_RED area
	    	    if (grade >= CLIMB_CAT_1) {dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);}
				// Draw Gradient in the bottom of the triangle
	    		dc.drawText(width - 2, gradeHeight - FONT_HEIGHT_SMALL, Gfx.FONT_SMALL, gradeStr + "%", Gfx.TEXT_JUSTIFY_RIGHT);
	    		// Draw VAM unit
	    		dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
	    		dc.drawText(x + 3, FONT_HEIGHT_SMALL - 3, Gfx.FONT_XTINY, "vam", Gfx.TEXT_JUSTIFY_LEFT);
	    	} else if (grade <= -CLIMB_CAT_3) {
	    	// When Gradient <= Cat3 descent, draw Speed
	    	    dc.setColor((bgColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	    	    dc.drawText(width - 2, 2, Gfx.FONT_SMALL, speedStr, Gfx.TEXT_JUSTIFY_RIGHT);
	    	    // When Gradient <= Cat1 descent, change drawing color (for Gradient)
	    	    // to WHITE to remain visible in RED or DK_RED area
	    	    if (grade <= -CLIMB_CAT_1) {dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);}
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
    }
    
    function toHMS(secs) {
    // Translate a value in seconds to "H:MM" or "M:SS" format
    	var hr = secs / 3600;
    	var min = (secs - (hr * 3600)) / 60;
    	var sec = secs % 60;
    	return (hr >= 1) ? 
    		(hr.format("%1d") + ":" + min.format("%02d")) : 
    		(min.format("%1d") + ":" + sec.format("%02d"));
    }
}