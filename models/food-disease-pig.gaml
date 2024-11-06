model FoodDiseasePig


import './disease-pig.gaml'
import './food-disease-factor.gaml'


species FoodDiseasePigCC parent: DiseasePig {	
	init {
		max_expose_time <- 24 * 60;
		avg_expose_time <- 12 * 60;
	}
	
	/**
	 * Util functions
	 */
	bool is_hungry {
		if(expose_count_per_day > 0) {
			return flip(0.5) and super.is_hungry();	
		}
		else {
			return super.is_hungry();
		}
	}
	
	float get_init_weight {
		return rnd(47.5, 52.5) with_precision 2;
	}
	
	int get_excrete_per_day {
		if(expose_count_per_day > 0) {
			return rnd(4, 6);
		}
		else {
			return super.get_excrete_per_day();
		}
	}
	/*****/
	
	/**
	 * Behaviour actions
	 */
	action expose {
		if(current = 3) {
			ask FoodDiseaseFactor {
				if(expose(myself)) {
					myself.seir <- 1;
					myself.expose_count_per_day <- myself.expose_count_per_day + 1;
				}
			}	
		}
	}
	
	action infect {
		if(is_start_of_day() and (max_expose_time <= expose_time or flip(1 - e ^ -((expose_time / (24 * 60)) / (avg_expose_time / (24 * 60)))))) {
			seir <- 0;
			expose_time <- 0;
			recover_count <- recover_count + 1;
		}
		else {
			expose_time <- expose_time + 1;
		}
	}
	/*****/
}


species FoodDiseasePigDC parent: FoodDiseasePigCC {
	init {
		k1 <- 0.46;
		k2 <- 0.81;
	}
}

species FoodDiseasePigCD parent: FoodDiseasePigCC {
	init {
		k1 <- 0.42;
		k2 <- 1.59;
	}
}

species FoodDiseasePigDD parent: FoodDiseasePigCC {
	init {
		k1 <- 0.46;
		k2 <- 0.9;
	}
	
	reflex update_k when: cycle mod (24 * 60) = 0 and int(cycle / (60 * 24)) = 35 {
		k1 <- 0.31;
		k2 <- 2.36;
	}
}
