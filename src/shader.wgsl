struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) coord: vec2<f32>,
};



fn get_distance(p:vec3<f32>) -> f32 {
    let sphere = vec4<f32>(0.0,1.0,6.0,1.0);

    let sphere_distance = length(p-sphere.xyz)-sphere.w;
    let plane_distance = p.y;

    return min(sphere_distance,plane_distance);
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


fn get_light(p:vec3<f32>,surface_distance:f32) -> f32 {
    var light_position = vec3<f32>(0.0,5.0,6.0);
    let light = normalize(light_position-p);
    let normal = get_normal(p);

    var dif = clamp(dot(normal,light),0.0,1.0);
    let d = ray_march(p+normal*surface_distance*2.0,vec3<f32>(1.0,1.0,1.0),100,100.,0.01);

    if d < length(light_position-p) {
        dif *= 0.1;
    }

    return dif;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {    
    var col = vec3<f32>(0.0,0.0,0.0);

    let ray_origin = vec3<f32>(0.0,1.0,0.0);
    let ray_direction = normalize(vec3<f32>(in.coord.x,in.coord.y,1.0));

    let d = ray_march(ray_origin,ray_direction,100,100.,0.01);
    let light_point = ray_origin + ray_direction * d;
    let diffuse_lighting = get_light(light_point,0.01);
    // d /= 6.0;
    col = vec3<f32>(diffuse_lighting,diffuse_lighting,diffuse_lighting);
    // col = get_normal(light_point);
    
    return vec4<f32>(col,1.0);
}


@vertex
fn vs_main(in:VertexOutput) -> @builtin(position) vec4<f32> {
  return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}

