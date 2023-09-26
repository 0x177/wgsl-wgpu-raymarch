# wgsl-wgpu-raymarch
this is a smiple raymarcher in wgsl.  it includes many useful functions and primitive SDFs. many of them are transcribed from [mecury demo team's GLSL library](https://mercury.sexy/hg_sdf/)

you can add true bump mapping for free by sampling a texture and adding the red channel to the distance returned from the SDF. i didnt add it because i dont plan to continue using WGSL. i will port this to another more capable language (probably rust-gpu)
and add the missing features there.

## WARNING
this code doesnt utilize whatever new wgsl features are there becuase the backend is outdated (wgpu is 3 versions behind as of the time i am writing this)
