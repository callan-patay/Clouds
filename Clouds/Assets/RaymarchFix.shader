﻿Shader "Custom/RaymarchFix" {
	Properties
	{
		_Volume("Texture", 3D) = "" {}
		_Volume1("Texture 2", 3D) = "" {}
		_Intensity("Intensity", Range(1.0, 5.0)) = 1.2
		_Threshold("Threshold", Range(0.0, 1.0)) = 0.95
		_SliceMin("Slice min", Vector) = (0.0, 0.0, 0.0, -1.0)
		_SliceMax("Slice max", Vector) = (1.0, 1.0, 1.0, -1.0)
		_Color("Color", Color) = (1, 1, 1, 1)
		_LightDir("LightDir", Vector) = (0.0, 0.0, 0.0, -1.0)

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
		float3 npos = mul(unity_WorldToObject, float4(position, 1.0)).xyz;
		return npos + float3(0.5, 0.5, 0.5);
	}

	//bool intersect(Ray r, AABB aabb, out float t0, out float t1)
	//{
	//	float3 invR = 1.0 / r.dir;
	//	float3 tbot = invR * (aabb.min - r.origin);
	//	float3 ttop = invR * (aabb.max - r.origin);
	//	float3 tmin = min(ttop, tbot);
	//	float3 tmax = max(ttop, tbot);
	//	float2 t = max(tmin.xx, tmin.yz);
	//	t0 = max(t.x, t.y);
	//	t = min(tmax.xx, tmax.yz);
	//	t1 = min(t.x, t.y);
	//	return t0 <= t1;
	//}

	//float sample_volume(float3 uv, float3 p, sampler3D _Volumes)
	//{
	//	float v = tex3D(_Volumes, uv).r * _Intensity;

	//	float3 axis = mul(_AxisRotationMatrix, float4(p, 0)).xyz;
	//	axis = texCoordsFromPosition(axis);
	//	float min = step(_SliceMin.x, axis.x) * step(_SliceMin.y, axis.y) * step(_SliceMin.z, axis.z);
	//	float max = step(axis.x, _SliceMax.x) * step(axis.y, _SliceMax.y) * step(axis.z, _SliceMax.z);

	//	return v * min * max;
	//}

	//half3 _Scale;
	//half3 _Pos;

	bool outside(float3 uv)
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
		//AABB aabb;

		//aabb.min = float3( -0.5f, -0.5f, -0.5f);
		//aabb.max = float3(0.5f, 0.5f, 0.5f);

		//float tnear;
		//float tfar;
		//intersect(r, aabb, tnear, tfar);

		//tnear = max(0.0, tnear);

		float4 density = (0.0, 0.0, 0.0, 0.0);

		//float3 start = r.origin;
		//float3 end = r.origin + r.dir * tfar;
		////float dist = abs(tfar - tnear); 
		//float dist = distance(start, end);
		//float step_size = dist / float(STEPS);
		////float step_size = 0.04f;
		//float3 ds = normalize(end - start) * step_size;
		//float3 p = start;
		for (int i = 0; i < STEPS; i++)
		{

			float3 p = texCoordsFromPosition(r.origin);
/*			if (p.x < 0 || p.x > 1.0 || p.y < 0 || p.y > 1.0 || p.z < 0 || p.z > 1.0)
			{
				return density;
			}*/	
			if (outside(p))
			{
				return density;
			}
			float4 texel = tex3D(_Volume, texCoordsFromPosition(r.origin));
			density += texel.r / STEPS;
			//density = 1.0f;
			r.origin += r.dir * STEP_SIZE;



		
			//float3 uv = texCoordsFromPosition(p);
			//float v = sample_volume(uv, p, _Volume);
			//float v1 = sample_volume(uv, p, _Volume1);
			//float4 src = float4(v1, v1, v1, v1) + float4(v,v,v,v);
			//src.a *= 0.5;
			//src.rgb *= src.a;

			//// blend
			//density = (1.0 - density.a) * src + density;

			//p += ds;

			//if (density.a > _Threshold) break;




		}
		//return saturate(density) * _Color;
		return density;
	}

	float2 coefficients(float3 wpos)
	{
			float3 npos = mul(unity_WorldToObject, float4(wpos, 1.0)).xyz + float3(0.5, 0.5, 0.5);
			return tex3D(_Volume, npos).rg;
	}

	uint hash(uint x) {
		x += (x << 10u);
		x ^= (x >> 6u);
		x += (x << 3u);
		x ^= (x >> 11u);
		x += (x << 15u);
		return x;
	}

	float random(float f) {
		const uint mantissaMask = 0x007FFFFFu;
		const uint one = 0x3F800000u;

		uint h = hash(asuint(f));
		h &= mantissaMask;
		h |= one;

		float  r2 = asfloat(h);
		return r2 - 1.0;
	}
	float3 _LightDir;

	float sampleDistance(Ray r)
	{
		float s = 0;

		float cumulusScatter = 0.0814896f;
		float cumulusAbsorb = 0.000000110804f;
		float max = cumulusScatter + cumulusAbsorb;

		float randValue = random(frac(r.origin.x + r.origin.y + r.origin.z));

		float newRand = random(randValue);
		while (true)
		{
			s += -log(1 - randValue) / max;
			newRand = random(randValue);
			float2 sigma;
			sigma = coefficients(r.origin + (s * r.dir));
			if(newRand < ((sigma.r + sigma.g) / max))
			{ 
				break;
			}
			randValue = random(newRand);
		}
		return s;
	}

	float g = 0.0f;
	float M_PI = 3.14159;
	float M_TWO_PI = 6.28318;

	float eval(const float3 wo, const float3 wi)
	{
		const float k = 1.0f + (g * g) - (2.0f * g * dot(wi, wo));
		return  (1.0f / (4.0f * M_PI)) *((1.0f - (g * g)) / (k * sqrt(k)));
	}

	float HG()
	{
		float costheta;
		costheta = (1.0f - (g * g)) / (1.0f - g + (2.0f * g * s1));
		costheta = (1.0f + (g * g) - (costheta * costheta)) / (2.0f * g);
		float sintheta;
		sintheta = sqrtf(1.0f - (costheta * costheta));
		float phi;
		phi = s2 * M_TWO_PI;
		wi = float3(sintheta * cos(phi), sintheta * sin(phi), costheta);
	}


	float3 computeDirectLighting(float3 pos)
	{




	}


	float3 trace(Ray r)
	{
		float3 paththrougput = (1.0f, 1.0f, 1.0f);
		float4 colour = (0.0f, 0.0f, 0.0f, 0.0f);
		for (int i = 0; i < 10; i++)
		{
			float distance = sampleDistance(r);
			r.origin += r.dir * distance;
			if (outside(texCoordsFromPosition(r.origin)))
			{
				break;
			}
			else
			{

			}

		}

		// 1 While path not terminated
		// Sample distance (wwodcock)
		// if outside cloud break
		// otherwise calculate direct lighting and add
		// sample phase function
		// goto 1
	}

	fixed4 frag(v2f i) : SV_Target
	{
		Ray ray;
		float3 worldPosition = i.wPos;
		float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
		ray.origin = worldPosition;// mul(unity_WorldToObject, float4(worldPosition, 1.0)).xyz;
		ray.dir = viewDirection;// mul(unity_WorldToObject, float4(viewDirection, 0)).xyz;

		float4 tp = raymarchHit(ray);
		return tp;
	}
		ENDCG
	}
	}
}