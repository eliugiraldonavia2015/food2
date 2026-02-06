import Foundation

struct CategoryItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let image: String // Nombre del Asset local
}

let allCategoryItems = [
    CategoryItem(name: "Hamburguesas", image: "category_burgers"),
    CategoryItem(name: "Pizza", image: "category_pizza"),
    CategoryItem(name: "Pollo", image: "category_chicken"),
    CategoryItem(name: "Tigrillo", image: "category_tigrillo"),
    CategoryItem(name: "Chifa", image: "category_chifa"),
    CategoryItem(name: "Salchipapas", image: "category_salchipapas"),
    CategoryItem(name: "Sushi", image: "category_sushi"),
    CategoryItem(name: "Alitas", image: "category_wings"),
    CategoryItem(name: "Tacos", image: "category_tacos"),
    CategoryItem(name: "Hornado", image: "category_hornado"),
    CategoryItem(name: "Fritada", image: "category_fritada"),
    CategoryItem(name: "Ceviches", image: "category_ceviche"),
    CategoryItem(name: "Mariscos", image: "category_seafood"),
    CategoryItem(name: "Comida Rápida", image: "category_fastfood"),
    CategoryItem(name: "Sanduches", image: "category_sandwiches"),
    CategoryItem(name: "Hot Dogs", image: "category_hotdogs"),
    CategoryItem(name: "Desayunos", image: "category_breakfast")
]
