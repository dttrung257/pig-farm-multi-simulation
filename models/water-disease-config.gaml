/**
* Name: WaterDiseaseConfig
*/


model WaterDiseaseConfig


import './water-disease-factor.gaml'


species WaterDiseaseConfig {
	int day;
	
	init {
		day <- 0;
	}
	
	reflex spread when: cycle mod (24 * 60) = 0 and int(cycle / (60 * 24)) = day {
		create WaterDiseaseFactor number: 4;
		loop i from: 0 to: 3 {
			WaterDiseaseFactor[i].duration <- 14 * 24 * 60;
			WaterDiseaseFactor[i].size <- 2.0;
			WaterDiseaseFactor[i].location <- water_locs[i];
		}
	}
}
