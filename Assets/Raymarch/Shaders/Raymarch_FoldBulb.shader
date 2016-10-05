Shader "Raymarch/FoldBulb" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _Mandel ("Mandel", Vector) = (1,1,0.5,1)

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
      float4 _Size;
      float4 _Mandel;

      #define USE_CLIP_THRESHOLD 0
      #define FRAC_ITERATION 4
      #include "RaymarchModules.cginc"

      float sdFunc(float3 p, float bailout, float power, float l, float t) {
        float3 z = p;
        float dr = 1;
        float r = 0;
        for (int i = 0; i < FRAC_ITERATION; i++) {
          z = fBoxFold(z, l);

          r = length(z);
          if (r > bailout) break;

          float theta = acos(z.z/r);
          float phi = atan2(z.y, z.x);
          dr = pow(r, power-1)*power*dr + 1;

          float zr = pow(r, power);
          theta = theta * power;
          phi = phi * power;

          z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
          z += p;
        }
        return 0.5*log(r)*r/dr;
      }

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);
        return sdFunc(p, _Mandel.x, _Mandel.y, _Mandel.z, _Mandel.w);
      }

      float2 uvFunc(float3 p) {
        return uvFuncBox(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      //#define USE_UNSCALE 0
      #include "RaymarchCore.cginc"
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
