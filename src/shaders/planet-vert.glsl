#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;
uniform vec4 u_Eye;
uniform float u_mountainHeight;     // float representing GUI control of mountain height

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out vec4 fs_CamPos;         // position of the camera
out float offset;
out float waterNoise;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.



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

float trilinearInterpolation(vec3 pos) {
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

    return top * (ty) + bottom * (1.0f - ty);
}



void main()
{
    // terrain noise calculation
    float summedNoise = 0.0;
    float water = 0.0;
    float amplitude = u_mountainHeight;
    float val;
    for(int i = 2; i <= 64; i *= 2) {
        vec3 pos = vec3(vs_Pos) * 1.5f * float(i);
        val = trilinearInterpolation(pos);
        summedNoise += val * amplitude;
        amplitude *= 0.5;
    }

    val =  summedNoise * .6f;
    vec4 offsetPos = vec4(val * vs_Pos.rgb, 0.0);
    offset = val;

    // water noise calculation
    vec3 waterPos = vec3(vs_Pos) * 16.f * ((sin(u_Time * .002) + 2.f)/4.0);
    waterNoise = trilinearInterpolation(waterPos) *1.5f;
    



    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 modelposition;
    if(val < 0.0f) {
       modelposition = u_Model * (vs_Pos + .2 * offsetPos); // decrease valleys
    }
    else {
       modelposition = u_Model * (vs_Pos + offsetPos); 
    }


    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    fs_CamPos = u_Eye;

    fs_Pos = modelposition;
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
