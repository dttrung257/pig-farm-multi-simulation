model TransmitDiseaseFactor


import './factor.gaml'


species TransmitDiseaseFactor parent: Factor {
	agent victim;
	
	init {
		b <- rnd(0.402, 1.85);
		victim <- nil;
	}
	
	reflex follow when: victim != nil {
		ask Background at_distance(size) {
			self.color <- rgb(background at { grid_x, grid_y });
		}
		location <- victim.location;
		if(duration = 1) {
			duration <- duration + 1;
		}
	}
	
	action remove {
		ask Background at_distance(size) {
			self.color <- rgb(background at { grid_x, grid_y });
		}
		do die;
	}
}
