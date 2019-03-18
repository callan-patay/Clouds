// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RayMarch" {

	Properties
	{

		_Volume("Texture", 3D) = "" {}
		_Color("Color", Color) = (1, 1, 1, 1)
		_Threshold("Threshold", Range(0.0, 1.0)) = 0.95
	}
		SubShader
	{
		// No culling or depth
		//Cull Off ZWrite Off ZTest Always
			Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
			LOD 100

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"


			#define STEPS 100
			#define STEP_SIZE 0.01

			struct appdata {
			float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD1; // World Position
			};

			struct Ray {
				float3 origin;
				float3 dir;
			};


			sampler3D _Volume;
			half _Threshold;
			half4 _Color;

			v2f vert(appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			float3 texCoordsFromPosition(float3 position)
			{
				float3 npos = mul(unity_WorldToObject, float4(position, 1.0)).xyz;
				return npos + float3(0.5, 0.5, 0.5);
			}

			bool outsideTexture(float3 uv)
			{
				const float EPSILON = 0.01;
				float lower = -EPSILON;
				float upper = 1 + EPSILON;
				return (
					uv.x < lower || uv.y < lower || uv.z < lower ||
					uv.x > upper || uv.y > upper || uv.z > upper
					);
			}

			fixed4 raymarchHit(Ray r) {

				float4 density = (0.0, 0.0, 0.0, 0.0);

				for (int i = 0; i < STEPS; i++)
				{

					float3 p = texCoordsFromPosition(r.origin);

					if (outsideTexture(p))
					{
						return density;
					}
					float4 texel = tex3D(_Volume, texCoordsFromPosition(r.origin));
					density += texel.r / STEPS;
					//density = 1.0f;
					r.origin += r.dir * STEP_SIZE;


					if (density.a > _Threshold) break;




				}
				return saturate(density) * _Color;
				//return density;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				Ray ray;
				float3 worldPosition = i.wPos;
				float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
				ray.origin = worldPosition;// mul(unity_WorldToObject, float4(worldPosition, 1.0)).xyz;
				ray.dir = viewDirection;// mul(unity_WorldToObject, float4(viewDirection, 0)).xyz;

				return raymarchHit(ray);
		  }
		  ENDCG
	  }
	}
}