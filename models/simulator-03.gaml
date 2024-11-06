model Simulator


import './food-disease-config.gaml'
import './food-disease-pig.gaml'


global {
	file pigs;
	int speed;
	string experiment_id;
	
    init {
    	pigs <- csv_file("../includes/input/food-disease-pigs.csv", true);
    	
    	speed <- 45;
    	
    	
    	create FoodDiseasePigDC from: pigs;
        create Trough number: 5;
        loop i from: 0 to: 4 {
        	Trough[i].location <- trough_locs[i];
        }
        create FoodDiseaseConfig number: 1;
        FoodDiseaseConfig[0].day <- 14;
    }
    
    reflex stop when: cycle = 60 * 24 * 55 {
    	do pause;
    }
}

experiment DC {
	parameter "Experiment ID" var: experiment_id <- "";
    output {
        display Simulator name: "Simulator" {
            grid Background border: #black;
            species FoodDiseasePigDC aspect: base;
        }
        display CFI name: "CFI" refresh: every((60 * 24)#cycles) {
        	chart "CFI" type: series {
        		loop pig over: FoodDiseasePigDC {
        			data string(pig.id) value: pig.cfi;
        		}
        	}
        }
        display Weight name: "Weight" refresh: every((60 * 24)#cycles) {
        	chart "Weight" type: histogram {
        		loop pig over: FoodDiseasePigDC {
        			data string(pig.id) value: pig.weight;
        		}
        	}
        }
        display CFIPig0 name: "CFIPig0" refresh: every((60 * 24)#cycles) {
        	chart "CFI vs Target CFI" type: series {
        		data 'CFI' value: FoodDiseasePigDC[0].cfi;
        		data 'Target CFI' value: FoodDiseasePigDC[0].target_cfi;
        	}
        }
        display DFIPig0 name: "DFIPig0" refresh: every((60 * 24)#cycles) {
        	chart "DFI vs Target DFI" type: series {
        		data 'DFI' value: FoodDiseasePigDC[0].dfi;
        		data 'Target DFI' value: FoodDiseasePigDC[0].target_dfi;
        	}
        }
    }
    
    reflex log when: mod(cycle, 24 * 60) = 0 {
    	ask simulations {
    		loop pig over: FoodDiseasePigDC {
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
    				pig.excrete_count,
    				pig.expose_count_per_day,
    				pig.recover_count
    			] to: "../includes/output/dc/" + experiment_id + "-" + string(pig.id) + ".csv" rewrite: false format: "csv";	
    		}
		}		
    }
    
    reflex capture when: mod(cycle, speed) = 0 {
    	ask simulations {
    		save (snapshot(self, "Simulator", {500.0, 500.0})) to: "../includes/output/dc/" + experiment_id + "-simulator-" + string(cycle) + ".png";
    		save (snapshot(self, "CFI", {500.0, 500.0})) to: "../includes/output/dc/" + experiment_id + "-cfi-" + string(cycle) + ".png";
    		save (snapshot(self, "Weight", {500.0, 500.0})) to: "../includes/output/dc/" + experiment_id + "-weight-" + string(cycle) + ".png";
    		save (snapshot(self, "CFIPig0", {500.0, 500.0})) to: "../includes/output/dc/" + experiment_id + "-cfipig0-" + string(cycle) + ".png";
    		save (snapshot(self, "DFIPig0", {500.0, 500.0})) to: "../includes/output/dc/" + experiment_id + "-dfipig0-" + string(cycle) + ".png";
    	}
    }
}
