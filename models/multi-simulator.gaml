/**
* Name: MultiSimulator
* Description: Modified simulator to handle disease appearances as string input
*/

model MultiSimulator

import "base-pigpen-model.gaml"
import "transmit-disease-config.gaml"
import "transmit-disease-pig.gaml"
import "transmit-disease-agent.gaml"
import "food-disease-config.gaml"
import "water-disease-config.gaml"
import "config.gaml"

global parent: BasePigpenModel {
    int final_step;
    int dead_pig_count;
    string pig_ids;
    int init_disease_appear_day;
    map<string, string> DB_PARAMS <- [  
        'host'::'localhost',
        'dbtype'::'mysql',
        'database'::'ags',
        'port'::'13306', 
        'user'::'agsuser',
        'passwd'::'123'
     ];
    
    init {
        // This flag is used to run sync or async simulation
        if (length(neighbor_ids) > 0) {
            sync <- true;
        } else {
            sync <- false;
        }
//		sync <- false;
        
        // Setup database helper
        do setup_database();
        
        // Initialize pigpen
        list<int> pig_list <- pig_ids split_with "," collect (int(each));
        total_pigs <- length(pig_list);
        unexposed_pig_count <- 0;
        exposed_pig_count <- 0;
        infected_pig_count <- 0;
        recovered_pig_count <- 0;
        dead_pig_count <- 0;
        
        loop pig_id over: pig_list {
            create TransmitDiseasePig {
                id <- pig_id;
            }
        }
        
//        loop pig_id over: pig_list {
//        	put 0 key: int(pig_id) in: previous_positions;
//    	}
        
        create Trough number: 5;
        loop i from: 0 to: 4 {
            Trough[i].location <- trough_locs[i];
        }
        
        if (init_disease_appear_day >= 0) {
        	create TransmitDiseaseConfig number: 1;
        	TransmitDiseaseConfig[0].day <- init_disease_appear_day;
        	is_affected_by_neighbor_pen <- true;
        } else {
        	is_affected_by_neighbor_pen <- false;
        }
        scheduled_disease_appearance_day <- -1;
        has_disease_in_neighbors <- false;
    }
    
    action attach_disease_to_random_pig {
        int random_disease_pig_index <- rnd(0, total_pigs - 1);
        create TransmitDiseaseConfig number: 1 returns: configs;
        ask configs[0] {
            do create_factor_and_attach_to(TransmitDiseasePig[random_disease_pig_index]);
        }
    }
    
    action attach_disease_to_pig(int pig_id) {
    	if (pig_id >= 0 and pig_id < length(TransmitDiseasePig)) {
    		loop pig over: TransmitDiseasePig {
    			if (pig.id = pig_id) {
        			create TransmitDiseaseConfig number: 1 returns: configs;
        			ask configs[0] {
            			do create_factor_and_attach_to(pig);
        			}
        		}
        	}
    	}
	}
    
//	action check_neighbor_pig_positions(int day) {
//    	if (!has_disease_in_neighbors) { return; }
//    	
//    	list<string> neighbor_list <- neighbor_ids split_with ",";
//    	list<int> pigs_to_infect <- [];
//    	
//    	ask db_helper {
//        	string query <- "SELECT x, y, pig_id FROM pig_movement_history WHERE run_id = ? AND pigpen_id IN (" + 
//            	           neighbor_list + ") AND cycle = ? AND (seir = 1 OR seir = 2)";
//        	list<list> infected_positions <- self.select(query, [myself.run_id, day * CYCLES_IN_ONE_DAY]);
//        	
//        	if (!empty(infected_positions) and !empty(infected_positions[2])) {
//            	loop infected_pos over: infected_positions[2] {
//                	point infected_location <- {float(infected_pos[0]), float(infected_pos[1])};
//                
//                	ask TransmitDiseasePig {
//                    	if (seir = 0) {
//                        	float dist <- infected_location distance_to self.location;
//                        	if (dist < 5.0 and !(pigs_to_infect contains self.id)) {
//                            	add self.id to: pigs_to_infect;
//                        	}
//                    	}
//                	}
//            	}
//        	}
//    	}
//    	
//    	// Apply infections after gathering all affected pigs
//    	loop pig_id over: pigs_to_infect {
//        	do attach_disease_to_pig(pig_id);
//    	}
//	}

	action check_neighbor_pig_positions_left(int day) {
    	if (day <= 0) { return; }
    	
    	// First check if neighbors have disease 
    	do check_neighbor_states(day);
    	
    	if (!has_disease_in_neighbor_left) { return; }
    	
    	// Then check pig positions in current pen
    	float b <- rnd(0.402, 1.85);
    	list<int> pigs_to_infect <- [];
    	
    	ask db_helper {
        	string query <- "SELECT DISTINCT pig_id FROM pig_movement_history " +
            	           "WHERE run_id = ? AND pigpen_id = ? " +
                	       "AND cycle <= ? AND cycle >= ? AND x <= 2.0";
                       
        	list<list> boundary_pigs <- self.select(DB_PARAMS, query, [myself.run_id, int(myself.pigpen_id), 
            	                                   day * CYCLES_IN_ONE_DAY, (day - 1) * CYCLES_IN_ONE_DAY]);
        
        	if (!empty(boundary_pigs[2])) {
            	loop pig_pos over: boundary_pigs[2] {
                	int pig_id <- int(pig_pos[0]);
                	loop pig over: TransmitDiseasePig {
                    	if (pig.id = pig_id and pig.seir = 0 and flip(1 - e ^ -b) and !(pigs_to_infect contains pig_id)) {
                        	pigs_to_infect <- pigs_to_infect + [pig_id];
                    	}
                	}
            	}
        	}
    	}
    	
    	// Infect the pigs that were near boundary
    	if (!empty(pigs_to_infect)) {
        	int random_index <- rnd(length(pigs_to_infect) - 1);
        	do attach_disease_to_pig(pigs_to_infect[random_index]);
    	}
	}

	
	action check_neighbor_pig_positions_right(int day) {
    	if (day <= 0) { return; }
    	
    	// First check if neighbors have disease
    	do check_neighbor_states(day);
    	
    	if (!has_disease_in_neighbor_right) { return; }
    	
    	// Then check pig positions in current pen
    	float b <- rnd(0.402, 1.85);
    	list<int> pigs_to_infect <- [];
    
    	ask db_helper {
        	string query <- "SELECT DISTINCT pig_id FROM pig_movement_history " +
            	           "WHERE run_id = ? AND pigpen_id = ? " +
                	       "AND cycle <= ? AND cycle >= ? AND x >= 93.0";
                       
        	list<list> boundary_pigs <- self.select(DB_PARAMS, query,
        		[myself.run_id, int(myself.pigpen_id), day * CYCLES_IN_ONE_DAY, (day - 1) * CYCLES_IN_ONE_DAY]
        	);
        	
        	if (!empty(boundary_pigs[2])) {
            	loop pig_pos over: boundary_pigs[2] {
                	int pig_id <- int(pig_pos[0]);
					loop pig over: TransmitDiseasePig {
						if (pig.id = pig_id and pig.seir = 0 and flip(1 - e ^ -b) and !(pigs_to_infect contains pig_id)) {
							pigs_to_infect <- pigs_to_infect + [pig_id];
						}
					}
            	}
        	}
    	}
    	
    	// Infect the pigs that were near boundary
    	if (!empty(pigs_to_infect)) {
        	int random_index <- rnd(length(pigs_to_infect) - 1);
        	do attach_disease_to_pig(pigs_to_infect[random_index]);
    	}
	}
    
    reflex daily when: mod(cycle, CYCLES_IN_ONE_DAY) = 0 {
        int current_day <- int(cycle / CYCLES_IN_ONE_DAY);
        
        // Update disease counts
        do count_disease_states();
        dead_pig_count <- total_pigs - unexposed_pig_count - exposed_pig_count - infected_pig_count - recovered_pig_count;
        
        // Save state and synchronize
        do save_daily_state(current_day);
        do save_pig_daily_data(current_day);
//        do save_position_changes();
        
//        if (length(neighbor_ids) > 0) { 
////            do check_neighbor_states(current_day);
//            do check_neighbor_pig_positions_left(current_day - 1);
//            do check_neighbor_pig_positions_right(current_day - 1);
//        }
        do wait_for_cycle_completion(cycle);
        
        // Check neighbors and schedule disease if needed
        if (length(neighbor_ids) > 0) { 
            do check_neighbor_states(current_day);
            do check_neighbor_pig_positions_left(current_day);
            do check_neighbor_pig_positions_right(current_day);
        }
        if (has_disease_in_neighbors and !is_affected_by_neighbor_pen) {
            scheduled_disease_appearance_day <- current_day + 1;
            is_affected_by_neighbor_pen <- true;
        }
        
        // Handle scheduled disease appearance
        if (current_day = scheduled_disease_appearance_day) {
            do attach_disease_to_random_pig();
        }
    }
    
    reflex disease_transmit {
    	float b <- rnd(0.402, 1.85);
    	list<int> pigs_to_infect <- [];
    	
    	int current_day <- int(cycle / CYCLES_IN_ONE_DAY);
    	if (current_day = scheduled_disease_appearance_day) {
    		bool affected <- false;
            loop pig over: TransmitDiseasePig {
            	if (pig.location.x <= 2 and pig.seir = 0 and flip(1 - e ^ -b) and !affected) {
            		create TransmitDiseaseConfig number: 1 returns: configs;
        			ask configs[0] {
            			do create_factor_and_attach_to(pig);
        			}
        			affected <- true;
            	}
            }
        }
        
        if (!empty(pigs_to_infect)) {
        	int random_index <- rnd(length(pigs_to_infect) - 1);
        	do attach_disease_to_pig(pigs_to_infect[random_index]);
    	}
    }
    
    reflex stop when: cycle = final_step {
        do pause;
    }
}

experiment MultiSimulation {
    parameter "Run_id" var: run_id <- 28;
    parameter "Final_step" var: final_step <- 150 * 24 * 55;
    parameter "Pigpen_id" var: pigpen_id <- "2";
    parameter "Neighbor_ids" var: neighbor_ids <- "1";
    parameter "All_pigpen_ids" var: all_pigpen_ids <- "";
    parameter "Pig_ids" var: pig_ids <- "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19";
    parameter "Init_disease_appear_day" var: init_disease_appear_day <- -1;
    
    output {
		display Simulator name: "Pigpen" {
    		grid Background border: (infected_pig_count > 0 or exposed_pig_count > 0) ? #darkorange : #transparent;
    		species TransmitDiseasePig aspect: base;
    		species TransmitDiseaseAgent aspect: base;
    	
    		overlay position: {2, 2} size: {10, 5} background: #black transparency: 1 {
        		draw "Pigpen " + pigpen_id at: {0, 20} color: #black font: font("Arial", 20, #plain);
        	
        		int total_minutes <- (cycle - (cycle mod 45));
        		int current_minutes <- (total_minutes mod 60);
	        	int current_hours <- (total_minutes / 60) mod 24;
    	    	int current_days <- int(total_minutes / (24 * 60));
        	
        		string time_display <- "Day " + current_days + ", " + 
            		(current_hours < 10 ? "0" : "") + current_hours + ":" + 
            		(current_minutes < 10 ? "0" : "") + current_minutes;
            	
        		draw time_display at: {0, 60} color: #black font: font("Arial", 14, #plain);
        		draw "Unexposed: " + unexposed_pig_count at: {1, 85} color: #black font: font("Arial", 14, #plain);
        		draw "Exposed: " + exposed_pig_count at: {1, 115} color: rgb(255, 150, 0) font: font("Arial", 14, #plain);
        		draw "Infected: " + infected_pig_count at: {1, 145} color: #red font: font("Arial", 14, #plain);
        		draw "Recovered: " + recovered_pig_count at: {1, 175} color: #green font: font("Arial", 14, #plain);
        		draw "Dead: " + dead_pig_count at: {1, 205} color: #gray font: font("Arial", 14, #plain);
        	
        		if (infected_pig_count > 0 or exposed_pig_count > 0) {
            		draw "DISEASE DETECTED!" at: {2, 235} color: #red font: font("Arial", 12, #bold);
        		}
    		}
		}
        
        display CFI name: "CFI" refresh: every((60 * 24) #cycles) {
            chart "CFI" type: series {
                loop pig over: TransmitDiseasePig {
                    data string(pig.id) value: pig.cfi;
                }
            }
        }
        
        display Weight name: "Weight" refresh: every((60 * 24) #cycles) {
            chart "Weight" type: histogram {
                loop pig over: TransmitDiseasePig {
                    data string(pig.id) value: pig.weight;
                }
            }
        }
        
        display CFIPig0 name: "CFIPig0" refresh: every((60 * 24) #cycles) {
            chart "CFI vs Target CFI" type: series {
                data 'CFI' value: TransmitDiseasePig[0].cfi;
                data 'Target CFI' value: TransmitDiseasePig[0].target_cfi;
            }
        }
        
        display DFIPig0 name: "DFIPig0" refresh: every((60 * 24) #cycles) {
            chart "DFI vs Target DFI" type: series {
                data 'DFI' value: TransmitDiseasePig[0].dfi;
                data 'Target DFI' value: TransmitDiseasePig[0].target_dfi;
            }
        }
    }
}
