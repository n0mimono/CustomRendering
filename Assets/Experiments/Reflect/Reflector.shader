Shader "Reflect/Reflector" {
  Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _SpecularGloss ("Specular Gloss", Color) = (1,1,1,1)
    _Emission ("Emission", Color) = (0,0,0,0)
    _MainTex ("Texture", 2D) = "white" {}
    _BumpMap ("Normals", 2D) = "bump" {}

    [Toggle] _UseSphereMesh ("Use Sphere Mesh", Float) = 1
    [Toggle] _ClipOrientation ("Clip Orientation", Float) = 0
  }
  SubShader {
    Pass {
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag

      #include "UnityCG.cginc"

      struct v2f {
        float4 pos         : SV_POSITION;
        float4 spos        : TEXCOORD1;
        float3 ray         : TEXCOORD2;
        float3 orientation : TEXCOORD3;
        float3 orientationX : TEXCOORD4;
        float3 orientationZ : TEXCOORD5;
      };
      
      v2f vert (float3 v: POSITION) {
        v2f o;
        o.pos = mul(UNITY_MATRIX_MVP, float4(v, 1));
        o.spos = ComputeScreenPos(o.pos);
        o.ray = mul(UNITY_MATRIX_MV, float4(v, 1)).xyz * float3(-1, -1, 1);
        o.orientation = mul((float3x3)unity_ObjectToWorld, float3(0, 1, 0));
        o.orientationX = mul ((float3x3)unity_ObjectToWorld, float3(1,0,0));
        o.orientationZ = mul ((float3x3)unity_ObjectToWorld, float3(0,0,1));

        return o;
      }

      float4 _Color;
      float4 _SpecularGloss;
      float4 _Emission;

      sampler2D _MainTex;
      sampler2D _BumpMap;
      sampler2D_float _CameraDepthTexture;
      sampler2D _NormalsCopy;

      float _UseSphereMesh;
      float _ClipOrientation;

      void frag (v2f i,
        out half4 outDiffuse  : COLOR0,
        out half4 outSpecular : COLOR1,
        out half4 outNormal   : COLOR2,
        out half4 outEmission : COLOR3
      ) {

        // reconstruction
        i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
        float2 uv = i.spos.xy / i.spos.w;
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
        depth = Linear01Depth(depth);

        float4 vpos = float4(i.ray * depth, 1);
        float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
        float3 opos = mul (unity_WorldToObject, float4(wpos, 1)).xyz;

        if (_UseSphereMesh) {
          clip (0.5 - length(opos.xyz));
        } else {
          clip (float3(0.5,0.5,0.5) - abs(opos.xyz));
        }
        float2 uv0 = opos.xz + 0.5;

        half4 normal = tex2D(_NormalsCopy, uv);
        fixed3 wnormal = normal.rgb * 2.0 - 1.0;

        // clipping
        if (_ClipOrientation) {
          clip (dot(wnormal, i.orientation) - 0.3);
        }
        clip (tex2D (_MainTex, uv0).r - 0.2);

        // 
        float3 normalDir = normalize(i.orientation);
        float3 viewDir   = normalize(_WorldSpaceCameraPos.xyz - wpos.xyz);
        float3 refDir    = reflect(-viewDir, normalDir);

        int n = 20;
        float3 tint = float3(1,1,1);
        for (int k = 1; k < n; k++) {
          float3 rayPos   = wpos + k * refDir / n * 10;
          float4 rayVpPos = mul(UNITY_MATRIX_VP, float4(rayPos, 1));
          float  rayDepth = rayVpPos.z / rayVpPos.w;
          float2 rayUv    = rayVpPos.xy / rayVpPos.w * 0.5 + 0.5;
          float  gDepth   = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, rayUv);
          if (rayDepth - gDepth > 0) {
            tint = tex2D(_NormalsCopy, rayUv);
            break;
          }
        }

        // diffuse
        fixed4 col = _Color;
        outDiffuse = col;
        outDiffuse = float4(tint, 1); //float4(refDir * tint, 1);

        // fixed specular
        outSpecular = _SpecularGloss;

        // normal
        fixed3 nor = UnpackNormal(tex2D(_BumpMap, uv0));
        half3x3 norMat = half3x3(i.orientationX, i.orientationZ, i.orientation);
        nor = mul (nor, norMat);
        outNormal = fixed4(nor*0.5+0.5,0);

        // fixed emission
        outEmission = _Emission;
      }
      ENDCG
    }
  }
}
