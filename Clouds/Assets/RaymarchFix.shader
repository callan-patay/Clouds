Shader "Custom/RaymarchFix" {

	Properties
	{
		_Radius("Radius", float) = 1
		_Centre("Centre", float) = 0
		_Volume("Texture", 3D) = "" {}
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

		sampler2D _MainTex;
	float _Radius;
	float _Centre;

#define STEPS 100
#define STEP_SIZE 0.02

	struct appdata {
		float4 vertex : POSITION;
	};

	struct v2f {
		float4 vertex : SV_POSITION;
		float3 wPos : TEXCOORD1; // World Position
	};


	sampler3D _Volume;

	v2f vert(appdata v) {
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		return o;
	}

	bool sphereHit(float3 p) {
		return distance(p, _Centre) < _Radius;
	}

	float3 texCoordsFromPosition(float3 position)
	{
		return position + float3(0.5, 0.5, 0.5);
	}

	float raymarchHit(float3 position, float3 direction) {
		float density = 0;
		for (int i = 0; i < STEPS; i++)
		{
			/*if (sphereHit(position))
			{
			return true;
			}*/
			float3 p = texCoordsFromPosition(position);
			if (p.x < 0 || p.x > 1.0 || p.y < 0 || p.y > 1.0 || p.z < 0 || p.z > 1.0)
			{
				return density;
			}
			float4 texel = tex3D(_Volume, texCoordsFromPosition(position));
			density += texel.r / STEPS;
			position += direction * STEP_SIZE;
		}
		return density;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		float3 worldPosition = i.wPos;
		float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
		float tp = raymarchHit(worldPosition, viewDirection);
		return (tp, tp, tp, tp);
	}
		ENDCG
	}
	}
}