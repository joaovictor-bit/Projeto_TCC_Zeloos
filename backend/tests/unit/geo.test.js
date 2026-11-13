const { calcularDistanciaEmMetros, pointInCircle } = require('../../src/utils/geo');

describe('utils/geo', () => {
  describe('calcularDistanciaEmMetros', () => {
    test('retorna 0 para o mesmo ponto', () => {
      expect(calcularDistanciaEmMetros(-23.55052, -46.63331, -23.55052, -46.63331)).toBe(0);
    });

    test('calcula aproximadamente 111 km para 1 grau de latitude', () => {
      const distancia = calcularDistanciaEmMetros(0, 0, 1, 0);
      expect(distancia).toBeGreaterThan(111000);
      expect(distancia).toBeLessThan(111400);
    });

    test('calcula a distância entre São Paulo e Rio de Janeiro (~360 km)', () => {
      const distancia = calcularDistanciaEmMetros(-23.55052, -46.63331, -22.90685, -43.1729);
      expect(distancia / 1000).toBeCloseTo(360, -1);
    });

    test('é simétrica (A→B igual a B→A)', () => {
      const ida = calcularDistanciaEmMetros(-23.5, -46.6, -23.6, -46.7);
      const volta = calcularDistanciaEmMetros(-23.6, -46.7, -23.5, -46.6);
      expect(ida).toBeCloseTo(volta, 6);
    });
  });

  describe('pointInCircle', () => {
    const centro = { lat: -23.55052, lon: -46.63331 };

    test('retorna true para o próprio centro', () => {
      expect(pointInCircle(centro.lat, centro.lon, centro.lat, centro.lon, 10)).toBe(true);
    });

    test('retorna true para ponto dentro do raio', () => {
      // ~55 m ao norte do centro
      expect(pointInCircle(centro.lat + 0.0005, centro.lon, centro.lat, centro.lon, 100)).toBe(true);
    });

    test('retorna false para ponto fora do raio', () => {
      // ~555 m ao norte do centro
      expect(pointInCircle(centro.lat + 0.005, centro.lon, centro.lat, centro.lon, 100)).toBe(false);
    });

    test('considera o limite do raio como dentro', () => {
      const lat = centro.lat + 0.001;
      const raio = calcularDistanciaEmMetros(lat, centro.lon, centro.lat, centro.lon);
      expect(pointInCircle(lat, centro.lon, centro.lat, centro.lon, raio)).toBe(true);
    });
  });
});
