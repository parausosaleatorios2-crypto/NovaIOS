#version 300 es
precision highp float;

in vec4 inVertex;
in vec2 inTexCoord;

out vec2 texCoords;

void main() {
	gl_Position = inVertex;
	texCoords = inTexCoord;
}
