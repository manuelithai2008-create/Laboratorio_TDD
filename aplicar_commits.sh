#!/usr/bin/env bash
set -e

if [ ! -f package.json ] || [ ! -d .git ]; then
  echo 'Ejecuta este script dentro de tu fork clonado (carpeta Laboratorio_TDD).'
  exit 1
fi

mkdir -p src test

paso() {
  npm test --silent > /dev/null
  git add -A
  if [ -n "$COAUTOR" ]; then
    git commit -q -m "$1" -m "Co-authored-by: $COAUTOR"
  else
    git commit -q -m "$1"
  fi
  echo "commit: $1"
}

cat > src/carrito.js << 'FIN_CODIGO_1'
export class Carrito {
  cantidadDeItems() {
    return 0;
  }

  subtotal() {
    return 0;
  }
}
FIN_CODIGO_1

cat > test/carrito.test.js << 'FIN_TEST_1'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });
});
FIN_TEST_1

paso 'feat: carrito vacío (iteración 1)'

cat > src/carrito.js << 'FIN_CODIGO_2'
export class Carrito {
  constructor() {
    this.productos = [];
  }

  agregar(nombre, precio, cantidad = 1) {
    this.productos.push({ nombre, precio, cantidad });
  }

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }
}
FIN_CODIGO_2

cat > test/carrito.test.js << 'FIN_TEST_2'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });
});
FIN_TEST_2

paso 'feat: agregar productos con cantidad por defecto (iteración 2)'

cat > src/carrito.js << 'FIN_CODIGO_3'
export class Carrito {
  constructor() {
    this.productos = [];
  }

  agregar(nombre, precio, cantidad = 1) {
    const existente = this.productos.find((p) => p.nombre === nombre);
    if (existente) {
      existente.cantidad += cantidad;
    } else {
      this.productos.push({ nombre, precio, cantidad });
    }
  }

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }
}
FIN_CODIGO_3

cat > test/carrito.test.js << 'FIN_TEST_3'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });
});
FIN_TEST_3

paso 'feat: acumular cantidad de productos repetidos (iteración 3)'

cat > src/carrito.js << 'FIN_CODIGO_4'
export class Carrito {
  constructor() {
    this.productos = [];
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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }
}
FIN_CODIGO_4

cat > test/carrito.test.js << 'FIN_TEST_4'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });
});
FIN_TEST_4

paso 'feat: validar precio y cantidad (iteración 4)'

cat > src/carrito.js << 'FIN_CODIGO_5'
export class Carrito {
  constructor() {
    this.productos = [];
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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }
}
FIN_CODIGO_5

cat > test/carrito.test.js << 'FIN_TEST_5'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });
});
FIN_TEST_5

paso 'feat: eliminar productos del carrito (iteración 5)'

cat > src/carrito.js << 'FIN_CODIGO_6'
const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
};

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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }

  aplicarCupon(codigo) {
    if (!(codigo in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = codigo;
  }

  descuento() {
    if (!this.cupon) return 0;
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
  }
}
FIN_CODIGO_6

cat > test/carrito.test.js << 'FIN_TEST_6'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });
});
FIN_TEST_6

paso 'feat: cupones de descuento DESC10 y DESC20 (iteración 6)'

cat > src/carrito.js << 'FIN_CODIGO_7'
const IVA = 0.19;

const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
};

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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }

  aplicarCupon(codigo) {
    if (!(codigo in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = codigo;
  }

  descuento() {
    if (!this.cupon) return 0;
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
  }

  iva() {
    return Math.round((this.subtotal() - this.descuento()) * IVA);
  }

  total() {
    return this.subtotal() - this.descuento() + this.iva();
  }
}
FIN_CODIGO_7

cat > test/carrito.test.js << 'FIN_TEST_7'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 119000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 107100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });
});
FIN_TEST_7

paso 'feat: calcular IVA y total a pagar (iteración 7)'

cat > src/carrito.js << 'FIN_CODIGO_8'
const IVA = 0.19;

const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
};

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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }

  aplicarCupon(codigo) {
    if (!(codigo in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = codigo;
  }

  descuento() {
    if (!this.cupon) return 0;
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
  }

  baseGravable() {
    return this.subtotal() - this.descuento();
  }

  iva() {
    return Math.round(this.baseGravable() * IVA);
  }

  total() {
    return this.baseGravable() + this.iva();
  }
}
FIN_CODIGO_8

cat > test/carrito.test.js << 'FIN_TEST_8'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 119000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 107100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });
});
FIN_TEST_8

paso 'refactor: extraer baseGravable() sin cambiar el comportamiento'

cat > src/carrito.js << 'FIN_CODIGO_9'
const IVA = 0.19;

const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
};

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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }

  aplicarCupon(codigo) {
    if (!(codigo in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = codigo;
  }

  descuento() {
    if (!this.cupon) return 0;
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
  }

  baseGravable() {
    return this.subtotal() - this.descuento();
  }

  iva() {
    return Math.round(this.baseGravable() * IVA);
  }

  total() {
    return this.baseGravable() + this.iva();
  }

  resumen() {
    return {
      subtotal: this.subtotal(),
      descuento: this.descuento(),
      iva: this.iva(),
      total: this.total(),
    };
  }
}
FIN_CODIGO_9

cat > test/carrito.test.js << 'FIN_TEST_9'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 119000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 107100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });

  describe('Reto A: resumen de la compra', () => {
    test('resumen devuelve todos los valores de la compra', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.deepEqual(carrito.resumen(), {
        subtotal: 100000,
        descuento: 10000,
        iva: 17100,
        total: 107100,
      });
    });

    test('resumen de un carrito vacío tiene todo en 0', () => {
      assert.deepEqual(carrito.resumen(), {
        subtotal: 0,
        descuento: 0,
        iva: 0,
        total: 0,
      });
    });
  });
});
FIN_TEST_9

paso 'feat: resumen de la compra (reto A)'

cat > src/carrito.js << 'FIN_CODIGO_10'
const IVA = 0.19;
const ENVIO = 12000;
const ENVIO_GRATIS_DESDE = 150000;

const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
};

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

  cantidadDeItems() {
    return this.productos.reduce((suma, p) => suma + p.cantidad, 0);
  }

  subtotal() {
    return this.productos.reduce((suma, p) => suma + p.precio * p.cantidad, 0);
  }

  aplicarCupon(codigo) {
    if (!(codigo in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = codigo;
  }

  descuento() {
    if (!this.cupon) return 0;
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
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
FIN_CODIGO_10

cat > test/carrito.test.js << 'FIN_TEST_10'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 119100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });

  describe('Reto A: resumen de la compra', () => {
    test('resumen devuelve todos los valores de la compra', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.deepEqual(carrito.resumen(), {
        subtotal: 100000,
        descuento: 10000,
        iva: 17100,
        envio: 12000,
        total: 119100,
      });
    });

    test('resumen de un carrito vacío tiene todo en 0', () => {
      assert.deepEqual(carrito.resumen(), {
        subtotal: 0,
        descuento: 0,
        iva: 0,
        envio: 0,
        total: 0,
      });
    });
  });

  describe('Reto B: costo de envío', () => {
    test('el envío cuesta 12000 si la base gravable es menor a 150000', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío es gratis si la base gravable es exactamente 150000', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.envio(), 0);
    });

    test('el envío cuesta 12000 con una base de 149999', () => {
      carrito.agregar('Cable', 149999, 1);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío se evalúa sobre la base con descuento', () => {
      carrito.agregar('Monitor', 160000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.baseGravable(), 144000);
      assert.equal(carrito.envio(), 12000);
    });

    test('el total incluye el envío y el envío no paga IVA', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('con envío gratis el total no suma envío', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.total(), 178500);
    });

    test('un carrito vacío no cobra envío', () => {
      assert.equal(carrito.envio(), 0);
    });
  });
});
FIN_TEST_10

paso 'feat: costo de envío gratis desde 150000 (reto B)'

cat > src/carrito.js << 'FIN_CODIGO_11'
const IVA = 0.19;
const ENVIO = 12000;
const ENVIO_GRATIS_DESDE = 150000;

const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
};

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
    if (!(codigo in CUPONES)) {
      throw new Error(`El cupón "${codigo}" no es válido`);
    }
    this.cupon = codigo;
  }

  descuento() {
    if (!this.cupon) return 0;
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
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
FIN_CODIGO_11

cat > test/carrito.test.js << 'FIN_TEST_11'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 119100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });

  describe('Reto A: resumen de la compra', () => {
    test('resumen devuelve todos los valores de la compra', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.deepEqual(carrito.resumen(), {
        subtotal: 100000,
        descuento: 10000,
        iva: 17100,
        envio: 12000,
        total: 119100,
      });
    });

    test('resumen de un carrito vacío tiene todo en 0', () => {
      assert.deepEqual(carrito.resumen(), {
        subtotal: 0,
        descuento: 0,
        iva: 0,
        envio: 0,
        total: 0,
      });
    });
  });

  describe('Reto B: costo de envío', () => {
    test('el envío cuesta 12000 si la base gravable es menor a 150000', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío es gratis si la base gravable es exactamente 150000', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.envio(), 0);
    });

    test('el envío cuesta 12000 con una base de 149999', () => {
      carrito.agregar('Cable', 149999, 1);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío se evalúa sobre la base con descuento', () => {
      carrito.agregar('Monitor', 160000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.baseGravable(), 144000);
      assert.equal(carrito.envio(), 12000);
    });

    test('el total incluye el envío y el envío no paga IVA', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('con envío gratis el total no suma envío', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.total(), 178500);
    });

    test('un carrito vacío no cobra envío', () => {
      assert.equal(carrito.envio(), 0);
    });
  });

  describe('Reto C: actualizar cantidad', () => {
    test('actualizar la cantidad reemplaza el valor anterior', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.actualizarCantidad('Mouse', 5);
      assert.equal(carrito.cantidadDeItems(), 5);
      assert.equal(carrito.subtotal(), 250000);
    });

    test('si la nueva cantidad es 0 el producto se elimina', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.actualizarCantidad('Mouse', 0);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('una cantidad negativa lanza un error', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.throws(() => carrito.actualizarCantidad('Mouse', -1), /cantidad/);
    });

    test('una cantidad decimal lanza un error', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.throws(() => carrito.actualizarCantidad('Mouse', 1.5), /cantidad/);
    });

    test('actualizar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.actualizarCantidad('Monitor', 2), /no está en el carrito/);
    });
  });
});
FIN_TEST_11

paso 'feat: actualizar cantidad de un producto (reto C)'

cat > src/carrito.js << 'FIN_CODIGO_12'
const IVA = 0.19;
const ENVIO = 12000;
const ENVIO_GRATIS_DESDE = 150000;

const CUPONES = {
  DESC10: 0.10,
  DESC20: 0.20,
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
    return Math.round(this.subtotal() * CUPONES[this.cupon]);
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
FIN_CODIGO_12

cat > test/carrito.test.js << 'FIN_TEST_12'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 119100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });

  describe('Reto A: resumen de la compra', () => {
    test('resumen devuelve todos los valores de la compra', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.deepEqual(carrito.resumen(), {
        subtotal: 100000,
        descuento: 10000,
        iva: 17100,
        envio: 12000,
        total: 119100,
      });
    });

    test('resumen de un carrito vacío tiene todo en 0', () => {
      assert.deepEqual(carrito.resumen(), {
        subtotal: 0,
        descuento: 0,
        iva: 0,
        envio: 0,
        total: 0,
      });
    });
  });

  describe('Reto B: costo de envío', () => {
    test('el envío cuesta 12000 si la base gravable es menor a 150000', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío es gratis si la base gravable es exactamente 150000', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.envio(), 0);
    });

    test('el envío cuesta 12000 con una base de 149999', () => {
      carrito.agregar('Cable', 149999, 1);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío se evalúa sobre la base con descuento', () => {
      carrito.agregar('Monitor', 160000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.baseGravable(), 144000);
      assert.equal(carrito.envio(), 12000);
    });

    test('el total incluye el envío y el envío no paga IVA', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('con envío gratis el total no suma envío', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.total(), 178500);
    });

    test('un carrito vacío no cobra envío', () => {
      assert.equal(carrito.envio(), 0);
    });
  });

  describe('Reto C: actualizar cantidad', () => {
    test('actualizar la cantidad reemplaza el valor anterior', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.actualizarCantidad('Mouse', 5);
      assert.equal(carrito.cantidadDeItems(), 5);
      assert.equal(carrito.subtotal(), 250000);
    });

    test('si la nueva cantidad es 0 el producto se elimina', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.actualizarCantidad('Mouse', 0);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('una cantidad negativa lanza un error', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.throws(() => carrito.actualizarCantidad('Mouse', -1), /cantidad/);
    });

    test('una cantidad decimal lanza un error', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.throws(() => carrito.actualizarCantidad('Mouse', 1.5), /cantidad/);
    });

    test('actualizar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.actualizarCantidad('Monitor', 2), /no está en el carrito/);
    });
  });

  describe('Reto D: cupones sin importar mayúsculas', () => {
    test('el cupón en minúsculas funciona', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('desc10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón con espacios funciona', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('  DESC20  ');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente con espacios sigue lanzando error', () => {
      assert.throws(() => carrito.aplicarCupon(' gratis '), /no es válido/);
    });
  });
});
FIN_TEST_12

paso 'feat: cupones sin importar mayúsculas ni espacios (reto D)'

cat > src/carrito.js << 'FIN_CODIGO_13'
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
FIN_CODIGO_13

cat > test/carrito.test.js << 'FIN_TEST_13'
import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Carrito } from '../src/carrito.js';

describe('Carrito de compras', () => {
  let carrito;

  beforeEach(() => {
    carrito = new Carrito();
  });

  describe('Iteración 1: carrito vacío', () => {
    test('un carrito nuevo no tiene ítems', () => {
      assert.equal(carrito.cantidadDeItems(), 0);
    });

    test('un carrito nuevo tiene subtotal 0', () => {
      assert.equal(carrito.subtotal(), 0);
    });
  });

  describe('Iteración 2: agregar productos', () => {
    test('agregar un producto actualiza cantidad y subtotal', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.cantidadDeItems(), 2);
      assert.equal(carrito.subtotal(), 100000);
    });

    test('agregar varios productos suma todos los subtotales', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 220000);
    });

    test('si no se indica cantidad, se agrega una unidad', () => {
      carrito.agregar('Audífonos', 80000);
      assert.equal(carrito.cantidadDeItems(), 1);
    });
  });

  describe('Iteración 3: producto repetido', () => {
    test('agregar el mismo producto acumula la cantidad en una sola línea', () => {
      carrito.agregar('Mouse', 50000, 1);
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.cantidadDeItems(), 3);
      assert.equal(carrito.subtotal(), 150000);
    });
  });

  describe('Iteración 4: validaciones', () => {
    test('no permite precios negativos o en cero', () => {
      assert.throws(() => carrito.agregar('Mouse', -100, 1), /precio/);
      assert.throws(() => carrito.agregar('Mouse', 0, 1), /precio/);
    });

    test('no permite cantidades en cero, negativas o decimales', () => {
      assert.throws(() => carrito.agregar('Mouse', 50000, 0), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, -1), /cantidad/);
      assert.throws(() => carrito.agregar('Mouse', 50000, 1.5), /cantidad/);
    });
  });

  describe('Iteración 5: eliminar productos', () => {
    test('eliminar un producto lo quita del carrito', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.eliminar('Mouse');
      assert.equal(carrito.cantidadDeItems(), 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('eliminar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.eliminar('Monitor'), /no está en el carrito/);
    });
  });

  describe('Iteración 6: cupones de descuento', () => {
    test('sin cupón el descuento es 0', () => {
      carrito.agregar('Teclado', 200000, 1);
      assert.equal(carrito.descuento(), 0);
    });

    test('el cupón DESC10 descuenta el 10 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón DESC20 descuenta el 20 % del subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC20');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente lanza un error', () => {
      assert.throws(() => carrito.aplicarCupon('GRATIS'), /no es válido/);
    });
  });

  describe('Iteración 7: IVA y total a pagar', () => {
    test('el IVA es el 19 % del subtotal cuando no hay cupón', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('el IVA se calcula sobre el valor con descuento', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.iva(), 17100);
      assert.equal(carrito.total(), 119100);
    });

    test('un carrito vacío tiene total 0', () => {
      assert.equal(carrito.total(), 0);
    });
  });

  describe('Reto A: resumen de la compra', () => {
    test('resumen devuelve todos los valores de la compra', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.aplicarCupon('DESC10');
      assert.deepEqual(carrito.resumen(), {
        subtotal: 100000,
        descuento: 10000,
        iva: 17100,
        envio: 12000,
        total: 119100,
      });
    });

    test('resumen de un carrito vacío tiene todo en 0', () => {
      assert.deepEqual(carrito.resumen(), {
        subtotal: 0,
        descuento: 0,
        iva: 0,
        envio: 0,
        total: 0,
      });
    });
  });

  describe('Reto B: costo de envío', () => {
    test('el envío cuesta 12000 si la base gravable es menor a 150000', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío es gratis si la base gravable es exactamente 150000', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.envio(), 0);
    });

    test('el envío cuesta 12000 con una base de 149999', () => {
      carrito.agregar('Cable', 149999, 1);
      assert.equal(carrito.envio(), 12000);
    });

    test('el envío se evalúa sobre la base con descuento', () => {
      carrito.agregar('Monitor', 160000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.baseGravable(), 144000);
      assert.equal(carrito.envio(), 12000);
    });

    test('el total incluye el envío y el envío no paga IVA', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.equal(carrito.iva(), 19000);
      assert.equal(carrito.total(), 131000);
    });

    test('con envío gratis el total no suma envío', () => {
      carrito.agregar('Monitor', 150000, 1);
      assert.equal(carrito.total(), 178500);
    });

    test('un carrito vacío no cobra envío', () => {
      assert.equal(carrito.envio(), 0);
    });
  });

  describe('Reto C: actualizar cantidad', () => {
    test('actualizar la cantidad reemplaza el valor anterior', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.actualizarCantidad('Mouse', 5);
      assert.equal(carrito.cantidadDeItems(), 5);
      assert.equal(carrito.subtotal(), 250000);
    });

    test('si la nueva cantidad es 0 el producto se elimina', () => {
      carrito.agregar('Mouse', 50000, 2);
      carrito.agregar('Teclado', 120000, 1);
      carrito.actualizarCantidad('Mouse', 0);
      assert.equal(carrito.productos.length, 1);
      assert.equal(carrito.subtotal(), 120000);
    });

    test('una cantidad negativa lanza un error', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.throws(() => carrito.actualizarCantidad('Mouse', -1), /cantidad/);
    });

    test('una cantidad decimal lanza un error', () => {
      carrito.agregar('Mouse', 50000, 2);
      assert.throws(() => carrito.actualizarCantidad('Mouse', 1.5), /cantidad/);
    });

    test('actualizar un producto que no existe lanza un error', () => {
      assert.throws(() => carrito.actualizarCantidad('Monitor', 2), /no está en el carrito/);
    });
  });

  describe('Reto D: cupones sin importar mayúsculas', () => {
    test('el cupón en minúsculas funciona', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('desc10');
      assert.equal(carrito.descuento(), 20000);
    });

    test('el cupón con espacios funciona', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('  DESC20  ');
      assert.equal(carrito.descuento(), 40000);
    });

    test('un cupón inexistente con espacios sigue lanzando error', () => {
      assert.throws(() => carrito.aplicarCupon(' gratis '), /no es válido/);
    });
  });

  describe('Reto E: cupón de valor fijo', () => {
    test('MENOS30K resta 30000 al subtotal', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('MENOS30K');
      assert.equal(carrito.descuento(), 30000);
      assert.equal(carrito.baseGravable(), 170000);
    });

    test('el descuento fijo nunca deja la base en negativo', () => {
      carrito.agregar('Cable', 20000, 1);
      carrito.aplicarCupon('MENOS30K');
      assert.equal(carrito.descuento(), 20000);
      assert.equal(carrito.baseGravable(), 0);
      assert.equal(carrito.iva(), 0);
    });

    test('los cupones de porcentaje siguen funcionando', () => {
      carrito.agregar('Teclado', 200000, 1);
      carrito.aplicarCupon('DESC10');
      assert.equal(carrito.descuento(), 20000);
    });
  });
});
FIN_TEST_13

paso 'feat: cupón de valor fijo MENOS30K (reto E)'


git log --oneline
npm test 2>&1 | grep -E '^# (tests|pass|fail)'
