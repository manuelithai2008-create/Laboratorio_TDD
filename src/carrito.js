const IVA = 0.19;
const ENVIO = 12000;
const ENVIO_GRATIS_DESDE = 150000;

const CUPONES = {
  DESC10: { tipo: 'porcentaje', valor: 0.10 },
  DESC20: { tipo: 'porcentaje', valor: 0.20 },
  MENOS30K: { tipo: 'fijo', valor: 30000 },
};

const normalizarCodigo = (codigo) => String(codigo).trim().toUpperCase();

export class Carrito {
  constructor() {
    this.productos = [];
    this.cupon = null;
  }

  agregar(nombre, precio, cantidad = 1) {
    if (typeof precio !== 'number' || precio <= 0) {
      throw new Error('El precio debe ser mayor que cero');
    }
    if (!Number.isInteger(cantidad) || cantidad <= 0) {
      throw new Error('La cantidad debe ser un entero positivo');
    }
    const existente = this.productos.find((p) => p.nombre === nombre);
    if (existente) {
      existente.cantidad += cantidad;
    } else {
      this.productos.push({ nombre, precio, cantidad });
    }
  }

  eliminar(nombre) {
    const indice = this.productos.findIndex((p) => p.nombre === nombre);
    if (indice === -1) {
      throw new Error(`El producto "${nombre}" no está en el carrito`);
    }
    this.productos.splice(indice, 1);
  }

  actualizarCantidad(nombre, nueva) {
    if (!Number.isInteger(nueva) || nueva < 0) {
      throw new Error('La cantidad debe ser un entero positivo o cero');
    }
    if (nueva === 0) {
      this.eliminar(nombre);
      return;
    }
    const existente = this.productos.find((p) => p.nombre === nombre);
    if (!existente) {
      throw new Error(`El producto "${nombre}" no está en el carrito`);
    }
    existente.cantidad = nueva;
  }

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }

  aplicarCupon(codigo) {
    const normalizado = normalizarCodigo(codigo);
    if (!(normalizado in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = normalizado;
  }

  descuento() {
    if (!this.cupon) return 0;
    const { tipo, valor } = CUPONES[this.cupon];
    if (tipo === 'fijo') {
      return Math.min(valor, this.subtotal());
    }
    return Math.round(this.subtotal() * valor);
  }

  baseGravable() {
    return this.subtotal() - this.descuento();
  }

  iva() {
    return Math.round(this.baseGravable() * IVA);
  }

  envio() {
    if (this.productos.length === 0) return 0;
    return this.baseGravable() >= ENVIO_GRATIS_DESDE ? 0 : ENVIO;
  }

  total() {
    return this.baseGravable() + this.iva() + this.envio();
  }

  resumen() {
    return {
      subtotal: this.subtotal(),
      descuento: this.descuento(),
      iva: this.iva(),
      envio: this.envio(),
      total: this.total(),
    };
  }
}
