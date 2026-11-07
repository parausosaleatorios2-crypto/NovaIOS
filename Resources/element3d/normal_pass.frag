#version 300 es
precision highp float;

in vec3 fragNormal;
in float fragViewDepth;

out vec4 outColor;

void main() {
	vec3 n = normalize(fragNormal);
	float invDepth = fragViewDepth > 0.0 ? 1.0 / fragViewDepth : 0.0;
	outColor = vec4(n, invDepth);
}
