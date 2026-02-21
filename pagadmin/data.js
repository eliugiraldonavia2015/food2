// Mock Data for Users (Restaurants)
const usersData = [
    { id: 'u1', name: 'Restaurante El Buen Sabor', email: 'contacto@buensabor.com', status: 'active' },
    { id: 'u2', name: 'Burger King Mock', email: 'manager@bkmock.com', status: 'active' },
    { id: 'u3', name: 'Pizza Hut Mock', email: 'admin@pizzahut.com', status: 'inactive' },
    { id: 'u4', name: 'Sushi Express', email: 'info@sushiexpress.com', status: 'active' }
];

// Mock Data for Dishes (Platos)
const dishesData = [
    { 
        id: 'd1', 
        name: 'Hamburguesa Clásica', 
        price: 5.99, 
        category: 'Hamburguesas', 
        restaurantId: 'u2', 
        restaurantName: 'Burger King Mock',
        image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=100&q=80',
        status: 'active'
    },
    { 
        id: 'd2', 
        name: 'Pizza Pepperoni', 
        price: 12.50, 
        category: 'Pizza', 
        restaurantId: 'u3', 
        restaurantName: 'Pizza Hut Mock',
        image: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=100&q=80',
        status: 'inactive'
    },
    { 
        id: 'd3', 
        name: 'Encebollado Mixto', 
        price: 4.50, 
        category: 'Sopas', 
        restaurantId: 'u1', 
        restaurantName: 'Restaurante El Buen Sabor',
        image: 'https://images.unsplash.com/photo-1572449043416-55f4685c9bb7?auto=format&fit=crop&w=100&q=80',
        status: 'active'
    },
    { 
        id: 'd4', 
        name: 'California Roll', 
        price: 8.99, 
        category: 'Sushi', 
        restaurantId: 'u4', 
        restaurantName: 'Sushi Express',
        image: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=100&q=80',
        status: 'active'
    },
    { 
        id: 'd5', 
        name: 'Bolón de Verde', 
        price: 2.50, 
        category: 'Desayunos', 
        restaurantId: 'u1', 
        restaurantName: 'Restaurante El Buen Sabor',
        image: 'https://images.unsplash.com/photo-1621356396429-57e3c4943f76?auto=format&fit=crop&w=100&q=80',
        status: 'active'
    }
];
