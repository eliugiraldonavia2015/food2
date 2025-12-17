import Foundation
import FirebaseFirestore

public final class MenuService {
    public static let shared = MenuService()
    private let db: Firestore
    private init() {
        db = DatabaseService.shared.db
    }
    
    private func restaurantsRef() -> CollectionReference {
        db.collection(AppConstants.Firebase.restaurantsCollection)
    }
    
    private func restaurantSectionsRef(_ restaurantId: String) -> CollectionReference {
        restaurantsRef().document(restaurantId).collection(AppConstants.Firebase.menuSectionsCollection)
    }
    
    private func restaurantItemsRef(_ restaurantId: String) -> CollectionReference {
        restaurantsRef().document(restaurantId).collection(AppConstants.Firebase.menuItemsCollection)
    }
    
    public func getSectionCatalog(completion: @escaping (Result<[SectionCatalogItem], Error>) -> Void) {
        db.collection(AppConstants.Firebase.sectionCatalogCollection)
            .order(by: "sortOrder")
            .getDocuments { snap, err in
                if let err = err {
                    completion(.success(self.defaultCatalog()))
                    return
                }
                guard let docs = snap?.documents, !docs.isEmpty else {
                    completion(.success(self.defaultCatalog()))
                    return
                }
                let items = docs.compactMap { d -> SectionCatalogItem? in
                    let id = d.documentID
                    let name = d.get("name") as? String ?? ""
                    let slug = d.get("slug") as? String ?? ""
                    let icon = d.get("icon") as? String
                    let sortOrder = d.get("sortOrder") as? Int ?? 0
                    let isActive = d.get("isActive") as? Bool ?? true
                    return SectionCatalogItem(id: id, name: name, slug: slug, icon: icon, sortOrder: sortOrder, isActive: isActive)
                }
                completion(.success(items))
            }
    }
    
    private func defaultCatalog() -> [SectionCatalogItem] {
        [
            SectionCatalogItem(id: "popular", name: "Popular", slug: "popular", icon: "flame", sortOrder: 0, isActive: true),
            SectionCatalogItem(id: "combos", name: "Combos", slug: "combos", icon: "square.grid.2x2", sortOrder: 1, isActive: true),
            SectionCatalogItem(id: "entradas", name: "Entradas", slug: "entradas", icon: "fork.knife", sortOrder: 2, isActive: true),
            SectionCatalogItem(id: "especiales", name: "Especiales", slug: "especiales", icon: "star", sortOrder: 3, isActive: true),
            SectionCatalogItem(id: "sopas", name: "Sopas", slug: "sopas", icon: "drop", sortOrder: 4, isActive: true),
            SectionCatalogItem(id: "bebidas", name: "Bebidas", slug: "bebidas", icon: "cup.and.saucer", sortOrder: 5, isActive: true)
        ]
    }
    
    public func seedSectionCatalogIfMissing(completion: @escaping (Error?) -> Void) {
        db.collection(AppConstants.Firebase.sectionCatalogCollection)
            .limit(to: 1)
            .getDocuments { snap, err in
                if let err = err {
                    completion(err)
                    return
                }
                if let snap = snap, !snap.isEmpty {
                    completion(nil)
                    return
                }
                let items = self.defaultCatalog()
                let batch = self.db.batch()
                for it in items {
                    let ref = self.db.collection(AppConstants.Firebase.sectionCatalogCollection).document(it.id)
                    batch.setData([
                        "name": it.name,
                        "slug": it.slug,
                        "icon": it.icon ?? "",
                        "sortOrder": it.sortOrder,
                        "isActive": it.isActive
                    ], forDocument: ref, merge: true)
                }
                batch.commit { e in completion(e) }
            }
    }
    
    public func getOrCreateRestaurantPrefix(restaurantId: String, restaurantName: String, completion: @escaping (Result<String, Error>) -> Void) {
        restaurantsRef().document(restaurantId).getDocument { doc, err in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let doc = doc, doc.exists, let prefix = doc.get("idPrefix") as? String, !prefix.isEmpty {
                completion(.success(prefix))
                return
            }
            self.generateUniquePrefix(basis: restaurantName) { result in
                switch result {
                case .failure(let e):
                    completion(.failure(e))
                case .success(let prefix):
                    let data: [String: Any] = [
                        "idPrefix": prefix,
                        "name": restaurantName,
                        "createdAt": Timestamp(date: Date())
                    ]
                    self.restaurantsRef().document(restaurantId).setData(data, merge: true) { e in
                        if let e = e {
                            completion(.failure(e))
                        } else {
                            completion(.success(prefix))
                        }
                    }
                }
            }
        }
    }
    
    private func generateUniquePrefix(basis: String, completion: @escaping (Result<String, Error>) -> Void) {
        let base = normalizePrefixSource(basis)
        var candidate = String(base.prefix(5))
        if candidate.isEmpty {
            candidate = randomPrefix()
        }
        checkPrefixAvailability(candidate) { available in
            if available {
                completion(.success(candidate))
            } else {
                self.findNextAvailablePrefix(base: candidate, attempt: 1, completion: completion)
            }
        }
    }
    
    private func findNextAvailablePrefix(base: String, attempt: Int, completion: @escaping (Result<String, Error>) -> Void) {
        let suffix = attempt <= 9 ? "\(attempt)" : String(UnicodeScalar(64 + attempt) ?? "X")
        let candidate = base.count >= 6 ? base : base + suffix
        checkPrefixAvailability(candidate) { available in
            if available {
                completion(.success(candidate))
            } else {
                self.findNextAvailablePrefix(base: base, attempt: attempt + 1, completion: completion)
            }
        }
    }
    
    private func normalizePrefixSource(_ s: String) -> String {
        let allowed = s.uppercased().filter { $0.isLetter || $0.isNumber }
        return allowed.replacingOccurrences(of: "O", with: "0").replacingOccurrences(of: "I", with: "1")
    }
    
    private func randomPrefix() -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTVWXYZ0123456789")
        return String((0..<5).map { _ in alphabet.randomElement()! })
    }
    
    private func checkPrefixAvailability(_ prefix: String, completion: @escaping (Bool) -> Void) {
        restaurantsRef().whereField("idPrefix", isEqualTo: prefix).limit(to: 1).getDocuments { snap, _ in
            completion(snap?.documents.isEmpty ?? true)
        }
    }
    
    public func enableSections(restaurantId: String, catalogItems: [SectionCatalogItem], completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        for item in catalogItems {
            let ref = restaurantSectionsRef(restaurantId).document(item.id)
            let data: [String: Any] = [
                "id": item.id,
                "restaurantId": restaurantId,
                "catalogId": item.id,
                "name": item.name,
                "description": "",
                "sortOrder": item.sortOrder,
                "isActive": true,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            batch.setData(data, forDocument: ref, merge: true)
        }
        batch.commit { e in
            completion(e)
        }
    }
    
    public func createMenuItem(restaurantId: String, sectionId: String, name: String, description: String?, price: Double, currency: String, imageUrls: [String], categoryCanonical: String?, tags: [String], isPublished: Bool, completion: @escaping (Result<MenuItem, Error>) -> Void) {
        getOrCreateRestaurantPrefix(restaurantId: restaurantId, restaurantName: name) { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success(let prefix):
                let suffix = ULID.new()
                let itemId = "\(prefix)-\(suffix)"
                let now = Date()
                let data: [String: Any] = [
                    "id": itemId,
                    "restaurantId": restaurantId,
                    "restaurantPrefix": prefix,
                    "menuId": "",
                    "sectionId": sectionId,
                    "name": name,
                    "description": description ?? "",
                    "imageUrls": imageUrls,
                    "price": price,
                    "currency": currency,
                    "sortOrder": 0,
                    "isPublished": isPublished,
                    "isAvailable": true,
                    "categoryCanonical": categoryCanonical ?? "",
                    "tags": tags,
                    "createdAt": Timestamp(date: now),
                    "updatedAt": Timestamp(date: now),
                    "updatedBy": restaurantId
                ]
                self.restaurantItemsRef(restaurantId).document(itemId).setData(data) { e in
                    if let e = e {
                        completion(.failure(e))
                    } else {
                        let model = MenuItem(id: itemId, restaurantId: restaurantId, restaurantPrefix: prefix, menuId: nil, sectionId: sectionId, name: name, description: description, imageUrls: imageUrls, price: price, currency: currency, sortOrder: 0, isPublished: isPublished, isAvailable: true, categoryCanonical: categoryCanonical, tags: tags, createdAt: now, updatedAt: now, updatedBy: restaurantId)
                        completion(.success(model))
                    }
                }
            }
        }
    }
    
    public func listMenuItems(restaurantId: String, publishedOnly: Bool, completion: @escaping (Result<[MenuItem], Error>) -> Void) {
        var q: Query = restaurantItemsRef(restaurantId).order(by: "sortOrder")
        if publishedOnly {
            q = q.whereField("isPublished", isEqualTo: true)
        }
        q.getDocuments { snap, err in
            if let err = err {
                completion(.failure(err))
                return
            }
            let items: [MenuItem] = snap?.documents.compactMap { d in
                let id = d.documentID
                let restaurantPrefix = d.get("restaurantPrefix") as? String ?? ""
                let sectionId = d.get("sectionId") as? String ?? ""
                let name = d.get("name") as? String ?? ""
                let description = d.get("description") as? String
                let imageUrls = d.get("imageUrls") as? [String] ?? []
                let price = d.get("price") as? Double ?? 0.0
                let currency = d.get("currency") as? String ?? "USD"
                let sortOrder = d.get("sortOrder") as? Int ?? 0
                let isPublished = d.get("isPublished") as? Bool ?? false
                let isAvailable = d.get("isAvailable") as? Bool ?? true
                let categoryCanonical = d.get("categoryCanonical") as? String
                let tags = d.get("tags") as? [String] ?? []
                let createdAt = (d.get("createdAt") as? Timestamp)?.dateValue() ?? Date()
                let updatedAt = (d.get("updatedAt") as? Timestamp)?.dateValue() ?? Date()
                let updatedBy = d.get("updatedBy") as? String
                return MenuItem(id: id, restaurantId: restaurantId, restaurantPrefix: restaurantPrefix, menuId: nil, sectionId: sectionId, name: name, description: description, imageUrls: imageUrls, price: price, currency: currency, sortOrder: sortOrder, isPublished: isPublished, isAvailable: isAvailable, categoryCanonical: categoryCanonical, tags: tags, createdAt: createdAt, updatedAt: updatedAt, updatedBy: updatedBy)
            } ?? []
            completion(.success(items))
        }
    }
    
    public func listEnabledSections(restaurantId: String, completion: @escaping (Result<[MenuSection], Error>) -> Void) {
        restaurantSectionsRef(restaurantId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "sortOrder")
            .getDocuments { snap, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                let sections: [MenuSection] = snap?.documents.compactMap { d in
                    let id = d.documentID
                    let name = d.get("name") as? String ?? ""
                    let description = d.get("description") as? String
                    let sortOrder = d.get("sortOrder") as? Int ?? 0
                    let createdAt = (d.get("createdAt") as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (d.get("updatedAt") as? Timestamp)?.dateValue() ?? Date()
                    return MenuSection(id: id, restaurantId: restaurantId, catalogId: id, name: name, description: description, sortOrder: sortOrder, isActive: true, createdAt: createdAt, updatedAt: updatedAt)
                } ?? []
                completion(.success(sections))
            }
    }
    
    public func ensureDemoData(restaurantId: String, restaurantName: String, completion: @escaping (Error?) -> Void) {
        getOrCreateRestaurantPrefix(restaurantId: restaurantId, restaurantName: restaurantName) { _ in
            self.listEnabledSections(restaurantId: restaurantId) { res in
                switch res {
                case .failure:
                    self.getSectionCatalog { catRes in
                        let base = (try? catRes.get()) ?? self.defaultCatalog()
                        let picked = Array(base.prefix(5))
                        self.enableSections(restaurantId: restaurantId, catalogItems: picked) { e in
                            if let e = e {
                                completion(e)
                            } else {
                                self.seedDemoItems(restaurantId: restaurantId, sections: picked, completion: completion)
                            }
                        }
                    }
                case .success(let secs):
                    if secs.isEmpty {
                        self.getSectionCatalog { catRes in
                            let base = (try? catRes.get()) ?? self.defaultCatalog()
                            let picked = Array(base.prefix(5))
                            self.enableSections(restaurantId: restaurantId, catalogItems: picked) { e in
                                if let e = e {
                                    completion(e)
                                } else {
                                    self.seedDemoItems(restaurantId: restaurantId, sections: picked, completion: completion)
                                }
                            }
                        }
                    } else {
                        let catItems = secs.map { SectionCatalogItem(id: $0.id, name: $0.name, slug: $0.id, icon: nil, sortOrder: $0.sortOrder, isActive: true) }
                        self.seedDemoItems(restaurantId: restaurantId, sections: catItems, completion: completion)
                    }
                }
            }
        }
    }
    
    private func seedDemoItems(restaurantId: String, sections: [SectionCatalogItem], completion: @escaping (Error?) -> Void) {
        let picks: [(String, String, Double, String)] = [
            ("Pizza", "https://images.unsplash.com/photo-1601924638867-3ec3b1f7c2d7", 9.99, "USD"),
            ("Burger", "https://images.unsplash.com/photo-1550547660-d9450f859349", 7.49, "USD"),
            ("Pasta", "https://images.unsplash.com/photo-1525755662778-989d0524087e", 8.99, "USD"),
            ("Nachos", "https://images.unsplash.com/photo-1586190848861-99aa4a171e90", 4.99, "USD"),
            ("Ramen", "https://images.unsplash.com/photo-1543353071-873f17a7a5c0", 10.99, "USD")
        ]
        var lastError: Error? = nil
        let group = DispatchGroup()
        for (idx, sec) in sections.enumerated() {
            let p = picks[min(idx, picks.count - 1)]
            group.enter()
            createMenuItem(restaurantId: restaurantId, sectionId: sec.id, name: p.0, description: "", price: p.2, currency: p.3, imageUrls: [p.1], categoryCanonical: sec.slug, tags: [], isPublished: true) { res in
                switch res {
                case .failure(let e): lastError = e
                case .success: break
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(lastError)
        }
    }
}
