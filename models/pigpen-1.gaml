/**
* Name: pigpen1
* Based on the internal empty template. 
* Author: trungdt
* Tags: 
*/

/**
* Name: Simulator
* Author: Dang Thanh Trung
*/
model Simulator

import './transmit-disease-config.gaml'
import './transmit-disease-pig.gaml'
import './config.gaml'

global {
	file pigs;
	string pigpen_id;
	string experiment_id;
	string neighbor_ids;
	string all_pigpen_ids;
	string root_output_dir;
	string output_dir;
	int day;
	int final_step;
	int unexposed_pig_count;
	int exposed_pig_count;
	int infected_pig_count;
	int recovered_pig_count;
	int total_pigs;
	int neighbor_unexposed_pigs_count;
	int neighbor_exposed_pigs_count;
	int neighbor_infected_pigs_count;
	int neighbor_recovered_pigs_count;
	int dead_pig_count;
	int scheduled_disease_appearance_day;
	bool has_cleaned_output_dir;
	bool has_disease_in_neighbors;
	bool is_affected_by_neighbor_pen;

	// synchronize variables
	bool is_cycle_complete <- false;
	bool can_proceed <- false;

	init {
		pigpen_id <- "1";
		neighbor_ids <- "2";
		all_pigpen_ids <- "1,2,3";
		root_output_dir <- "../includes/output/multi_simulation";
		pigs <- csv_file("../includes/input/transmit-disease-pigs.csv", true);
		total_pigs <- length(pigs);
		unexposed_pig_count <- 0;
		exposed_pig_count <- 0;
		infected_pig_count <- 0;
		recovered_pig_count <- 0;
		dead_pig_count <- 0;
		scheduled_disease_appearance_day <- -1;
		create TransmitDiseasePig from: pigs;
		create Trough number: 5;
		loop i from: 0 to: 4 {
			Trough[i].location <- trough_locs[i];
		}

		create TransmitDiseaseConfig number: 1;
		TransmitDiseaseConfig[0].day <- 1;
		is_affected_by_neighbor_pen <- true;
	}

	reflex stop when: cycle = final_step {
		do pause;
	}

	action create_disease_agent {
		create TransmitDiseaseConfig number: 1;
		TransmitDiseaseConfig[0].day <- get_current_day();
	}

	action attach_disease_to_random_pig {
		int random_disease_pig_index <- rnd(0, total_pigs - 1);
		create TransmitDiseaseConfig number: 1 returns: configs;
		ask configs[0] {
			do create_factor_and_attach_to(TransmitDiseasePig[random_disease_pig_index]);
		}

	}

	action schedule_disease_onset {
		if (get_current_day() = scheduled_disease_appearance_day) {
			do attach_disease_to_random_pig();
		}

	}

	action set_schedule_day (int target_day) {
		scheduled_disease_appearance_day <- target_day;
	}

	bool has_summary_file (string neighbor_id) {
		string neighbor_file <- root_output_dir + "/" + neighbor_id + "/" + experiment_id + "-summary.csv";
		return file_exists(neighbor_file);
	}

	list<int> get_neighbor_states {
		list<int> total_counts <- [0, 0, 0, 0];
		if length(neighbor_ids) > 0 {
			list<string> neighbor_id_list <- neighbor_ids split_with ",";
			loop neighbor_id over: neighbor_id_list {
				string neighbor_file <- root_output_dir + "/" + neighbor_id + "/" + experiment_id + "-summary.csv";
				if file_exists(neighbor_file) {
					file neighbor_state_file <- csv_file(neighbor_file, ",", true);
					matrix data <- matrix(neighbor_state_file);
					int last_index <- length(data) - 1;
					if (last_index < 5) {
						return;
					}

					loop item_index from: 0 to: last_index {
						if (mod(item_index, 6) = 0 and int(data[item_index]) = get_current_day()) {
							total_counts[0] <- total_counts[0] + int(data[item_index + 2]);
							total_counts[1] <- total_counts[1] + int(data[item_index + 3]);
							total_counts[2] <- total_counts[2] + int(data[item_index + 4]);
							total_counts[3] <- total_counts[3] + int(data[item_index + 5]);
							break;
						}

					}

				}

			}

		}

		return total_counts;
	}

	action check_neighbor_daily {
		list<int> neighbor_data <- get_neighbor_states();
		neighbor_unexposed_pigs_count <- neighbor_data[0];
		neighbor_exposed_pigs_count <- neighbor_data[1];
		neighbor_infected_pigs_count <- neighbor_data[2];
		neighbor_recovered_pigs_count <- neighbor_data[3];
		has_disease_in_neighbors <- neighbor_exposed_pigs_count > 0;
		if (has_disease_in_neighbors and !is_affected_by_neighbor_pen) {
			do set_schedule_day(get_current_day() + rnd(1, 3));
			is_affected_by_neighbor_pen <- true;
		}

	}

	int get_current_day {
		return int(floor(cycle / CYCLES_IN_ONE_DAY));
	}

	action clear_old_output_dir {
		if (has_cleaned_output_dir) {
			return;
		}

		output_dir <- length(pigpen_id) > 0 ? root_output_dir + "/" + pigpen_id : root_output_dir;
		string sync_dir <- root_output_dir + "/sync/" + pigpen_id;
		bool output_dir_deleted <- delete_file(output_dir);
		bool sync_dir_deleted <- delete_file(sync_dir);
		has_cleaned_output_dir <- true;
	}

	action detect_disease {
		unexposed_pig_count <- 0;
		exposed_pig_count <- 0;
		infected_pig_count <- 0;
		recovered_pig_count <- 0;
		loop pig over: TransmitDiseasePig {
			switch pig.seir {
				match UNEXPOSED_STATUS {
					unexposed_pig_count <- unexposed_pig_count + 1;
				}

				match EXPOSED_STATUS {
					exposed_pig_count <- exposed_pig_count + 1;
				}

				match INFECTED_STATUS {
					infected_pig_count <- infected_pig_count + 1;
				}

				match RECOVERED_STATUS {
					recovered_pig_count <- recovered_pig_count + 1;
				}

			}

		}

		dead_pig_count <- total_pigs - unexposed_pig_count - exposed_pig_count - infected_pig_count - recovered_pig_count;
	}

	action save_pigpen_data {
		unexposed_pig_count <- 0;
		exposed_pig_count <- 0;
		infected_pig_count <- 0;
		recovered_pig_count <- 0;
		loop pig over: TransmitDiseasePig {
			switch pig.seir {
				match UNEXPOSED_STATUS {
					unexposed_pig_count <- unexposed_pig_count + 1;
				}

				match EXPOSED_STATUS {
					exposed_pig_count <- exposed_pig_count + 1;
				}

				match INFECTED_STATUS {
					infected_pig_count <- infected_pig_count + 1;
				}

				match RECOVERED_STATUS {
					recovered_pig_count <- recovered_pig_count + 1;
				}

			}

		}

		save [get_current_day(), total_pigs, unexposed_pig_count, exposed_pig_count, infected_pig_count, recovered_pig_count] to: output_dir + "/" + experiment_id + "-summary.csv"
		rewrite: false format: "csv";
	}

	action save_pig_data {
		loop pig over: TransmitDiseasePig {
			save
			[get_current_day(), pig.id, pig.target_dfi, pig.dfi, pig.target_cfi, pig.cfi, pig.weight, pig.eat_count, pig.excrete_each_day, pig.excrete_count, pig.expose_count_per_day, pig.recover_count, pig.seir]
			to: output_dir + "/" + experiment_id + "-" + string(pig.id) + ".csv" rewrite: false format: "csv";
		}

	}

	action wait_for_others {
		if (cycle > 0 and mod(cycle, CYCLES_IN_ONE_DAY) = 0) {
			// Check pigpen each cycle
			do detect_disease();

			// Daily actions
			if (mod(cycle, CYCLES_IN_ONE_DAY) = 0) {
				do save_pigpen_data();
				do check_neighbor_daily();
				do schedule_disease_onset();
				do save_pig_data();
			}

			is_cycle_complete <- true;
			save "" to: root_output_dir + "/sync/" + pigpen_id + "/cycle_" + cycle + "_flag.txt" rewrite: false format: "csv";
			
			if (cycle = 0) {
				return;
			}
			
			loop while: !can_proceed {
				bool all_complete <- true;
				list<string> pigpen_id_list <- all_pigpen_ids split_with ",";
				loop id over: pigpen_id_list {
					if (int(pigpen_id) = int(id)) {
						continue;
					}
					
					string flag_file <- root_output_dir + "/sync/" + id + "/cycle_" + cycle + "_flag.txt";
					if (!file_exists(flag_file)) {
						all_complete <- false;
						break;
					}

				}

				if (all_complete) {
					can_proceed <- true;
				}

			}

			is_cycle_complete <- false;
			can_proceed <- false;
		}
	}

}

experiment Pigpen1 {
	parameter "Experiment ID" var: experiment_id <- "";
	parameter "Final Step" var: final_step <- 60 * 24 * 55;
	output {
		display Simulator name: "Simulator" {
			grid Background;
			species TransmitDiseasePig aspect: base;
			overlay position: {2, 2} size: {10, 5} background: #black transparency: 1 {
				draw "Day: " + get_current_day() at: {0, 2} color: #black font: font("Arial", 14, #plain);
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

	reflex synchronize {
		ask simulations {
			do clear_old_output_dir();
			do wait_for_others();
		}

	}

	//	reflex capture when: mod(cycle, PLAY_SPEED) = 0 {
	//		ask simulations {
	//			save (snapshot(self, "Simulator", {500.0, 500.0})) to: output_dir + "/" + experiment_id + "-simulator-" + string(cycle) + ".png";
	//			save (snapshot(self, "CFI", {500.0, 500.0})) to: output_dir + "/" + experiment_id + "-cfi-" + string(cycle) + ".png";
	//			save (snapshot(self, "Weight", {500.0, 500.0})) to: output_dir + "/" + experiment_id + "-weight-" + string(cycle) + ".png";
	//			save (snapshot(self, "CFIPig0", {500.0, 500.0})) to: output_dir + "/" + experiment_id + "-cfipig0-" + string(cycle) + ".png";
	//			save (snapshot(self, "DFIPig0", {500.0, 500.0})) to: output_dir + "/" + experiment_id + "-dfipig0-" + string(cycle) + ".png";
	//		}
	//
	//	}

}
