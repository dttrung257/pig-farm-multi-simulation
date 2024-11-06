model TransmitDiseaseConfig


import './transmit-disease-factor.gaml'


species TransmitDiseaseConfig {
	int day;
	
	init {
		day <- 0;
	}
	
	point get_relax_loc {
    	return { rnd(60.0, 95.0), rnd(60.0, 95.0) };
    }
	
	reflex spread when: cycle mod (24 * 60) = 0 and int(cycle / (60 * 24)) = day {
		create TransmitDiseaseFactor number: 1;
		TransmitDiseaseFactor[0].duration <- 2 * 24 * 60;
		TransmitDiseaseFactor[0].size <- 2.0;
		TransmitDiseaseFactor[0].location <- get_relax_loc();
	}
	
	agent create_factor_and_attach_to(agent pig) {
		create TransmitDiseaseFactor number: 1 returns: factors;
		factors[0].duration <- 2 * 24 * 60;
		factors[0].size <- 2.0;
		factors[0].location <- pig.location;
		factors[0].victim <- pig;
		return factors[0];
	}
}
