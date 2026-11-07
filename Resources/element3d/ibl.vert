#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp samplerCube;



in vec2 inPosition;
in vec2 inTexCoord;

out vec2 texCoords;

uniform vec4 renderOffset;
 
void main()
{
	gl_Position = vec4(inPosition, 0.0, 1.0);
	texCoords = inTexCoord;
}

