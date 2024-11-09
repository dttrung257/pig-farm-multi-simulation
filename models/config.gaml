/**
* Name: Config
*/
model Config

global {
	float e;
	int CYCLES_IN_ONE_DAY <- 24 * 60;
	int UNEXPOSED_STATUS <- 0;
	int EXPOSED_STATUS <- 1;
	int INFECTED_STATUS <- 2;
	int RECOVERED_STATUS <- 3;
	int DEAD_STATUS <- 4;
	int PLAY_SPEED <- 100;

	init {
		e <- 2.72;
	}

}
