
struct DirectionLight
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular;
	float3 Direction;
	float pad;
};

struct PointLight
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular;
	float3 Position;
	float Range;
	float3 AttenuationParam;
	float pad;
};

struct SpotLight
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular;
	float3 Direction;
	float Spot;
	float3 Position;
	float Range;
	float3 AttenuationParam;
	float pad;
};

struct Material
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular; // specular w = specular power
	float4 Reflect;
};

void ComputeDirectionLight(Material material
	, DirectionLight directionLight
	, float3 normal
	, float3 toEye
	, out float4 ambient
	, out float4 diffuse
	, out float4 specular)
{
	ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	specular = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// ������
	ambient = material.Ambient * directionLight.Ambient;

	// ���ݻ籤
	float ndotl = dot(normal, -directionLight.Direction);

	if (ndotl < 0)
	{
		return;
	}

	diffuse = material.Diffuse * directionLight.Diffuse * ndotl;

	// ���ݻ籤
	float3 r = reflect(directionLight.Direction, normal);
	float rdotv = dot(r, normalize(toEye));
	specular = material.Specular * directionLight.Specular * pow(max(rdotv, 0.0f), directionLight.Specular.w);
}

void ComputePointLight(Material material
	, PointLight pointLight
	, float3 position
	, float3 normal
	, float3 toEye
	, out float4 ambient
	, out float4 diffuse
	, out float4 specular)
{
	ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	specular = float4(0.0f, 0.0f, 0.0f, 0.0f);

	float3 lightDirection = position - pointLight.Position;
	float distance = length(lightDirection);

	if (distance > pointLight.Range)
	{
		return;
	}

	// �ֺ���
	ambient = material.Ambient * pointLight.Ambient;

	// ���ݻ籤
	lightDirection /= distance;
	float ndotl = dot(normal, -lightDirection);

	if (ndotl < 0)
	{
		return;
	}

	diffuse = material.Diffuse * pointLight.Diffuse * ndotl;

	// ���ݻ籤
	float3 r = reflect(lightDirection, normal);
	float rdotv = dot(r, normalize(toEye));
	specular = material.Specular * pointLight.Specular * pow(max(rdotv, 0.0f), pointLight.Specular.w);

	// ������
	float invAttenuationRate = 1 / dot(pointLight.AttenuationParam, float3(1.0f, distance, distance * distance));
	diffuse *= invAttenuationRate;
	specular *= invAttenuationRate;
}

void ComputeSpotLight(Material material
	, SpotLight spotLight
	, float3 position
	, float3 normal
	, float3 toEye
	, out float4 ambient
	, out float4 diffuse
	, out float4 specular)
{
	ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	specular = float4(0.0f, 0.0f, 0.0f, 0.0f);

	float3 lightDirection = position - spotLight.Position;
	float distance = length(lightDirection);

	if (distance > spotLight.Range)
	{
		return;
	}

	// �ֺ���
	ambient = material.Ambient * spotLight.Ambient;

	// ���ݻ籤
	lightDirection /= distance;
	float ndotl = dot(normal, -lightDirection);

	if (ndotl < 0)
	{
		return;
	}

	diffuse = material.Diffuse * spotLight.Diffuse * ndotl;

	// ���ݻ籤
	float3 r = reflect(lightDirection, normal);
	float rdotv = dot(r, normalize(toEye));
	specular = material.Specular * spotLight.Specular * pow(max(rdotv, 0.0f), spotLight.Specular.w); // max�� ������� �ùٸ� ���� ���´�.

	// �߽��� �Ÿ��� ������ ���� ���� ����
	float spot = pow(max(dot(lightDirection, spotLight.Direction), 0.0f), spotLight.Spot);

	// ������
	float invAttenuationRate = spot / dot(spotLight.AttenuationParam, float3(1.0f, distance, distance * distance));
	diffuse *= invAttenuationRate;
	specular *= invAttenuationRate;
}

float3 NormalSampleToWorldSpace(float3 normalMapSample, float3 unitNormalW, float3 tangentW)
{
	// Uncompress each component from [0,1] to [-1,1].
	float3 normalT = 2.0f * normalMapSample - 1.0f;

	// Build orthonormal basis.
	float3 N = unitNormalW;
	float3 T = normalize(tangentW - dot(tangentW, N) * N);
	float3 B = cross(N, T);

	float3x3 TBN = float3x3(T, B, N);

	// Transform from tangent space to world space.
	float3 bumpedNormalW = mul(normalT, TBN);

	return bumpedNormalW;
}

static const float SMAP_SIZE = 2048.0f;
static const float SMAP_DX = 1.0f / SMAP_SIZE;

float CalcShadowFactor(SamplerComparisonState samShadow,
	Texture2D shadowMap,
	float4 shadowPosH)
{
	// ���� �������� �� �ؽ�ó ���� ��ǥ
	shadowPosH.xyz /= shadowPosH.w;

	// ���̴� �ؽ�ó ������ NDC�� �����ϴ�.
	float depth = shadowPosH.z;

	// �ؼ� ������� Ŀ�� ����
	const float dx = SMAP_DX;
	float percentLit = 0.0f;
	const float2 offsets[9] =
	{
		float2(-dx,  -dx), float2(0.0f,  -dx), float2(dx,  -dx),
		float2(-dx, 0.0f), float2(0.0f, 0.0f), float2(dx, 0.0f),
		float2(-dx,  +dx), float2(0.0f,  +dx), float2(dx,  +dx)
	};

	[unroll]
	for (int i = 0; i < 9; ++i)
	{
		// �ش��Լ��� PCF�� ����Ͽ� 0 ~ 1 ������ ������� ��ȯ�Ѵ�.
		percentLit += shadowMap.SampleCmpLevelZero(samShadow, // ���÷�
			shadowPosH.xy + offsets[i], // �ؽ�ó ��ǥ
			depth).r; // �񱳰�
	}

	return percentLit /= 9.0f;
}