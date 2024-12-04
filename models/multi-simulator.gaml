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
    
    init {
        // This flag is used to run sync or async simulation
        if (length(neighbor_ids) > 0) {
            sync <- true;
        } else {
            sync <- false;
        }
        
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
    
    reflex daily when: mod(cycle, CYCLES_IN_ONE_DAY) = 0 {
        int current_day <- int(cycle / CYCLES_IN_ONE_DAY);
        
        // Update disease counts
        do count_disease_states();
        dead_pig_count <- total_pigs - unexposed_pig_count - exposed_pig_count - infected_pig_count - recovered_pig_count;
        
        // Save state and synchronize
        do save_daily_state(current_day);
        do save_pig_daily_data(current_day);
        do wait_for_cycle_completion(cycle);
        
        // Check neighbors and schedule disease if needed
        if (length(neighbor_ids) > 0) { 
            do check_neighbor_states(current_day);
        }
        if (has_disease_in_neighbors and !is_affected_by_neighbor_pen) {
            scheduled_disease_appearance_day <- current_day + rnd(1,3);
            is_affected_by_neighbor_pen <- true;
        }
        
        // Handle scheduled disease appearance
        if (current_day = scheduled_disease_appearance_day) {
            do attach_disease_to_random_pig();
        }
    }
    
    reflex stop when: cycle = final_step {
        do pause;
    }
}

experiment MultiSimulation {
    parameter "Run_id" var: run_id <- 1;
    parameter "Final_step" var: final_step <- 150 * 24 * 55;
    parameter "Pigpen_id" var: pigpen_id <- "1";
    parameter "Neighbor_ids" var: neighbor_ids <- "";
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
