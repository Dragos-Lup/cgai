shader_type canvas_item;

// A bunch of parameters, you can mess with these in the editor if you'd like
// See the attached file for a short tutorial
// Mandelbulb junk
uniform float mandelbulb_iterations = 4;
uniform float mandelbulb_bailout = 256.0;
uniform float mandelbulb_power = 8.0; 
uniform float power_min = 1.0;
uniform float power_max = 15.0;
uniform float power_speed = 0.5;

uniform bool animated = true;
uniform bool independent_powers = true;
uniform float power_phase_offset = 0.5;
uniform vec4 mandelbulb_color1 : source_color = vec4(0.10, 0.20, 0.30, 1.0);
uniform vec4 mandelbulb_color2 : source_color = vec4(0.02, 0.10, 0.30, 1.0);
uniform vec4 mandelbulb_color3 : source_color = vec4(0.30, 0.10, 0.02, 1.0);

// Lighting junk
uniform float ambient_light = 0.1;
uniform float diffuse_strength = 0.5;
uniform float spec_strength = 1.5;
uniform float spec_shininess = 64.0;

// new frensel stuff, didn't play with too much
uniform float reflect_strength = 0.4;
uniform float fresnel_power = 3.0;
uniform float fresnel_scale = 0.6;


uniform vec3 light_position = vec3(4.0, 4.0, 4.0);
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec4 sky_color1 : source_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform vec4 sky_color2 : source_color = vec4(0.2, 0.3, 0.5, 1.0);

// Camera parameters
uniform vec3 cam_pos = vec3(0.0, 0.0, -2.5);
uniform float cam_rot_y = 0.0; // Y AXIS ROTATION (IN RADIANS)
uniform float cam_rot_x = 0.0; // X AXIS ROTATION (IN RADIANS)
uniform bool rot_in_place = true; // Whether or not rotation also changes camera position, to rotate around a point.
								// When true! this happens

uniform float mb_space = 2.0; // Distance between mandelbulbs
uniform int mb_count = 5; // Number of mandelbulbs to render
uniform float mandelbulb_arrangement = 0.0; // 0 = circular, 1 = grid, values in between blend

float sdfUnion(float s1, float s2)
{
    //// your implementation starts
    
    return min(s1,s2);

    //// your implementation ends
}

float sdfSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float get_power(int index) {
    if (!animated) {
        return mandelbulb_power;
    }
    
    float amplitude = (power_max - power_min) * 0.5;
    float midpoint = (power_max + power_min) * 0.5;
    
    if (independent_powers) {
        float phase = float(index) * power_phase_offset;
        return midpoint + amplitude * sin(TIME * power_speed + phase);
    } else {
        return midpoint + amplitude * sin(TIME * power_speed);
    }
}

// the big fella
// essentially all of the mandelbulb implementation is here.
float sdMandelbulb(vec3 p, float power, out vec4 trap) {
    vec3 w = p;
    float m = dot(w, w);
    
    trap = vec4(abs(w), m);
    float dz = 1.0;

    for(int i = 0; i < int(mandelbulb_iterations); i++) {
        dz = power * pow(m, (power - 1.0) / 2.0) * dz + 1.0;
        
        float r = length(w);
        
        if (r < 0.000001) {
            r = 0.000001;
        }
        
        float b = power * acos(clamp(w.y / r, -1.0, 1.0));
        float a = power * atan(w.x, w.z);
        w = p + pow(r, power) * vec3(sin(b) * sin(a), cos(b), sin(b) * cos(a));
        
        trap = min(trap, vec4(abs(w), m));
        
        m = dot(w, w);
        if(m > mandelbulb_bailout)
            break;
    }
    
    return 0.25 * log(m) * sqrt(m) / dz;
}
// END OF SDF FUNCTIONS



vec3 getMandelbulbPosition(int index) {
    float angle = 2.0 * 3.14159265 * float(index) / float(mb_count);

    vec3 circularPos = vec3(cos(angle) * mb_space, sin(angle) * mb_space * 0.5, sin(angle) * mb_space);
    
    int side = int(ceil(sqrt(float(mb_count))));
    float gdspace = mb_space * 0.8;
    vec3 gridPos = vec3(
        mod(float(index), float(side)) * gdspace - (float(side-1) * gdspace * 0.5),
        0.0,
        floor(float(index) / float(side)) * gdspace - (float(side-1) * gdspace * 0.5)
    );
    
    return mix(circularPos, gridPos, mandelbulb_arrangement);
}

float map(vec3 p, out vec4 trap) {
	
    float result = 100.0; // Start with a large distance
    
    for(int i = 0; i < mb_count; i++) {
        vec3 offset = getMandelbulbPosition(i);
        float power = get_power(i);
        vec4 localTrap;
        
        float dist = sdMandelbulb(p - offset, power, localTrap);
        
        // If this is the closest mandelbulb so far, update the trap value
        if (dist < result) {
            trap = localTrap;
            result = dist;
        }
        
        // Use smooth union for a more organic blend between mandelbulbs
        // result = sdfSmoothUnion(result, dist, 0.3);
        result = sdfUnion(result, dist);
    }
    
    return result;
}

// Simple version for normal calculation
float map_wrapper(vec3 p) {
    vec4 trap;
    return map(p, trap);
}

// Normal, essentially stolen, but changed a little
//DONT TOUCH works great i promise
vec3 normal(vec3 p) {
    const float dx = 0.001;
	
    return normalize(vec3(
        map_wrapper(p + vec3(dx, 0.0, 0.0)) - map_wrapper(p - vec3(dx, 0.0, 0.0)),
        map_wrapper(p + vec3(0.0, dx, 0.0)) - map_wrapper(p - vec3(0.0, dx, 0.0)),
        map_wrapper(p + vec3(0.0, 0.0, dx)) - map_wrapper(p - vec3(0.0, 0.0, dx))
    ));
}

// Ray marching function, pretty much taken from hw
float rayMarching(vec3 origin, vec3 dir, out vec4 trap) {
    float s = 0.0;
    
    for(int i = 0; i < 100; i++) {
        vec3 p = origin + dir * s;
        float d = map(p, trap);
        
        if(d < 0.001) {
            return s;
        }
        
        if(s > 123.0) {
            return 123.0;
        }
        
        s += d;
    }
    
    return 123.0;
}

// Draws the sky and sun stuff
vec3 skyStuff(vec3 rd) {
    vec3 sky = mix(sky_color1.rgb, sky_color2.rgb, 0.5 + 0.5 * rd.y);
    float sunSpec = pow(max(dot(rd, normalize(light_position)), 0.0), 64.0);
    sky += specular_color.rgb * sunSpec * 2.0;
	return sky;
}

// Fresnel
float fresnel(vec3 normal, vec3 viewDir) {
    return fresnel_scale * pow(1.0 - clamp(dot(normal, viewDir), 0.0, 1.0), fresnel_power);
}

// glossier shading stuff
vec3 glossyShading(vec3 p, vec3 n, vec3 viewDir, vec4 trap) {
    vec3 lightDir = normalize(light_position - p);
    
    vec3 albedo = vec3(0.01);
    albedo = mix(albedo, mandelbulb_color1.rgb, clamp(trap.y, 0.0, 1.0));
    albedo = mix(albedo, mandelbulb_color2.rgb, clamp(trap.z * trap.z, 0.0, 1.0));
    albedo = mix(albedo, mandelbulb_color3.rgb, clamp(pow(trap.w, 6.0), 0.0, 1.0));
    albedo *= 0.7;
    
    vec3 ambient = albedo * ambient_light * clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
	
    vec3 diffuse = albedo * max(dot(n, lightDir), 0.0) * diffuse_strength;
	
	vec4 temp;
	float shadow = 1.0;
    float s = rayMarching(p + n * 0.02, lightDir, temp);
    if(s < length(light_position - p)) {
        shadow = 0.2;
    }
    
    float spec = pow(max(dot(n, normalize(lightDir + viewDir)), 0.0), spec_shininess);
    vec3 specular = specular_color.rgb * spec * spec_strength;
    
    float sunSpec = pow(max(dot(n, normalize(normalize(light_position) + viewDir)), 0.0), spec_shininess / 2.0);
    specular += specular_color.rgb * sunSpec * 0.3;
    
	vec3 reflection = skyStuff(reflect(-viewDir, n));
    
    vec3 finalColor = ambient + (diffuse * shadow) + (specular * shadow);
    finalColor = mix(finalColor, reflection, fresnel(n, viewDir) * reflect_strength);
    
	finalColor = pow(finalColor, vec3(0.7, 0.9, 1.0));
	return finalColor;
}

vec3 rotateY(vec3 v, float angle) {
    float cosa = cos(angle);
    float sina = sin(angle);
    return vec3(v.x * cosa - v.z * sina, v.y, v.x * sina + v.z * cosa);
}

vec3 rotateX(vec3 v, float angle) {
    float cosa = cos(angle);
    float sina = sin(angle);
    return vec3(v.x, v.y * cosa - v.z * sina, v.y * sina + v.z * cosa);
}

// Main stuff
vec4 mainImage(vec2 fragCoord, vec2 resolution) {
    vec2 uv = (fragCoord - 0.5 * resolution) / resolution.y;
    vec3 dir = normalize(vec3(uv, 1.0));
    // Camera rotation stuff
    dir = rotateY(dir, cam_rot_y);
    dir = rotateX(dir, cam_rot_x);
    
    // Camera pos
    vec3 origin = cam_pos;
	
    // We're rotating around the center for now
	if (rot_in_place){
	    origin = rotateY(origin, cam_rot_y);
	    origin = rotateX(origin, cam_rot_x);
	}
    
    // Ray marching
	vec4 trap;
    float s = rayMarching(origin, dir, trap);
    vec3 color = vec3(0.1);
    
    // If the ray did actually hit
    if(s < 123.0) {
        vec3 p = origin + dir * s;
        vec3 n = normal(p);
        // color = phongShading(p, n, trap);
		vec3 viewDir = normalize(origin - p);
        color = glossyShading(p, n, viewDir, trap);
    } else { 
        // Background stuff
        //color = vec3(0.8, 0.9, 1.1) * (0.6 + 0.4 * dir.y);
        //color += 5.0 * vec3(0.8, 0.7, 0.5) * pow(clamp(dot(dir, normalize(vec3(0.577, 0.577, -0.577))), 0.0, 1.0), 32.0);
    	color = skyStuff(dir);
	}
    // Vignette effect // doesn't look good
    // color *= 1.0 - 0.05 * length(uv);
    // Color correction? Should make things pop (Actually just makes it way worse i think)
	// color = color / (1.0 + color);
    // Gamma correction
    color = pow(color, vec3(0.4545));
    return vec4(color, 1.0);
}

void fragment() {
    vec2 resolution = 1.0 / TEXTURE_PIXEL_SIZE;
    COLOR = mainImage(UV * resolution, resolution);
}