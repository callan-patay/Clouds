Shader "Custom/Clouds" {
	Properties {
		_Volume("Texture", 3D) = "" {}
		_LightDir("LightDir", Vector) = (0.0, 0.0, 0.0, -1.0)
		g("g", Range(-1.0, 1.0)) = 0.8
	}
		SubShader{
			Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
			LOD 100

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
				Pass
		{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				// Use shader model 3.0 target, to get nicer looking lighting
				#include "UnityCG.cginc"
				//#pragma target 3.0

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
				float3 _LightDir;
				float g;
				float M_PI = 3.14159;

				v2f vert(appdata v) {
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					return o;
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

				float3 texCoordsFromPosition(float3 position)
				{
					float3 npos = mul(unity_WorldToObject, float4(position, 1.0)).xyz;
					return npos + float3(0.5, 0.5, 0.5);
				}

				float2 coefficients(float3 wpos)
				{
					//float3 npos = mul(unity_WorldToObject, float4(wpos, 1.0)).xyz + float3(0.5, 0.5, 0.5);
					return tex3D(_Volume, texCoordsFromPosition(wpos)).rg;
				}

				float sampleDistance(Ray r, inout float randValue)
				{
					float s = 0;

					float cumulusScatter = 0.0814896f;
					float cumulusAbsorb = 0.000000110804f;
					float max = cumulusScatter + cumulusAbsorb;

					randValue = random(randValue);

					float newRand = random(randValue);
					int intersected = 0;
					for (int i = 0; i < 10; i++)
					{
						s += -log(1 - randValue) / max;
						newRand = random(randValue);
						float2 sigma;
						sigma = coefficients(r.origin + (s * r.dir));
						if (newRand < ((sigma.r + sigma.g) / max))
						{
							intersected = 1;
							break;
						}
						randValue = random(newRand);
					}
					if (intersected == 1)
					{
						return s;
					}
					return 1000000000.0f;
				}


				float eval(const float3 wo, const float3 wi)
				{
					const float k = 1.0f + (g * g) - (2.0f * g * dot(wi, wo));
					return  (1.0f / (4.0f * M_PI)) *((1.0f - (g * g)) / (k * sqrt(k)));
				}

				float3x3 createOrthonormalbasis(float3 v1)
				{
					float3 v2;
					float3 v3;
					if (abs(v1.x) > abs(v1.y))
					{
						float invlength = 1.0f / sqrt(v1.x*v1.x + v1.z*v1.z);
						v2 = float3(-v1.z * invlength, 0.0f, v1.x * invlength);
					}
					else
					{
						float invLength = 1.0f / sqrt(v1.y*v1.y + v1.z*v1.z);
						v2 = float3(0.0f, v1.z*invLength, -v1.y * invLength);
					}

					v3 = cross(v1, v2);


					float3x3 OMatrix =
					{
						v2.x, v2.y, v2.z,
						v3.x, v3.y, v3.z,
						v1.x, v1.y, v1.z
					};

					return OMatrix;
				}

				float3 HG(Ray r, float randValue)
				{
					float M_TWO_PI = M_PI * 2;
					float s1 = random(randValue);
					float s2 = random(s1);
					float costheta;
					costheta = (1.0f - (g * g)) / (1.0f - g + (2.0f * g * s1));
					costheta = (1.0f + (g * g) - (costheta * costheta)) / (2.0f * g);
					float sintheta;
					sintheta = sqrt(1.0f - (costheta * costheta));
					float phi;
					phi = s2 * M_TWO_PI;

					float3 wi = float3(sintheta * cos(phi), sintheta * sin(phi), costheta);

					float3x3 Omatrix = createOrthonormalbasis(r.dir);
					Omatrix = transpose(Omatrix);

					float3 wiglobal = mul(Omatrix, wi);

					return wiglobal;
				}

				float3 computeDirectLighting(float3 pos, float3 dirtosun, inout float randValue)
				{
					float s = 0;

					float cumulusScatter = 0.0814896f;
					float cumulusAbsorb = 0.000000110804f;
					float max = cumulusScatter + cumulusAbsorb;

					randValue = random(randValue);// frac(r.origin.x + r.origin.y + r.origin.z));

					float newRand = random(randValue);
					float3 sunLight = float3(10000, 10000, 10000);
					for (int i = 0; i < 10; i++)
					{
						randValue = random(newRand);
						s += -log(1 - randValue) / max;
						float3 newpos;
						newpos = pos + (dirtosun * s);
						if (outsideTexture(texCoordsFromPosition(newpos)))
						{
							return sunLight;
						}
						float2 sigma;
						sigma = coefficients(newpos);
						if (newRand > ((sigma.r + sigma.g) / max))
						{
							return float3(0, 0, 0);
						}
						
					}
					return sunLight;
				}


				float4 trace(Ray r, float3 lightDir)
				{
					float randValue = random(frac(r.origin.x + r.origin.y + r.origin.z));
					float3 paththrougput = (1.0f, 1.0f, 1.0f);
					float4 colour = (0.0f, 0.0f, 0.0f, 0.0f);

					float newRand = random(randValue);

					for (int i = 0; i < 10; i++)
					{

						float distance = sampleDistance(r, randValue);
						r.origin += r.dir * distance;
						if (outsideTexture(texCoordsFromPosition(r.origin)))
						{
							break;
						}
						else
						{
							float2 sigma;
							sigma = coefficients(r.origin);
							colour = colour + float4((paththrougput * computeDirectLighting(r.origin, -lightDir, newRand) * sigma.g * eval(-r.dir, -lightDir)), 1);
							float3 dir;
							dir = HG(r, newRand);
							paththrougput = paththrougput * sigma.g;
							r.dir = dir;
						}

					}
					return colour;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					Ray ray;
					float3 worldPosition = i.wPos;
					float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
					ray.origin = worldPosition;// mul(unity_WorldToObject, float4(worldPosition, 1.0)).xyz;
					ray.dir = viewDirection;// mul(unity_WorldToObject, float4(viewDirection, 0)).xyz;
					_LightDir = normalize(_LightDir);
					return trace(ray, _LightDir);
				}
				
				ENDCG
			}
		}
}
