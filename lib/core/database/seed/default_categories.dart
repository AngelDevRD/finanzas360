/// Datos de seed para categorías por defecto, insertadas en el primer
/// arranque de la base de datos. Los ids son fijos (no UUID) para que la
/// inserción sea idempotente y referenciable desde código si hace falta.
class CategorySeed {
  final String id;
  final String name;
  final String type; // income | expense
  final String? parentId;
  final String icon;
  final int color;

  const CategorySeed({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentId,
  });
}

const _incomeColor = 0xFF22C55E; // verde
const _expenseColor = 0xFFEF4444; // rojo

const List<CategorySeed> kDefaultIncomeCategories = [
  CategorySeed(
    id: 'inc_salario',
    name: 'Salario',
    type: 'income',
    icon: 'work',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_freelance',
    name: 'Freelance',
    type: 'income',
    icon: 'laptop',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_negocio',
    name: 'Negocio',
    type: 'income',
    icon: 'storefront',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_comisiones',
    name: 'Comisiones',
    type: 'income',
    icon: 'percent',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_bonificaciones',
    name: 'Bonificaciones',
    type: 'income',
    icon: 'card_giftcard',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_regalos',
    name: 'Regalos',
    type: 'income',
    icon: 'redeem',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_reembolsos',
    name: 'Reembolsos',
    type: 'income',
    icon: 'replay',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_ventas',
    name: 'Ventas',
    type: 'income',
    icon: 'sell',
    color: _incomeColor,
  ),
  CategorySeed(
    id: 'inc_otros',
    name: 'Otros',
    type: 'income',
    icon: 'category',
    color: _incomeColor,
  ),
];

const List<CategorySeed> kDefaultExpenseGroups = [
  CategorySeed(
    id: 'exp_vivienda',
    name: 'Vivienda',
    type: 'expense',
    icon: 'home',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_servicios',
    name: 'Servicios',
    type: 'expense',
    icon: 'bolt',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_alimentacion',
    name: 'Alimentación',
    type: 'expense',
    icon: 'shopping_cart',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_transporte',
    name: 'Transporte',
    type: 'expense',
    icon: 'directions_car',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_salud',
    name: 'Salud',
    type: 'expense',
    icon: 'medical_services',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_educacion',
    name: 'Educación',
    type: 'expense',
    icon: 'school',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_entretenimiento',
    name: 'Entretenimiento',
    type: 'expense',
    icon: 'movie',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_compras',
    name: 'Compras',
    type: 'expense',
    icon: 'checkroom',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_finanzas',
    name: 'Finanzas',
    type: 'expense',
    icon: 'request_quote',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_otros',
    name: 'Otros',
    type: 'expense',
    icon: 'more_horiz',
    color: _expenseColor,
  ),
];

const List<CategorySeed> kDefaultExpenseLeaves = [
  // Vivienda
  CategorySeed(
    id: 'exp_vivienda_alquiler',
    name: 'Alquiler',
    type: 'expense',
    parentId: 'exp_vivienda',
    icon: 'home',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_vivienda_hipoteca',
    name: 'Hipoteca',
    type: 'expense',
    parentId: 'exp_vivienda',
    icon: 'house',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_vivienda_mantenimiento',
    name: 'Mantenimiento',
    type: 'expense',
    parentId: 'exp_vivienda',
    icon: 'build',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_vivienda_reparaciones',
    name: 'Reparaciones',
    type: 'expense',
    parentId: 'exp_vivienda',
    icon: 'handyman',
    color: _expenseColor,
  ),

  // Servicios
  CategorySeed(
    id: 'exp_servicios_electricidad',
    name: 'Electricidad',
    type: 'expense',
    parentId: 'exp_servicios',
    icon: 'bolt',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_servicios_agua',
    name: 'Agua',
    type: 'expense',
    parentId: 'exp_servicios',
    icon: 'water_drop',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_servicios_internet',
    name: 'Internet',
    type: 'expense',
    parentId: 'exp_servicios',
    icon: 'wifi',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_servicios_telefono',
    name: 'Teléfono',
    type: 'expense',
    parentId: 'exp_servicios',
    icon: 'phone',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_servicios_cable',
    name: 'Cable',
    type: 'expense',
    parentId: 'exp_servicios',
    icon: 'tv',
    color: _expenseColor,
  ),

  // Alimentacion
  CategorySeed(
    id: 'exp_alimentacion_supermercado',
    name: 'Supermercado',
    type: 'expense',
    parentId: 'exp_alimentacion',
    icon: 'shopping_cart',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_alimentacion_restaurantes',
    name: 'Restaurantes',
    type: 'expense',
    parentId: 'exp_alimentacion',
    icon: 'restaurant',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_alimentacion_delivery',
    name: 'Delivery',
    type: 'expense',
    parentId: 'exp_alimentacion',
    icon: 'delivery_dining',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_alimentacion_snacks',
    name: 'Snacks',
    type: 'expense',
    parentId: 'exp_alimentacion',
    icon: 'cookie',
    color: _expenseColor,
  ),

  // Transporte
  CategorySeed(
    id: 'exp_transporte_combustible',
    name: 'Combustible',
    type: 'expense',
    parentId: 'exp_transporte',
    icon: 'local_gas_station',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_transporte_uber',
    name: 'Uber',
    type: 'expense',
    parentId: 'exp_transporte',
    icon: 'local_taxi',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_transporte_taxi',
    name: 'Taxi',
    type: 'expense',
    parentId: 'exp_transporte',
    icon: 'local_taxi',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_transporte_publico',
    name: 'Transporte público',
    type: 'expense',
    parentId: 'exp_transporte',
    icon: 'directions_bus',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_transporte_mantenimiento',
    name: 'Mantenimiento vehículo',
    type: 'expense',
    parentId: 'exp_transporte',
    icon: 'directions_car_filled',
    color: _expenseColor,
  ),

  // Salud
  CategorySeed(
    id: 'exp_salud_medicamentos',
    name: 'Medicamentos',
    type: 'expense',
    parentId: 'exp_salud',
    icon: 'medication',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_salud_consultas',
    name: 'Consultas médicas',
    type: 'expense',
    parentId: 'exp_salud',
    icon: 'medical_services',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_salud_seguro',
    name: 'Seguro médico',
    type: 'expense',
    parentId: 'exp_salud',
    icon: 'health_and_safety',
    color: _expenseColor,
  ),

  // Educacion
  CategorySeed(
    id: 'exp_educacion_cursos',
    name: 'Cursos',
    type: 'expense',
    parentId: 'exp_educacion',
    icon: 'school',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_educacion_universidad',
    name: 'Universidad',
    type: 'expense',
    parentId: 'exp_educacion',
    icon: 'school',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_educacion_libros',
    name: 'Libros',
    type: 'expense',
    parentId: 'exp_educacion',
    icon: 'menu_book',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_educacion_certificaciones',
    name: 'Certificaciones',
    type: 'expense',
    parentId: 'exp_educacion',
    icon: 'workspace_premium',
    color: _expenseColor,
  ),

  // Entretenimiento
  CategorySeed(
    id: 'exp_entretenimiento_streaming',
    name: 'Streaming',
    type: 'expense',
    parentId: 'exp_entretenimiento',
    icon: 'tv',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_entretenimiento_videojuegos',
    name: 'Videojuegos',
    type: 'expense',
    parentId: 'exp_entretenimiento',
    icon: 'sports_esports',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_entretenimiento_cine',
    name: 'Cine',
    type: 'expense',
    parentId: 'exp_entretenimiento',
    icon: 'theater_comedy',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_entretenimiento_eventos',
    name: 'Eventos',
    type: 'expense',
    parentId: 'exp_entretenimiento',
    icon: 'event',
    color: _expenseColor,
  ),

  // Compras
  CategorySeed(
    id: 'exp_compras_ropa',
    name: 'Ropa',
    type: 'expense',
    parentId: 'exp_compras',
    icon: 'checkroom',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_compras_tecnologia',
    name: 'Tecnología',
    type: 'expense',
    parentId: 'exp_compras',
    icon: 'devices',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_compras_hogar',
    name: 'Hogar',
    type: 'expense',
    parentId: 'exp_compras',
    icon: 'chair',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_compras_accesorios',
    name: 'Accesorios',
    type: 'expense',
    parentId: 'exp_compras',
    icon: 'watch',
    color: _expenseColor,
  ),

  // Finanzas
  CategorySeed(
    id: 'exp_finanzas_prestamos',
    name: 'Préstamos',
    type: 'expense',
    parentId: 'exp_finanzas',
    icon: 'request_quote',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_finanzas_tarjetas',
    name: 'Tarjetas de crédito',
    type: 'expense',
    parentId: 'exp_finanzas',
    icon: 'credit_card',
    color: _expenseColor,
  ),
  CategorySeed(
    id: 'exp_finanzas_intereses',
    name: 'Intereses',
    type: 'expense',
    parentId: 'exp_finanzas',
    icon: 'trending_down',
    color: _expenseColor,
  ),

  // Otros
  CategorySeed(
    id: 'exp_otros_varios',
    name: 'Gastos varios',
    type: 'expense',
    parentId: 'exp_otros',
    icon: 'more_horiz',
    color: _expenseColor,
  ),
];

List<CategorySeed> get kAllDefaultCategories => [
  ...kDefaultIncomeCategories,
  ...kDefaultExpenseGroups,
  ...kDefaultExpenseLeaves,
];
