/**
* Name: MultiDiseasePig
*/


model MultiDiseasePig


import './disease-pig.gaml'


species AbstractDiseasePig parent: DiseasePig {
	MultiDiseasePig pig;
	
	init {
		pig <- nil;
	}
	
	aspect base {}
	
	action eat {
		if(pig != nil) {
			ask Trough {
            if(add_pig(pig)) {
            	myself.location <- location;
	            myself.current <- 3;
	            myself.duration <- myself.eat_time();
	            myself.eat_count <- myself.eat_count + 1;
	            break;
            }
        }	
		}
    }
    
    action go_out {
    	if(pig != nil) {
	    	ask Trough {
	    		do remove_pig(pig);
	    	}
	    }
    	location <- get_gate_out_loc();
    	current <- 4;
    }
	
	reflex routine {
    	do seir_routine();
    	do seir_refresh_per_day();
    }
}


species MultiDiseasePig parent: DiseasePig {
	list<AbstractDiseasePig> abstracts; // order by severity increase
	list<AbstractDiseasePig> resistances;
	list<AbstractDiseasePig> resiliences;
	
	init {
		resistances <- [];
		resiliences <- [];
	}
	
	/**
	 * Util functions
	 */
	action aggregate_from_abstracts {
		loop abstract over: abstracts {
			if((abstract.expose_count_per_day > 0 or abstract.seir = 2 or abstract.seir = 1) and !contains(resistances, abstract)) {
				add abstract to: resistances;
			}
			if(
				abstract.expose_count_per_day = 0 and
				abstract.recover_count > 0 and
				(abstract.seir = 0 or abstract.seir = 3) and
				!contains(resiliences, abstract)
			) {
				add abstract to: resiliences;
			}
			expose_count_per_day <- expose_count_per_day + abstract.expose_count_per_day;
		}
		
		seir <- 0;
		loop abstract over: resistances {
			if(abstract.seir > seir) {
				seir <- abstract.seir;
			}
		}
		if(all_match(abstracts, each.seir = 3)) {
			seir <- 3;
		}
	}

	action sync_to_abstracts {
		loop abstract over: abstracts {
			abstract.id <- id;
    
		    abstract.a <- a;
		    abstract.b <- b;
		    abstract.fi <- fi;
		    abstract.init_weight <- init_weight; 
		    abstract.weight <- weight;
		    
		    abstract.target_dfi <- target_dfi;
		    abstract.target_cfi <- target_cfi;
		    abstract.dfi <- dfi;
		    abstract.cfi <- cfi;
		    
		    abstract.current <- current;
		    abstract.duration <- duration;
		    
		    abstract.excrete_count <- excrete_count;
		    abstract.eat_count <- eat_count;
		    
		    abstract.excrete_each_day <- excrete_each_day;
		    
		    abstract.location <- location;
		}
	}
	
	action sync_from_resistance(AbstractDiseasePig abstract) {  
		    current <- abstract.current;
		    duration <- abstract.duration;
		    
		    location <- abstract.location;
		    
		    excrete_count <- abstract.excrete_count;
		    eat_count <- abstract.eat_count;
		    
		    excrete_each_day <- abstract.excrete_each_day;
	}
	/*****/
	
	/**
	 * DFI, CFI and Weight
	 */
	float resistance {
		if(length(resistances) > 1) {
			float s <- 0.0;
			float k1_max <- max_of(resistances, each.k1);
			float ln_n <- ln(length(resistances));
			loop abstract over: resistances {
				s <- s + e ^ abstract.k1;
			}
			return (ln(s) - k1_max) * (1 - k1_max) / ln_n;	
		}
		else if(length(resistances) = 1) {
			return resistances[0].k1;
		}
		return super.resistance();
	}
	
	float resilience {
		if(length(resistances) = 0 and length(resiliences) > 0) {
			float s <- 0.0;
			loop abstract over: resiliences {
				s <- s + e ^ abstract.k2;
			}
			return (ln(s) * (1 - cfi / target_cfi)) with_precision 2;
		}
		return super.resilience();
	}
	/*****/
	
	/**
	 * Event loop functions
	 */
	action aggregate_seir_refresh_per_day {
		do seir_refresh_per_day();
		if(is_start_of_day()) {
			resistances <- [];	
		}
	}
	
	action aggregate_normal_routine {
		int l <- length(resistances);
		if(l > 0) {
			AbstractDiseasePig abstract <- resistances[l - 1];
			ask abstract {
				do normal_routine();
			}
			do sync_from_resistance(abstract);
		}
		else {
			do normal_routine();
		}
	}
	/*****/
	
	reflex routine {
		do sync_to_abstracts();
		do aggregate_from_abstracts();
    	do aggregate_normal_routine();
    	do refresh_per_day();
    	do aggregate_seir_refresh_per_day();
    }
}
