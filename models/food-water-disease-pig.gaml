/**
* Name: FoodWaterDiseasePig
*/


model FoodWaterDiseasePig


import './multi-disease-pig.gaml'
import './food-disease-factor.gaml'
import './water-disease-factor.gaml'


species AbstractFoodDiseasePig parent: AbstractDiseasePig {
	init {
		max_expose_time <- 24 * 60;
		avg_expose_time <- 12 * 60;
		
		k1 <- 0.24;
		k2 <- 0.81;
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


species AbstractWaterDiseasePig parent: AbstractDiseasePig {
	init {
		max_expose_time <- 7 * 24 * 60;
		avg_expose_time <- 5 * 24 * 60;
		
		k1 <- 0.46;
		k2 <- 0.81;
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
		if(current = 6) {
			ask WaterDiseaseFactor {
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


species FoodWaterDiseasePig parent: MultiDiseasePig {
	init {
		create AbstractWaterDiseasePig number: 1 returns: water;
		create AbstractFoodDiseasePig number: 1 returns: food;
		water[0].pig <- self;
		food[0].pig <- self;
		abstracts <- [water[0], food[0]];
	}
	
	/**
	 * Util functions
	 */
	float get_init_weight {
		return rnd(47.5, 52.5) with_precision 2;
	}
	/*****/
}