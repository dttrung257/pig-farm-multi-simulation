/** 
* Name: DatabaseUtil
* Author: Đặng Thành Trung 
* Description: Base database utility with config file support using AgentDB
*/

model DatabaseUtil

global {
    map<string, string> DEFAULT_CONFIG <- [  
        'host'::'localhost',
        'dbtype'::'mysql',
        'database'::'ags',
        'port'::'13306', 
        'user'::'agsuser',
        'passwd'::'123'
    ];
}

species DatabaseUtil parent: AgentDB {
    bool is_connected <- false;
    
    init {
        do load_config("../includes/database.conf");
    }
    
    action load_config(string config_path) {
        try {
            file config_file <- text_file(config_path);
            if (config_file.exists) {
                list<string> lines <- config_file.contents;
                
                map<string, string> config;
                loop line over: lines {
                    if (line != "" and (line contains "::")) {
                        list<string> parts <- line split_with "::";
                        if (length(parts) = 2) {
                            string key <- parts[0];
                            string value <- parts[1];
                            // Trim whitespace
                            key <- key replace (" ", "");
                            value <- value replace (" ", "");
                            put value key: key in: config;
                        }
                    }
                }
                
                if (!empty(config)) {
                    do setParameter(params: config);
                    write "Database configuration loaded successfully";
                } else {
                    do setParameter(params: DEFAULT_CONFIG);
                    write "WARNING: Empty config file, using default configuration";
                }
            } else {
                do setParameter(params: DEFAULT_CONFIG);
                write "WARNING: Config file not found at: " + config_path + ", using default configuration";
            }
        } catch {
            do setParameter(params: DEFAULT_CONFIG);
            write "ERROR: Failed to load config file, using default configuration";
        }
    }

    // Helper functions
    string build_column_string(list<string> columns) {
        if (empty(columns)) { return "*"; }
        
        string result <- "";
        loop col over: columns {
            if (result != "") { result <- result + ","; }
            result <- result + col;
        }
        return result;
    }
    
    list build_where_clause(map<string,unknown> conditions) {
        string clause <- "";
        list params <- [];
        
        if (!empty(conditions)) {
            clause <- " WHERE ";
            loop cond over: conditions.keys {
                if (clause != " WHERE ") {
                    clause <- clause + " AND ";
                }
                clause <- clause + cond + " = ?";
                add conditions[cond] to: params;
            }
        }
        
        return [clause, params];
    }
    
    // Database connection handling
    bool ensure_connection {
        if (!is_connected) {
            do connect(params: self.getParameter());
            is_connected <- self.isConnected();
        }
        return is_connected;
    }
    
    // Core database operations
    list<list> db_fetch(string table_name, list<string> columns <- [], map<string,unknown> conditions <- []) {
        if (!ensure_connection()) { return list<list>([[], [], []]); }
        
        try {
            string column_str <- build_column_string(columns);
            list where_info <- build_where_clause(conditions);
            string query <- "SELECT " + column_str + " FROM " + table_name + string(where_info[0]);
            
            return list<list>(self.select(query, list(where_info[1])));
        } catch {
            write "ERROR: Failed to fetch data from " + table_name;
            return list<list>([[], [], []]);
        }
    }
    
    bool db_insert(string table_name, map<string,unknown> data) {
        if (!ensure_connection()) { return false; }
        
        try {
            list<string> columns <- [];
            list values <- [];
            loop key over: data.keys {
                add string(key) to: columns;
                add data[key] to: values;
            }
            
            do insert(into: table_name, columns: columns, values: values);
            return true;
        } catch {
            write "ERROR: Failed to insert data into " + table_name;
            return false;
        }
    }
    
    bool db_update(string table_name, map<string,unknown> data, map<string,unknown> conditions) {
        if (!ensure_connection()) { return false; }
        
        try {
            string query <- "UPDATE " + table_name + " SET ";
            list params <- [];
            
            bool isFirst <- true;
            loop col over: data.keys {
                if (!isFirst) { query <- query + ","; }
                query <- query + string(col) + "=?";
                add data[col] to: params;
                isFirst <- false;
            }
            
            list where_info <- build_where_clause(conditions);
            query <- query + string(where_info[0]);
            loop param over: list(where_info[1]) {
                add param to: params;
            }
            
            do executeUpdate(updateComm: query, values: params);
            return true;
        } catch {
            write "ERROR: Failed to update data in " + table_name;
            return false;
        }
    }
    
    bool db_delete(string table_name, map<string,unknown> conditions) {
        if (!ensure_connection()) { return false; }
        
        try {
            list where_info <- build_where_clause(conditions);
            string query <- "DELETE FROM " + table_name + string(where_info[0]);
            
            do executeUpdate(updateComm: query, values: list(where_info[1]));
            return true; 
        } catch {
            write "ERROR: Failed to delete data from " + table_name;
            return false;
        }
    }
}
