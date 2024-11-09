/**
* Name: FoodDiseaseFactor
*/


model FoodDiseaseFactor


import './factor.gaml'


species FoodDiseaseFactor parent: Factor {
	init {
		b <- 100.0;
	}
}