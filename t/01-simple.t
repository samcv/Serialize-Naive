#!/usr/bin/env perl6

use v6;
use strict;

use Serialize::Naive;
use Test;

plan 11;

class Point does Serialize::Naive
{
	has Int $.x;
	has Int $.y;
}

multi sub infix:<==>(Point:D $p1, Point:D $p2)
{
	return $p1.x == $p2.x && $p1.y == $p2.y;
}

class Circle does Serialize::Naive
{
	has Point $.center;
	has Rat $.radius;
}

multi sub infix:<==>(Circle:D $c1, Circle:D $c2)
{
	return $c1.radius == $c2.radius && $c1.center == $c2.center;
}

class Triangle does Serialize::Naive
{
	has Array[Point] $.vertices;
	has Str $.label;

	method is-valid() returns Bool:D
	{
		return $!vertices.elems == 3;
	}
}

{
	my %data = center => {x => 1, y => 2}, radius => 1.5;

	my Circle:D $c = Circle.deserialize(%data);
	is $c.radius, 1.5, 'trivial - radius';
	is $c.center.x, 1, 'trivial - center - x';
	is $c.center.y, 2, 'trivial - center - y';

	my Circle:D $c-f = deserialize Circle, %data;
	ok $c-f == $c, 'trivial - function vs method';

	my %tridata = label => 'Soldier Y', unhand => 'me', vertices => [
		{x => 0, y => 0},
		{x => 1},
		{x => 1, y => 1, weird => 'ness'},
	];

	my UInt:D $warnings = 0;
	my Triangle:D $tri = Triangle.deserialize(%tridata,
	    :warn(sub ($) { $warnings++ }));
	ok $tri.is-valid, 'triangle - valid';
	nok $tri.vertices[1].y.defined, 'triangle - an undefined value';
	is $warnings, 2, 'triangle - unhandled value warnings';

	my %newdata = $c.serialize;
	is-deeply %newdata, %data, 'trivial - serialize back';
	my %newdata-f = serialize $c;
	is-deeply %newdata-f, %data, 'trivial - serialize using a function';

	my %newtridata = $tri.serialize;
	%tridata<unhand>:delete;
	%tridata<vertices>[2]<weird>:delete;
	is-deeply %newtridata, %tridata, 'triangle - serialize back';
	my %newtridata-f = serialize $tri;
	is-deeply %newtridata-f, %tridata, 'triangle - serialize using a function';
}
