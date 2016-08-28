// http://docs.unity3d.com/ja/current/Manual/GraphicsCommandBuffers.html

Shader "GrabBlur/Blur" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
  }
  SubShader {
    Pass {
      ZTest Always
      ZWrite Off
      Cull Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        float4 uv2 : TEXCOORD2;
        float4 uv3 : TEXCOORD3;
      };

      float4 offsets;
      sampler2D _MainTex;

      v2f vert (appdata v) {
        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

        o.uv = v.uv;
        o.uv1 = v.uv.xyxy + offsets.xyxy * float4(1,1, -1,-1) * 1;
        o.uv2 = v.uv.xyxy + offsets.xyxy * float4(1,1, -1,-1) * 2;
        o.uv3 = v.uv.xyxy + offsets.xyxy * float4(1,1, -1,-1) * 3;

        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }
      
      fixed4 frag (v2f i) : SV_Target {
        fixed4 col = half4(0,0,0,0);

        col += 0.40 * tex2D(_MainTex, i.uv);
        col += 0.15 * tex2D(_MainTex, i.uv1.xy);
        col += 0.15 * tex2D(_MainTex, i.uv1.zw);
        col += 0.10 * tex2D(_MainTex, i.uv2.xy);
        col += 0.10 * tex2D(_MainTex, i.uv2.zw);
        col += 0.05 * tex2D(_MainTex, i.uv3.xy);
        col += 0.05 * tex2D(_MainTex, i.uv3.zw);

        return col;
      }
      ENDCG
    }
  }
}
