Shader "Melt/Melter" {
	Properties {
    _SampleDistance ("Sample Distance", Float) = 1
    _WeightFactor ("Weight Factor", Float) = 1
	}
	SubShader {
		Pass {
      ZWrite Off

      CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

      struct ap {
        float4 vertex: POSITION;
        float3 normal : NORMAL;
      };

      struct v2f {
        float4 pos    : SV_POSITION;
        float4 spos   : TEXCOORD1;
        float3 ray    : TEXCOORD2;
        float3 normal : TEXCOORD3;
        float4 wpos   : TEXCOORD4;
      };

			v2f vert (ap v) {
				v2f o;
				o.pos    = mul(UNITY_MATRIX_MVP, v.vertex);
        o.spos   = ComputeScreenPos(o.pos);
        o.ray    = mul(UNITY_MATRIX_MV, v.vertex).xyz * float3(-1, -1, 1);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.wpos   = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

      sampler2D_float _CameraDepthTexture;
      float4 _CameraDepthTexture_TexelSize;

      sampler2D _CameraGBufferTexture0;
      sampler2D _CameraGBufferTexture1;
      sampler2D _CameraGBufferTexture2;
      sampler2D _CameraGBufferTexture3;
      float4x4 _InvViewProj;

      float _SampleDistance;
      float _WeightFactor;

      float overlay(float a, float b) {
        if (a < 0.5) {
          return 1 - 2 * (1 - a) * (1 - b);
        } else {
          return 2 * (a * b);
        }
      }

      float4 worldPosition(float2 uv, float d) {
        float2 spos = uv * 2 - 1;
        float4 wpos = mul(_InvViewProj, float4(spos, d, 1));
        wpos /= wpos.w;
        return wpos;
      }

			void frag (v2f i,
        out half4 outDiffuse  : COLOR0,
        out half4 outSpecular : COLOR1,
        out half4 outNormal   : COLOR2,
        out half4 outEmission : COLOR3
      ) {
        // sphere weight
        float3 normalDir = normalize(i.normal);
        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
        float NdotV = max(0,dot(normalDir, viewDir));

        // screen space uv
        i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
        float2 uv0 = i.spos.xy / i.spos.w;

        // nine sampling
        float2 offsets[9] = {
          float2( 0,  0),
          float2( 1,  0),
          float2( 1,  1),
          float2( 0,  1),
          float2(-1,  1),
          float2(-1,  0),
          float2(-1, -1),
          float2( 0, -1),
          float2( 1, -1),
        };

        // uvs, depths
        // and we select the index whoose mininum depth.
        float2 uv[9];
        float depth[9];
        int minIdx = 0;
        float minDepth = 1;
        for (int j = 0; j < 9; j++) {
          uv[j] = uv0 + offsets[j] * _SampleDistance * _CameraDepthTexture_TexelSize.x;
          depth[j] = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv[j]);

          if (depth[j] < minDepth) {
            minDepth = depth[j];
            minIdx = j;
          }
        }

        // we calculate the weights based on world distance;
        float w = 0;
        float weights[9];
        float4 wposMin = worldPosition(uv[minIdx], depth[minIdx]);
        for (int j = 0; j < 9; j++) {
            float4 wpos = worldPosition(uv[j], depth[j]);
            float dist = length(wposMin.xyz - wpos.xyz);
            weights[j] = 1 / (1 + dist * _WeightFactor);
            w += weights[j];
        }

        // re-weight
        //weights[0] += NdotV;
        for (int j = 0; j < 9; j++) weights[j] /= w;

        // center g buffer
        float4 buffer[4] = { float4(0,0,0,0), float4(0,0,0,0), float4(0,0,0,0), float4(0,0,0,0) };
        for (int j = 0; j < 9; j++) buffer[0] += tex2D(_CameraGBufferTexture0, uv[j]) * weights[j];
        for (int j = 0; j < 9; j++) buffer[1] += tex2D(_CameraGBufferTexture1, uv[j]) * weights[j];
        for (int j = 0; j < 9; j++) buffer[2] += tex2D(_CameraGBufferTexture2, uv[j]) * weights[j];
        for (int j = 0; j < 9; j++) buffer[3] += tex2D(_CameraGBufferTexture3, uv[j]) * weights[j];

        // output
        outDiffuse  = buffer[0];
        outSpecular = buffer[1];
        outNormal   = buffer[2];
        outEmission = buffer[3];

        //outNormal = float4(1,1,1,1) * NdotV;

 			}
			ENDCG
		}
	}
}
