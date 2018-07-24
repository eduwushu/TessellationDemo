#ifndef RENDER_COMMON_GLSL
#define RENDER_COMMON_GLSL

const vec4 RED     = vec4(1,0,0,1);
const vec4 GREEN   = vec4(0,1,0,1);
const vec4 BLUE    = vec4(0,0,1,1);
const vec4 CYAN    = vec4(0,1,1,1);
const vec4 MAGENTA = vec4(1,0,0.5,1);
const vec4 YELLOW  = vec4(1,1,0,1);
const vec4 BLACK   = vec4(0,0,0,1);

uniform int heightmap;
uniform int num_vertices, num_indices;

uniform int morph_debug;
uniform float morph_k;

uniform int itpl_type;
uniform float itpl_alpha;

uniform int color_mode;
uniform int render_MVP;

// based on Filip Strugar's CDLOD paper (until intPart & signVec)
vec2 morphVertex(uvec4 key, vec2 leaf_p, vec2 tree_p, out uint morphed)
{
    mat3x2 xform;
    lt_getTriangleXform_64(key.xy, xform);
    vec4 mesh_p = M * lt_Leaf_to_MeshPosition(leaf_p, key, false, poly_type);

    if(mode == TERRAIN && heightmap > 0) {
        mesh_p.z = getHeight(cam_pos.xy, screen_res);
    }
    float vertex_lvl = distanceToLod(mesh_p.xyz);
    float node_lvl = lt_level_64(key.xy);
    float tessLevel = clamp(node_lvl -  vertex_lvl, 0.0, 1.0);
    float morphK = smoothstep(0.4, 0.5, tessLevel);

    morphed = (morphK > 0 && morphK < 1) ? 1 : 0;

    // nb of intervals per side of node primitive
    float patchTessFactor = 1u << uint(cpu_lod);
    vec2 fracPart = fract(leaf_p * patchTessFactor * 0.5) * 2.0 / patchTessFactor;
    vec2 intPart = floor(leaf_p * patchTessFactor * 0.5);
    vec2 signVec = mod(intPart, 2.0) * vec2(-2.0) + vec2(1.0);

    return tree_p - mat2(xform) * (signVec * fracPart) * morphK;
}

// based on Filip Strugar's CDLOD paper (until intPart & signVec)
vec2 morphVertexDebug(uvec4 key, vec2 leaf_p, vec2 tree_p, float k)
{
    mat3x2 xform;
    lt_getTriangleXform_64(key.xy, xform);
    float morphK =  k;
    // nb of intervals per side of node primitive
    float patchTessFactor = 1u << uint(cpu_lod);
    vec2 fracPart = fract(leaf_p * patchTessFactor * 0.5) * 2.0 / patchTessFactor;
    vec2 intPart = floor(leaf_p * patchTessFactor * 0.5);
    vec2 signVec = mod(intPart, 2.0) * vec2(-2.0) + vec2(1.0);

    return tree_p - mat2(xform) * (signVec * fracPart) * morphK;
}


vec4 toScreenSpace(vec3 v)
{
    if(render_MVP > 0)
        return MVP * vec4(v.x, v.y, v.z, 1);
    else
        return vec4(v.xyz * 0.2, 1) ;
}

vec4 levelColor(uint lvl, uint morphed)
{
    vec4 c = vec4(0.0, 0.0, 0.9, 1);
    c.r += (float(lvl) / 10.0);
    if (lvl % 2 == 1) {
        c.g += 0.5;
    }
    c = mix(c, RED, float(morphed)*0.5);
    return c;
}

#endif