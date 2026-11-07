#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp samplerCube;



in vec2 texCoords;

out vec4 fragData[1];

uniform sampler2D textureSampler;

uniform vec3 initialCoord;
uniform vec3 coordIncX;
uniform vec3 coordIncY;

void main()
{
	vec3 textureDirection = initialCoord + texCoords.x * coordIncX + texCoords.y * coordIncY;
	
	float latitude = atan(textureDirection.x, textureDirection.z) / 6.28318531 + 0.5;
	float longitude = atan(textureDirection.y, sqrt(textureDirection.x*textureDirection.x + textureDirection.z*textureDirection.z)) / 3.1415 + 0.5;
	
	vec2 coords = vec2(latitude, longitude);
	
 	vec2 coordDx = vec2(length(dFdx(textureDirection.xy)) / 6.28318531, dFdx(longitude));
	vec2 coordDy = vec2(length(dFdy(textureDirection.xy)) / 6.28318531, dFdy(longitude));
	
	vec4 environment = textureGrad(textureSampler, coords, coordDx, coordDy);
	
	fragData[0] = environment;
}

