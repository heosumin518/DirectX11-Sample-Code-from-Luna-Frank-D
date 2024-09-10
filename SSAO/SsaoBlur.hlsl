cbuffer cbPerFrame : register(b0)
{
	float gTexelWidth;
	float gTexelHeight;
	bool gHorizontalBlur;
};

Texture2D gNormalDepthMap : register(t0);
Texture2D gInputImage : register(t1);
SamplerState samPoint : register(s0);

struct VertexIn
{
	float3 PosL    : POSITION;
	float3 NormalL : NORMAL;
	float2 Tex     : TEXCOORD;
};

struct VertexOut
{
    float4 PosH  : SV_POSITION;
	float2 Tex   : TEXCOORD;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;
	
	// ������� ȭ���� ��� ���δ� �簢������ �ٽ� �׸���.
	vout.PosH = float4(vin.PosL, 1.0f);
	vout.Tex = vin.Tex;
	
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
	float gWeights[11] = 
	{	
		0.05f, 0.05f, 0.1f, 0.1f, 0.1f, 0.2f, 0.1f, 0.1f, 0.1f, 0.05f, 0.05f
	};
	const int gBlurRadius = 5;

	float2 texOffset;

	if (gHorizontalBlur)
	{
		texOffset = float2(gTexelWidth, 0.0f);
	}
	else
	{
		texOffset = float2(0.0f, gTexelWidth);
	}

	// �߾� ���� �׻� ���տ� �⿩�ϵ��� �̸� ó���Ѵ�.
	float4 color      = gWeights[5] * gInputImage.SampleLevel(samPoint, pin.Tex, 0.0);
	float totalWeight = gWeights[5];
	 
	// ����/���� ������ ���ø�
	float4 centerNormalDepth = gNormalDepthMap.SampleLevel(samPoint, pin.Tex, 0.0f);

	for(float i = -gBlurRadius; i <= gBlurRadius; ++i)
	{
		// �߾Ӱ��� �ٽ� ó������ �ʴ´�.
		if( i == 0 )
			continue;

		float2 tex = pin.Tex + i * texOffset;
		float4 neighborNormalDepth = gNormalDepthMap.SampleLevel(samPoint, tex, 0.0f);

		// �߾Ӱ� �̿��� ������ �ʹ� ���̳��ų� ���� ���̰� �ʹ� ũ�� �ش� ǥ���� �帮�⿡�� �����Ѵ�.
		if( dot(neighborNormalDepth.xyz, centerNormalDepth.xyz) < 0.8f &&
		    abs(neighborNormalDepth.a - centerNormalDepth.a) > 0.2f )
		{
			continue;
		}

		float weight = gWeights[i + gBlurRadius];

		color += weight * gInputImage.SampleLevel(samPoint, tex, 0.0);
		totalWeight += weight;
	}

	// ����� ����ġ��� ���� �����ش�.
	return color / totalWeight;
}