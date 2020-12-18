#include "ColorConverter.fxsub"

float mHue : CONTROLOBJECT < string name = "ColorExtractionController.pmx"; string item = "抽出色相"; >;
float mRadius : CONTROLOBJECT < string name = "ColorExtractionController.pmx"; string item = "閾半径"; >;

static float targetHue = mHue;
static float thresholdRadius = mRadius;

static float maxLimit = targetHue + thresholdRadius;
static float minLimit = targetHue - thresholdRadius;

static bool isUnderflow = minLimit + 1.0 < 1.0;
static bool isOverflow = maxLimit - 1.0 > 0.0;

////////////////////////////////////////////////////////////////////////////////////////////////

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

// レンダリングターゲットのクリア値
float4 ClearColor = {1,1,1,0};
float ClearDepth  = 1.0;

// オリジナルの描画結果を記録するためのレンダーターゲット
texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;

struct VS_OUTPUT {
    float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
};

// パス
VS_OUTPUT VS_pass( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    
    return Out;
}

float4 PS_colorExtraction(float2 Tex: TEXCOORD0) : COLOR
{   
    float4 texColor = tex2D( ScnSamp, Tex );

    float4 hsv = HSVFrom(texColor);
    
    return minLimit < hsv.r && hsv.r < maxLimit ? texColor 
         : isUnderflow && minLimit + 1.0 < hsv.r ? texColor
         : isOverflow && hsv.r < maxLimit - 1.0 ? texColor
         : GrayscaleFrom(texColor);
}

////////////////////////////////////////////////////////////////////////////////////////////////

technique ColorExtraction <
    string Script = 
        "RenderColorTarget0=ScnMap;"
	    "RenderDepthStencilTarget=DepthBuffer;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
	    "ScriptExternal=Color;"
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=ColorExtraction;"
    ;
> {
    pass ColorExtraction < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 VS_pass();
        PixelShader  = compile ps_2_0 PS_colorExtraction();
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////
