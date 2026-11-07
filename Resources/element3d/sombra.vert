#version 300 es
precision highp float;
precision highp int;

in vec4 inPosition;

struct RenderState {
	int dynamicReflection;
	bool clipPlane, globalEnvironment, ambientOcclusion;
	bool rayTracedShadows, shadowMaps;
	bool blendOpacity;
	bool globalWireframe, wireframeSupersample, flipNormals;
	bool pad0, pad1;
};
layout(std140) uniform ShaderState {
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
struct DynamicReflection {
	int clipMirror;
	bool disableEnvironment;
	vec4 offset, reflectDirection;
};
layout(std140) uniform ModelProperties {
	vec4 modelFlip;
	vec2 uvRepeat, uvOffset;
	float normalInvert, flipNormal;
	DynamicReflection dynamicReflection;
} modelProperties;

uniform mat4 shadowV;
uniform mat4 shadowP;

void main() {
	vec4 worldPos = modelMatrix * (inPosition * modelProperties.modelFlip);
	gl_Position = shadowP * (shadowV * worldPos);
}
