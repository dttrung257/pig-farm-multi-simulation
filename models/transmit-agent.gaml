/**
* Name: Pig
*/


model Pig


import './config.gaml'
import './trough.gaml'
import './farm.gaml'

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
 * ID | Name    | Duration     | Next
 * --------------------------------------------------
 * 0  | relax   | relax_time   | go_in: [0, 1]
 * 1  | go-in   | 0            | wait: [2]
 * 2  | wait    | 0            | eat: [2, 3]
 * 3  | eat     | eat_time     | go_out: [4]
 * 4  | go-out  | 0            | relax_after_eat: [5]
 * 5  | relax   | satiety_time | drink: [6, 7]
 * 6  | drink   | 1            | relax_after_drink: [7]
 * 7  | relax   | 0            | excrete: [8, 0]
 * 8  | excrete | excrete_time | relax_after_excrete: [0]
 * 9  | die     |
*/

species Pig {
    int id;

    aspect base {
        draw circle(1.6) color: #pink;
        draw string(id) color: #black size: 5;
    }

    init {
        location <- get_relax_loc();
    }
    
    /**
     * Get location functions
     */
    point get_relax_loc {
    	return { rnd(60.0, 95.0), rnd(60.0, 95.0) };
    }
    /*****/
    
    action eat {
    	ask Trough {
            if(add_pig(myself)) {
            	myself.location <- location;
	            break;
            }
        }
    }
    
    action relax_after_eat {
    	location <- get_relax_loc();
    }
}
