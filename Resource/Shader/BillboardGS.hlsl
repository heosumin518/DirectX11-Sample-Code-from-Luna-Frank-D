#include "LightHelper.hlsl"

cbuffer cbPerObject : register(b0)
{
	float4x4 gViewProj;
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
};

cbuffer cbFixed
{
	float2 gTexC[4] = 
	{
		float2(0.0f, 1.0f),
		float2(0.0f, 0.0f),
		float2(1.0f, 1.0f),
		float2(1.0f, 0.0f)
	};
};

struct GeoIn
{
	float3 CenterW : POSITION;
	float2 SizeW   : SIZE;
};

struct GeoOut
{
	float4 PosH    : SV_POSITION;
    float3 PosW    : POSITION;
    float3 NormalW : NORMAL;
    float2 Tex     : TEXCOORD;
    uint   PrimID  : SV_PrimitiveID;
};

[maxvertexcount(4)]
void main(point GeoIn gin[1]
	, uint primID : SV_PrimitiveID
	, inout TriangleStream<GeoOut> triStream)
{
	float3 up = float3(0.0f, 1.0f, 0.0f);
	float3 look = gEyePosW - gin[0].CenterW;
	look.y = 0.0f;
	look = normalize(look);
	float3 right = cross(up, look);

	float halfWidth  = 0.5f * gin[0].SizeW.x;
	float halfHeight = 0.5f * gin[0].SizeW.y;

	// �� �࿡ ���� ���� �������� ��� ��ǥ�� ������ 
	float4 v[4];
	v[0] = float4(gin[0].CenterW + halfWidth * right - halfHeight * up, 1.0f);
	v[1] = float4(gin[0].CenterW + halfWidth * right + halfHeight * up, 1.0f);
	v[2] = float4(gin[0].CenterW - halfWidth * right - halfHeight * up, 1.0f);
	v[3] = float4(gin[0].CenterW - halfWidth * right + halfHeight * up, 1.0f);


	float2 gTexC[4] = 
	{
		float2(0.0f, 1.0f),
		float2(0.0f, 0.0f),
		float2(1.0f, 1.0f),
		float2(1.0f, 0.0f)
	};

	GeoOut gout;
	[unroll]
	for(int i = 0; i < 4; ++i)
	{
		gout.PosH     = mul(v[i], gViewProj);
		gout.PosW     = v[i].xyz;
		gout.NormalW  = look;
		gout.Tex      = gTexC[i];
		gout.PrimID   = primID;
		
		triStream.Append(gout);
	}

	// triStream.RestartStrip();
}