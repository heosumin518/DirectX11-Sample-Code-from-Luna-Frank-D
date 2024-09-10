#pragma once

namespace common
{
	class RenderStates
	{
	public:
		static void Init(ID3D11Device* device);
		static void Destroy();

	public:
		// RasterizerState
		static ID3D11RasterizerState* WireFrameRS; // ���̾����������� ������
		static ID3D11RasterizerState* NoCullRS; // �ĸ����Ÿ� ���� ����
		static ID3D11RasterizerState* CullClockwiseRS; // �ݽð������ �������� ����
		static ID3D11RasterizerState* DepthRS;

		// BlendState
		static ID3D11BlendState* AlphaToCoverageBS; // ����������
		static ID3D11BlendState* TransparentBS; // ���� �ȼ��� ���İ����� ȥ���ϰڴ�.
		static ID3D11BlendState* NoRenderTargetWritesBS; // �������� ȥ���� ���� �ʴ´�.
		static ID3D11BlendState* AdditiveBlending; // �������� ȥ���� ���� �ʴ´�.

		// DepthStecilState
		static ID3D11DepthStencilState* MarkMirrorDSS; // ���� ���� on, ���ٽ� ����/���� on(�׻� ��/��� ��� �� ���ٽ� ���ذ����� ����)
		static ID3D11DepthStencilState* DrawReflectionDSS; // ���� ����/���� on, ���ٽ� ���� on (���� �� ��)
		static ID3D11DepthStencilState* NoDoubleBlendDSS; // ���� ����/���� on, ���ٽ� ����/���� on(���� �� ��/��� ��� �� increase ����)
		static ID3D11DepthStencilState* LessEqualDSS; // ���� ����/���� on (���̰� ���Ƶ� ���)
		static ID3D11DepthStencilState* DisableDepthDSS;
		static ID3D11DepthStencilState* NoDepthWrites;
		static ID3D11DepthStencilState* EqualsDSS;
	};
}