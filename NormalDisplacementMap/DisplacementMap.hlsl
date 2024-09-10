#include "../Resource/Shader/LightHelper.hlsl"

cbuffer cbPerObject : register(b0)
{
	float4x4 gWorld;
	float4x4 gWorldInvTranspose;
	float4x4 gViewProj;
	float4x4 gWorldViewProj;
	float4x4 gTexTransform;
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

	float gHeightScale; // ���̸� ����ġ
	float gMaxTessDistance; // �׼����̼� �ִ� �Ÿ�
	float gMinTessDistance; // �׼����̼� �ּ� �Ÿ�
	float gMaxTessFactor; // �׼����̼� �ִ� ���
	float gMinTessFactor; // �׼����̼� �ּ� ���
}

Texture2D gDiffuseMap : register(t0);
Texture2D gNormalMap : register(t1);
TextureCube gCubeMap : register(t2);
SamplerState gSamLinear : register(s0);

struct VertexIn
{
	float3 PosL : POSITION;
	float3 NormalL : NORMAL;
	float2 Tex : TEXCOORD;
	float3 TangentL : TANGENT;
};

struct VertexOut
{
	float3 PosW : POSITION;
	float3 NormalW : NORMAL;
	float3 TangentW : TANGENT;
	float2 Tex : TEXCOORD;
	float TessFactor : TESS;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;

	vout.PosW = mul(float4(vin.PosL, 1.f), gWorld).xyz;
	vout.NormalW = mul(vin.NormalL, (float3x3)gWorldInvTranspose);
	vout.TangentW = mul(vin.TangentL, (float3x3)gWorld);

	vout.Tex = mul(float4(vin.Tex, 0.f, 1.f), gTexTransform).xy;

	float d = distance(vout.PosW, gEyePosW);

	// �Ÿ� ���� ���� �� ����� ����ġ�� ���
	float tessRatio = saturate((gMinTessDistance - d) / (gMinTessDistance - gMaxTessDistance));
	vout.TessFactor = gMinTessFactor + tessRatio * (gMaxTessFactor - gMinTessFactor);

	return vout;
}

struct PatchTess
{
	float EdgeTess[3] : SV_TessFactor;
	float InsideTess : SV_InsideTessFactor;
};

PatchTess PatchHS(InputPatch<VertexOut, 3> patch, uint patchID : SV_PrimitiveID)
{
	PatchTess pt;

	// ���� �����κ��� �� �׼����̼� ����� ���ϹǷ�
	// �޽÷� ���� �����Ǵ� ���� �׻� ���� �׼����̼� ����� ����
	pt.EdgeTess[0] = 0.5f * (patch[1].TessFactor + patch[2].TessFactor);
	pt.EdgeTess[1] = 0.5f * (patch[2].TessFactor + patch[0].TessFactor);
	pt.EdgeTess[2] = 0.5f * (patch[0].TessFactor + patch[1].TessFactor);

	// ���� �׼����̼� ����� ù ����� ó���߳�?
	pt.InsideTess = pt.EdgeTess[0];

	return pt;
}

struct HullOut
{
	float3 PosW : POSITION;
	float3 NormalW : NORMAL;
	float3 TangentW : TANGENT;
	float2 Tex : TEXCOORD;
};

[domain("tri")] // ��ġ�� ����
[partitioning("fractional_odd")] // �׼����̼� ����� �Ų����� ó��
[outputtopology("triangle_cw")] // ���� ����
[outputcontrolpoints(3)]
[patchconstantfunc("PatchHS")]
HullOut HS(InputPatch<VertexOut, 3> p, uint i : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
	HullOut hout;

	// ���ϱ��� ��ü�� ������ �ִ� ���� �ƴϹǷ� �׳� �ܼ� �н��ϵ��� ó��
	hout.PosW = p[i].PosW;
	hout.NormalW = p[i].NormalW;
	hout.TangentW = p[i].TangentW;
	hout.Tex = p[i].Tex;

	return hout;
}

struct DomainOut
{
	float4 PosH : SV_POSITION;
	float3 PosW : POSITION;
	float3 NormalW : NORMAL;
	float3 TangentW : TANGENT;
	float2 Tex : TEXCOORD;
};

[domain("tri")]
DomainOut DS(PatchTess patchTess, float3 bary : SV_DomainLocation, const OutputPatch<HullOut, 3> tri)
{
	DomainOut dout;

	// ���������κ��� �����ؼ� ���� ����
	dout.PosW = bary.x * tri[0].PosW + bary.y * tri[1].PosW + bary.z * tri[2].PosW;
	dout.NormalW = bary.x * tri[0].NormalW + bary.y * tri[1].NormalW + bary.z * tri[2].NormalW;
	dout.TangentW = bary.x * tri[0].TangentW + bary.y * tri[1].TangentW + bary.z * tri[2].TangentW;
	dout.Tex = bary.x * tri[0].Tex + bary.y * tri[1].Tex + bary.z * tri[2].Tex;

	dout.NormalW = normalize(dout.NormalW);

	// ���� ��ġ�� �þ� ��ġ ������ �Ÿ��� MipInterval�� ���� �ӷ����� ����
	// ���͹��� �� �� ���༭ ó���ϹǷ� �Ÿ� 40�̸��� 0�����̴�.
	const float MipInterval = 20.f;
	float mipLevel = clamp((distance(dout.PosW, gEyePosW) - MipInterval) / MipInterval, 0.f, 6.f);

	float h = gNormalMap.SampleLevel(gSamLinear, dout.Tex, mipLevel).a;

	// ���� �������� ���̰���ŭ �İ��
	// h�� 1���� ���ֹǷ� ������ -1 ~ 0��
	dout.PosW += (gHeightScale * (h - 1.f)) * dout.NormalW;

	dout.PosH = mul(float4(dout.PosW, 1.f), gViewProj);

	return dout;
}

float4 PS(DomainOut pin) : SV_Target
{
	pin.NormalW = normalize(pin.NormalW);

	float3 toEye = gEyePosW - pin.PosW;
	float distanceToEye = length(toEye);
	toEye /= distanceToEye;

	float4 texColor = float4(1, 1, 1, 1);
	if (gUseTexure)
	{
		texColor = gDiffuseMap.Sample(gSamLinear, pin.Tex);

		clip(texColor.a - 0.1f);
	}

	float3 normalMapSample = gNormalMap.Sample(gSamLinear, pin.Tex).rgb;

	// ����ȭ�� ���� �븻�� ź��Ʈ�� �����Ѵ�
	float3 bumpedNormalW = NormalSampleToWorldSpace(normalMapSample, pin.NormalW, pin.TangentW);

	float4 litColor = texColor;
	if (gUseLight && gLightCount > 0)
	{
		float4 ambient = float4(0.f, 0.f, 0.f, 0.f);
		float4 diffuse = float4(0.f, 0.f, 0.f, 0.f);
		float4 spec = float4(0.f, 0.f, 0.f, 0.f);

		[unroll]
		for (int i = 0; i < gLightCount; ++i)
		{
			float4 A, D, S;
			ComputeDirectionLight(gMaterial, gDirLights[i], bumpedNormalW, toEye, A, D, S);

			ambient += A;
			diffuse += D;
			spec += S;
		}

		litColor = texColor * (ambient + diffuse) + spec;

		float3 incident = -toEye;
		float3 reflectionVector = reflect(incident, bumpedNormalW);
		float4 reflectionColor = gCubeMap.Sample(gSamLinear, reflectionVector);

		litColor += gMaterial.Reflect * reflectionColor;
	}

	if (gUseFog)
	{
		// ǥ��� ī�޶������ �Ÿ��� ���� ���� �Ÿ��� ��
		// �Ÿ��� �־����� ���� ���۰Ÿ��� ���� ��û ū ����
		// �̰� range�� ������ 0 ~ 1������ ����ȭ ��ų ����
		float fogLerp = saturate((distanceToEye - gFogStart) / gFogRange);

		// �Ÿ��� �ָ� ���� �������� �ȼ� ������ ���� ���Ƿ� �Ȱ� ���� ����
		litColor = lerp(litColor, gFogColor, fogLerp);
	}

	litColor.a = gMaterial.Diffuse.a * texColor.a;

	return litColor;
}