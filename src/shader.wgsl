struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) coord: vec2<f32>,
};


fn get_rot_matrix(a:f32) -> mat2x2<f32> {
    let s = sin(a);
    let c = cos(a);

    return mat2x2<f32>(c,-s,s,c);
}

fn get_material(i:i32) -> vec3<f32> {
    return vec3<f32>(0.89,0.109,0.474);
}

fn smin(a:f32,b:f32,k:f32) -> f32 {
  let h:f32 = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

fn signed_distance_bean(p:vec3<f32>,a:vec3<f32>,b:vec3<f32>,radius:f32) -> f32 {
    let ab = b-a;
    let ap = p-a;

    let t = clamp(dot(ab,ap) / dot(ab,ab),0.0,1.0);

    let c = a+t*ab;

    return length(p-c)-radius;
}

fn signed_distance_doughnut(p:vec3<f32>,radius:vec2<f32>) -> f32 {
    let x = length(p.xz)-radius.x;
    return length(vec2<f32>(x,p.y))-radius.y;
}

fn signed_distance_box(p:vec3<f32>,size:vec3<f32>) -> f32 {
    return length(max(abs(p)-size,vec3<f32>(0.0,0.0,0.0)));
}

fn get_distance(p:vec3<f32>) -> f32 {
    let sphere1 = vec4<f32>(0.0,1.0,6.0,1.0);
    let sphere2 = vec4<f32>(1.0,1.3,6.0,1.0);

    let sphere_distance = max(-length(p-sphere1.xyz)-sphere1.w,length(p-sphere2.xyz)-sphere2.w);
    let plane_distance = p.y;
    let capsule_distance = signed_distance_bean(p,vec3<f32>(1.0,1.0,6.0),vec3<f32>(3.0,2.0,6.0),0.2);
    let torus_distance = signed_distance_doughnut(p-vec3<f32>(-2.0,1.0,6.0),vec2<f32>(1.5,0.5));
    let cube_distance = signed_distance_box(p-vec3<f32>(-3.0,2.0,4.0),vec3<f32>(0.5,0.5,0.5));

    return min(smin(capsule_distance,smin(min(sphere_distance,cube_distance),torus_distance,0.5),0.5),plane_distance);
}

fn get_normal(p:vec3<f32>) -> vec3<f32> {
    let distance = get_distance(p);
    let e = vec2<f32>(0.01,0.0);

    let normal = distance - vec3<f32>(
        get_distance(p-e.xyy),
        get_distance(p-e.yxy),
        get_distance(p-e.yyx),
    );

    return normalize(normal);
}

fn ray_march(ray_origin_unmut:vec3<f32>,ray_direction:vec3<f32>,max_steps:i32,max_distance:f32,surface_distance:f32) -> f32 {
    var distance_marched: f32 = 0.0;
    var ray_origin = ray_origin_unmut;

    for (var i = 0; i < max_steps; i += 1) {
        let p = ray_origin + ray_direction*distance_marched;
        let distance_to_scene = get_distance(p);
        distance_marched += distance_to_scene;

        if (distance_marched>max_distance || distance_to_scene<surface_distance) {break;}
    }
    
    return distance_marched;   
}


fn get_light(p:vec3<f32>,surface_distance:f32,max_steps:i32,max_distance:f32,id:i32) -> vec3<f32> {
    let color = get_material(id);
    var light_position = vec3<f32>(2.0,5.0,3.0);
    let temp_pos = light_position.xz * get_rot_matrix(3.1415/2.0);
    light_position.x = temp_pos.x;
    light_position.z = temp_pos.y;
    let light = normalize(light_position-p);
    let normal = get_normal(p);

    
    var dif = color * clamp(dot(normal,light),0.0,1.0);
    let d = ray_march(p+normal*surface_distance*2.0,vec3<f32>(1.0,1.0,1.0),max_steps,max_distance,surface_distance);

    if d < length(light_position-p) {
        dif *= 0.1;
    }

    return dif;
}


@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {    
    var col = vec3<f32>(0.0,0.0,0.0);
    let max_steps: i32 = 100;
    let max_distance: f32 = 100.0;
    let surface_distance: f32 = 0.01; 

    let ray_origin = vec3<f32>(0.0,1.0,0.0);
    let ray_direction = normalize(vec3<f32>(in.coord.x,in.coord.y,1.0));

    let d = ray_march(ray_origin,ray_direction,max_steps,max_distance,surface_distance);
    let light_point = ray_origin + ray_direction * d;
    let diffuse_lighting = get_light(light_point,surface_distance,max_steps,max_distance,1);
    col = diffuse_lighting;
    
    return vec4<f32>(col,1.0);
}


@vertex
fn vs_main() -> @builtin(position) vec4<f32> {
  return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}