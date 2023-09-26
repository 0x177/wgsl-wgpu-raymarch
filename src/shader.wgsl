struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) coord: vec2<f32>,
};


struct Uniforms {
    mouse: vec2<f32>,
    time: f32,
    screen_width: f32,
    screen_height: f32,
};

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;


@group(0) @binding(1)
var texture: texture_2d<f32>;


@group(0) @binding(2)
var tsampler: sampler;


fn get_rot_matrix(a:f32) -> mat2x2<f32> {
    let s = sin(a);
    let c = cos(a);

    return mat2x2<f32>(c,-s,s,c);
}

fn repeat(d:f32,domain:f32) -> f32 {
    return (d%domain)-domain/2.0;
}


fn smin(a:f32,b:f32,k:f32) -> f32 {
    let h:f32 = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
    return mix(a, b, h) - k*h*(1.0-h);
}

fn union_stairs(a:f32, b:f32,r:f32,n:f32) -> f32 {
	let s = r/n;
	let u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs (((u - a + s% 2.0 * s)) - s)));
}


fn vmax(v:vec2<f32>) -> f32 {
	return max(v.x, v.y);
}

fn vmax3(v:vec3<f32>) -> f32 {
	return max(max(v.x, v.y), v.z);
}

fn vmax4(v:vec4<f32>) -> f32 {
	return max(max(v.x, v.y), max(v.z, v.w));
}

fn vmin(v:vec2<f32>) -> f32 {
	return min(v.x, v.y);
}

fn vmin3(v:vec3<f32>) -> f32 {
	return min(min(v.x, v.y), v.z);
}

fn vmin4(v:vec4<f32>) -> f32 {
	return min(min(v.x, v.y), min(v.z, v.w));
}



fn signed_distance_bean(p:vec3<f32>,a:vec3<f32>,b:vec3<f32>,radius:f32) -> f32 {
    let ab = b-a;
    let ap = p-a;

    let t = clamp(dot(ab,ap) / dot(ab,ab),0.0,1.0);

    let c = a+t*ab;

    return length(p-c)-radius;
}

fn signed_distance_torus(p:vec3<f32>,radius:vec2<f32>) -> f32 {
    let x = length(p.xz)-radius.x;
    return length(vec2<f32>(x,p.y))-radius.y;
}

fn signed_distance_box(p:vec3<f32>,size:vec3<f32>) -> f32 {
    return length(max(abs(p)-size,vec3<f32>(0.0,0.0,0.0)));
}

fn signed_distance_box_endless(p:vec2<f32>,size:vec2<f32>) -> f32 {
    let d = abs(p)-size;
    return length(max(d,vec2<f32>(0.0)+ vmax(min(d,vec2<f32>(0.0)))));
}


fn mandelbulb(p: vec3<f32>,power:f32) -> f32 {
    var z = p;
    var dr = 1.0;
    var r = 0.0;

    for (var i = 0; i < 15; i++) {
        r = length(z);

        if r > 2.0 {
            break;
        }

        let theta = acos(z.z/r) * power;
        let phi = atan2(z.y,z.x) * power;
        let zr = pow(r,power);

        dr = pow(r,power - 1.0) * power * dr + 1.0;
        z = zr * vec3<f32>(sin(theta)*cos(phi),sin(phi)*sin(theta),cos(theta));
        z += p;
    }

    return 0.5 * log(r) * r / dr;
}

fn plane(p:vec3<f32>,normal:vec3<f32>,distance_from_origin:f32) -> f32 {
    return dot(p,normal) + distance_from_origin;
}

fn disc(p:vec3<f32>,r:f32) -> f32 {
    let l = length(p.xz) - r;
    if l < 0.0 {
        return abs(p.y);
    }

    return length(vec2<f32>(p.y,l));
}

fn hexagonal_circum_circle(p:vec3<f32>,h:vec2<f32>) -> f32 {
    let q = abs(p);
    return max(q.y - h.y, max(q.x*sqrt(3.0)*0.5 + q.z*0.5, q.z) - h.x);
}

fn get_distance(p:vec3<f32>) -> vec2<f32> {
    let sphere1 = vec4<f32>(0.0,1.0,6.0,1.0);
    let sphere2 = vec4<f32>(3.0,1.3,6.0,1.0);

    let sphere_distance = smin(length(p-sphere1.xyz)-sphere1.w,length(p-sphere2.xyz)-sphere2.w,0.5);
    let plane_distance = p.y;
    let capsule_distance = signed_distance_bean(p,vec3<f32>(1.0,1.0,6.0),vec3<f32>(3.0,2.0,6.0),0.2);
    let torus_distance = signed_distance_torus(p-vec3<f32>(-2.0,1.0,6.0),vec2<f32>(1.5,0.5));
    let cube_distance = signed_distance_box(p-vec3<f32>(-3.0,1.0,4.0),vec3<f32>(0.5,0.5,0.5));
    let bulb = mandelbulb(p+vec3<f32>(3.0,-1.0,-2.0),uniforms.time);

    let distance_smooth= smin(smin(sphere_distance,smin(smin(capsule_distance,smin(torus_distance,cube_distance,1.0),1.0),bulb,1.0),1.0),plane_distance,1.0);
    let distance= min(min(sphere_distance,min(min(capsule_distance,min(torus_distance,cube_distance)),bulb)),plane_distance);
    
    if distance == sphere_distance {
        return vec2<f32>(distance,1.0);
    }
    if distance == plane_distance {
        return vec2<f32>(distance,2.0);
    }
    if distance == capsule_distance {
        return vec2<f32>(distance,3.0);
    }
    if distance == torus_distance {
        return vec2<f32>(distance,4.0);
    }
    if distance == cube_distance {
        return vec2<f32>(distance,5.0);
    }
    if distance == bulb {
        return vec2<f32>(distance,6.0);
    }

    return vec2<f32>(distance_smooth,0.0);
}



fn get_normal(p:vec3<f32>) -> vec3<f32> {
    let distance = get_distance(p).x;
    let e = vec2<f32>(0.01,0.0);

    let normal = distance - vec3<f32>(
        get_distance(p-e.xyy).x,
        get_distance(p-e.yxy).x,
        get_distance(p-e.yyx).x,
    );

    return normalize(normal);
}

fn ray_march(ray_origin_unmut:vec3<f32>,ray_direction:vec3<f32>,max_steps:i32,max_distance:f32,surface_distance:f32) -> vec2<f32> {
    var distance_marched: f32 = 0.0;
    var ray_origin = ray_origin_unmut;

    var material = 0.0;

    for (var i = 0; i < max_steps; i += 1) {
        let p = ray_origin + ray_direction*distance_marched;
        let distance_to_scene = get_distance(p);
        distance_marched += distance_to_scene.x;

        material = distance_to_scene.y;

        if (distance_marched>max_distance || distance_to_scene.x<surface_distance) {break;}
    }
    
    return vec2<f32>(distance_marched,material);   
}


fn get_light(p:vec3<f32>,surface_distance:f32,max_steps:i32,max_distance:f32) -> f32 {
    var light_position = vec3<f32>(2.0,5.0,3.0);
    let temp_pos = light_position.xz * get_rot_matrix(uniforms.time);
    light_position.x = temp_pos.x;
    light_position.z = temp_pos.y;
    let light = normalize(light_position-p);
    let normal = get_normal(p);

    
    var dif = clamp(dot(normal,light),0.0,1.0);
    let d = ray_march(p+normal*surface_distance*2.0,vec3<f32>(1.0,1.0,1.0),max_steps,max_distance,surface_distance).x;

    if d < length(light_position-p) {
        dif *= 0.1;
    }

    return dif;
}


fn tri_planar_mapping(light_point:vec3<f32>,texture:texture_2d<f32>,tsampler:sampler) -> vec3<f32> {
    let texture_col_xz = textureSample(texture,tsampler,light_point.xz*0.5+0.5).xyz;
    let texture_col_yz = textureSample(texture,tsampler,light_point.yz*0.5+0.5).xyz;
    let texture_col_xy = textureSample(texture,tsampler,light_point.xy*0.5+0.5).xyz;
    let norm = abs(get_normal(light_point));
    return texture_col_yz*norm.x + texture_col_xz*norm.y + texture_col_xy*norm.z;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {   
    var col = vec3<f32>(0.0,0.0,0.0);
    let max_steps: i32 = 100;
    let max_distance: f32 = 100.0;
    let surface_distance: f32 = 0.01; 

    let ray_origin = vec3<f32>(0.0,1.0,0.0);
    let ray_direction = normalize(vec3<f32>(in.coord.x+uniforms.mouse.x,in.coord.y+uniforms.mouse.y,1.0));

    let d = ray_march(ray_origin,ray_direction,max_steps,max_distance,surface_distance);
    let light_point = ray_origin + ray_direction * d.x;
    let diffuse_lighting = get_light(light_point,surface_distance,max_steps,max_distance);
    col = vec3<f32>(diffuse_lighting);
    let material = i32(d.y);
    // let texture_col_xz = textureSample(texture,tsampler,light_point.xz*0.5+0.5).xyz;
    // let texture_col_yz = textureSample(texture,tsampler,light_point.yz*0.5+0.5).xyz;
    // let texture_col_xy = textureSample(texture,tsampler,light_point.xy*0.5+0.5).xyz;
    // let norm = abs(get_normal(light_point));
    if material == 1 {
        col = tri_planar_mapping(light_point,texture,tsampler);
    }
    if material == 2 {
        col = tri_planar_mapping(light_point,texture,tsampler);
    }
    if material == 3 {
        col = vec3<f32>(253./255.,103./255.,58./255.);
    }
    if material == 4 {
        col = vec3<f32>(253./255.,103./255.,58./255.);
    }
    if material == 5 {
        col = tri_planar_mapping(light_point,texture,tsampler);
    }
    if material == 6 {
        col = vec3<f32>(0.8,0.0,0.4);
    }

    col *= diffuse_lighting;
    //gamma correction
    col = pow(col,vec3<f32>(0.4545,0.4545,0.4545));
    
    return vec4<f32>(col,1.0);
}


@vertex
fn vs_main() -> @builtin(position) vec4<f32> {
  return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}