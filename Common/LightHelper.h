#pragma once

#include <directxtk/SimpleMath.h>

namespace common
{
	struct DirectionLight
	{
		DirectX::SimpleMath::Vector4 Ambient;
		DirectX::SimpleMath::Vector4 Diffuse;
		DirectX::SimpleMath::Vector4 Specular;
		DirectX::SimpleMath::Vector3 Direction;
		float pad;
	};

	struct PointLight
	{
		DirectX::SimpleMath::Vector4 Ambient;
		DirectX::SimpleMath::Vector4 Diffuse;
		DirectX::SimpleMath::Vector4 Specular;
		DirectX::SimpleMath::Vector3 Position;
		float Range;
		DirectX::SimpleMath::Vector3 AttenuationParam; // ���� �Ű����� a0, a1, a2
		float pad;
	};

	struct SpotLight
	{
		DirectX::SimpleMath::Vector4 Ambient;
		DirectX::SimpleMath::Vector4 Diffuse;
		DirectX::SimpleMath::Vector4 Specular;
		DirectX::SimpleMath::Vector3 Direction;
		float Spot; // ���Կ� ���� ����
		DirectX::SimpleMath::Vector3 Position;
		float Range;
		DirectX::SimpleMath::Vector3 AttenuationParam; // ���� �Ű����� a0, a1, a2
		float pad;
	};

	struct Material
	{
		DirectX::SimpleMath::Vector4 Ambient;
		DirectX::SimpleMath::Vector4 Diffuse;
		DirectX::SimpleMath::Vector4 Specular; // specular�� ������ ������ ������ �����
		DirectX::SimpleMath::Vector4 Reflect;
	};
}