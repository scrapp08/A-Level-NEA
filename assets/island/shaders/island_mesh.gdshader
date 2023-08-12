shader_type spatial;

uniform sampler2D noise;
uniform float height_scale = 0.5;

void vertex() {
  float height = texture(noise, VERTEX.xz / 2.0 + 0.5).x;
  VERTEX.y += height;
}
