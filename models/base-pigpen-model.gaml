/**
* Name: BasePigpenModel 
* Author: Đặng Thành Trung
* Description: Base model for pigpen simulations with shared functionality
*/
model BasePigpenModel

import "./database-helper.gaml"
import './transmit-disease-pig.gaml'
import "./database-helper.gaml"

global {
	// Database related
	int run_id;
	bool sync;
	DatabaseHelper db_helper;

	// Pigpen identification
	string pigpen_id;
	string experiment_id;
	string neighbor_ids;
	string all_pigpen_ids;
//	string pig_ids;

	// Common metrics
	int unexposed_pig_count;
	int exposed_pig_count;
	int infected_pig_count;
	int recovered_pig_count;
	int total_pigs;

	// Neighbor state tracking
	int neighbor_unexposed_pigs_count;
	int neighbor_exposed_pigs_count;
	int neighbor_infected_pigs_count;
	int neighbor_recovered_pigs_count;

	// Disease management
	bool has_disease_in_neighbors;
	bool is_affected_by_neighbor_pen;
	int scheduled_disease_appearance_day;

	action setup_database {
		create DatabaseHelper returns: helpers;
		db_helper <- helpers[0];
	}

	action wait_for_cycle_completion (int cycle_number) {
		if (mod(cycle_number, CYCLES_IN_ONE_DAY) = 0) {
			// Mark current cycle as complete
			ask db_helper {
				do mark_cycle_complete(myself.run_id, int(myself.pigpen_id), cycle_number);
			}

			// Wait for all pigpens to complete
			bool can_proceed <- false;
			loop while: (!can_proceed and sync) {
				ask db_helper {
					can_proceed <- self.are_all_pigpens_complete(myself.run_id, cycle_number, (myself.all_pigpen_ids split_with ","));
				}

			}
		}

	}

	action check_neighbor_states (int day) {
		list<string> neighbor_list <- neighbor_ids split_with ",";
		ask db_helper {
			list<list> states <- get_neighbor_states(myself.run_id, neighbor_list, day);

			// Reset counts
			myself.neighbor_unexposed_pigs_count <- 0;
			myself.neighbor_exposed_pigs_count <- 0;
			myself.neighbor_infected_pigs_count <- 0;
			myself.neighbor_recovered_pigs_count <- 0;

			// Process results only if we have data rows
			if (length(states) >= 3 and !empty(states[2])) {
				loop state over: states[2] { // Access the data rows
					myself.neighbor_unexposed_pigs_count <- myself.neighbor_unexposed_pigs_count + int(state[1]);
					myself.neighbor_exposed_pigs_count <- myself.neighbor_exposed_pigs_count + int(state[2]);
					myself.neighbor_infected_pigs_count <- myself.neighbor_infected_pigs_count + int(state[3]);
					myself.neighbor_recovered_pigs_count <- myself.neighbor_recovered_pigs_count + int(state[4]);
				}

			}

			myself.has_disease_in_neighbors <- myself.neighbor_exposed_pigs_count > 0;
		}

	}
	
	action save_pig_daily_data(int day) {
    	loop pig over: TransmitDiseasePig {
        	ask db_helper {
            	do save_pig_data_daily(
                	myself.run_id, 
                	int(myself.pigpen_id),
                	day,
                	pig.id,
                	pig.dfi,
                	pig.cfi,
                	pig.target_cfi,
                	pig.target_dfi,
                	pig.weight,
                	pig.eat_count,
                	pig.excrete_count,
                	pig.seir
            	);
        	}
    	}
	}


	action save_daily_state (int day) {
		ask db_helper {
			do
			save_pigpen_state(myself.run_id, int(myself.pigpen_id), day, myself.total_pigs, myself.unexposed_pig_count, myself.exposed_pig_count, myself.infected_pig_count, myself.recovered_pig_count);
		}

	}

	// Helper function to count disease states - should be called before saving state
	action count_disease_states {
		unexposed_pig_count <- 0;
		exposed_pig_count <- 0;
		infected_pig_count <- 0;
		recovered_pig_count <- 0;
		ask TransmitDiseasePig {
			switch self.seir {
				match UNEXPOSED_STATUS {
					myself.unexposed_pig_count <- myself.unexposed_pig_count + 1;
				}

				match EXPOSED_STATUS {
					myself.exposed_pig_count <- myself.exposed_pig_count + 1;
				}

				match INFECTED_STATUS {
					myself.infected_pig_count <- myself.infected_pig_count + 1;
				}

				match RECOVERED_STATUS {
					myself.recovered_pig_count <- myself.recovered_pig_count + 1;
				}

			}

		}

	}

}
