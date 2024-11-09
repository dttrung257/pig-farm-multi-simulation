/**
* Name: Factor
*/


model Factor

import './config.gaml'
import './farm.gaml'


species Factor {
	int duration;
	float size;
	float b; // transmit rate
	
	init {
		b <- 0.0;
		size <- 0.0;
		duration <- 0;
	}
	
	reflex update {
		if(duration > 0) {
			ask Background at_distance(size) {
				self.color <- #lightyellow;
			}
			duration <- duration - 1;
		}
		else {
			ask Background at_distance(size) {
				self.color <- rgb(background at { grid_x, grid_y });
			}
			do die;
		}
	}
	
	bool expose(agent pig) {
		return flip(1 - e ^ -b) and distance_to(pig.location, location) <= size;
	}
}
