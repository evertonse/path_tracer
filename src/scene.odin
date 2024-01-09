package tracer

import fmt "core:fmt"

MAX_OBJECTS :: 2;
ELMENTS_IN_1OBJ :: 23;

Scene :: struct  {
    objects: [MAX_OBJECTS]Object ,
    sceneData1D: [MAX_OBJECTS * ELMENTS_IN_1OBJ]f32,
};



scene_make :: proc() -> (self: Scene) {

    for i in 0..<len(self.objects) {
        self.objects[i] = object_make();
    }

    scene_flatten(&self)
    fmt.println("Done making scene")
    return self
}

// Convert to 1D
scene_flatten :: proc(using s: ^Scene) {
	// x, y, z, r, g, b, type, radius, cubeSize, isLight, reflectivity, refract, percentSpecular, roughness powerOfLight rotationTransform
	// 1  2  3  4  5  6    7     8     9 10 11     12         13          14          15             16       17            18 19 20
  array2D :[MAX_OBJECTS][ELMENTS_IN_1OBJ]float;
	for i := 0; i < MAX_OBJECTS; i =+1 {
		array2D[i][0] = objects[i].pos[0];
		array2D[i][1] = objects[i].pos[1];
		array2D[i][2] = objects[i].pos[2];

		array2D[i][3] = objects[i].colour[0];
		array2D[i][4] = objects[i].colour[1];
		array2D[i][5] = objects[i].colour[2];

		array2D[i][6] = objects[i].type;
		array2D[i][7] = objects[i].radius;

		array2D[i][8] = objects[i].cubeSize[0];
		array2D[i][9] = objects[i].cubeSize[1];
		array2D[i][10] = objects[i].cubeSize[2];

		array2D[i][11] = objects[i].isLight;
		array2D[i][12] = objects[i].reflectivity;
		array2D[i][13] = objects[i].refractionIndex;
		array2D[i][14] = objects[i].percentSpecular;
		array2D[i][15] = objects[i].roughness;
		array2D[i][16] = objects[i].powerOfLight;

		array2D[i][17] = objects[i].rot[0];
		array2D[i][18] = objects[i].rot[1];
		array2D[i][19] = objects[i].rot[2];

		array2D[i][20] = objects[i].specularColour[0];
		array2D[i][21] = objects[i].specularColour[1];
		array2D[i][22] = objects[i].specularColour[2];
	}

	for i := 0; i < MAX_OBJECTS; i += 1 {
		for j := 0; j < ELMENTS_IN_1OBJ; j +=1 {
			sceneData1D[i * ELMENTS_IN_1OBJ + j] = array2D[i][j];
		}
	}
}

updateObjectsFrom1D :: proc(using s:^Scene) {
	for i := 0; i < MAX_OBJECTS; i += 1 {
    index := i * ELMENTS_IN_1OBJ; // Calculate the starting index for each object in the 1D array

		objects[i].pos[0] = sceneData1D[index + 0];
		objects[i].pos[1] = sceneData1D[index + 1];
		objects[i].pos[2] = sceneData1D[index + 2];

		objects[i].colour[0] = sceneData1D[index + 3];
		objects[i].colour[1] = sceneData1D[index + 4];
		objects[i].colour[2] = sceneData1D[index + 5];

		objects[i].type = sceneData1D[index + 6];
		objects[i].radius = sceneData1D[index + 7];

		objects[i].cubeSize[0] = sceneData1D[index + 8];
		objects[i].cubeSize[1] = sceneData1D[index + 9];
		objects[i].cubeSize[2] = sceneData1D[index + 10];

		objects[i].isLight = sceneData1D[index + 11];
		objects[i].reflectivity = sceneData1D[index + 12];
		objects[i].refractionIndex = sceneData1D[index + 13];
		objects[i].percentSpecular = sceneData1D[index + 14];
		objects[i].roughness = sceneData1D[index + 15];
		objects[i].powerOfLight = sceneData1D[index + 16];

		objects[i].rot[0] = sceneData1D[index + 17];
		objects[i].rot[1] = sceneData1D[index + 18];
		objects[i].rot[2] = sceneData1D[index + 19];

		objects[i].specularColour[0] = sceneData1D[index + 20];
		objects[i].specularColour[1] = sceneData1D[index + 21];
		objects[i].specularColour[2] = sceneData1D[index + 22];
	}
}

rearrangeObjects :: proc(using s: ^Scene) {
  writeIndex := 0;

	// Move objects with type != 0 towards the front
	for readIndex := 0; readIndex < MAX_OBJECTS; readIndex +=1 {
		if (objects[readIndex].type != 0) {
			objects[writeIndex] = objects[readIndex];
			writeIndex += 1;
		}
	}

	// Fill the rest of the array with objects of type 0
	for (writeIndex < MAX_OBJECTS) {
    obj: Object ;
		objects[writeIndex] = obj; // Set type to 0 for remaining elements
		writeIndex +=1;
	}
}

