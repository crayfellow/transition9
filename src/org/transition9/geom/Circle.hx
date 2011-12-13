/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package org.transition9.geom;

import com.pblabs.geom.CircleUtil;
import com.pblabs.geom.Geometry;
import com.pblabs.geom.Vector2;
import org.transition9.util.Cloneable;

import de.polygonal.motor2.geom.math.XY;

class Circle
	implements Cloneable<Circle>
{
	public var center :XY;
	public var radius :Float;
	public var x (get_x, set_x) :Float;
	public var y (get_y, set_y) :Float;
 
	public function new (?radius :Float = 0, ?x :Float = 0, ?y :Float= 0)
	{
		this.radius = radius;
		this.center = new Vector2(x, y);
	}
	
	public function distance (other :Circle) :Float
	{
		return  CircleUtil.distance(this, other);
	}
	
	public function clone () :Circle
	{
		return new Circle(radius, x, y);
	}
	
	public function toString () :String
	{
		return "[r=" + radius + ", x=" + x + ", y=" + y + "]";
	}
	
	function get_x () :Float
	{
		return center.x;
	}
	
	function set_x (val :Float) :Float
	{
		center.x = val;
		return val;
	}
	
	function get_y () :Float
	{
		return center.y;
	}
	
	function set_y (val :Float) :Float
	{
		center.y = val;
		return val;
	}

}