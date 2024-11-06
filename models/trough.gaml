model Trough


species Trough {
	agent pig;
	
	
	init {
		pig <- nil;
	}
	
	bool add_pig(agent p) {
		if(pig = nil) {
			pig <- p;
			return true;
		}
		return false;
	}
	
	action remove_pig(agent p) {
		if(pig = p) {
			pig <- nil;
		}
	}
}
