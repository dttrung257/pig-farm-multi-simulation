/**
* Name: transmitdiseaseagent
* Based on the internal empty template. 
* Author: trungdt
* Tags: 
*/


model TransmitDiseaseAgent

import './disease-pig.gaml'
import './transmit-disease-factor.gaml'
import './transmit-disease-config.gaml'

/* Insert your model definition here */

species TransmitDiseaseAgent parent: DiseasePig {
	int go_in_cycle;
	agent factor;
	
	init {
		factor <- nil;
		create TransmitDiseaseConfig number: 1 returns: configs;
		ask configs[0] {
            myself.factor <- create_factor_and_attach_to(myself);
        }
        
        go_in_cycle <- 0;
	}
	
	aspect base {
		draw image("../includes/images/farmer.png") size: 5.0;
    }
    
    reflex timer {
    	go_in_cycle <- go_in_cycle + 1;
    }
    
    reflex remove {
    	ask factor as TransmitDiseaseFactor {
			do remove();
		}
    	
    	do die;
    }
	
//	float get_init_weight {
//		return rnd(47.5, 52.5) with_precision 2;
//	}
//	
//	action expose {
//		ask TransmitDiseaseFactor {
//			if(expose(myself)) {
//				myself.seir <- 1;
//				myself.expose_count_per_day <- myself.expose_count_per_day + 1;
//			}
//		}
//	}
//	
//	action infect {
//		invoke infect();
//		if(seir = 2) {
//			ask TransmitDiseaseConfig {
//				myself.factor <- create_factor_and_attach_to(myself);
//			}	
//		}
//	}
//	
//	bool is_hungry {
//		if(seir = 1) {
//			return flip(0.5) and super.is_hungry();	
//		}
//		else if(seir = 2) {
//			return false;
//		}
//		else {
//			return super.is_hungry();
//		}
//	}
//	
//	reflex remove when: seir = 3 or seir = 4 {
//		ask factor as TransmitDiseaseFactor {
//			do remove();
//		}
//	}
}
