// Symbiotic Fireflies v4 (Ghostty / Shadertoy Compatible)

// ========================================================
// CONFIGURATION CONSTANTS
// ========================================================

// -- TIMING & MOVEMENT --
const float BASE_FLASH_FREQUENCY = 0.3; 
const float MOVEMENT_SPEED = 3.0; 
const float SYNC_WAVE_FREQUENCY = 0.3;

// -- SPATIAL CONTROLS --
const float SWARM_DENSITY = 0.075; 
const float SWARM_CLUMPING = 0.85; 
const float GRID_SCALE = 12.0; 

// -- AESTHETIC EFFECTS --
// 0.0 disables the climax shift. 1.0 pushes synced flashes gold.
const float CLIMAX_COLOR_SHIFT = 1.0; 

// 0.0 disables. 1.0 adds a subtle RGB separation/lens effect toward the screen edges.
const float CHROMATIC_DISPERSION = 1.0; 

// 0.0 disables. 1.0 allows fireflies to drift closer/further away (size, brightness, parallax).
const float DEPTH_EFFECT = 1.0; 

// ========================================================
// NOISE & RANDOMNESS
// ========================================================
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); 
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ========================================================
// ORGANIC PALETTE CYCLING
// ========================================================
vec3 getFireflyColor(float time) {
    vec3 amber       = vec3(1.00, 0.82, 0.30); 
    vec3 yellowGreen = vec3(0.80, 0.85, 0.40); 
    vec3 paleMint    = vec3(0.88, 0.98, 0.88); 

    float cycle = fract(time * 0.02); 
    if (cycle < 0.333) return mix(amber, yellowGreen, smoothstep(0.0, 0.333, cycle));
    if (cycle < 0.666) return mix(yellowGreen, paleMint, smoothstep(0.333, 0.666, cycle));
    return mix(paleMint, amber, smoothstep(0.666, 1.0, cycle));
}

// ========================================================
// MAIN RENDER LOOP
// ========================================================
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = uv;
    p.x *= iResolution.x / iResolution.y;
    
    // Vector pointing outward from screen center (used for lens dispersion)
    vec2 fromCenter = uv - 0.5; 

    vec2 gridP = p * GRID_SCALE;
    vec2 cellId = floor(gridP);
    vec2 cellFract = fract(gridP);

    vec3 col = vec3(0.0);

    // -- MACRO SYNC MECHANICS --
    float macroTime = iTime * 0.05 * SYNC_WAVE_FREQUENCY; 
    float syncStrength = pow(sin(macroTime * 3.1415), 6.0); 
    float globalPhase = iTime * 6.0 * BASE_FLASH_FREQUENCY; 
    vec3 baseColor = getFireflyColor(iTime);
    vec3 climaxColor = vec3(1.2, 1.1, 0.8); // Overblown gold

    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 id = cellId + neighbor;

            // -- DENSITY & CLUMPING --
            float clusterMap = valueNoise(id * 0.15); 
            float clumpMultiplier = smoothstep(0.3, 0.7, clusterMap) * 2.0; 
            float localDensity = mix(SWARM_DENSITY, SWARM_DENSITY * clumpMultiplier, SWARM_CLUMPING);
            localDensity = clamp(localDensity, 0.0, 1.0);
            
            float existenceHash = hash12(id + 73.1);
            if (existenceHash > localDensity) continue; 

            // -- Z-AXIS / DEPTH CALCULATION --
            float h = hash12(id); 
            vec2 offset = hash22(id);
            
            // Generate a slowly changing Z depth value (0.0 = far, 1.0 = near)
            float zPhase = iTime * MOVEMENT_SPEED * 0.15 + h * 6.2831;
            float zRaw = sin(zPhase) * 0.5 + 0.5; 
            float z = mix(0.5, zRaw, DEPTH_EFFECT); // If disabled, everyone sits at 0.5 depth
            
            // Map depth to size, brightness, and parallax drift
            float depthSize = mix(0.002, 0.008, z); 
            float depthBrightness = mix(0.1, 1.5, z);
            float parallaxAmount = mix(0.1, 0.35, z);

            // -- SPATIAL MOVEMENT --
            float movePhase = iTime * MOVEMENT_SPEED * (0.15 + h * 0.2) + h * 6.2831;
            offset += parallaxAmount * vec2(cos(movePhase), sin(movePhase * 1.1));

            vec2 pos = neighbor + offset - cellFract;

            // -- PHASE ALIGNMENT --
            float driftRate = 0.5 * mix(-1.0, 1.0, hash12(id + 1.0)) * BASE_FLASH_FREQUENCY;
            float rawOffset = h * 6.2831 + iTime * driftRate;
            float wrappedOffset = mod(rawOffset + 3.1415, 6.2831) - 3.1415;
            
            float currentOffset = mix(wrappedOffset, 0.0, syncStrength);
            float indPhase = globalPhase + currentOffset;

            // -- BLINK & COLOR --
            float blink = sin(indPhase) * 0.5 + 0.5;
            blink = pow(blink, 10.0); 
            
            // Shift towards the blinding gold during the synchronized climax
            vec3 fireflyColor = mix(baseColor, climaxColor, syncStrength * blink * CLIMAX_COLOR_SHIFT);

            // -- RENDER GLOW & CHROMATIC DISPERSION --
            // Push RGB channels apart based on distance from screen center
            vec2 dispersion = fromCenter * 0.02 * CHROMATIC_DISPERSION * z; 
            
            float distR = length(pos - dispersion);
            float distG = length(pos);
            float distB = length(pos + dispersion);

            // Calculate inverse-square glow for each color channel separately
            vec3 glowVec = vec3(
                depthSize / (distR * distR + 0.002),
                depthSize / (distG * distG + 0.002),
                depthSize / (distB * distB + 0.002)
            );

            // Apply all modifiers
            glowVec *= blink * depthBrightness * mix(0.3, 1.0, hash12(id * 1.3));

            col += fireflyColor * glowVec;
        }
    }

    // Subtle vignette
    float vignette = 1.0 - smoothstep(0.4, 1.5, length(uv - 0.5));
    col *= vignette;

    // Background compilation
    vec4 termColor = texture(iChannel0, uv);
    if (termColor.a == 0.0) termColor = vec4(0.0, 0.0, 0.0, 1.0);
    
    fragColor = termColor + vec4(col, 1.0);
}