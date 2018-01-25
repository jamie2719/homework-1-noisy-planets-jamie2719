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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

in float offset;


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.






// Return a random direction in a circle
vec3 random3(vec3 p) {
    return normalize(2.0f * fract(sin(vec3(dot(p,vec3(127.1,311.7, 217.4)),
    dot(p,vec3(269.5,183.3, 359.2)), 
    dot(p,vec3(171.1,513.3, 237.9))))*43758.5453) - 1.0f);
}

vec2 random2( vec2 p ) {
    return normalize(2.0f * fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453) - 1.0f);
}

float perlin(vec3 p, vec3 gridPoint) {
    vec3 gradient = random3(gridPoint);
    vec3 toP = p - gridPoint;
    return dot(toP, gradient);
}




void main()
{
    vec3 pos = vec3(fs_Pos) *4.0f;
    float tx = smoothstep(0.0, 1.0, fract(pos.x));
    float ty = smoothstep(0.0, 1.0, fract(pos.y));
    float tz = smoothstep(0.0, 1.0, fract(pos.z));

    vec3 bottomBackLeft = floor(vec3(pos));
    vec3 topBackLeft =      vec3(bottomBackLeft.x,        bottomBackLeft.y + 1.0f, bottomBackLeft.z);
    vec3 topBackRight =     vec3(bottomBackLeft.x + 1.0f, bottomBackLeft.y + 1.0f, bottomBackLeft.z);
    vec3 bottomBackRight =  vec3(bottomBackLeft.x + 1.0f, bottomBackLeft.y,        bottomBackLeft.z);
    vec3 bottomFrontLeft =  vec3(bottomBackLeft.x,        bottomBackLeft.y,        bottomBackLeft.z + 1.0f);
    vec3 topFrontLeft =     vec3(bottomBackLeft.x,        bottomBackLeft.y + 1.0f, bottomBackLeft.z + 1.0f);
    vec3 topFrontRight =    vec3(bottomBackLeft.x + 1.0f, bottomBackLeft.y + 1.0f, bottomBackLeft.z + 1.0f);
    vec3 bottomFrontRight = vec3(bottomBackLeft.x + 1.0f, bottomBackLeft.y,        bottomBackLeft.z + 1.0f);


    float bbl = perlin(vec3(pos), bottomBackLeft); 
    float tbl = perlin(vec3(pos), topBackLeft);
    float tbr = perlin(vec3(pos), topBackRight);
    float bbr = perlin(vec3(pos), bottomBackRight);
    float bfl = perlin(vec3(pos), bottomFrontLeft);
    float tfl = perlin(vec3(pos), topFrontLeft); 
    float tfr = perlin(vec3(pos), topFrontRight); 
    float bfr = perlin(vec3(pos), bottomFrontRight);

    //trilinear interpolation of 8 perlin noise values
    float tfbr = tfr * (tz) + tbr * (1.0f - tz);
    float tfbl = tbl * (1.0f - tz) + tfl * tz;
    float bfbl = bbl * (1.0f - tz) + bfl * tz;
    float bfbr = bfr * (tz) + bbr * (1.0f - tz);

    float top = tfbl * (1.0f - tx) + tfbr * tx;
    float bottom = bfbl * (1.0f - tx) + bfbr * tx;

    float val = top * (ty) + bottom * (1.0f - ty);




    val *= .7f;
    //vec4 diffuseColor = vec4((val + 1.0f) * 0.5);
    //diffuseColor.a = 1.0;
vec4 diffuseColor;



if(fs_Pos.y > .15 || fs_Pos.y < -.15) {
    diffuseColor = vec4(1.0, 1.0, 1.0, 1.0); //mountaintop
} 
else if(fs_Pos.y > .08 || fs_Pos.y < -.08) {
    diffuseColor = vec4(90.0f / 255.0f, 67.0f / 255.0f, 0.0f, 1.0f); //mountain
}
else if(fs_Pos.y > .03 || fs_Pos.y < -.03) {
    diffuseColor = vec4(0.0f, 150.0f / 255.0f, 0.0f, 1.0); //grass
}
else if(fs_Pos.y > .02 || fs_Pos.y < -.02) {
    diffuseColor = vec4(248.0f / 255.0f, 205.0 / 255.0f, 80.0 / 255.0f, 1.0); //sand  
}
else {
    diffuseColor = vec4(0.0, 0.0, 1.0, 1.0); //water/
}

//(fs_Pos.y < .04  && fs_Pos.y > -.04) {
  //  diffuseColor = vec4(0.0, 0.0, 1.0, 1.0); //water
//} 


    // Material base color (before shading)
        //vec4 diffuseColor = u_Color;
        
        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        //out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        //diffuseColor.rgb / 255.0f;
        out_Col = diffuseColor;

}
