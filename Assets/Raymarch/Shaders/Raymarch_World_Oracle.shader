Shader "Raymarch/World_Oracle" {
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

      #define FRAC_ITERATION 5
      #include "RaymarchModules.cginc"

      float sdFunc_Frac(float3 p, float4 c, float4 rot, float l) {
        float3 z = p;
        float dr = 1;
        float r = 0;
        float power = c.y;

        for (int i = 0; i < 4; i++) {
          z = fBoxFold(z, l);
        }

        for (int i = 0; i < 1; i++) {          
          z = fBoxFold(z, l);
          z = trRotate(z, rot);

          //z = fTetraFold(z);          
          z = fTetraFold(fTetraFoldNegative(z));
          //z = fTetraFoldNegative(abs(z));
          //z = fOctaFold(abs(z));

          r = length(z);
          if (r > c.x) break;

          float theta = acos(z.z/r);
          float phi = atan2(z.y, z.x);
          dr = pow(r, power-1)*power*dr + 1;

          float zr = pow(r, power);
          theta = theta * power;
          phi = phi * power;

          z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
          z += p;
        }

        for (int i = 0; i < 8; i++) {
          z = fBoxFold(z, l);
        }
        r = length(z);

        return 0.5*log(r)*r/dr;
      }

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);

        float d1 = sdFunc_Frac(p, _Mandel, _Rotate, _BoxFold);
        return d1;
      }

      float2 uvFunc(float3 p) {
        return uvFuncQuartz(p);
      }

      float4 diffuseFunc(float3 p, float d, float i) {
        return float4(p.z * 0.1 + 0.4 + d, p.x * p.y * 0.02 + 0.7, p.y * 0.05 + p.z * 0.2 + 0.5,1);
      }

      #define DIFFUSE_FUNC diffuseFunc
      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
      #define NORMAL_PRECISION 0.01
      #define CHECK_CONV_BY_CLIP_THRESHOLD 1
      #define USE_CLIP_THRESHOLD 1
      #define CLIP_THRESHOLD 0.5
      #define RAY_ITERATION 64 //32 //128
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
