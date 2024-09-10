#pragma once

#include <directxtk/SimpleMath.h>

#include "d3dUtil.h"
#include "LightHelper.h"
#include "Camera.h"

namespace terrain
{
	using DirectX::SimpleMath::Matrix;
	using DirectX::SimpleMath::Vector2;
	using DirectX::SimpleMath::Vector3;
	using DirectX::SimpleMath::Vector4;
	using namespace common;

	struct VertexTerrain
	{
		Vector3 Pos;
		Vector2 Tex;
		Vector2 BoundsY;
	};

	struct PerObjectTerrain
	{
		Matrix ViewProj;
		Material Material;
	};

	struct PerFrameTerrain
	{
		common::DirectionLight DirLights[3];
		Vector3 EyePosW;
		float  FogStart;
		Vector4 FogColor;
		float  FogRange;
		float MinDist;
		float MaxDist;
		float MinTess;
		float MaxTess;
		float TexelCellSpaceU;
		float TexelCellSpaceV;
		float WorldCellSpace;
		Vector4 WorldFrustumPlanes[6];
		Vector2 TexScale; // = 50.0f;
		float unuserd[2];
	};

	class Terrain
	{
	public:
		struct InitInfo
		{
			std::wstring HeightMapFilename;
			std::wstring LayerMapFilename0;
			std::wstring LayerMapFilename1;
			std::wstring LayerMapFilename2;
			std::wstring LayerMapFilename3;
			std::wstring LayerMapFilename4;
			std::wstring BlendMapFilename;
			float HeightScale;
			UINT HeightmapWidth;
			UINT HeightmapHeight;
			float CellSpacing;
		};

	public:
		Terrain();
		~Terrain();

		void Init(ID3D11Device* device, ID3D11DeviceContext* dc, const InitInfo& initInfo);
		void Draw(ID3D11DeviceContext* dc, const Camera& cam, DirectionLight lights[3]);

		inline void SetWorld(Matrix M);

		inline float GetWidth() const;
		inline float GetDepth() const;
		inline float GetHeight(float x, float z) const;
		inline Matrix GetWorld()const;

	private:
		void buildTerrain(ID3D11Device* device);

		void LoadHeightmap();
		void Smooth();
		bool InBounds(int i, int j);
		float Average(int i, int j);
		void CalcAllPatchBoundsY();
		void CalcPatchBoundsY(UINT i, UINT j);
		void BuildQuadPatchVB(ID3D11Device* device);
		void BuildQuadPatchIB(ID3D11Device* device);
		void BuildHeightmapSRV(ID3D11Device* device);

	private:
		static const int CellsPerPatch = 64;

		// ��� ���� ����� �� �����Ҵ�.
		PerObjectTerrain mPerObjectTerrain;
		PerFrameTerrain mPerFrameTerrain;
		ID3D11Buffer* mFrameTerrainCB;
		ID3D11Buffer* mObjectTerrainCB;

		// ������ ���̴��� �� ���ε��� �Ŷ� �����Ҵ�.
		ID3D11VertexShader* mTerrainVS;
		ID3D11HullShader* mTerrainHS;
		ID3D11DomainShader* mTerrainDS;
		ID3D11PixelShader* mTerrainPS;
		ID3D11InputLayout* mTerrainIL;

		// ���÷� ������Ʈ�� ���� ������Ʈ�� �־����, �����ؼ� ������
		ID3D11SamplerState* mSamLinear;
		ID3D11SamplerState* mSamHeightMap;

		ID3D11Buffer* mQuadPatchVB;
		ID3D11Buffer* mQuadPatchIB;

		// ���ڿ� �ϳ� �����ϸ� �˾Ƽ� �����ǵ���
		ID3D11ShaderResourceView* mLayerMapArraySRV;
		ID3D11ShaderResourceView* mBlendMapSRV;
		ID3D11ShaderResourceView* mHeightMapSRV;

		InitInfo mInfo;

		UINT mNumPatchVertices;
		UINT mNumPatchQuadFaces;

		UINT mNumPatchVertRows;
		UINT mNumPatchVertCols;

		Matrix mWorld;

		Material mMat;

		std::vector<Vector2> mPatchBoundsY;
		std::vector<float> mHeightmap;
	};

	void Terrain::SetWorld(Matrix M)
	{
		mWorld = M;
	}

	float Terrain::GetWidth()const
	{
		return (mInfo.HeightmapWidth - 1) * mInfo.CellSpacing;
	}
	float Terrain::GetDepth()const
	{
		return (mInfo.HeightmapHeight - 1) * mInfo.CellSpacing;
	}
	float Terrain::GetHeight(float x, float z)const
	{
		// ���� x, y ��ǥ ������ ���� ��ĭ�� ������ ���Ѵ�.
		// �ʺ��� ������ x�� ���ϰ�, �� ũ��� �����ָ� �ε� �Ҽ��� ��ǥ�� ��������.
		float c = (x + 0.5f * GetWidth()) / mInfo.CellSpacing; 
		float d = (z - 0.5f * GetDepth()) / -mInfo.CellSpacing;

		// �������� ���� ������ ���ؿ´�.
		int row = (int)floorf(d);
		int col = (int)floorf(c);

		// A B
		// C D
		float A = mHeightmap[row * mInfo.HeightmapWidth + col];
		float B = mHeightmap[row * mInfo.HeightmapWidth + col + 1];
		float C = mHeightmap[(row + 1) * mInfo.HeightmapWidth + col];
		float D = mHeightmap[(row + 1) * mInfo.HeightmapWidth + col + 1];

		// ���Ե� �ﰢ���� ���ϱ� ���� �� ���� ��ǥ�� ���Ѵ�.
		float s = c - (float)col;
		float t = d - (float)row;

		// �� ���� 1���� �۴ٴ� ���� ���� �ﰢ���� �ǹ��Ѵ�.
		if (s + t <= 1.0f)
		{
			// A -> B
			// C
			float uy = B - A;
			float vy = C - A;

			return A + s * uy + t * vy;
		}
		else
		{
			//      B
			// C <- D
			float uy = C - D;
			float vy = B - D;

			return D + (1.0f - s) * uy + (1.0f - t) * vy;
		}
	}
	Matrix Terrain::GetWorld()const
	{
		return mWorld;
	}
}