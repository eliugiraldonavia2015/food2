import Foundation

struct MockData {
    static let forYouItems: [FeedItem] = [
        // 1. Foodie Review con historias (círculo verde)
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            backgroundUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
            username: "Burger Master",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
            title: "🔥 Smash Burger Deluxe",
            description: "Juicy double patty with special sauce, crispy onions, and melted cheese. The perfect burger experience!",
            soundTitle: "Grill Beats • Burger Jam",
            likes: 12400,
            comments: 342,
            shares: 120
        ),
        // 2. Sponsored sin historias
        .init(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            backgroundUrl: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            username: "Pizza Palace",
            label: .sponsored,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1568602471122-7832951cc4c5",
            title: "🍕 Pepperoni Feast",
            description: "Loaded with extra pepperoni, mozzarella, and our signature tomato sauce. Order now!",
            soundTitle: "Pizza Groove • Delivery Beat",
            likes: 8500,
            comments: 156,
            shares: 45
        ),
        // 3. Normal con historias (círculo verde)
        .init(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            backgroundUrl: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445",
            username: "Sushi Sensation",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
            title: "🎌 Dragon Roll Supreme",
            description: "Fresh salmon, avocado, and cucumber wrapped in nori. Topped with eel sauce and sesame seeds.",
            soundTitle: "Tokyo Vibes • Sushi Flow",
            likes: 23100,
            comments: 890,
            shares: 430,
            videoUrl: "https://vz-eb3c7132-8b5.b-cdn.net/0f36fe06-1355-4596-a707-5bbf19b9e08c/playlist.m3u8",
            posterUrl: "https://vz-eb3c7132-8b5.b-cdn.net/0f36fe06-1355-4596-a707-5bbf19b9e08c/thumbnail_76c09eff.jpg"
        ),
        // 4. Foodie Review sin historias
        .init(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            backgroundUrl: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47",
            username: "Pasta Paradise",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1547425260-76bcadfb4f2c",
            title: "🍝 Truffle Mushroom Pasta",
            description: "Creamy truffle sauce with wild mushrooms and parmesan. A gourmet experience!",
            soundTitle: "Italian Beats • Pasta Jam",
            likes: 15600,
            comments: 420,
            shares: 210
        ),
        // 5. Sponsored con historias (círculo verde)
        .init(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            backgroundUrl: "https://images.unsplash.com/photo-1559715745-e1b33a271c8f",
            username: "Dessert Heaven",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
            title: "🍰 Chocolate Lava Cake",
            description: "Warm chocolate cake with molten center. Served with vanilla ice cream.",
            soundTitle: "Sweet Melody • Dessert Mix",
            likes: 45000,
            comments: 1200,
            shares: 3500
        ),
        // 6. Normal sin historias
        .init(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            backgroundUrl: "https://images.unsplash.com/photo-1565958011703-44f9829ba187",
            username: "Salad Bar",
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
            title: "🥗 Superfood Bowl",
            description: "Quinoa, kale, avocado, nuts, and seeds with citrus vinaigrette. Healthy and delicious!",
            soundTitle: "Fresh Beats • Green Mix",
            likes: 5600,
            comments: 89,
            shares: 23
        ),
        // 7. Foodie Review con historias (círculo verde) - Mix completo
        .init(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            backgroundUrl: "https://images.unsplash.com/photo-1565299507177-b0ac66763828",
            username: "Taco Fiesta",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            title: "🌮 Street Tacos Pack",
            description: "Authentic street-style tacos with your choice of meat, cilantro, onions, and lime.",
            soundTitle: "Fiesta Rhythm • Taco Beat",
            likes: 18900,
            comments: 670,
            shares: 890
        )
    ]
    
    static let followingItems: [FeedItem] = [
        // 1. Restaurante con historias (círculo verde)
        .init(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            backgroundUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            username: "BBQ Kingdom",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1560250097-0b93528c311a",
            title: "🔥 Smoked Brisket Plate",
            description: "14-hour smoked brisket with peppery bark, house pickles, and cornbread. Authentic Texas style!",
            soundTitle: "Smokehouse Beats • BBQ Jam",
            likes: 32100,
            comments: 1500,
            shares: 2100
        ),
        // 2. Sponsored sin historias
        .init(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            backgroundUrl: "https://images.unsplash.com/photo-1572802419224-296b0aeee0d9",
            username: "Green Delight",
            label: .sponsored,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61",
            title: "🥗 Power Bowl",
            description: "Superfood salad with quinoa, roasted vegetables, and tahini dressing. Fuel your day!",
            soundTitle: "Healthy Vibes • Green Mix",
            likes: 4200,
            comments: 120,
            shares: 45
        ),
        // 3. Normal con historias (círculo verde)
        .init(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            backgroundUrl: "https://images.unsplash.com/photo-1551504734-b464e32a163a",
            username: "Taco Express",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1519244703995-f4e0f30006d5",
            title: "🌮 Street Taco Box",
            description: "Authentic street tacos with your choice of meat, fresh cilantro, onions, and lime wedges.",
            soundTitle: "Street Beats • Taco Flow",
            likes: 14500,
            comments: 340,
            shares: 180
        ),
        // 4. Foodie Review sin historias
        .init(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            backgroundUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e",
            username: "Sandwich Artisans",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
            title: "🥪 Ultimate Club",
            description: "Triple-decker with turkey, bacon, avocado, tomato, and special sauce. Served with chips.",
            soundTitle: "Delicious Beats • Sandwich Jam",
            likes: 9800,
            comments: 230,
            shares: 120
        ),
        // 5. Sponsored con historias (círculo verde)
        .init(
            id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            backgroundUrl: "https://images.unsplash.com/photo-1559715745-e1b33a271c8f",
            username: "Sweet Corner",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1544725176-7c40e5a71c5e",
            title: "🍩 Donut Variety",
            description: "Freshly baked donuts with various glazes and toppings. Perfect with coffee!",
            soundTitle: "Sweet Melody • Donut Mix",
            likes: 28900,
            comments: 980,
            shares: 1500
        ),
        // 6. Normal sin historias
        .init(
            id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
            backgroundUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591",
            username: "Pizza Corner",
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
            title: "🍕 Margherita Classic",
            description: "Traditional pizza with fresh mozzarella, tomato sauce, and basil. Simple and delicious!",
            soundTitle: "Italian Beats • Pizza Flow",
            likes: 11200,
            comments: 450,
            shares: 320
        ),
        // 7. Foodie Review con historias (círculo verde) - Mix completo
        .init(
            id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
            backgroundUrl: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            username: "Gourmet Burgers",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            title: "🍔 Signature Burger",
            description: "Gourmet beef patty with aged cheddar, caramelized onions, and truffle aioli. Served with fries.",
            soundTitle: "Gourmet Beats • Burger Mix",
            likes: 34500,
            comments: 1100,
            shares: 2300
        )
    ]
}
