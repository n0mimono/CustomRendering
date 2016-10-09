Shader "Raymarch/World_Garden" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _Mandel ("Mandel", Vector) = (1,1,0.5,1)
    _Rotate ("Rotate 1", Vector) = (0,1,0,0.4)

    [Header(GBuffer)]
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)

     [Header(Framework)]
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)
    _LocalTangent ("Local Tangent", Vector) = (0.15,1.24,0.89,0)
  }
 	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

    CGINCLUDE
      float4 _Size;
      float4 _Mandel;
      float4 _Rotate;

      #define FRAC_ITERATION 10
      #include "RaymarchModules.cginc"

      float sdFunc_GroundBall(float3 p) {
        p = trRotate(p, M_PI / 4, float3(0,1,0));

        float d1 = sdBox(p + float3(0,10,0), float3(1,10,1));
        float d2 = sdSphere(p + float3(0,3,0), 2.5);

        float3 p3 = trRotate(p, M_PI / 4, float3(0,1,0));
        float d3 = sdBox(p3 + float3(0,25,0), float3(3.5,20,3.5));

        return opUni(opUni(d1, d2, 4), d3, 2);
      }


float sdFractalKaleido_tmp(float3 p, float4 c, float4 r1, float4 r2) {
  float a = c.w;
  float3 b = c.xyz;
  float r;
  for (int i = 0; i < FRAC_ITERATION; i++) {
    p = trRotate(p, r1);
    p = fTetraFoldNegative(abs(p));

    p.z -= 0.5 * b.z * (a - 1) / a;
    p.z = abs(-p.z);
    p.z += 0.5 * b.z * (a - 1) / a;

    p = trRotate(p, r2);
    p.xy = p.xy * a + (1 - a) * b.xy;
    p.z = a * p.z;

  }
  return (length(p)-2) * pow(a, -FRAC_ITERATION);
}

      float distFunc(float3 p) {
        float d0 = sdFunc_GroundBall(p);
        p = trScale(p, _Size.xyz / _Size.w);

        float d1 = sdFractalKaleido_tmp(p, _Mandel, _Rotate, _Rotate);
        return d1;
        //return opUni(d1, d0);
      }

      float2 uvFunc(float3 p) {
        return uvFuncQuartz(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
      #define NORMAL_PRECISION 0.01
      #define CHECK_CONV_BY_CLIP_THRESHOLD 1
      #define USE_CLIP_THRESHOLD 1
      #define CLIP_THRESHOLD 0.5
      #define RAY_ITERATION 64 // 128
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
