Shader "Forward/ForwardTransparentSkinBool" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    _Alpha ("Alpha", Range(0, 1)) = 1

    [Header(Rim)]
    _RimPower ("Rim Power", Float) = 1
    _RimAmplitude ("Rim Amplitude", Float) = 1
    _RimTint ("Rim Tint", Color) = (1,1,1,1)

    [Header(Cut)]
    _CutRimPower ("Cut Rim Power", Float) = 3
    _CutRimAmplitude ("Cut Rim Amplitude", Float) = 10
    _CutRimOffset ("Cut Rim Tint", Float) = 0.1

    _CutAxis ("Cut Axis", Vector) = (0,1,0,0)
    _CutThreshold ("Cut Threshold", Float) = 0.5
    _CutColor ("Cut Color", Color) = (1,1,1,1)
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

      float _CutRimPower;
      float _CutRimAmplitude;
      float _CutRimOffset;

      float4 _CutAxis;
      float _CutThreshold;
      float4 _CutColor;

      v2f vert (appdata v) {
        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }

      float cutPosition(float3 pos) {
        return dot(pos, normalize(_CutAxis.xyz)) - _CutThreshold;
      }

      fixed4 frag_base(v2f i, bool useCutRim) {
        fixed4 col = tex2D(_MainTex, i.uv);

        float3 normalDir = normalize(i.normal);
        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

        float NNdotV = 1 - dot(normalDir, viewDir);
        float rim = pow(NNdotV, _RimPower) * _RimAmplitude;
        col.rgb += rim * (1 - abs(_Alpha * 2 - 1)) * _RimTint.rgb;
        col.a = _Alpha * (1 + rim);

        if (useCutRim) { 
          float4 cutRim = float4(_CutColor.rgb, _Alpha);
          float cutVal = max(0,_CutRimAmplitude*(cutPosition(i.worldPos.xyz) + _CutRimOffset));
          col = lerp(col, cutRim, saturate(pow(cutVal, _CutRimPower)));
        }

        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }

      fixed4 frag_face (v2f i) : SV_Target {
        if (cutPosition(i.worldPos.xyz) > 0) discard;
        return frag_base(i, true);
      }

      fixed4 frag_cut (v2f i) : SV_Target {
        if (cutPosition(i.worldPos.xyz) > 0) discard;
        return float4(_CutColor.rgb, _Alpha);
      }

      fixed4 frag_face_add (v2f i) : SV_Target {
        float4 col = frag_base(i, false);
        col.rgb = (col.r + col.b + col.g) / 3;
        col.a *= 0.4;
        return col;
      }
    ENDCG

    // 0: front depth
    Pass {
      ColorMask 0
      Zwrite On

      Stencil {
        Ref 1
        Comp Always
        Pass Replace
      }

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag_face
      ENDCG
    }

    // 1: cut
    Pass {
      Cull Front
      Blend SrcAlpha OneMinusSrcAlpha
      ZTest Less
      Zwrite On
      Offset 1,0

      Stencil {
        Ref 2
        Comp Greater
        Pass Replace
      }

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag_cut
      ENDCG
    }

    // 2: color
    Pass {
      Blend SrcAlpha OneMinusSrcAlpha
      ZTest LEqual
      ZWrite Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag_face
      #pragma multi_compile_fog
      ENDCG
    }

    // 3: front add depth
    Pass {
      ColorMask 0
      Zwrite On

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag_face_add
      ENDCG
    }

    // 4: front add color
    Pass {
      Blend SrcAlpha OneMinusSrcAlpha
      ZTest LEqual
      ZWrite Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag_face_add
      ENDCG
    }

  }
}
