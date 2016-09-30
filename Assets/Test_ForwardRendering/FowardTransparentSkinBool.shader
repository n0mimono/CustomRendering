Shader "Forward/ForwardTransparentSkinBool" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    _Alpha ("Alpha", Range(0, 1)) = 1

    _RimPower ("Rim Power", Float) = 1
    _RimAmplitude ("Rim Amplitude", Float) = 1
    _RimTint ("Rim Tint", Color) = (1,1,1,1)
  }
  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }

    CGINCLUDE
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float3 normal : NORMAL;
      };

      struct v2f {
        float2 uv : TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
        float3 normal : TEXCOORD2;
        float4 worldPos : TEXCOORD3;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;
      float _Alpha;

      float _RimPower;
      float _RimAmplitude;
      float4 _RimTint;

      v2f vert (appdata v) {
        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }
      
      fixed4 frag (v2f i) : SV_Target {
        fixed4 col = tex2D(_MainTex, i.uv);

        float3 normalDir = normalize(i.normal);
        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

        float NNdotV = 1 - dot(normalDir, viewDir);
        float rim = pow(NNdotV, _RimPower) * _RimAmplitude;
        col.rgb += rim * (1 - abs(_Alpha * 2 - 1)) * _RimTint.rgb;
        col.a = _Alpha * (1 + rim);

        UNITY_APPLY_FOG(i.fogCoord, col);

        return col;
      }
    ENDCG

    Pass {
      ColorMask 0
      Zwrite On

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      ENDCG
    }

    Pass {
      Blend SrcAlpha OneMinusSrcAlpha
      ZTest LEqual
      ZWrite Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      ENDCG
    }

  }
}
