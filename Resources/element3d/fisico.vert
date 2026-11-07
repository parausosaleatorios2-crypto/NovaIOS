#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp sampler2DArray;
precision highp samplerCube;



struct RenderState
{
	int dynamicReflection;
	bool clipPlane;
	bool globalEnvironment;
	bool ambientOcclusion;
	bool rayTracedShadows, shadowMaps;
	bool blendOpacity;
	bool globalWireframe;
	bool wireframeSupersample;
	bool flipNormals;
	bool pad0, pad1;
};

layout(std140) uniform ShaderState
{
	RenderState renderState;

	vec2 frameBufferSize;

	int objectId;

	vec2 modelUvOffset;
	vec4 modelColor;

	mat4 modelMatrix;
	mat4 baseModelMatrix;
	mat4 normalMatrix;

	mat4 dynamicPlaneMatrix;
	mat4 cubeViewMatrix[6];

	vec4 clipPlane;
};

layout(std140) uniform TransformMatrices
{
	mat4 viewMatrix, projectionMatrix;
	vec3 eyePosition;
	vec2 viewportScale, viewportOffset;
};

struct DynamicReflection
{
	int clipMirror;
	bool disableEnvironment;
	vec4 offset, reflectDirection;
};

layout(std140) uniform ModelProperties
{
	vec4 modelFlip;
	vec2 uvRepeat, uvOffset;
	float normalInvert, flipNormal;

	DynamicReflection dynamicReflection;
} modelProperties;



in vec4 inPosition;
in vec2 inTexCoord;
in vec3 inNormal;
in vec4 inTangent;

out vec4 base_worldPosition;
out vec3 base_worldNormal;
out vec4 base_worldTangent;
out vec4 base_viewPosition;
out vec2 base_texCoords;
out float base_worldScale;

void main()
{
	base_worldPosition = modelMatrix * (inPosition * modelProperties.modelFlip);

	base_viewPosition = viewMatrix * base_worldPosition;

	gl_Position = projectionMatrix * base_viewPosition;

	mat3 normalTransformMatrix = mat3(normalMatrix);
	mat3 rotationMatrix = mat3(modelMatrix);
	
	base_worldNormal = normalize(normalTransformMatrix * ((inNormal * modelProperties.modelFlip.xyz * modelProperties.normalInvert) * (renderState.flipNormals ? -1.0 : 1.0)));

	base_worldScale = length(rotationMatrix * inNormal);

	base_worldTangent = vec4(normalize(rotationMatrix * inTangent.xyz), inTangent.w);
	
	base_texCoords = inTexCoord * modelProperties.uvRepeat + modelProperties.uvOffset;
}

