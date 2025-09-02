(() => {
  // ../../../node_modules/perfect-freehand/dist/esm/index.mjs
  function $(e, t, u, x = (h) => h) {
    return e * x(0.5 - t * (0.5 - u));
  }
  function se(e) {
    return [-e[0], -e[1]];
  }
  function l(e, t) {
    return [e[0] + t[0], e[1] + t[1]];
  }
  function a(e, t) {
    return [e[0] - t[0], e[1] - t[1]];
  }
  function b(e, t) {
    return [e[0] * t, e[1] * t];
  }
  function he(e, t) {
    return [e[0] / t, e[1] / t];
  }
  function R(e) {
    return [e[1], -e[0]];
  }
  function B(e, t) {
    return e[0] * t[0] + e[1] * t[1];
  }
  function ue(e, t) {
    return e[0] === t[0] && e[1] === t[1];
  }
  function ge(e) {
    return Math.hypot(e[0], e[1]);
  }
  function de(e) {
    return e[0] * e[0] + e[1] * e[1];
  }
  function A(e, t) {
    return de(a(e, t));
  }
  function G(e) {
    return he(e, ge(e));
  }
  function ie(e, t) {
    return Math.hypot(e[1] - t[1], e[0] - t[0]);
  }
  function L(e, t, u) {
    let x = Math.sin(u), h = Math.cos(u), y = e[0] - t[0], n = e[1] - t[1], f = y * h - n * x, d = y * x + n * h;
    return [f + t[0], d + t[1]];
  }
  function K(e, t, u) {
    return l(e, b(a(t, e), u));
  }
  function ee(e, t, u) {
    return l(e, b(t, u));
  }
  var { min: C, PI: xe } = Math;
  var pe = 0.275;
  var V = xe + 1e-4;
  function ce(e, t = {}) {
    let { size: u = 16, smoothing: x = 0.5, thinning: h = 0.5, simulatePressure: y = true, easing: n = (r) => r, start: f = {}, end: d = {}, last: D = false } = t, { cap: S = true, easing: j = (r) => r * (2 - r) } = f, { cap: q = true, easing: c = (r) => --r * r * r + 1 } = d;
    if (e.length === 0 || u <= 0) return [];
    let p = e[e.length - 1].runningLength, g = f.taper === false ? 0 : f.taper === true ? Math.max(u, p) : f.taper, T = d.taper === false ? 0 : d.taper === true ? Math.max(u, p) : d.taper, te = Math.pow(u * x, 2), _ = [], M = [], H = e.slice(0, 10).reduce((r, i) => {
      let o = i.pressure;
      if (y) {
        let s = C(1, i.distance / u), W = C(1, 1 - s);
        o = C(1, r + (W - r) * (s * pe));
      }
      return (r + o) / 2;
    }, e[0].pressure), m = $(u, h, e[e.length - 1].pressure, n), U, X = e[0].vector, z = e[0].point, F = z, O = z, E = F, J = false;
    for (let r = 0; r < e.length; r++) {
      let { pressure: i } = e[r], { point: o, vector: s, distance: W, runningLength: I } = e[r];
      if (r < e.length - 1 && p - I < 3) continue;
      if (h) {
        if (y) {
          let v = C(1, W / u), Z = C(1, 1 - v);
          i = C(1, H + (Z - H) * (v * pe));
        }
        m = $(u, h, i, n);
      } else m = u / 2;
      U === void 0 && (U = m);
      let le = I < g ? j(I / g) : 1, fe = p - I < T ? c((p - I) / T) : 1;
      m = Math.max(0.01, m * Math.min(le, fe));
      let re = (r < e.length - 1 ? e[r + 1] : e[r]).vector, Y = r < e.length - 1 ? B(s, re) : 1, be = B(s, X) < 0 && !J, ne = Y !== null && Y < 0;
      if (be || ne) {
        let v = b(R(X), m);
        for (let Z = 1 / 13, w = 0; w <= 1; w += Z) O = L(a(o, v), o, V * w), _.push(O), E = L(l(o, v), o, V * -w), M.push(E);
        z = O, F = E, ne && (J = true);
        continue;
      }
      if (J = false, r === e.length - 1) {
        let v = b(R(s), m);
        _.push(a(o, v)), M.push(l(o, v));
        continue;
      }
      let oe = b(R(K(re, s, Y)), m);
      O = a(o, oe), (r <= 1 || A(z, O) > te) && (_.push(O), z = O), E = l(o, oe), (r <= 1 || A(F, E) > te) && (M.push(E), F = E), H = i, X = s;
    }
    let P = e[0].point.slice(0, 2), k = e.length > 1 ? e[e.length - 1].point.slice(0, 2) : l(e[0].point, [1, 1]), Q = [], N = [];
    if (e.length === 1) {
      if (!(g || T) || D) {
        let r = ee(P, G(R(a(P, k))), -(U || m)), i = [];
        for (let o = 1 / 13, s = o; s <= 1; s += o) i.push(L(r, P, V * 2 * s));
        return i;
      }
    } else {
      if (!(g || T && e.length === 1)) if (S) for (let i = 1 / 13, o = i; o <= 1; o += i) {
        let s = L(M[0], P, V * o);
        Q.push(s);
      }
      else {
        let i = a(_[0], M[0]), o = b(i, 0.5), s = b(i, 0.51);
        Q.push(a(P, o), a(P, s), l(P, s), l(P, o));
      }
      let r = R(se(e[e.length - 1].vector));
      if (T || g && e.length === 1) N.push(k);
      else if (q) {
        let i = ee(k, r, m);
        for (let o = 1 / 29, s = o; s < 1; s += o) N.push(L(i, k, V * 3 * s));
      } else N.push(l(k, b(r, m)), l(k, b(r, m * 0.99)), a(k, b(r, m * 0.99)), a(k, b(r, m)));
    }
    return _.concat(N, M.reverse(), Q);
  }
  function me(e, t = {}) {
    var q;
    let { streamline: u = 0.5, size: x = 16, last: h = false } = t;
    if (e.length === 0) return [];
    let y = 0.15 + (1 - u) * 0.85, n = Array.isArray(e[0]) ? e : e.map(({ x: c, y: p, pressure: g = 0.5 }) => [c, p, g]);
    if (n.length === 2) {
      let c = n[1];
      n = n.slice(0, -1);
      for (let p = 1; p < 5; p++) n.push(K(n[0], c, p / 4));
    }
    n.length === 1 && (n = [...n, [...l(n[0], [1, 1]), ...n[0].slice(2)]]);
    let f = [{ point: [n[0][0], n[0][1]], pressure: n[0][2] >= 0 ? n[0][2] : 0.25, vector: [1, 1], distance: 0, runningLength: 0 }], d = false, D = 0, S = f[0], j = n.length - 1;
    for (let c = 1; c < n.length; c++) {
      let p = h && c === j ? n[c].slice(0, 2) : K(S.point, n[c], y);
      if (ue(S.point, p)) continue;
      let g = ie(p, S.point);
      if (D += g, c < j && !d) {
        if (D < x) continue;
        d = true;
      }
      S = { point: p, pressure: n[c][2] >= 0 ? n[c][2] : 0.5, vector: G(a(S.point, p)), distance: g, runningLength: D }, f.push(S);
    }
    return f[0].vector = ((q = f[1]) == null ? void 0 : q.vector) || [0, 0], f;
  }
  function ae(e, t = {}) {
    return ce(me(e, t), t);
  }

  // binding.js
  globalThis.getStroke = ae;
  var average = (a2, b2) => (a2 + b2) / 2;
  function getSvgPathFromStroke(points, closed = true) {
    const len = points.length;
    if (len < 4) {
      return ``;
    }
    let a2 = points[0];
    let b2 = points[1];
    const c = points[2];
    let result = `M${a2[0].toFixed(2)},${a2[1].toFixed(2)} Q${b2[0].toFixed(
      2
    )},${b2[1].toFixed(2)} ${average(b2[0], c[0]).toFixed(2)},${average(
      b2[1],
      c[1]
    ).toFixed(2)} T`;
    for (let i = 2, max = len - 1; i < max; i++) {
      a2 = points[i];
      b2 = points[i + 1];
      result += `${average(a2[0], b2[0]).toFixed(2)},${average(a2[1], b2[1]).toFixed(
        2
      )} `;
    }
    if (closed) {
      result += "Z";
    }
    return result;
  }
  globalThis.getSvgPathFromStroke = getSvgPathFromStroke;
})();
