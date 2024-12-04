/**
 * Name: DatabaseHelper 
 * Author: Đặng Thành Trung
 * Description: Complete database helper with business logic using AgentDB
 */

model DatabaseHelper

import "./database-util.gaml"

species DatabaseHelper2 parent: DatabaseUtil {
    
    // Execute operation safely
    action execute_safely(string operation) {
        if (!ensure_connection()) { return; }
        
        switch operation {
            match "count_complete" {
                do count_complete_cycles();
            }
        }
    }
    
    // Get sync status for all pigpens at a cycle  
    list<list> get_sync_status(int run_id, int cycle_number) {
        if (!ensure_connection()) {
            return [["pigpen_id", "is_complete"], ["int", "bool"], []];
        }
        
        list<list> result <- db_fetch(
            "pigpen_sync_runs",
            ["pigpen_id", "is_complete"], 
            ["run_id"::run_id, "cycle"::cycle_number]
        );
        
        if (empty(result)) {
            return [["pigpen_id", "is_complete"], ["int", "bool"], []];
        }
        return result;
    }
    
    // Mark cycle as complete for a pigpen
    action mark_cycle_complete(int run_id, int pigpen_id, int cycle_number) {
        if (!ensure_connection()) { return; }
        
        try {
            list<list> existing <- db_fetch(
                "pigpen_sync_runs",
                ["id"],
                ["run_id"::run_id, "pigpen_id"::pigpen_id, "cycle"::cycle_number]  
            );
            
            if (empty(existing[2])) {
                do db_insert(
                    "pigpen_sync_runs",
                    ["run_id"::run_id, "pigpen_id"::pigpen_id, "cycle"::cycle_number, "is_complete"::true]
                );
            } else {
                do db_update(
                    "pigpen_sync_runs",
                    ["is_complete"::true],
                    ["run_id"::run_id, "pigpen_id"::pigpen_id, "cycle"::cycle_number]
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
        
        if (!ensure_connection()) { return; }
        
        try {
            map<string,unknown> conditions <- ["run_id"::run_id, "pigpen_id"::pigpen_id, "day"::day];
            list<list> existing <- db_fetch("pigpen_daily", ["id"], conditions);
            
            map<string,unknown> data <- [
                "total_pigs"::total_pigs,
                "unexposed_count"::unexposed,
                "exposed_count"::exposed,
                "infected_count"::infected,
                "recovered_count"::recovered
            ];
            
            if (empty(existing) or empty(existing[2])) {
                do db_insert("pigpen_daily", data + conditions);
            } else {
                do db_update("pigpen_daily", data, conditions);
            }
        } catch {
            write "ERROR: Failed to save pigpen state in database";
            is_connected <- false;
        }
    }
    
    // Save pig data daily
    action save_pig_data_daily(int run_id, int pigpen_id, int day, int pig_id, float dfi,
        float cfi, float target_cfi, float target_dfi, float weight, int eat_count,
        int excrete_count, int seir) {
        
        if (!ensure_connection()) { return; }
        
        try {
            map<string,unknown> conditions <- [
                "run_id"::run_id,
                "pigpen_id"::pigpen_id, 
                "day"::day,
                "pig_id"::pig_id
            ];
            
            list<list> existing <- db_fetch("pig_data_daily", ["id"], conditions);
            
            map<string,unknown> data <- [
                "weight"::weight,
                "cfi"::cfi,
                "dfi"::dfi,
                "target_cfi"::target_cfi,
                "target_dfi"::target_dfi,
                "eat_count"::eat_count,
                "excrete_count"::excrete_count,
                "seir"::seir
            ];
            
            if (empty(existing) or empty(existing[2])) {
                do db_insert("pig_data_daily", data + conditions);
            } else {
                do db_update("pig_data_daily", data, conditions); 
            }
        } catch {
            write "ERROR: Failed to save pig data in database";
            is_connected <- false;
        }
    }

    // Get neighbor states for specific day
    list<list> get_neighbor_states(int run_id, list<string> neighbor_ids, int day) {
        if (!ensure_connection()) {
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
            
            list<list> result <- db_fetch(
                "pigpen_daily",
                ["pigpen_id", "unexposed_count", "exposed_count", "infected_count", "recovered_count"],
                ["run_id"::run_id, "day"::day]
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
    
    // Check if all pigpens completed a cycle
    bool are_all_pigpens_complete(int run_id, int cycle_number, list<string> all_pigpen_ids) {
        if (!ensure_connection()) { return false; }
        
        try {
            list<list> results <- db_fetch(
                "pigpen_sync_runs",
                ["COUNT(*) as complete_count"],
                ["run_id"::run_id, "cycle"::cycle_number, "is_complete"::true]
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
    
    // Count complete cycles
    action count_complete_cycles {
        if (!ensure_connection()) { return; }
        
        try {
            list<list> results <- db_fetch(
                "pigpen_sync_runs",
                ["COUNT(DISTINCT cycle) as count"],
                ["is_complete"::true]
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
