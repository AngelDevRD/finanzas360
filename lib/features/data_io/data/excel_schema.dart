/// Nombres de hojas y columnas del formato de intercambio Excel. Centralizado
/// para que exportación, importación y plantilla usen siempre los mismos
/// nombres y el lector tolere agregar columnas nuevas sin romper archivos
/// viejos (las columnas se buscan por nombre, no por posición).
class ExcelSchema {
  static const sheetMovimientos = 'Movimientos';
  static const sheetPresupuestos = 'Presupuestos';
  static const sheetMetas = 'Metas';

  static const colFecha = 'Fecha';
  static const colTipo = 'Tipo';
  static const colCategoria = 'Categoría';
  static const colDescripcion = 'Descripción';
  static const colMonto = 'Monto';

  static const colLimiteMensual = 'Límite Mensual';

  static const colNombre = 'Nombre';
  static const colObjetivo = 'Objetivo';
  static const colAhorrado = 'Ahorrado';

  static const tipoIngreso = 'Ingreso';
  static const tipoGasto = 'Gasto';
}
