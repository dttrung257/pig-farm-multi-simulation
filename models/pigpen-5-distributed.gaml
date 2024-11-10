/**
* Name: Pigpen1WithDB
* Author: Đặng Thành Trung
* Description: Pigpen 1 implementation using database synchronization
*/

model MultiSimulator

import "base-pigpen-model.gaml"
import "transmit-disease-config.gaml"
import "transmit-disease-pig.gaml"
import "config.gaml"

global parent: BasePigpenModel {
    file pigs;
    int final_step;
    int dead_pig_count <- 0;
    
    init {
        // Set pigpen specific values
        pigpen_id <- "5";
        neighbor_ids <- "4,6";
        all_pigpen_ids <- "1,2,3,4,5,6";
        
        // Setup database helper
        // current_run_id <- 1;
        do setup_database();
        
        // Initialize pigpen
        pigs <- csv_file("../includes/input/transmit-disease-pigs.csv", true);
        total_pigs <- length(pigs);
        unexposed_pig_count <- 0;
		exposed_pig_count <- 0;
		infected_pig_count <- 0;
		recovered_pig_count <- 0;
        
        create TransmitDiseasePig from: pigs;
        create Trough number: 5;
        loop i from: 0 to: 4 {
            Trough[i].location <- trough_locs[i];
        }

//        create TransmitDiseaseConfig number: 1;
//        TransmitDiseaseConfig[0].day <- 1;

        is_affected_by_neighbor_pen <- false;
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
        do wait_for_cycle_completion(cycle);
        
        // Check neighbors and schedule disease if needed
        do check_neighbor_states(current_day);
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

experiment Pigpen5 {
    parameter "Run ID" var: current_run_id <- 1;
    parameter "Experiment ID" var: experiment_id <- "";
    parameter "Final Step" var: final_step <- 60 * 24 * 55;
    
    output {
        display Simulator name: "Simulator" {
            grid Background border: (infected_pig_count > 0 or exposed_pig_count > 0) ? #darkorange : #transparent;
            species TransmitDiseasePig aspect: base;
            
            overlay position: {2, 2} size: {10, 5} background: #black transparency: 1 {
                int current_minutes <- cycle mod 60;
                int current_hours <- (cycle / 60) mod 24;
                int current_days <- int(cycle / (24 * 60));
                
                string time_display <- "Day " + current_days + ", " + 
                    (current_hours < 10 ? "0" : "") + current_hours + ":" + 
                    (current_minutes < 10 ? "0" : "") + current_minutes;
                    
                draw time_display at: {0, 2} color: #black font: font("Arial", 14, #plain);
                draw "Unexposed: " + unexposed_pig_count at: {1, 35} color: #black font: font("Arial", 14, #plain);
                draw "Exposed: " + exposed_pig_count at: {1, 65} color: rgb(255, 150, 0) font: font("Arial", 14, #plain);
                draw "Infected: " + infected_pig_count at: {1, 95} color: #red font: font("Arial", 14, #plain);
                draw "Recovered: " + recovered_pig_count at: {1, 125} color: #green font: font("Arial", 14, #plain);
                draw "Dead: " + dead_pig_count at: {1, 155} color: #gray font: font("Arial", 14, #plain);
                
                if (infected_pig_count > 0 or exposed_pig_count > 0) {
                    draw "DISEASE DETECTED!" at: {2, 185} color: #red font: font("Arial", 12, #bold);
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
