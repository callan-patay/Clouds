Shader "Custom/RaymarchFix" {

	Properties
	{
		_Volume("Texture", 3D) = "" {}
		_Volume1("Texture 2", 3D) = "" {}
		_Intensity("Intensity", Range(1.0, 5.0)) = 1.2
		_Threshold("Threshold", Range(0.0, 1.0)) = 0.95
		_SliceMin("Slice min", Vector) = (0.0, 0.0, 0.0, -1.0)
		_SliceMax("Slice max", Vector) = (1.0, 1.0, 1.0, -1.0)
		_Color("Color", Color) = (1, 1, 1, 1)
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
#define STEP_SIZE 0.02

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

	struct AABB {
		float3 min;
		float3 max;
	};

	half4 _Color;
	sampler3D _Volume;
	sampler3D _Volume1;
	half _Intensity, _Threshold;
	half3 _SliceMin, _SliceMax;
	float4x4 _AxisRotationMatrix;
	v2f vert(appdata v) {
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		return o;
	}

	float3 texCoordsFromPosition(float3 position)
	{
		return position + float3(0.5, 0.5, 0.5);
	}

	bool intersect(Ray r, AABB aabb, out float t0, out float t1)
	{
		float3 invR = 1.0 / r.dir;
		float3 tbot = invR * (aabb.min - r.origin);
		float3 ttop = invR * (aabb.max - r.origin);
		float3 tmin = min(ttop, tbot);
		float3 tmax = max(ttop, tbot);
		float2 t = max(tmin.xx, tmin.yz);
		t0 = max(t.x, t.y);
		t = min(tmax.xx, tmax.yz);
		t1 = min(t.x, t.y);
		return t0 <= t1;
	}

	float sample_volume(float3 uv, float3 p)
	{
		float v = tex3D(_Volume, uv).r * _Intensity;

		float3 axis = mul(_AxisRotationMatrix, float4(p, 0)).xyz;
		axis = texCoordsFromPosition(axis);
		float min = step(_SliceMin.x, axis.x) * step(_SliceMin.y, axis.y) * step(_SliceMin.z, axis.z);
		float max = step(axis.x, _SliceMax.x) * step(axis.y, _SliceMax.y) * step(axis.z, _SliceMax.z);

		return v * min * max;
	}

	float sample_volume1(float3 uv, float3 p)
	{
		float v = tex3D(_Volume1, uv).r * _Intensity;

		float3 axis = mul(_AxisRotationMatrix, float4(p, 0)).xyz;
		axis = texCoordsFromPosition(axis);
		float min = step(_SliceMin.x, axis.x) * step(_SliceMin.y, axis.y) * step(_SliceMin.z, axis.z);
		float max = step(axis.x, _SliceMax.x) * step(axis.y, _SliceMax.y) * step(axis.z, _SliceMax.z);

		return v * min * max;
	}

	fixed4 raymarchHit(Ray r) {
		AABB aabb;

		aabb.min = float3(r.origin.x  - 0.5f, r.origin.y - 0.5f, r.origin.z - 0.5f);
		aabb.max = float3(r.origin.x + 0.5f, r.origin.y + 0.5f, r.origin.z + 0.5f);
		float tnear;
		float tfar;
		intersect(r, aabb, tnear, tfar);

		tnear = max(0.0, tnear);

		float4 density = (0.0, 0.0, 0.0, 0.0);

		float3 start = r.origin;
		float3 end = r.origin + r.dir * tfar;
		//float dist = abs(tfar - tnear); 
		float dist = distance(start, end);
		float step_size = dist / float(STEPS);
		//float step_size = 0.04f;
		float3 ds = normalize(end - start) * step_size;
		float3 p = start;
		for (int i = 0; i < STEPS; i++)
		{

			//float3 p = texCoordsFromPosition(r.origin);
			//if (p.x < 0 || p.x > 1.0 || p.y < 0 || p.y > 1.0 || p.z < 0 || p.z > 1.0)
			//{
			//	return density;
			//}
			//float4 texel = tex3D(_Volume, texCoordsFromPosition(r.origin));
			//density += texel.r / STEPS;
			////density = 1.0f;
			//r.origin += r.dir * STEP_SIZE;

			float3 uv = texCoordsFromPosition(p);
			float v = sample_volume(uv, p);
			float v1 = sample_volume1(uv, p);
			float4 src = float4(v1, v1, v1, v1) + float4(v,v,v,v);
			src.a *= 0.5;
			src.rgb *= src.a;

			// blend
			density = (1.0 - density.a) * src + density;
			p += ds;

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
		ray.origin = worldPosition;
		ray.dir = viewDirection;

		float4 tp = raymarchHit(ray);
		return tp;
	}
		ENDCG
	}
	}
}