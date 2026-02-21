// Main Application Logic for Dashboard

// Check auth
const user = JSON.parse(localStorage.getItem('foodtook_admin_user'));
if (!user) {
    window.location.href = 'index.html';
} else {
    document.getElementById('adminName').textContent = user.name || 'Admin';
}

function logout() {
    localStorage.removeItem('foodtook_admin_user');
    window.location.href = 'index.html';
}

// Navigation Logic
function showSection(sectionId) {
    // Hide all sections
    document.getElementById('usersSection').style.display = 'none';
    document.getElementById('dishesSection').style.display = 'none';
    
    // Update Nav Active State (Simple implementation)
    const links = document.querySelectorAll('.nav-link');
    links.forEach(link => link.classList.remove('active'));
    
    // Show selected
    if (sectionId === 'users') {
        document.getElementById('usersSection').style.display = 'block';
        document.getElementById('pageTitle').textContent = 'Gestión de Usuarios';
        links[0].classList.add('active'); // Assuming first link is users
        renderUsers();
    } else if (sectionId === 'dishes') {
        document.getElementById('dishesSection').style.display = 'block';
        document.getElementById('pageTitle').textContent = 'Catálogo de Platos';
        links[1].classList.add('active'); // Assuming second link is dishes
        renderDishes();
    }
}

// Render Users
function renderUsers() {
    const tbody = document.getElementById('usersTableBody');
    tbody.innerHTML = '';
    
    usersData.forEach(user => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>#${user.id}</td>
            <td><strong>${user.name}</strong></td>
            <td>${user.email}</td>
            <td><span class="status-badge ${user.status === 'active' ? 'status-active' : 'status-inactive'}">${user.status === 'active' ? 'Activo' : 'Inactivo'}</span></td>
            <td>
                <button class="action-btn" onclick="alert('Editar usuario ${user.id}')">Editar</button>
                <button class="action-btn" onclick="alert('Ver platos de ${user.id}')">Platos</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

// Render Dishes
function renderDishes(filterRestaurantId = 'all') {
    const tbody = document.getElementById('dishesTableBody');
    tbody.innerHTML = '';
    
    const filteredData = filterRestaurantId === 'all' 
        ? dishesData 
        : dishesData.filter(d => d.restaurantId === filterRestaurantId);
        
    filteredData.forEach(dish => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><img src="${dish.image}" alt="${dish.name}" class="dish-image"></td>
            <td><strong>${dish.name}</strong></td>
            <td>$${dish.price.toFixed(2)}</td>
            <td>${dish.category}</td>
            <td>${dish.restaurantName}</td>
            <td><span class="status-badge ${dish.status === 'active' ? 'status-active' : 'status-inactive'}">${dish.status === 'active' ? 'Disponible' : 'No disponible'}</span></td>
            <td>
                <button class="action-btn" onclick="alert('Editar plato ${dish.id}')">Editar</button>
                <button class="action-btn" style="color: #dc3545;" onclick="alert('Eliminar plato ${dish.id}')">Eliminar</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

// Populate Filter Dropdown
function populateUserFilter() {
    const select = document.getElementById('userFilter');
    // Clear existing options except first
    while (select.options.length > 1) {
        select.remove(1);
    }
    
    usersData.forEach(user => {
        const option = document.createElement('option');
        option.value = user.id;
        option.textContent = user.name;
        select.appendChild(option);
    });
}

function filterDishes() {
    const select = document.getElementById('userFilter');
    renderDishes(select.value);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    populateUserFilter();
    renderUsers(); // Default view
});
