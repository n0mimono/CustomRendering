Shader "Raymarch/Sample/Sample05" {
  Properties {
    _Bailout ("Bailout", Float) = 1
    _Power ("Power", Float) = 1

    [Header(GBuffer)]
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)

     [Header(Framework)]
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)
    _LocalTangent ("Local Tangent", Vector) = (0.15,1.24,0.89,0)
    [Enum(Sphere,1,Box,2)] _ModelClip ("Model Clip", Float) = 1
  }
 	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

    CGINCLUDE
      #define ITERATION 4
      float _Bailout;
      float _Power;

      #include "RaymarchModules.cginc"
      float distFunc(float3 p) {
        // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
        float3 z = p;
        float dr = 1;
        float r = 0;
        for (int i = 0; i < ITERATION; i++) {
          r = length(z);
          if (r > _Bailout) break;
    
          float theta = acos(z.z/r);
          float phi = atan2(z.y, z.x);
          dr = pow(r, _Power-1)*_Power*dr + 1;

          float zr = pow(r, _Power);
          theta = theta * _Power;
          phi = phi * _Power;
    
          z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
          z += p;
        }
        return 0.5*log(r)*r/dr;
      }

      float2 uvFunc(float3 p) {
        return uvFuncSphere(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #include "RaymarchBasic.cginc"
    ENDCG

		Pass {
      Tags { "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma vertex vert_raymarch
			#pragma fragment frag_raymarch
     	ENDCG
		}
	}
}
