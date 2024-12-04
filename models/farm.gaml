/**
* Name: Farm
*/


model Farm

import './factor.gaml'

global {
	file background <- image_file("../includes/images/background.png");
	file background_flipped <- image_file("../includes/images/background_flipped.png");
	
	list<point> trough_locs <- [{51.0, 22.0}, {58.5, 22.0}, {68.0, 22.0}, {76.0, 22.0}, {85.0, 22.0}];
	list<point> water_locs <- [{2.0, 60.0}, {2.0, 70.0}, {2.0, 80.0}, {2.0, 90.0}];
	
    list<point> trough_locs_flipped <- [{35.0, 22.0}, {27.0, 22.0}, {17.5, 22.0}, {9.5, 22.0}, {0.5, 22.0}];
    list<point> water_locs_flipped <- [{98.0, 60.0}, {98.0, 70.0}, {98.0, 80.0}, {98.0, 90.0}];
}

grid Background width: 64 height: 64 neighbors: 8 {
	rgb color <- rgb(background at {grid_x, grid_y});
}

//grid Background width: 64 height: 64 neighbors: 8 {
//    rgb color <- pigpen_type = 1 ? rgb(background at {grid_x, grid_y}) : rgb(background_flipped at {grid_x, grid_y});
//}
