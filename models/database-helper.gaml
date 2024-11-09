/**
* Name: DatabaseHelper
* Author: Đặng Thành Trung
* Description: Helper class for database operations with connection handling
*/

model DatabaseHelper

global {
    // map<string, string> DB_PARAMS <- [  
    //    'host'::'localhost',
    //    'dbtype'::'mysql',
    //    'database'::'agent_simulation',
    //    'port'::'13306', 
    //    'user'::'agsuser',
    //    'passwd'::'agspassword'
    // ];
    map<string, string> DB_PARAMS <- [  
        'host'::'172.30.11.8',
        'dbtype'::'mysql',
        'database'::'agent_simulation',
        'port'::'3306', 
        'user'::'agsuser',
        'passwd'::'2MKf2apdFvdSgFxiIxCt'
    ];
}

species DatabaseHelper skills: [SQLSKILL] {
    bool is_connected <- false;
    
    action ensure_connection {
        if (!is_connected) {
            is_connected <- self.testConnection(DB_PARAMS);
            if (!is_connected) {
                write "WARNING: Could not connect to database. Will retry later.";
            }
        }
    }
    
    action execute_safely (string operation) {
        do ensure_connection();
        if (!is_connected) { return; }
        
        switch operation {
            match "count_complete" {
                do count_complete_cycles();
            }
            // Add other operations as needed
        }
    }
    
    // Get current sync status for all pigpens at a cycle
    list<list> get_sync_status(int run_id, int cycle_number) {
        do ensure_connection();
        if (!is_connected) { 
            return [["pigpen_id", "is_complete"], ["int", "bool"], []];
        }
        
        list<list> result <- select(DB_PARAMS,
            "SELECT pigpen_id, is_complete FROM pigpen_sync_runs WHERE run_id = ? AND cycle = ?",
            [run_id, cycle_number]
        );
        
        if (empty(result)) {
            return [["pigpen_id", "is_complete"], ["int", "bool"], []];
        }
        return result;
    }
    
    // Mark a cycle as complete for a pigpen
    action mark_cycle_complete(int run_id, int pigpen_id, int cycle_number) {
        do ensure_connection();
        if (!is_connected) { return; }
        
        try {
            list<list> existing <- select(DB_PARAMS,
                "SELECT id FROM pigpen_sync_runs WHERE run_id = ? AND pigpen_id = ? AND cycle = ?",
                [run_id, pigpen_id, cycle_number]
            );
            
            if (empty(existing[2])) {
                do insert(DB_PARAMS, 
                    "pigpen_sync_runs",
                    ["run_id", "pigpen_id", "cycle", "is_complete"],
                    [run_id, pigpen_id, cycle_number, true]
                );
            } else {
                do executeUpdate(DB_PARAMS,
                    "UPDATE pigpen_sync_runs SET is_complete = true WHERE run_id = ? AND pigpen_id = ? AND cycle = ?",
                    [run_id, pigpen_id, cycle_number]
                );
            }
        } catch {
            write "ERROR: Failed to mark cycle complete in database";
            is_connected <- false;
        }
    }
    
    // Save daily pigpen state
    action save_pigpen_state(int run_id, int pigpen_id, int day, int total_pigs, 
        int unexposed, int exposed, int infected, int recovered) {
        
        do ensure_connection();
        if (!is_connected) { return; }
        
        try {
            list<list> existing <- select(DB_PARAMS,
                "SELECT id FROM pigpen_daily WHERE run_id = ? AND pigpen_id = ? AND day = ?",
                [run_id, pigpen_id, day]
            );
            
            if (empty(existing) or empty(existing[2])) {
                do insert(DB_PARAMS,
                    "pigpen_daily",
                    ["run_id", "pigpen_id", "day", "total_pigs", "unexposed_count", 
                     "exposed_count", "infected_count", "recovered_count"],
                    [run_id, pigpen_id, day, total_pigs, unexposed, exposed, infected, recovered]
                );
            } else {
                do executeUpdate(DB_PARAMS,
                    "UPDATE pigpen_daily SET total_pigs = ?, unexposed_count = ?, " +
                    "exposed_count = ?, infected_count = ?, recovered_count = ? " +
                    "WHERE run_id = ? AND pigpen_id = ? AND day = ?",
                    [total_pigs, unexposed, exposed, infected, recovered, run_id, pigpen_id, day]
                );
            }
        } catch {
            write "ERROR: Failed to save pigpen state in database";
            is_connected <- false;
        }
    }
    
    // Get neighbor states for a specific day
    list<list> get_neighbor_states(int run_id, list<string> neighbor_ids, int day) {
        do ensure_connection();
        if (!is_connected) { 
            return [
                ["pigpen_id", "unexposed_count", "exposed_count", "infected_count", "recovered_count"],
                ["string", "int", "int", "int", "int"],
                []
            ];
        }
        
        try {
            // Build IN clause for neighbor IDs
            string neighbor_list <- "";
            loop id over: neighbor_ids {
                if (neighbor_list != "") {
                    neighbor_list <- neighbor_list + ",";
                }
                neighbor_list <- neighbor_list + "'" + id + "'";
            }
            
            list<list> result <- select(DB_PARAMS,
                "SELECT pigpen_id, unexposed_count, exposed_count, infected_count, recovered_count " +
                "FROM pigpen_daily " + 
                "WHERE run_id = ? AND day = ? AND pigpen_id IN (" + neighbor_list + ")",
                [run_id, day]
            );
            
            if (empty(result)) {
                return [
                    ["pigpen_id", "unexposed_count", "exposed_count", "infected_count", "recovered_count"],
                    ["string", "int", "int", "int", "int"],
                    []
                ];
            }
            return result;
        } catch {
            write "ERROR: Failed to get neighbor states from database";
            is_connected <- false;
            return [
                ["pigpen_id", "unexposed_count", "exposed_count", "infected_count", "recovered_count"],
                ["string", "int", "int", "int", "int"],
                []
            ];
        }
    }
    
    // Check if all pigpens have completed a cycle
    bool are_all_pigpens_complete(int run_id, int cycle_number, list<string> all_pigpen_ids) {
        do ensure_connection();
        if (!is_connected) {
        	return false;
        }
        
        try {
            list<list> results <- select(DB_PARAMS,
                "SELECT COUNT(*) as complete_count FROM pigpen_sync_runs " +
                "WHERE run_id = ? AND cycle = ? AND is_complete = true",
                [run_id, cycle_number]
            );
            
            if (empty(results) or empty(results[2])) {
                return false;
            }
            
            int complete_count <- int(results[2][0][0]);
            return complete_count = length(all_pigpen_ids);
        } catch {
            write "ERROR: Failed to check cycle completion status";
            is_connected <- false;
            return false;
        }
    }
    
    action count_complete_cycles {
        do ensure_connection();
        if (!is_connected) {
        	return;
        }
        
        try {
            list<list> results <- select(DB_PARAMS,
                "SELECT COUNT(DISTINCT cycle) FROM pigpen_sync_runs WHERE is_complete = true"
            );
            if (!empty(results) and !empty(results[2])) {
                write "Complete cycles: " + results[2][0];
            }
        } catch {
            write "ERROR: Failed to count complete cycles";
            is_connected <- false;
        }
    }
}
