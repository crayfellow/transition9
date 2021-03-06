/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This source file was derived from the actionscript aspirin library.
 * A copy of the LGPL license is located at the root of the SDK.
 *
 * The original file source header (required by the LGPL license):
 *
 * aspirin library - Taking some of the pain out of Actionscript development.
 * Copyright (C) 2007-2010 Three Rings Design, Inc., All Rights Reserved
 * http://code.google.com/p/ooo-aspirin/
 * 
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

package transition9.util;

import transition9.rtti.ReflectUtil;

import Type;

/* Contains sorting Comparators.
 * These functions take any parameters but require only the first to, so they are suitable
 * for passing to Array.sort(), or with a flex Sort object. Note that returning values other
 * than 1, 0, or -1 confuse a flex Sort object.
 * In general, these functions don't handle sorting undefined, it will be coerced to null.
 */
class Comparators
{
	/**
	 * Create a Comparator function that reverses the ordering of the specified Comparator.
	 */
	inline public static function createReverse (comparator :Dynamic->Dynamic->Int) :Dynamic->Dynamic->Int
	{
		return function (o1 :Dynamic, o2 :Dynamic) :Int {
			return comparator(o2, o1); // simply reverse the ordering
		};
	}

	/**
	 * Create a Comparator appropriate for comparing objects of the specified type.
	 * If an appropriate comparator cannot be determined, compareUnknowns is returned.
	 */
	public static function createFor<T> (type :ValueType) :Dynamic -> Dynamic ->Int
	{
		switch (type) {
			case TNull: return compareUnknowns;
			case TInt: return compareInts;
			case TFloat: return compareFloats;
			case TBool: return compareBooleans;
			case TObject: return compareUnknowns;
			case TFunction: return compareUnknowns;
			case TClass(c):
				if (c == String) {
					return compareStrings;
				} else {
					var k = Type.createEmptyInstance(c);
					if (Std.is(k, Comparable)) {
						return compareComparables;
					} else {
						return compareUnknowns;
					}
				}
			case TEnum(e): return compareEnums;
			case TUnknown: return compareUnknowns;
		}
	}

	/**
	 * Create a Comparator function that sorts according to one or more fields of Objects.
	 * Array.sortOn() only works with public variables, and not with public getters. This
	 * implementation works with both.
	 */
	public static function createFields <T> (sortFields :Array<String>, ?defaults :Array<Dynamic> = null) :T->T->Int
	{
		if (defaults == null) {
			defaults = [];
		}
		// TODO: copy the arrays for safety?
		return function (a :T, b :T) :Int {
			for (ii in 0...sortFields.length) {
				var sortField:String = sortFields[ii];
				var def:Dynamic = defaults[ii];
				var aVal:Dynamic = if (a != null && Reflect.hasField(a, sortField)) ReflectUtil.field(a, sortField) else def;
				var bVal:Dynamic = if (b != null && Reflect.hasField(b, sortField)) ReflectUtil.field(b, sortField) else def;
				var c:Int = compareUnknowns(aVal, bVal);
				if (c != 0) {
					return c;
				}
			}
			return 0;
		};
	}

	/**
	 * Compose another comparator into one that can compare null and non-null elements
	 * safely, sorting the nulls to the bottom.
	 *
	 * @example
	 * <listing version="3.0">
	 * Arrays.sort(myStringArray, Comparators.createNullSafe(Comparators.compareStrings));
	 * </listing>
	 */
	public static function createNullSafe (comparator :Dynamic->Dynamic->Int) :Dynamic->Dynamic->Int
	{
		return function (o1 :Dynamic, o2 :Dynamic) :Int {
			if (o1 == o2) { // same obj, or both null
				return 0;
			} else if (o1 == null) {
				return -1;
			} else if (o2 == null) {
				return 1;
			} else {
				return comparator(o1, o2);
			}
		};
	}

	/**
	 * A standard Comparator for comparing Comparable values.
	 */
	inline public static function compareComparables (c1 :Comparable<Dynamic>, c2 :Comparable<Dynamic> = null) :Int
	{
		return c1.compareTo(c2);
	}

	/**
	 * Compare two objects by their toString() values, case sensitively.
	 * Yes, you can pass any objects to this function, and HaXe will coerce them
	 * to Strings, calling Std.string() if not a simple type.
	 */
	inline public static function compareStrings (s1 :String, s2 :String) :Int
	{
		return (s1 == s2) ? 0 : ((s1 > s2) ? 1 : -1);
	}

	/**
	 * Compare two objects by their toString().toLowerCase() values, case insensitively.
	 * Yes, you can pass any objects to this function, and HaXe will coerce them
	 * to Strings, calling Std.string() if not a simple type.
	 */
	inline public static function compareStringsInsensitively (s1 :String, s2 :String) :Int
	{
		return compareStrings(s1.toLowerCase(), s2.toLowerCase());
	}
	
	inline public static function compareEnums (e1 :EnumValue, e2 :EnumValue) :Int
	{
	    return compareStrings(Type.enumConstructor(e1), Type.enumConstructor(e2));
	}
	

	/**
	 * Compare two values whose type is not known at compile type. Tries to figure it out.
	 * Also handles nulls.
	 * Note that this method may look like it can safely compare heterogeneous types,
	 * but <b>it cannot</b>. Consider the array: [ true, "meerkat", false ].
	 * compareUnknowns(true, "meerkat") returns -1;
	 * compareUnknowns("meerkat", false) returns -1;
	 * but compareUnknowns(true, false) returns 1, which violates transitivity.
	 * If in doubt, try using createNullSafe(compareStrings), which can safely and consistently
	 * sort <b>anything</b>.
	 */
	public static function compareUnknowns (o1 :Dynamic, o2 :Dynamic) :Int
	{
		if (o1 == o2) { // use strict equality
			return 0;
		} else if (o1 == null) {
			return -1;
		} else if (o2 == null) {
			return 1;
		} else if (Std.is(o1, Comparable)) {
			return cast(o1, Comparable<Dynamic>).compareTo(o2); // it doesn't matter if o2 is Comparable
		} else if (StdTools.is(o1, TFloat) && (StdTools.is(o2, TInt) || StdTools.is(o2, TFloat))) {
			return compareFloats(cast(o1, Float), cast(o2, Float));
		} else if (StdTools.is(o1, TInt) && StdTools.is(o2, TInt)) {
			return compareInts(cast(o1, Int), cast(o2, Int));
		} else if (StdTools.is(o1, TBool) && StdTools.is(o2, TBool)) {
			return compareBooleans(cast(o1, Bool), cast(o2, Bool));
		} else {
			// fuck it, coerce them both to String
			return compareStrings(Std.string(o1), Std.string(o2));
		}
	}

	/**
	 * Compares two Boolean values.
	 */
	inline public static function compareBooleans (v1 :Bool, v2 :Bool) :Int
	{
		return if (v1 == v2) 0 else if (v1) 1 else -1;
	}
	
	/**
	 * Compares two int values in an overflow safe manner.
	 */
	inline public static function compareInts (v1 :Int, v2 :Int) :Int
	{
		if (v1 > v2) {
			return 1;
		} else if (v1 == v2) {
			return 0;
		} else {
			return -1;
		}
	}

	/**
	 * WARNING: this is untested in haxe.
	 * Compares two Float values, taking into account the intricacies of dealing with NaN.
	 */
	inline public static function compareFloats (v1 :Float, v2 :Float) :Int
	{
		if (v1 > v2) {
			return 1;
		} else if (v1 < v2) {
			return -1;
		} else if (v1 == v2) {
			return 0;
		} else {
			// at this point, we know that at least one value is NaN. Luckily, there doesn't seem
			// to be a -0 in actionscript, even though it's supposedly IEEE-754. TODO: test more?
			return compareBooleans(Math.isNaN(v1), Math.isNaN(v2));
		}
	}
	
	inline public static function compareHashables (v1 :transition9.ds.Hashable, v2 :transition9.ds.Hashable) :Int
	{
		transition9.util.Assert.isNotNull(v1);
		transition9.util.Assert.isNotNull(v2);
		return compareInts(v1.hashCode(), v2.hashCode());
	}
}
