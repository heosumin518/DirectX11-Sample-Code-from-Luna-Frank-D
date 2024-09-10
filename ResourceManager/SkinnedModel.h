#pragma once

#include <array>
#include <vector>
#include <string>

#include <d3d11.h>
#include <directxtk/SimpleMath.h>

#include "Animation.h"
#include "Subset.h"
#include "eMaterialTexture.h"
#include "LightHelper.h"
#include "Vertex.h"

namespace resourceManager
{
	struct SkinnedNode
	{
		enum { INVALID_INDEX = -1 };

		size_t CurrentIndex;
		size_t ParentIndex; // ���� ��ȸ ��� �ε���
		std::string Name;
		DirectX::SimpleMath::Matrix ToParentMatrix = DirectX::SimpleMath::Matrix::Identity; // �θ� ��������
		DirectX::SimpleMath::Matrix ToRootMatrix = DirectX::SimpleMath::Matrix::Identity; // ��Ʈ ��������
		std::vector<size_t> SubsetIndex;
	};

	struct SkinnedBone
	{
		std::string Name;
		size_t NodeIndex; // ���� ��ȸ ��� �ε���
		DirectX::SimpleMath::Matrix OffsetMatrix;
	};

	struct SkinnedSubset
	{
		SkinnedSubset() :
			Id(-1),
			VertexStart(0), VertexCount(0),
			FaceStart(0), FaceCount(0)
		{
		}

		unsigned int Id;
		unsigned int VertexStart;
		unsigned int VertexCount;
		unsigned int FaceStart;
		unsigned int FaceCount;
		std::vector<SkinnedBone> Bones;
	};

	// �ִϸ��̼� ���̶�� �����ϴ� �� ������
	// �׷��� ��� �ִϸ��̼��̵� ��Ű�� �ִϸ��̼��̵� �ϴ� ó���� ���� �����ϱ�
	// ��忡 ���Ե� �Ž� ������ ����������� �ǳ� �ٽ�
	// ��带 ������Ʈ ��Ų �� �Ž� ��ȸ�ϸ鼭 �������ϵ��� ������ ���� ���� ��
	class SkinnedModel
	{
	public:
		SkinnedModel(ID3D11Device* d3dDevice, const std::string& fileName);
		~SkinnedModel();

		// �ùٸ��� �������Ϸ��� ��� �������� ������Ʈ
		// ��� ��ȸ�ϸ鼭 ����� ���̺�� �޽� ������
		// �޽� �������� �� ���� ��û�� �ð��� ���� ����� ���� �� ������Ʈ �ؼ� ó���Ѵ�.
		void Draw(ID3D11DeviceContext* d3dContext, const std::string& clipName, float timePos);

	public:
		enum { MAX_BONE_COUNT = 128 };

		// node
		std::vector<SkinnedNode> NodeInorderTraversal; // ���� ��ȸ ������ �����

		// material
		std::vector<common::Material> Materials;
		std::array<std::vector<ID3D11ShaderResourceView*>, static_cast<size_t>(eMaterialTexture::Size)> SRVs;
		ID3D11Buffer* MaterialCB;

		// mesh
		std::vector<vertex::PosNormalTexTanSkinned> Vertices;
		std::vector<UINT> Indices;
		ID3D11Buffer* VB;
		ID3D11Buffer* IB;
		DXGI_FORMAT IndexBufferFormat; // �׻� 32��Ʈ ������ 
		UINT VertexStride;
		std::vector<SkinnedSubset> SubsetTable;
		ID3D11Buffer* BoneCB;

		// scene data
		DirectX::BoundingBox BoundingBox;
		DirectX::BoundingSphere BoundingSphere;

		// animation 
		std::map<std::string, AnimationClip> Animations;
	};

	struct SkinnedModelInstance
	{
		SkinnedModel* SkinnedModel;
		DirectX::SimpleMath::Matrix WorldMatrix;
		float TimePos;
		std::string AnimationName;
	};
}