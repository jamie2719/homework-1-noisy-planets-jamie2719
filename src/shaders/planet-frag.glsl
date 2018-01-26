#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform float u_Time;
uniform vec4 u_Eye;
uniform int u_ocean;              // bool representing GUI control of whether ocean is water (1) or lava (0)

 // float representing whether planet is in total ice age (-2), partial ice age (-1), 
 //neutral (0), partial global warming (1), or complete global warming (2)
uniform int u_globalWarming;     


// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float waterNoise; // perlin noise value for ocean
in float offset;    // perlin noise value for terrain height
in vec4 fs_CamPos;


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// calculate color for poles of planet
vec4 colorPoles() {
    if(offset > .005) {
        return vec4(155.0f/255.0f, 161.0f/255.0f, 161.0f/255.0f, .8);
    }
    else if(offset > .02f) {
        return vec4(233.0f/255.0f, 1.0, 1.0, .8);
    }
    else if(offset > .06f) {
        return vec4(1.0, 1.0, 1.0, 1.0);
    }
}

//calculate color for ocean
vec4 colorOcean() {
    //ocean is water
    if(u_ocean == 1) { 
        return vec4(0.0f, 0.0f, 200.0f/255.0f, .8f) + vec4(0.0f, 0.0f, waterNoise, 0.0f);
    }
    //ocean is lava
    else { 
        return vec4(241.0f/255.0f, 20.0f/255.0f, 0.0f, .8f) + vec4(waterNoise, 0.0f, 0.0f, 0.0f);
    }
}


void main()
{
    vec4 diffuseColor;
    bool isOcean = false;

    if(offset > .25) { 
        diffuseColor = vec4(1.0, 1.0, 1.0, 1.0); // mountaintop
    } 
    else if(offset > .09) { 
        diffuseColor = vec4(90.0f / 255.0f, 67.0f / 255.0f, 0.0f, 1.0f); // mountain
    }
    else if(offset > .02) { 
        // raise water level
        if(u_globalWarming == 2 && offset < .06) {
            diffuseColor = colorOcean();
            isOcean = true;
        }
        else {
            diffuseColor = vec4(0.0f, 150.0f / 255.0f, 0.0f, 1.0); //grass
        }
    }
    else if(offset > .005) { 
        // raise water level
        if(u_globalWarming == 1 || u_globalWarming == 2) {
            diffuseColor = colorOcean();
            isOcean = true;
        }
        else {
            diffuseColor = vec4(248.0f / 255.0f, 205.0 / 255.0f, 80.0 / 255.0f, 1.0); //sand
        }  
    }
    else {
        diffuseColor = colorOcean();
        isOcean = true;
    }



// north and south pole icecaps
    //neutral
    if(u_globalWarming == 0) { 
        if((fs_Pos.y < -.7f || fs_Pos.y > .8f)) {
            if(!isOcean) { 
                diffuseColor = colorPoles();
            }
            else {
                diffuseColor.a = .6f;
            }
        }
    }     
    //partially melted
    else if(u_globalWarming == 1) { 
        if((fs_Pos.y < -.9f || fs_Pos.y > .95f)) { //ocean
            if(!isOcean) {

                    diffuseColor = colorPoles();

            }
            else {
                diffuseColor.a = .6f;
            }
        }
    }
    //partial ice age
    else if(u_globalWarming == -1){ 
        if((fs_Pos.y < -.4f || fs_Pos.y > .5f)) { //ocean
            if(!isOcean) {
                diffuseColor = colorPoles();
            }
            else {
                diffuseColor.a = .6f;
            }
        }
    }
    //ice age
    else if(u_globalWarming == -2) { 
        if(!isOcean) { 
            diffuseColor = colorPoles();
        }
        else {
           
            diffuseColor.a = .6f;

        }
    }
    else { //melted
        
    }



    vec4 view = fs_CamPos - fs_Pos;

    vec4 h = (view + fs_LightVec) / 2.0;
    vec4 n = fs_Nor;
    float specIntensity = max(pow(dot(normalize(h), normalize(n)), 100.0), 0.0f); // blinn-phong


    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
     diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.3;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    // Compute final shaded color
    if(isOcean) {
        //blinn phong shading for ocean
        out_Col = vec4(diffuseColor.rgb * lightIntensity + specIntensity, diffuseColor.a);
    }
    else {
        //lambert shading for terrain
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    }
    

}
