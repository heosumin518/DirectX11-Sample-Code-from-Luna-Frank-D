#include "../Resource/Shader/LightHelper.hlsl"

cbuffer cbPerObject : register(b0)
{
	float4x4 gWorld;
	float4x4 gWorldInvTranspose;
	float4x4 gViewProj;
	float4x4 gWorldViewProj;
	float4x4 gTexTransform;

	// ������ ������� ������ ����� �����Ƽ� �߰�
	float4x4 gShadowTransform;
	Material gMaterial;
};

cbuffer cbPerFrame : register(b1)
{
	DirectionLight gDirLights[3];
	float3 gEyePosW;
	int gLightCount;
	float4 gFogColor;
	float  gFogStart;
	float  gFogRange;
	bool gUseTexure;
	bool gUseLight;
	bool gUseFog;
};

struct VertexIn
{
	float3 PosL    : POSITION;
	float3 NormalL : NORMAL;
	float2 Tex     : TEXCOORD;
};

struct VertexOut
{
	float4 PosH    : SV_POSITION;
	float3 PosW    : POSITION;
	float3 NormalW : NORMAL;
	float2 Tex     : TEXCOORD;
	float4 ShadowPosH : TEXCOORD1;
};

Texture2D gDiffuseMap : register(t0);
Texture2D gShadowMap : register(t1);
SamplerState gSamLinear : register(s0);
SamplerComparisonState samShadow : register(s1);

VertexOut VS(VertexIn vin)
{
	VertexOut vout;

	vout.PosW = mul(float4(vin.PosL, 1.0f), gWorld).xyz;
	vout.NormalW = mul(vin.NormalL, (float3x3)gWorldInvTranspose);

	vout.PosH = mul(float4(vin.PosL, 1.0f), gWorldViewProj);

	vout.Tex = mul(float4(vin.Tex, 0.0f, 1.0f), gTexTransform).xy;
	
	vout.ShadowPosH = mul(float4(vin.PosL, 1.0f), gShadowTransform);

	return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
	pin.NormalW = normalize(pin.NormalW);

	float3 toEye = gEyePosW - pin.PosW;

	float distToEye = length(toEye);

	toEye /= distToEye;

	float4 texColor = float4(1, 1, 1, 1);
	if (gUseTexure)
	{
		texColor = gDiffuseMap.Sample(gSamLinear, pin.Tex);

		clip(texColor.a - 0.1f);
	}

	float4 litColor = texColor;
	if (gUseLight && gLightCount > 0)
	{
		float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
		float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
		float4 spec = float4(0.0f, 0.0f, 0.0f, 0.0f);
		
		float3 shadow = float3(1.0f, 1.0f, 1.0f);
		shadow[0] = CalcShadowFactor(samShadow, gShadowMap, pin.ShadowPosH);

		[unroll]
		for (int i = 0; i < gLightCount; ++i)
		{
			float4 A, D, S;
			ComputeDirectionLight(gMaterial, gDirLights[i], pin.NormalW, toEye, A, D, S);

			ambient += A;
			diffuse += shadow[i] * D;
			spec += shadow[i] * S;
		}

		litColor = texColor * (ambient + diffuse) + spec;
	}

	if (gUseFog)
	{
		float fogLerp = saturate((distToEye - gFogStart) / gFogRange);
		litColor = lerp(litColor, gFogColor, fogLerp);
	}

	litColor.a = gMaterial.Diffuse.a * texColor.a;

	return litColor;
}
