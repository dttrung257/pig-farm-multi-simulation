model FoodDiseaseConfig


import './food-disease-factor.gaml'


species FoodDiseaseConfig {
	int day;
	
	init {
		day <- 0;
	}
	
	reflex spread when: cycle mod (24 * 60) = 0 and int(cycle / (60 * 24)) = day {
		create FoodDiseaseFactor number: 5;
		loop i from: 0 to: 4 {
			FoodDiseaseFactor[i].duration <- 7 * 24 * 60;
			FoodDiseaseFactor[i].size <- 2.0;
			FoodDiseaseFactor[i].location <- trough_locs[i];
		}
	}
}
