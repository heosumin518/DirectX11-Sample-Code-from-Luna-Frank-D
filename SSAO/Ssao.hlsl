cbuffer cbPerFrame : register(b0)
{
	float4x4 gViewToTexSpace; // Proj*Texture
	float4   gOffsetVectors[14];
	float4   gFrustumCorners[4];
};
 
Texture2D gNormalDepthMap : register(t0);
Texture2D gRandomVecMap : register(t1);
 
SamplerState samNormalDepth : register(s0);
SamplerState samRandomVec : register(s1);

struct VertexIn
{
	float3 PosL            : POSITION;
	float3 ToFarPlaneIndex : NORMAL;
	float2 Tex             : TEXCOORD;
};

struct VertexOut
{
    float4 PosH       : SV_POSITION;
    float3 ToFarPlane : TEXCOORD0;
	float2 Tex        : TEXCOORD1;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;
	
	// ����ȭ�� ���� �״�� �����ϰ�, �ε����� ���� �� ��� ������ ���� �����Ѵ�.
	vout.PosH = float4(vin.PosL, 1.0f);
	vout.ToFarPlane = gFrustumCorners[vin.ToFarPlaneIndex.x].xyz;
	vout.Tex = vin.Tex;
	
    return vout;
}

int gSampleCount = 14;
float    gSurfaceEpsilon     = 0.05f;
float    gOcclusionRadius    = 0.5f;
float    gOcclusionFadeStart = 1.0f;
float    gOcclusionFadeEnd   = 2.0f;

float OcclusionFunction(float distZ)
{
	float occlusion = 0.0f;

	// ���󵵰� �����Ƿ��� �ּ��� �۽Ƿк��� �տ� �����ؾ� �Ѵ�.
	if(distZ > gSurfaceEpsilon)
	{
		// �Ÿ��� �ּ��� ���󵵰� �۵��� �ϰ�, ����ȭ���ش�.
		float fadeLength = gOcclusionFadeEnd - gOcclusionFadeStart; 
		occlusion = saturate( (gOcclusionFadeEnd-distZ) / fadeLength ); 
	}
	
	return occlusion;	
}

float4 PS(VertexOut pin) : SV_Target
{
	// ȭ�鿡 ���̴� �ȼ��� �븻�� ���̰��� �д´�.
	float4 normalDepth = gNormalDepthMap.SampleLevel(samNormalDepth, pin.Tex, 0.0f);
	float3 n = normalDepth.xyz;
	float pz = normalDepth.w;
	
	// ������ �� ��� �Ÿ��� ���� ��ġ�� �о�´�.
	float depthRatio = pz / pin.ToFarPlane.z;
	float3 p = depthRatio * pin.ToFarPlane;
	
	// ������ ���͸� �о�ͼ� -1, 1�� �����Ѵ�.
	float3 randVec = 2.0f * gRandomVecMap.SampleLevel(samRandomVec, 4.0f * pin.Tex, 0.0f).rgb - 1.0f;

	float occlusionSum = 0.0f;

	[unroll]
	for(int i = 0; i < gSampleCount; ++i)
	{
		// ���� ���Ϳ� �ݻ���� ���� ������ ������ ���͸� ��´�.
		float3 offset = reflect(gOffsetVectors[i].xyz, randVec);
	
		// ������ ���Ͱ� ����� �ݴ븦 ���ϰ� �ִٸ� �����´�.
		float flip = sign( dot(offset, n) );
		float3 q = p + flip * gOcclusionRadius * offset;
		
		// ���Ƿ� ���� ǥ���� �ؽ�ó �������� ��ȯ�Ѵ�.
		float4 projQ = mul(float4(q, 1.0f), gViewToTexSpace);
		projQ /= projQ.w;

		// ���̸��� ���ø��Ͽ� ���� �������� �������� ���Ѵ�.
		float rz = gNormalDepthMap.SampleLevel(samNormalDepth, projQ.xy, 0.0f).a;
		float3 r = (rz / q.z) * q; 

		// ���� ���̸� ����Ѵ�.
		float distZ = p.z - r.z;

		// ���� ��鿡 �ִ��� �˻��Ѵ�. �� ���Ͱ� ���� ��鿡 ������ �������� �ƴ�!
		float dp = max(dot(n, normalize(r - p)), 0.0f);
		
		// ���󵵸� ������Ų��.
		float occlusion = dp * OcclusionFunction(distZ);
		occlusionSum += occlusion;
	}
	
	occlusionSum /= gSampleCount;
	
	// ���޵��� �����ش�.
	float access = 1.0f - occlusionSum;

	// �ŵ� ���� ���� �ø��� �� ���ĸ� ����� ���� ��� ��������.
	return saturate(pow(access,4));
}
