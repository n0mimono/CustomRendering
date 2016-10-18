Shader "Raymarch/World_Castle" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _Mandel ("Mandel", Vector) = (2,14.8,0,1)
    _Rotate ("Rotate", Vector) = (0,1,0,0.46)
    _BoxFold ("Box Fold", Float) = 2.2

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
      float _BoxFold;

      #define FRAC_ITERATION 6
      #include "RaymarchModules.cginc"

      float sdFractalKaleidoBox(float3 p, float4 c, float4 rot, float l) {
        float a = c.w;
        float3 b = c.xyz;
        float r;

        for (int i = 0; i < 5; i++) {
          //p = fBoxFold(p, l);
        }

        for (int i = 0; i < FRAC_ITERATION; i++) {
          p = trRotate(p, rot);
          //p = fTetraFoldNegative(abs(p));
          p = fOctaFold(abs(p));

          p.z -= 0.5 * b.z * (a - 1) / a;
          p.z = abs(-p.z);
          p.z += 0.5 * b.z * (a - 1) / a;

          p = trRotate(p, rot);
          p.xy = p.xy * a + (1 - a) * b.xy;
          p.z = a * p.z;

        }
        return (length(p)-2) * pow(a, -FRAC_ITERATION);
      }

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);

        float d1 = sdFractalKaleidoBox(p, _Mandel, _Rotate, _BoxFold);
        return d1;
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
      #define RAY_ITERATION 128 // 64 // 128
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
