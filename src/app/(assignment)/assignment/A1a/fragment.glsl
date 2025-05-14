/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1A: SDF and Ray Marching
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

const vec3 CAM_POS = vec3(-0.35, 1.0, -3.0);
float sdf2(vec3 p);

/////////////////////////////////////////////////////
//// sdf functions
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 1: sdf primitives
//// You are asked to implement sdf primitive functions for sphere, plane, and box.
//// In each function, you will calculate the sdf value based on the function arguments.
/////////////////////////////////////////////////////

//// sphere: p - query point; c - sphere center; r - sphere radius
float sdfSphere(vec3 p, vec3 c, float r)
{
    //// your implementation starts
    
    return length(p - c) - r;
    
    //// your implementation ends
}

//// plane: p - query point; h - height
float sdfPlane(vec3 p, float h)
{
    //// your implementation starts
    
    return p.y - h;
    
    //// your implementation ends
}

//// box: p - query point; c - box center; b - box half size (i.e., the box size is (2*b.x, 2*b.y, 2*b.z))
float sdfBox(vec3 p, vec3 c, vec3 b)
{
    //// your implementation starts
    
    vec3 d = abs(p-c) -b;
    //what
    return min(max(max(d.y, d.z), d.x), 0.0) + length(max(d, 0.0));
    
    //// your implementation ends
}

//// The next couple are taken from IQ 3D.


float sdTorus(vec3 p, vec3 c, vec2 t )
{
  vec2 q = vec2(length(p.xz-c.xz)-t.x,p.y-c.y);
  return length(q)-t.y;
}

float sdCone(vec3 p, vec3 c, vec2 angle, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(angle.x/angle.y,-1.0);
    
  vec2 w = vec2( length(p.xz-c.xz), p.y-c.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}


/////////////////////////////////////////////////////
//// boolean operations
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 2: sdf boolean operations
//// You are asked to implement sdf boolean operations for intersection, union, and subtraction.
/////////////////////////////////////////////////////

float sdfIntersection(float s1, float s2)
{
    //// your implementation starts
    
    return max(s1,s2);

    //// your implementation ends
}

float sdfUnion(float s1, float s2)
{
    //// your implementation starts
    
    return min(s1,s2);

    //// your implementation ends
}

float sdfSubtraction(float s1, float s2)
{
    //// your implementation starts
    
    return max(s1,-s2);

    //// your implementation ends
}


float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

/////////////////////////////////////////////////////
//// sdf calculation
/////////////////////////////////////////////////////
// For Whatever reason, this wouldn't work in its original place, I moved it.
//// sdf2: p - query point
float sdf2(vec3 p)
{
    float s = 0.;

    //// 1st object: plane
    float plane1_h = -0.1;
    
    //// your implementation starts
    float planePart = sdfPlane(p, plane1_h);

    float toorus = sdTorus(p, vec3(1,.5,0), vec2(.4,.1));
    float toorus2 = sdTorus(p, vec3(1,.55,0), vec2(.425,.115));
    vec3 spherezC = vec3(-2.0, 1.0, 0.0);
    float spherezR = 0.25;
    float spherePartZ = sdfSphere(p, spherezC, spherezR);
    vec3 spherezC2 = vec3(-2.0, 1.35, 0.0);
    float spherezR2 = 0.225;
    float spherePartZ2 = sdfSphere(p, spherezC2, spherezR2);
    vec3 spherezC3 = vec3(-2.0, 1.65, 0.0);
    float spherezR3 = 0.2;
    float spherePartZ3 = sdfSphere(p, spherezC3, spherezR3);

    float cone = sdCone(p,vec3(-2,.25,0.0), vec2(.2,-.5), -.6);

    vec3 sC = vec3(-0.5, 1.0, -.25);
    float sR = 0.3;
    float sZ = sdfSphere(p, sC, sR);
    sC = vec3(-0.75, .7, 0.0);
    sR = 0.4;
    float sZ2 = sdfSphere(p, sC, sR);
    sC = vec3(-0.5, 0.4, 0.0);
    sR = 0.4;
    float sZ3 = sdfSphere(p, sC, sR);

    float blobby = opSmoothUnion(sZ2, sZ, .05);
    blobby = opSmoothUnion(sZ3, blobby, .05);
    sC = vec3(-0.55, .1, 0.0);
    sR = 0.6;
    sZ3 = sdfSphere(p, sC, sR);
    blobby = opSmoothUnion(sZ3, blobby, .05);
    sC = vec3(-0.5, 1.35, -.25);
    sR = 0.32;
    sZ3 = sdfSphere(p, sC, sR);
    blobby = opSmoothUnion(sZ3, blobby, .05);



    s = sdfUnion(planePart,toorus2); // Donut1 and 2
    s = sdfUnion(toorus,s); // Donut1 and 2
    s = sdfUnion(spherePartZ,s); // Bottom
    s = sdfUnion(spherePartZ2,s); //Middle
    s = sdfUnion(spherePartZ3,s); // Top
    s = sdfUnion(cone,s); // Cone
    s = sdfUnion(s,blobby); //blobby
    
    
    //// your implementation ends

    return s;
}
/////////////////////////////////////////////////////
//// Step 3: scene sdf
//// You are asked to use the implemented sdf boolean operations to draw the following objects in the scene by calculating their CSG operations.
/////////////////////////////////////////////////////

//// sdf: p - query point
float sdf(vec3 p)
{
    float s = 0.;

    //// 1st object: plane
    float plane1_h = -0.1;
    
    //// 2nd object: sphere
    vec3 sphere1_c = vec3(-2.0, 1.0, 0.0);
    float sphere1_r = 0.25;

    //// 3rd object: box
    vec3 box1_c = vec3(-1.0, 1.0, 0.0);
    vec3 box1_b = vec3(0.2, 0.2, 0.2);

    //// 4th object: box-sphere subtraction
    vec3 box2_c = vec3(0.0, 1.0, 0.0);
    vec3 box2_b = vec3(0.3, 0.3, 0.3);

    vec3 sphere2_c = vec3(0.0, 1.0, 0.0);
    float sphere2_r = 0.4;

    //// 5th object: sphere-sphere intersection
    vec3 sphere3_c = vec3(1.0, 1.0, 0.0);
    float sphere3_r = 0.4;

    vec3 sphere4_c = vec3(1.3, 1.0, 0.0);
    float sphere4_r = 0.3;

    //// calculate the sdf based on all objects in the scene
    
    //// your implementation starts
    float planePart = sdfPlane(p, plane1_h);
    float spherePart = sdfSphere(p, sphere1_c, sphere1_r);
    float boxPart = sdfBox(p, box1_c, box1_b);

    float boxspherePart = sdfSubtraction(sdfBox(p, box2_c, box2_b), sdfSphere(p, sphere2_c, sphere2_r));
    
    float spherespherePart = sdfIntersection(sdfSphere(p, sphere3_c, sphere3_r), sdfSphere(p, sphere4_c, sphere4_r));
    
    s = sdfUnion(sdfUnion(sdfUnion(sdfUnion(planePart, spherePart),boxPart), boxspherePart), spherespherePart);
    //// your implementation ends

    return s;
}

/////////////////////////////////////////////////////
//// ray marching
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 4: ray marching
//// You are asked to implement the ray marching algorithm within the following for-loop.
/////////////////////////////////////////////////////

//// ray marching: origin - ray origin; dir - ray direction 
float rayMarching(vec3 origin, vec3 dir)
{
    float s = 0.0;
    // TODO: ask why this is 100 (I'm pretty sure its arbitrary)
    for(int i = 0; i < 100; i++)
    {
        //// your implementation starts
        vec3 curr = origin + dir * s;
        float dist = sdf2(curr);

        if (dist < 0.001) {
            return s;
        }

        s += dist;
        //123.0 is a sorta arbitrary value but ill know it ran
        if (s > 123.0) {
            return 123.0;
        }
        //// your implementation ends
    }
    
    return s;
}

/////////////////////////////////////////////////////
//// normal calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 5: normal calculation
//// You are asked to calculate the sdf normal based on finite difference.
/////////////////////////////////////////////////////

//// normal: p - query point
vec3 normal(vec3 p)
{
    float s = sdf2(p);          //// sdf value in p
    float dx = 0.01;           //// step size for finite difference

    //// your implementation starts
    
    return normalize(vec3(
                sdf2(p + vec3(dx, 0.0, 0.0)) - s, 
                sdf2(p + vec3(0.0, dx, 0.0)) - s, 
                sdf2(p + vec3(0.0, 0.0, dx)) - s));

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Phong shading
//////////////// /////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 6: lighting and coloring
//// You are asked to specify the color for each object in the scene.
//// Each object must have a separate color without mixing.
//// Notice that we have implemented the default Phong shading model for you.
/////////////////////////////////////////////////////

vec3 phong_shading(vec3 p, vec3 n)
{
    //// background
    if(p.z > 10.0){
        return vec3(0.9, 0.6, 0.2);
    }

    //// phong shading
    vec3 lightPos = vec3(4.*sin(iTime), 4., 4.*cos(iTime));  
    vec3 l = normalize(lightPos - p);               
    float amb = 0.1;
    float dif = max(dot(n, l), 0.) * 0.7;
    vec3 eye = CAM_POS;
    float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.9;

    vec3 sunDir = vec3(0, 1, -1);
    float sunDif = max(dot(n, sunDir), 0.) * 0.2;

    //// shadow
    float s = rayMarching(p + n * 0.02, l);
    if(s < length(lightPos - p)) dif *= .2;

    vec3 color = vec3(1.0, 1.0, 1.0);

    //// your implementation for coloring starts
    //// 1st object: plane
    float plane1_h = -0.1;
    
    //// 2nd object: sphere
    vec3 sphere1_c = vec3(-2.0, 1.0, 0.0);
    float sphere1_r = 0.25;

    //// 3rd object: box
    vec3 box1_c = vec3(-1.0, 1.0, 0.0);
    vec3 box1_b = vec3(0.2, 0.2, 0.2);

    //// 4th object: box-sphere subtraction
    vec3 box2_c = vec3(0.0, 1.0, 0.0);
    vec3 box2_b = vec3(0.3, 0.3, 0.3);

    vec3 sphere2_c = vec3(0.0, 1.0, 0.0);
    float sphere2_r = 0.4;

    //// 5th object: sphere-sphere intersection
    vec3 sphere3_c = vec3(1.0, 1.0, 0.0);
    float sphere3_r = 0.4;

    vec3 sphere4_c = vec3(1.3, 1.0, 0.0);
    float sphere4_r = 0.3;

    float planePart = sdfPlane(p, plane1_h);
    float spherePart = sdfSphere(p, sphere1_c, sphere1_r);
    float boxPart = sdfBox(p, box1_c, box1_b);
    float boxspherePart = sdfSubtraction(sdfBox(p, box2_c, box2_b), sdfSphere(p, sphere2_c, sphere2_r));
    float spherespherePart = sdfIntersection(sdfSphere(p, sphere3_c, sphere3_r), sdfSphere(p, sphere4_c, sphere4_r));
    // Copied from before

    float small = 0.001;
    //I'm not sure which of the modules does this, but one of the two adds this neat color picker that i love.
    if (abs(planePart) < small) {
        color = vec3(0.06, 0.86, 0.06); // Green
    } else if (abs(spherePart) < small) {
        color = vec3(0.87, 0.09, 0.09); // Red
    } else if (abs(boxPart) < small) {
        color = vec3(0.0, 0.76, 1.0); //Blue
    } else if (abs(boxspherePart) < small) {
        color = vec3(0.56, 0.07, 0.85); // Purple
    } else if (abs(spherespherePart) < small) {
        color = vec3(0.79, 0.89, 0.02); //Yellow
    }

    //// your implementation for coloring ends

    return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// Step 7: creative expression
//// You will create your customized sdf scene with new primitives and CSG operations in the sdf2 function.
//// Call sdf2 in your ray marching function to render your customized scene.
/////////////////////////////////////////////////////

vec3 phong_shading2(vec3 p, vec3 n)
{
    //// background
    if(p.z > 10.0){
        return vec3(0.9, 0.6, 0.2);
    }

    //// phong shading
    vec3 lightPos = vec3(4.*sin(iTime), 4., 4.*cos(iTime));  
    vec3 l = normalize(lightPos - p);               
    float amb = 0.1;
    float dif = max(dot(n, l), 0.) * 0.7;
    vec3 eye = CAM_POS;
    float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.9;

    vec3 sunDir = vec3(0, 1, -1);
    float sunDif = max(dot(n, sunDir), 0.) * 0.2;

    //// shadow
    float s = rayMarching(p + n * 0.02, l);
    if(s < length(lightPos - p)) dif *= .2;

    vec3 color = vec3(1.0, 1.0, 1.0);

    //// your implementation for coloring starts
    float plane1_h = -0.1;
    
    //// your implementation starts
    float planePart = sdfPlane(p, plane1_h);

    float toorus = sdTorus(p, vec3(1,.5,0), vec2(.4,.1));
    float toorus2 = sdTorus(p, vec3(1,.55,0), vec2(.425,.115));
    vec3 spherezC = vec3(-2.0, 1.0, 0.0);
    float spherezR = 0.25;
    float spherePartZ = sdfSphere(p, spherezC, spherezR);
    vec3 spherezC2 = vec3(-2.0, 1.35, 0.0);
    float spherezR2 = 0.225;
    float spherePartZ2 = sdfSphere(p, spherezC2, spherezR2);
    vec3 spherezC3 = vec3(-2.0, 1.65, 0.0);
    float spherezR3 = 0.2;
    float spherePartZ3 = sdfSphere(p, spherezC3, spherezR3);

    float cone = sdCone(p,vec3(-2,.25,0.0), vec2(.2,-.5), -.6);

    vec3 sC = vec3(-0.5, 1.0, -.25);
    float sR = 0.3;
    float sZ = sdfSphere(p, sC, sR);
    sC = vec3(-0.75, .7, 0.0);
    sR = 0.4;
    float sZ2 = sdfSphere(p, sC, sR);
    sC = vec3(-0.5, 0.4, 0.0);
    sR = 0.4;
    float sZ3 = sdfSphere(p, sC, sR);

    float blobby = opSmoothUnion(sZ2, sZ, .05);
    blobby = opSmoothUnion(sZ3, blobby, .05);
    sC = vec3(-0.55, .1, 0.0);
    sR = 0.6;
    sZ3 = sdfSphere(p, sC, sR);
    blobby = opSmoothUnion(sZ3, blobby, .05);
    sC = vec3(-0.5, 1.35, -.25);
    sR = 0.32;
    sZ3 = sdfSphere(p, sC, sR);
    blobby = opSmoothUnion(sZ3, blobby, .05);



    s = sdfUnion(planePart,toorus2); // Donut1 and 2
    s = sdfUnion(toorus,s); // Donut1 and 2
    s = sdfUnion(spherePartZ,s); // Bottom
    s = sdfUnion(spherePartZ2,s); //Middle
    s = sdfUnion(spherePartZ3,s); // Top
    s = sdfUnion(cone,s); // Cone
    s = sdfUnion(s,blobby); //blobby
    
    // Copied from before

    float small = 0.001;
    //I'm not sure which of the modules does this, but one of the two adds this neat color picker that i love.
    if (abs(planePart) < small) {
        color = vec3(0.26, 0.69, 0.82); // Green
    } else if (abs(toorus2) < small) {
        color = vec3(0.88, 0.3, 0.76); // Red
    } else if (abs(toorus) < small) {
        color = vec3(0.95, 0.89, 0.37); //Blue
    } else if (abs(spherePartZ) < small) {
        color = vec3(0.96, 0.15, 0.88); // Purple
    } else if (abs(spherePartZ2) < small) {
        color = vec3(0.31, 0.15, 0.02); //Yellow
    } else if (abs(spherePartZ3) < small) {
        color = vec3(0.02, 0.89, 0.45); //Yellow
    } else if (abs(cone) < small) {
        color = vec3(0.95, 0.68, 0.13); //Yellow
    } else if (abs(blobby) < small) {
        color = vec3(0.44, 0.12, 1.0); //Yellow
    }

    //// your implementation for coloring ends

    return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// main function
/////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;         //// screen uv
    vec3 origin = CAM_POS;                                                  //// camera position 
    vec3 dir = normalize(vec3(uv.x, uv.y, 1));                 //// camera direction
    float s = rayMarching(origin, dir);                         //// ray marching
    vec3 p = origin + dir * s;                                              //// ray-sdf intersection
    vec3 n = normal(p);                                                     //// sdf normal
    vec3 color = phong_shading2(p, n);                                       //// phong shading
    fragColor = vec4(color, 1.);                                            //// fragment color
}

void main()
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}