/**********************************************************************
Title: GoogleMapSupportFunctions.js
Author: John Brodrick & Fred Rossmark
Created: 5/19/2016
Description: Contains various geometric objects and functions 
    supporting points, line segments, lines and polygons.  Also 
    encapsulates helper code for manipulating a google map.
Dependencies: 
    - Base google maps js api - https://maps.google.com/maps/api/js
    - Google Maps Geometry supplemental js library.  See - https://developers.google.com/maps/documentation/javascript/libraries
    - Jquery
**********************************************************************/

/////////////////// Namespaces ///////////////////////////////////////////////////
var enterprise = enterprise || {}; // root namespace obj

enterprise.createNamespace = function (namespace) 
{
    var nsparts = namespace.split(".");
    var parent = enterprise;
 
    if (nsparts[0] === "enterprise") 
        nsparts = nsparts.slice(1);
 
    for (var i = 0; i < nsparts.length; i++) 
    {
        var partname = nsparts[i];

        if (typeof parent[partname] === "undefined")
            parent[partname] = {};

        parent = parent[partname];
    }
    
    return parent;
};

enterprise.createNamespace("enterprise.googlemapsupportfunctions.misc");
enterprise.createNamespace("enterprise.googlemapsupportfunctions.cartesianmath");
enterprise.createNamespace("enterprise.googlemapsupportfunctions.mapping");
enterprise.createNamespace("enterprise.googlemapsupportfunctions.mapping.shapes");

/////////////////// MISC ///////////////////////////////////////////////////////////////////////////////////
// if trying to log in ie - fail gracefully
if (typeof console === "undefined" || typeof console.log === "undefined") {
    console = {};
    console.log = function(msg) {};
}

enterprise.googlemapsupportfunctions.misc.extend = function(Child, Parent)
{
	Child.prototype = enterprise.googlemapsupportfunctions.misc.inherit(Parent.prototype);
	Child.prototype.constructor = Child;
	Child.parent = Parent.prototype;
}

enterprise.googlemapsupportfunctions.misc.inherit = function(proto)
{
	function F() {}
	F.prototype = proto;
	return new F();
}

enterprise.googlemapsupportfunctions.misc.include = function(srcURL)
{
    var imported = document.createElement("script");
    imported.src = srcURL;
    document.getElementsByTagName("head")[0].appendChild(imported);
}

/////////////////// Cartesian Math Namespace ///////////////////////////////////////////////////

/////////////////// Point Object ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.cartesianmath.Point = function(xCoordinate, yCoordinate)
{
    // Public Members
    this.x = xCoordinate;
    this.y = yCoordinate;
};

// Point Public Methods
enterprise.googlemapsupportfunctions.cartesianmath.Point.prototype.toString = function()
{
    return "(" + this.x + ", " + this.y + ")";
};

enterprise.googlemapsupportfunctions.cartesianmath.Point.prototype.deepCompare = function(otherPoint)
{
    return this.x === otherPoint.x && this.y === otherPoint.y;
};

enterprise.googlemapsupportfunctions.cartesianmath.Point.prototype.createGoogleLatLng = function()
{
    return new google.maps.LatLng(this.y, this.x);
};

/////////////////// LineSegment Object ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.cartesianmath.LineSegment = function(pointOne, pointTwo)
{
    // Private Members
    var slope = null, yIntercept = null, xIntercept = null;
    
    if((pointOne.x - pointTwo.x) != 0)
    {
        slope = (pointOne.y - pointTwo.y)/(pointOne.x - pointTwo.x);
        yIntercept = pointOne.y - slope * pointOne.x;
        
        if(slope!=0)
            xIntercept = (pointOne.y - yIntercept)/slope;
    }
    else
        xIntercept = pointOne.x;
    
    // Public Members
    this.point1 = pointOne;
    this.point2 = pointTwo;  
    this.midpoint = new enterprise.googlemapsupportfunctions.cartesianmath.Point((pointOne.x + pointTwo.x)/2,(pointOne.y + pointTwo.y)/2);
    this.line = new enterprise.googlemapsupportfunctions.cartesianmath.Line(slope,yIntercept,xIntercept);
};

// LineSegment Public Methods
enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.getIntWithAnotherLineSeg = function(otherLineSeg)
{
    var intPoint = this.line.getIntWithAnotherLine(otherLineSeg.line);
    
    if(intPoint != null && (!this.isPointOnSegment(intPoint) || !otherLineSeg.isPointOnSegment(intPoint)))
        intPoint = null;
    
    return intPoint;
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.isPointOnSegment = function(point)
{
    var bRet = false;
    
    if(this.line.isPointOnLine(point) && 
        point.x >= this.minX() && point.x <= this.maxX() && 
        point.y >= this.minY() && point.y <= this.maxY())
        bRet = true;
    
    return bRet;
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.minX = function()
{
    if(this.point1.x < this.point2.x)
        return this.point1.x;
    else
        return this.point2.x;
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.maxX = function()
{
    if(this.point1.x > this.point2.x)
        return this.point1.x;
    else
        return this.point2.x;
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.minY = function()
{        
    if(this.point1.y < this.point2.y)
        return this.point1.y;
    else
        return this.point2.y;
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.maxY = function()
{       
    if(this.point1.y > this.point2.y)
        return this.point1.y;
    else
        return this.point2.y;        
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.toString = function()
{
    return "Point 1: " + this.point1.toString() + ", Point 2: " + 
        this.point2.toString() + ", Line Eq: " + this.line.toString() + 
        ", MinX: " + this.minX() + ", MaxX: " + this.maxX() + ", MinY: " + 
        this.minY() + ", MaxY: " + this.maxY();
};

enterprise.googlemapsupportfunctions.cartesianmath.LineSegment.prototype.deepCompare = function(otherLineSegment)
{
    return this.point1.deepCompare(otherLineSegment.point1) &&
        this.point2.deepCompare(otherLineSegment.point2) && 
        this.line.deepCompare(otherLineSegment.line);
};

/////////////////// Line Object ////////////////////////////////////////////////////////
// Represents a mathematical line (extends to infinity)
enterprise.googlemapsupportfunctions.cartesianmath.Line = function(slope, yIntercept, xIntercept)
{
    // Public Members
    this.slope = slope;
    this.yIntercept = yIntercept;
    this.xIntercept = xIntercept;
    this.isVertical = (slope==null && yIntercept==null);
};

// Line Public Methods
enterprise.googlemapsupportfunctions.cartesianmath.Line.prototype.getIntWithAnotherLine = function(otherLine)
{
    var intersection = null;
    
    // if lines are not parallel we can find the intersection
    if(this.slope!==otherLine.slope)
    {
        var x,y;
        
        if(this.isVertical)
        {
            x = this.xIntercept;
            y = otherLine.slope*x + otherLine.yIntercept;
        }
        else
        {
            if(otherLine.isVertical)
                x = otherLine.xIntercept;
            else
                x = (otherLine.yIntercept - this.yIntercept)/(this.slope - otherLine.slope);
            
            y = this.slope*x + this.yIntercept;
        }
        
        intersection = new enterprise.googlemapsupportfunctions.cartesianmath.Point(x,y);
    }
    
    return intersection;
};

enterprise.googlemapsupportfunctions.cartesianmath.Line.prototype.isPointOnLine = function(point)
{
    return (this.isVertical? point.x == this.xIntercept : point.y == this.slope*point.x + this.yIntercept);
};

enterprise.googlemapsupportfunctions.cartesianmath.Line.prototype.toString = function()
{
    var strRet;
    
    if(this.isVertical)
        strRet = "x = " + this.xIntercept;
    else
        strRet = "y = " + (this.slope==0? "" + this.yIntercept : this.slope + "x " + (this.yIntercept<0? "- " + -1*this.yIntercept: "+ " + this.yIntercept));
    
    return strRet;
};

enterprise.googlemapsupportfunctions.cartesianmath.Line.prototype.deepCompare = function(otherLine)
{
    return this.slope === otherLine.slope && 
        this.yIntercept === otherLine.yIntercept && 
        this.xIntercept === otherLine.xIntercept && 
        this.isVertical === otherLine.isVertical;
};

/////////////////// Shapes Namespace ///////////////////////////////////////////////////

/////////////////// Shape Enums ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.shapes.MarkerIconEnum = 
{
	RED : 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|ff0000',
	GREEN : 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|00ff00',
	BLUE : 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|0000ff',
	YELLOW : 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|ffff00',
    ORANGE: 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|ff9933',
    PURPLE: 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|cc33ff',
    WHITE: 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|FFFFFF',
    LIGHT_GRAY: 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|cccccc',
    DARK_GRAY: 'https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|595959'
};

enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes = 
{
	BOUNDARY_CREATION_ERROR : 'BOUNDARY_CREATION_ERROR'
};

/////////////////// Shape Exceptions ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.shapes.BoundaryCreationError = function(errMsgInit)
{
    this.type = enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR;
    this.errMsg = errMsgInit;
}

/////////////////// Boundary Object ////////////////////////////////////////////////////////
// Helper object to represent custom boundary regions drawn around all MapShapes
enterprise.googlemapsupportfunctions.mapping.shapes.Boundary = function(visibleInit, boundarySizeInMetersInit)
{
    this.visible = visibleInit;
    this.boundarySizeInMeters = boundarySizeInMetersInit;
    this.shapes = [];
};

enterprise.googlemapsupportfunctions.mapping.shapes.Boundary.prototype.hide = function()
{
    this.visible = false;
    for(var i=0; i<this.shapes.length;i++)
        this.shapes[i].setMap(null);    
};

enterprise.googlemapsupportfunctions.mapping.shapes.Boundary.prototype.show = function(googleMap)
{
    this.visible = true;
    for(var i=0; i<this.shapes.length;i++)
        this.shapes[i].setMap(googleMap);
};

enterprise.googlemapsupportfunctions.mapping.shapes.Boundary.prototype.addCircle = function(centerPoint, radius, map, relatedShape)
{
    var circ = new google.maps.Circle({
            center: centerPoint,
            radius: radius,
            strokeColor: "#cc33ff",
            strokeOpacity: 0,
            strokeWeight: 0,
            fillColor: "#cc33ff",
            fillOpacity: 0.15,
            map: map,
            zIndex: 0
        });
        
    circ.addListener('click', 
        function()
        {
			try
			{
				relatedShape.toggleBoundary(relatedShape.googleMapHelper.boundarySizeInMeters);
			}
			catch(e)
			{
				if(e.type === enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR)
					alert(e.errMsg);
				else
					throw e;
			}
        }
    );
    
    this.shapes.push(circ);
}

enterprise.googlemapsupportfunctions.mapping.shapes.Boundary.prototype.addRectangle = function(latLngArray, map, relatedShape)
{
    var rect = new google.maps.Polygon({
            paths: latLngArray,
            strokeColor: "#cc33ff",
            strokeOpacity: 0,
            strokeWeight: 0,
            fillColor: "#cc33ff",
            fillOpacity: 0.15,
            map: map,
            zIndex: 1,
            geodesic: true
        });
    
    rect.addListener('click', 
        function()
        {
			try
			{
				relatedShape.toggleBoundary(relatedShape.googleMapHelper.boundarySizeInMeters);
			}
			catch(e)
			{
				if(e.type === enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR)
					alert(e.errMsg);
				else
					throw e;
			}
        }
    );    
    
    this.shapes.push(rect);
}

/////////////////// MapShape Object ////////////////////////////////////////////////////////
// Base class for all map shapes
enterprise.googlemapsupportfunctions.mapping.shapes.MapShape = function(markerLatLng, googleMapHelperInit, markerTitle, markerURL)
{
    this.googleMapHelper = googleMapHelperInit;
    
    this.createGoogleMapMarker = function(googleLatLng, markerTitle, markerURL) 
    {
        var marker = null;
        
        if(googleLatLng)
        {
            marker = new google.maps.Marker({
                  position: googleLatLng,
                  icon: { url: '' + markerURL + '' },
                  title: markerTitle
            });
            
            var clickedMapShape = this;
        
            marker.addListener('click', 
                function()
                {
					try
					{
						clickedMapShape.toggleBoundary(clickedMapShape.googleMapHelper.boundarySizeInMeters);
					}
					catch(e)
					{
						if(e.type === enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR)
							alert(e.errMsg);
						else
							throw e;
					}
                }
            );
        }

        return marker;
    };
    
	this.googleMapMarker = this.createGoogleMapMarker(markerLatLng, markerTitle, markerURL);
    this.boundaries = {};
    this.visibleBoundary;
    this.googleMapShape;
    this.boundariesEnabled = true;
    this.shapeMetaData = {}; // reserved space for storing data associated w/ shape
};

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.getInverseHeadings = function(point1, point2)
{
    var heading = google.maps.geometry.spherical.computeHeading(point1, point2);
    var inverseHeading1 = heading + 90, inverseHeading2 = heading - 90; // both directions perpendicular to line semgent
    
    if(inverseHeading1 > 180)
        inverseHeading1 = inverseHeading1 - 360;
    else if(inverseHeading1 < -180)
        inverseHeading1 = inverseHeading1 + 360;
    
    if(inverseHeading2 > 180)
        inverseHeading2 = inverseHeading2 - 360;
    else if(inverseHeading2 < -180)
        inverseHeading2 = inverseHeading2 + 360;
    
    return { inverseHeading1: inverseHeading1, inverseHeading2: inverseHeading2 };
}

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.getOutwardFacingHeading = function(pointToFindHeadingFor, secondPoint)
{
    var inverseHeadings = this.getInverseHeadings(pointToFindHeadingFor, secondPoint);

    var adjPoint = google.maps.geometry.spherical.interpolate(pointToFindHeadingFor, secondPoint, .1);
    var outwardTestPoint1 = google.maps.geometry.spherical.computeOffset(adjPoint, 20, inverseHeadings.inverseHeading1);
    var outwardTestPoint2 = google.maps.geometry.spherical.computeOffset(adjPoint, 20, inverseHeadings.inverseHeading2);        
    var isTestPoint1Outside = !google.maps.geometry.poly.containsLocation(outwardTestPoint1, this.googleMapShape);
    var isTestPoint2Outside = !google.maps.geometry.poly.containsLocation(outwardTestPoint2, this.googleMapShape);
    var outwardFacingHeading = null;
                
    if(isTestPoint1Outside && !isTestPoint2Outside)
        outwardFacingHeading = inverseHeadings.inverseHeading1;
    else if(!isTestPoint1Outside && isTestPoint2Outside)
        outwardFacingHeading = inverseHeadings.inverseHeading2;
    
    return outwardFacingHeading;
}

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.hideOnMap = function()
{
	if(this.googleMapMarker)
		this.googleMapMarker.setMap(null);
    if(this.googleMapShape)
        this.googleMapShape.setMap(null);
    this.hideBoundary();
};

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.showOnMap = function()
{
	if(this.googleMapMarker)
		this.googleMapMarker.setMap(this.googleMapHelper.googleMap);	
    if(this.googleMapShape)
        this.googleMapShape.setMap(this.googleMapHelper.googleMap);
    this.hideBoundary();
};

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.clearBoundaryCache = function()
{   
    this.hideBoundary();
    this.boundaries = {};
}

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.hideBoundary = function() 
{
    if(this.visibleBoundary)
    {
        this.visibleBoundary.hide();
        this.visibleBoundary = null;
    }
};

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.isBoundaryVisible = function()
{
    if(selectedShape.visibleBoundary)
        return true;
    else
        return false;
}

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.disableBoundaries = function()
{
    this.boundariesEnabled = false;
}

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.enableBoundaries = function()
{
    this.boundariesEnabled = true;
}

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.toggleBoundary = function(boundarySizeInMeters)
{
    if(boundarySizeInMeters && boundarySizeInMeters > 0 && this.boundariesEnabled)
    {
        var matchingSizedBoundary = this.boundaries[boundarySizeInMeters];
        
        if(this.visibleBoundary && this.visibleBoundary.boundarySizeInMeters != boundarySizeInMeters)
            this.visibleBoundary.hide();
        
        if(!matchingSizedBoundary)
        {
            this.visibleBoundary = this.createBoundary(boundarySizeInMeters);
            this.boundaries[boundarySizeInMeters] = this.visibleBoundary;            
        }
        else
        {
            if(matchingSizedBoundary.visible)
                this.hideBoundary();
            else
            {
                this.visibleBoundary = matchingSizedBoundary;
                matchingSizedBoundary.show(this.googleMapHelper.googleMap);
            }
        }
    }
};

enterprise.googlemapsupportfunctions.mapping.shapes.MapShape.prototype.updateBoundarySize = function(boundarySizeInMeters)
{
    if(boundarySizeInMeters && boundarySizeInMeters > 0 && this.visibleBoundary && this.visibleBoundary.boundarySizeInMeters != boundarySizeInMeters)
    {        
        var matchingSizedBoundary = this.boundaries[boundarySizeInMeters];
        
        this.hideBoundary();
        
        if(!matchingSizedBoundary)
        {
            this.visibleBoundary = this.createBoundary(boundarySizeInMeters);
            this.boundaries[boundarySizeInMeters] = this.visibleBoundary;            
        }
        else
        {
            this.visibleBoundary = matchingSizedBoundary;
            matchingSizedBoundary.show(this.googleMapHelper.googleMap);
        }
    }
}

/////////////////// MapPoint Object ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.shapes.MapPoint = function(googleLatLng, googleMapHelperInit, markerTitle, markerURL)
{    
	enterprise.googlemapsupportfunctions.mapping.shapes.MapPoint.parent.constructor.call(this, googleLatLng, googleMapHelperInit, markerTitle, markerURL);
	this.showOnMap();
};

enterprise.googlemapsupportfunctions.misc.extend(enterprise.googlemapsupportfunctions.mapping.shapes.MapPoint, 
	enterprise.googlemapsupportfunctions.mapping.shapes.MapShape); // MapPoint inherits from MapShape

enterprise.googlemapsupportfunctions.mapping.shapes.MapPoint.prototype.createBoundary = function(boundarySizeInMeters)
{
    var boundary = new enterprise.googlemapsupportfunctions.mapping.shapes.Boundary(true, boundarySizeInMeters);
    
    boundary.addCircle(this.googleMapMarker.getPosition(), boundarySizeInMeters, this.googleMapHelper.googleMap, this);
    
    return boundary;
};

enterprise.googlemapsupportfunctions.mapping.shapes.MapPoint.prototype.getOverlayType = function()
{    
    return google.maps.drawing.OverlayType.MARKER;
}
    
/////////////////// Polyline Object ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.shapes.Polyline = function(googleLatLngs, googleMapHelperInit, markerTitle, markerURL)
{	
    this.createGoogleMapPolyline = function(googleLatLngs)
    {
        var poly = new google.maps.Polyline({
              path: googleLatLngs,
              strokeColor: "#33CC33",
              strokeOpacity: 0.8,
              strokeWeight: 4,
              zIndex: 2,
              geodesic: true
        });
        
        var clickedPolyline = this;
        
        poly.addListener('click', 
            function()
            {
                clickedPolyline.toggleBoundary(clickedPolyline.googleMapHelper.boundarySizeInMeters);
            }
        );
        
        return poly;
    };

	enterprise.googlemapsupportfunctions.mapping.shapes.Polyline.parent.constructor.call(this, googleLatLngs[0], googleMapHelperInit, markerTitle, markerURL);
	this.googleMapShape = this.createGoogleMapPolyline(googleLatLngs);
   	this.showOnMap();
};

enterprise.googlemapsupportfunctions.misc.extend(enterprise.googlemapsupportfunctions.mapping.shapes.Polyline, 
	enterprise.googlemapsupportfunctions.mapping.shapes.MapShape); // Polyline inherits from MapShape
    
// Polyline Public Methods	
enterprise.googlemapsupportfunctions.mapping.shapes.Polyline.prototype.getOverlayType = function()
{    
    return google.maps.drawing.OverlayType.POLYLINE;
}

enterprise.googlemapsupportfunctions.mapping.shapes.Polyline.prototype.createBoundary = function(boundarySizeInMeters)
{
    var boundary = new enterprise.googlemapsupportfunctions.mapping.shapes.Boundary(true, boundarySizeInMeters);
    var path = this.googleMapShape.getPath();
    
    for(var i=0; i<path.length; i++)
    {
        if(i<path.length-1)
        {
            var point1 = path.getAt(i), point2 = path.getAt(i+1);
            var p1InverseHeadings = this.getInverseHeadings(point1, point2);
            var p2InverseHeadings = this.getInverseHeadings(point2, point1);
            
            var corners = [];
            corners.push(google.maps.geometry.spherical.computeOffset(point1, boundarySizeInMeters, p1InverseHeadings.inverseHeading1));
            corners.push(google.maps.geometry.spherical.computeOffset(point2, boundarySizeInMeters, p2InverseHeadings.inverseHeading2));
            corners.push(google.maps.geometry.spherical.computeOffset(point2, boundarySizeInMeters, p2InverseHeadings.inverseHeading1));
            corners.push(google.maps.geometry.spherical.computeOffset(point1, boundarySizeInMeters, p1InverseHeadings.inverseHeading2));
            
            boundary.addRectangle(corners, this.googleMapHelper.googleMap, this);
        }
        
        boundary.addCircle(path.getAt(i), boundarySizeInMeters, this.googleMapHelper.googleMap, this);
    }
    
    return boundary;
};

/////////////////// Polygon Object ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.shapes.Polygon = function(googleLatLngs, googleMapHelperInit, markerTitle, markerURL)
{
	enterprise.googlemapsupportfunctions.mapping.shapes.Polygon.parent.constructor.call(this, googleLatLngs[0], googleMapHelperInit, markerTitle, markerURL);
    
    this.createGoogleMapPolygon = function(googleLatLngs)
    {
        var poly = new google.maps.Polygon({
            paths: googleLatLngs,
            strokeColor: "#33CC33",
            strokeOpacity: 0.8,
            strokeWeight: 2,
            fillColor: "#33CC33",
            fillOpacity: 0.35,
            geodesic: true
        });        
        
        var clickedPolygon = this;
        
        poly.addListener('click', 
            function()
            {
				try
				{
				    clickedPolygon.toggleBoundary(clickedPolygon.googleMapHelper.boundarySizeInMeters);
				}
				catch(e)
				{
					if(e.type === enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR)
						alert(e.errMsg);
					else
						throw e;
				}
            }
        );
        
        return poly;
    };
    
	this.googleMapShape = this.createGoogleMapPolygon(googleLatLngs);
    this.showOnMap();
};

enterprise.googlemapsupportfunctions.misc.extend(enterprise.googlemapsupportfunctions.mapping.shapes.Polygon, 
	enterprise.googlemapsupportfunctions.mapping.shapes.MapShape); // Polygon inherits from MapShape
    
// Polygon Public Methods
enterprise.googlemapsupportfunctions.mapping.shapes.Polygon.prototype.getOverlayType = function()
{    
    return google.maps.drawing.OverlayType.POLYGON;
}

enterprise.googlemapsupportfunctions.mapping.shapes.Polygon.prototype.createBoundary = function(boundarySizeInMeters)
{
    var boundary = new enterprise.googlemapsupportfunctions.mapping.shapes.Boundary(true, boundarySizeInMeters);
    var path = this.googleMapShape.getPath();
    var bErrors = false;
    
    for(var i=0; i<path.length && !bErrors; i++)
    {
        var point1 = path.getAt(i), point2 = path.getAt(i==path.length-1 ? 0 : i+1);
        var corners = [];
        var point1OutwardHeading = this.getOutwardFacingHeading(point1, point2);
        var point2OutwardHeading = this.getOutwardFacingHeading(point2, point1);
        
		if(point1OutwardHeading && point2OutwardHeading)
		{
            corners.push(point1);
            corners.push(point2);
            corners.push(google.maps.geometry.spherical.computeOffset(point2, boundarySizeInMeters, point2OutwardHeading));
            corners.push(google.maps.geometry.spherical.computeOffset(point1, boundarySizeInMeters, point1OutwardHeading));
			boundary.addRectangle(corners, this.googleMapHelper.googleMap, this);
			boundary.addCircle(point1, boundarySizeInMeters, this.googleMapHelper.googleMap, this);
		}
        else
            bErrors = true;
    }
    
    if(bErrors)
        throw new enterprise.googlemapsupportfunctions.mapping.shapes.BoundaryCreationError(
            'There were errors creating the boundary for this polygon.  ' + 
            'Either edges are overlapping, edges are too close (within 20 meters), ' + 
            'or the shape width is less than 20 meters and would be better represented as a point or line');
    
    return boundary;
};

/////////////////// Mapping Namespace ////////////////////////////////////////////////////////

/////////////////// Mapping Exceptions ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.GeocodingError = function(errMsgInit)
{
    this.type = "GEOCODING_ERROR";
    this.errMsg = errMsgInit;
}

/////////////////// GoogleMapHelper Object ////////////////////////////////////////////////////////
enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper = function(googleMapInit)
{   
	this.googleMap = googleMapInit;
    this.mapPoints = [];
    this.polygons = [];
	this.polylines = [];
	this.geocoder;
    this.bounds;
    this.boundarySizeInMeters = 800;
    
    // Private Functions
    function geocodeAddressHelper(address, deferredInit)
    {
        var dfd = deferredInit || jQuery.Deferred();
        
        if(!this.geocoder)
            this.geocoder = new google.maps.Geocoder();
            
        this.geocoder.geocode( { 'address': address}, 
            function(results, status) 
            {
                if (status == google.maps.GeocoderStatus.OK) 
                {
                    dfd.resolve(results[0].geometry.location);
                }
                else if(status == google.maps.GeocoderStatus.OVER_QUERY_LIMIT)
                    setTimeout(function(){ geocodeAddressHelper(address, dfd); }, 2000); // try again later
                else 
                {
                    dfd.reject(new enterprise.googlemapsupportfunctions.mapping.GeocodingError('Geocode failed with error code = ' + status), address);
                }
            }
        );
        
        if(typeof deferredInit === "undefined")
            return dfd.promise();
    }
    
    // Privileged Functions
    // Returns a jquery.deffered.promise object that can be used to chain callback functions
    // to handle success or failure events.  On success it would be a good idea to save the 
    // result back to the object on the server so we don't have to keep geocoding the address
    // Params
    //      address - string representing the address to be geocoded
    this.geocodeAddress = function(address) 
    {   
        return geocodeAddressHelper(address);
    };
};

// Public Methods
enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.calculateFlatEarthMidpoint = function(point1, point2, shape)
{
    var midpoint = new 
            enterprise.googlemapsupportfunctions.cartesianmath.LineSegment(
                this.createCartesianMathPoint(point1), 
                this.createCartesianMathPoint(point2)
            ).midpoint.createGoogleLatLng();
    
    // check to see if our location is on the shape, if not then the shape crosses the int date line and we need 
    // to flip the longitude around by 180 degrees
    if(!google.maps.geometry.poly.isLocationOnEdge(midpoint, shape, 10e-2))
    {
        var newLng;
        
        if(midpoint.lng() < 0)
            newLng = midpoint.lng() + 180;
        else
            newLng = midpoint.lng() - 180;
        
        midpoint = this.createGoogleLatLng(midpoint.lat(), newLng);
    }
    
    return midpoint;
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.getMarkerIcon = function(markerIconEnumColor)
{
    return {
        url: markerIconEnumColor,
        size: new google.maps.Size(21,34),
        origin: new google.maps.Point(0,0),
        anchor: new google.maps.Point(10,34)
    };
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.getBoundarySizeInMiles = function() 
{
    return this.boundarySizeInMeters/1600;
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.setBoundarySizeInMiles = function(boundarySizeInMiles) 
{
    this.boundarySizeInMeters = boundarySizeInMiles*1600;
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.addPolygon = function(googleLatLngs, markerTitle, markerIcon, boundaryVisible, includeInZoom) 
{	
    var polygon = null;
    
	if(googleLatLngs && googleLatLngs.length >= 3)
	{
		polygon = new enterprise.googlemapsupportfunctions.mapping.shapes.Polygon(googleLatLngs, this, markerTitle, markerIcon);
	
        if(boundaryVisible)
		{
			try
			{
				polygon.toggleBoundary(this.boundarySizeInMeters);
			}
			catch(e)
			{
				if(e.type !== enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR)
					throw e; // fail silently on boundary creation errors, rethrow all else
			}
		}
        
		this.polygons.push(polygon);
        
		if(includeInZoom)
        {
			for(var i=0;i<googleLatLngs.length;i++)
            {
                if(!this.bounds)
                    this.bounds = new google.maps.LatLngBounds();
                
                this.bounds.extend(googleLatLngs[i]);
            }
        }
    }
    
    return polygon;
};

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.addPolyline = function(googleLatLngs, markerTitle, markerIcon, boundaryVisible, includeInZoom) 
{	
    var polyline = null;
    
	if(googleLatLngs && googleLatLngs.length >= 2)
	{
		polyline = new enterprise.googlemapsupportfunctions.mapping.shapes.Polyline(googleLatLngs, this, markerTitle, markerIcon);
	
        if(boundaryVisible)
            polyline.toggleBoundary(this.boundarySizeInMeters);
        
		this.polylines.push(polyline);
        
		if(includeInZoom)
        {
			for(var i=0;i<googleLatLngs.length;i++)
            {
                if(!this.bounds)
                    this.bounds = new google.maps.LatLngBounds();
                
				this.bounds.extend(googleLatLngs[i]);
            }
        }
    }
    
    return polyline;
};

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.addPoint = function(googleLatLng, markerTitle, markerIcon, boundaryVisible, includeInZoom)
{	    
	var mapPoint = null;
    
	if(googleLatLng)
	{
        mapPoint = new enterprise.googlemapsupportfunctions.mapping.shapes.MapPoint(googleLatLng, this, markerTitle, markerIcon);
	
        if(boundaryVisible)
            mapPoint.toggleBoundary(this.boundarySizeInMeters);
		this.mapPoints.push(mapPoint);
		
		if(includeInZoom)
        {
            if(!this.bounds)
                this.bounds = new google.maps.LatLngBounds();
            
			this.bounds.extend(googleLatLng);
        }
    }
    
    return mapPoint;
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.fitBounds = function()
{
    if(this.bounds)
    {
        this.googleMap.fitBounds(this.bounds);
        var listener = google.maps.event.addListener(this.googleMap, "idle", function() { 
          if (map.getZoom() > 14) map.setZoom(14); 
          google.maps.event.removeListener(listener); 
        });
    }
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.updateVisibleShapeBoundarySizes = function(boundarySizeInMiles)
{    
    if(boundarySizeInMiles && boundarySizeInMiles > 0)
    {
        this.setBoundarySizeInMiles(boundarySizeInMiles);
        
        for(var mapPointIndex=0; mapPointIndex<this.mapPoints.length; mapPointIndex++)
            if(this.mapPoints[mapPointIndex].visibleBoundary)
                this.mapPoints[mapPointIndex].updateBoundarySize(this.boundarySizeInMeters);
        
        for(var polylineIndex=0; polylineIndex<this.polylines.length; polylineIndex++)
            if(this.polylines[polylineIndex].visibleBoundary)
                this.polylines[polylineIndex].updateBoundarySize(this.boundarySizeInMeters);
        
        for(var polygonIndex=0; polygonIndex<this.polygons.length; polygonIndex++)
		{
            if(this.polygons[polygonIndex].visibleBoundary)
			{
				try
				{
					this.polygons[polygonIndex].updateBoundarySize(this.boundarySizeInMeters);
				}
				catch(e)
				{
					if(e.type !== enterprise.googlemapsupportfunctions.mapping.shapes.ExceptionTypes.BOUNDARY_CREATION_ERROR)
						throw e; // fail silently on boundary creation errors, rethrow all else
				}
			}
		}
    }   
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.createGoogleLatLng = function(lat, lng)
{
	var googleLatLng = null;
	
    if(typeof lat !== "undefined" && typeof lng !== "undefined" && lat !== null && lng !== null)
		googleLatLng = new google.maps.LatLng(lat,lng);
	
	return googleLatLng;
}

enterprise.googlemapsupportfunctions.mapping.GoogleMapHelper.prototype.createCartesianMathPoint = function(googleLatLng)
{
    return new enterprise.googlemapsupportfunctions.cartesianmath.Point(googleLatLng.lng(), googleLatLng.lat());
}