model DiseasePig


import './pig.gaml'


/**
 * Pig behaviors table 
 *---------------------------------------------------
 * 
 * ID: Behavior ID
 * Name: Current behavior
 * Duration: Remain time before run trigger function
 * Next: Next behavior
 * 
 * --------------------------------------------------
 * ID | Name           | Next
 * --------------------------------------------------
 * 0  | not-expose     | expose: [0, 1]
 * 1  | expose         | infect: [1, 2]
 * 2  | infect         | recover: [2, 3, 4]
 * 3  | recover        | shed: [3, 0]
 * 4  | die            |
 */
species DiseasePig parent: Pig {
	int seir;
	
	int expose_time;
	int infect_time;
	int shed_time;
	
	int expose_count_per_day;
	int recover_count;
	
	int max_expose_time;
	int avg_expose_time;
	int max_infect_time;
	int avg_infect_time;
	int max_shed_time;
	int avg_shed_time;
	
	float u; // death probability
	
	float k1;
	float k2;
	
	init {
		seir <- 0;
		
		expose_time <- 0;
		infect_time <- 0;
		shed_time <- 0;
		
		expose_count_per_day <- 0;
		recover_count <- 0;
		
		max_expose_time <- 0;
		avg_expose_time <- 0;
		max_infect_time <- 0;
		avg_infect_time <- 0;
		max_shed_time <- 0;
		avg_shed_time <- 0;
		
		u <- 0.0;
		
		k1 <- 0.0;
		k2 <- 0.0;
	}
	
	aspect base {
		if(seir = 0) {
			draw circle(1.6) color: #pink;
			draw string(id) color: #black size: 5;
		}
		else if(seir = 1) {
			draw circle(1.6) color: #yellow;
			draw string(id) color: #black size: 5;
		}
		else if(seir = 2) {
			draw circle(1.6) color: #red;
			draw string(id) color: #black size: 5;
		}
		else if(seir = 3) {
			draw circle(1.6) color: #lightgreen;
			draw string(id) color: #black size: 5;
		}
    }
	
	/**
	 * DFI, CFI and Weight
	 */
    float resistance {
		if(expose_count_per_day > 0 or seir = 1 or seir = 2) {
			return k1;
		}
		else {
			return super.resistance();
		}
	}
	
	float resilience {
		if(expose_count_per_day = 0 and recover_count > 0 and (seir = 0 or seir = 3)) {
			return (k2 * (1 - cfi / target_cfi)) with_precision 2;
		}
		else {
			return super.resilience();
		}
	}
	/*****/
	
	/**
	 * Behaviour actions
	 */
	action expose {}
	
	action infect {
		if(is_start_of_day() and (max_expose_time <= expose_time or flip(1 - e ^ -(expose_time / avg_expose_time)))) {
			seir <- 2;
			expose_time <- 0;
		}
		else {
			expose_time <- expose_time + 1;
		}
	}
	
	action recover {
		if(is_start_of_day() and (max_infect_time <= infect_time or flip(1 - e ^ -(infect_time / avg_infect_time)))) {
			if(flip(u)) {
				seir <- 4;
				current <- 9;
			}
			else {
				seir <- 3;
				infect_time <- 0;
				recover_count <- recover_count + 1;	
			}
		}
		else {
			infect_time <- infect_time + 1;
		}
	}
	
	action shed {
		if(is_start_of_day() and (max_shed_time <= shed_time or flip(1 - e ^ -(shed_time / avg_shed_time)))) {
			seir <- 0;
			shed_time <- 0;
		}
		else {
			shed_time <- shed_time + 1;
		}
	}
	/*****/
	
	/**
     * Event loop functions
     */
    action seir_routine {
    	if(seir = 0) {
    		do expose();
    	}
    	else if(seir = 1) {
    		do infect();
    	}
    	else if(seir = 2) {
    		do recover();
    	}
    	else if(seir = 3) {
    		do shed();
    	}
    }
    
    action seir_refresh_per_day {
		if(is_start_of_day()) {
			expose_count_per_day <- 0;	
		}
	}
    /*****/
    
    reflex routine {
    	do normal_routine();
    	do seir_routine();
    	do refresh_per_day();
    	do seir_refresh_per_day();
    }
}
