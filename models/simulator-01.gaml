/**
* Name: Simulator
*/


model Simulator


import './farm.gaml'
import './pig.gaml'


global {
	int speed;
	string experiment_id;
	
    init {
    	file pigs <- csv_file("../includes/input/pigs.csv", true);
    	speed <- 45;
    	
    	create Pig from: pigs;
        create Trough number: 5;
        loop i from: 0 to: 4 {
        	Trough[i].location <- trough_locs[i];
        }
    }
    
    reflex stop when: cycle = 60 * 24 * 120 {
    	do pause;
    }
}

experiment Normal {
	parameter "Experiment ID" var: experiment_id <- "";
    output {
        display Simulator name: "Simulator" {
            grid Background border: #black;
            species Pig aspect: base;
            
            overlay position: {2, 2} size: {10, 5} background: #black transparency: 1 {
                int current_minutes <- cycle mod 60;
                int current_hours <- (cycle / 60) mod 24;
                int current_days <- int(cycle / (24 * 60));
                
                string time_display <- "Day " + current_days + ", " + 
                    (current_hours < 10 ? "0" : "") + current_hours + ":" + 
                    (current_minutes < 10 ? "0" : "") + current_minutes;
                    
                draw time_display at: {0, 2} color: #black font: font("Arial", 14, #plain);
            }
        }
        display CFI name: "CFI" refresh: every((60 * 24)#cycles) {
        	chart "CFI" type: series {
        		loop pig over: Pig {
        			data string(pig.id) value: pig.cfi;
        		}
        	}
        }
        display Weight name: "Weight" refresh: every((60 * 24)#cycles) {
        	chart "Weight" type: histogram {
        		loop pig over: Pig {
        			data string(pig.id) value: pig.weight;
        		}
        	}
        }
        display CFIPig0 name: "CFIPig0" refresh: every((60 * 24)#cycles) {
        	chart "CFI vs Target CFI" type: series {
        		data 'CFI' value: Pig[0].cfi;
        		data 'Target CFI' value: Pig[0].target_cfi;
        	}
        }
        display DFIPig0 name: "DFIPig0" refresh: every((60 * 24)#cycles) {
        	chart "DFI vs Target DFI" type: series {
        		data 'DFI' value: Pig[0].dfi;
        		data 'Target DFI' value: Pig[0].target_dfi;
        	}
        }
    }
    
    reflex log when: mod(cycle, 24 * 60) = 0 {
    	ask simulations {
    		loop pig over: Pig {
    			save [
    				floor(cycle / (24 * 60)),
    				pig.id,
    				pig.target_dfi,
    				pig.dfi,
    				pig.target_cfi,
    				pig.cfi,
    				pig.weight,
    				pig.eat_count,
    				pig.excrete_each_day,
    				pig.excrete_count
    			] to: "../includes/output/normal/" + experiment_id + "-"  + string(pig.id) + ".csv" rewrite: false format: "csv";	
    		}
		}
    }
    
    reflex capture when: mod(cycle, 45) = 0 {
    	ask simulations {
    		save (snapshot(self, "Simulator", {500.0, 500.0})) to: "../includes/output/normal/" + experiment_id + "-simulator-" + string(cycle) + ".png";
    		save (snapshot(self, "CFI", {500.0, 500.0})) to: "../includes/output/normal/" + experiment_id + "-cfi-" + string(cycle) + ".png";
    		save (snapshot(self, "Weight", {500.0, 500.0})) to: "../includes/output/normal/" + experiment_id + "-weight-" + string(cycle) + ".png";
    		save (snapshot(self, "CFIPig0", {500.0, 500.0})) to: "../includes/output/normal/" + experiment_id + "-cfipig0-" + string(cycle) + ".png";
    		save (snapshot(self, "DFIPig0", {500.0, 500.0})) to: "../includes/output/normal/" + experiment_id + "-dfipig0-" + string(cycle) + ".png";
    	}
    }
}
