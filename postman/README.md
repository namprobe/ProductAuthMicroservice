# ProductAuth Microservice API - Postman Documentation

## Overview
This Postman collection provides complete API testing for the ProductAuth Microservice system, including Authentication, Product Management, and Category Management.

## Files Included
- `ProductAuth_Microservice_API.postman_collection.json` - Main API collection
- `ProductAuth_Development.postman_environment.json` - Development environment variables

## Quick Setup

### 1. Import to Postman
1. Open Postman
2. Click **Import** button
3. Select both JSON files:
   - `ProductAuth_Microservice_API.postman_collection.json`
   - `ProductAuth_Development.postman_environment.json`

### 2. Set Environment
1. In Postman, select **ProductAuth Microservice - Development** environment
2. Verify environment variables are loaded correctly

### 3. Start Services
Make sure all services are running:
```bash
docker-compose up -d
```

Verify services are healthy:
- AuthService: http://localhost:5001/swagger
- ProductService: http://localhost:5002/swagger
- Gateway: http://localhost:5000/swagger

## API Testing Workflow

### Step 1: Authentication
1. **Login CMS**
   - Endpoint: `POST /api/cms/auth/login`
   - Uses default admin credentials from environment
   - Auto-saves `access_token` and `refresh_token` to environment
   - Required for all protected endpoints

### Step 2: Category Management
1. **Create Category** (creates a sample Electronics category)
   - Auto-saves `category_id` to environment for use in product creation
2. **Get All Categories** (view paginated list)
3. **Get Category by ID** (view specific category details)
4. **Update Category** (modify category information)
5. **Delete Category** (remove category)

### Step 3: Product Management
1. **Create Product** (uses the category_id from previous step)
   - Auto-saves `product_id` to environment
2. **Get All Products** (view paginated list with filters)
3. **Get Product by ID** (view specific product details)
4. **Update Product** (modify product information)
5. **Delete Product** (remove product)

### Step 4: Gateway Testing
1. **Gateway Health Check**
2. **Auth Service Health** (through Gateway)
3. **Product Service Health** (through Gateway)

## API Endpoints

### Authentication Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/cms/auth/login` | Login to CMS system | No |
| POST | `/api/cms/auth/logout` | Logout from CMS system | Yes |

### Product Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/cms/products` | Get all products with pagination | No |
| GET | `/api/cms/products/{id}` | Get product by ID | No |
| POST | `/api/cms/products` | Create new product | Yes |
| PUT | `/api/cms/products/{id}` | Update product | Yes |
| DELETE | `/api/cms/products/{id}` | Delete product | Yes |

### Category Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/cms/categories` | Get all categories with pagination | No |
| GET | `/api/cms/categories/{id}` | Get category by ID | No |
| POST | `/api/cms/categories` | Create new category | Yes |
| PUT | `/api/cms/categories/{id}` | Update category | Yes |
| DELETE | `/api/cms/categories/{id}` | Delete category | Yes |

### Gateway Health Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Gateway health check |
| GET | `/health/auth` | AuthService health through Gateway |
| GET | `/health/products` | ProductService health through Gateway |

## Environment Variables

### Service URLs
- `base_url`: AuthService URL (default: http://localhost:5001)
- `gateway_url`: Gateway URL (default: http://localhost:5000)
- `product_service_url`: ProductService URL (default: http://localhost:5002)

### Authentication
- `access_token`: JWT access token (auto-populated after login)
- `refresh_token`: JWT refresh token (auto-populated after login)
- `admin_email`: Default admin email (admin@productauth.com)
- `admin_password`: Default admin password (Admin@123)

### Testing IDs
- `product_id`: Product ID for testing (auto-populated after product creation)
- `category_id`: Category ID for testing (auto-populated after category creation)

## Sample Request Bodies

### Login Request
```json
{
  "email": "admin@productauth.com",
  "password": "Admin@123",
  "grantType": 0
}
```

### Create Category Request
```json
{
  "name": "Electronics",
  "description": "Electronic devices and accessories",
  "parent_category_id": null,
  "image_path": "/images/categories/electronics.jpg"
}
```

### Create Product Request
```json
{
  "name": "iPhone 15 Pro",
  "description": "Latest iPhone with advanced features",
  "price": 999.99,
  "discount_price": 899.99,
  "stock_quantity": 100,
  "category_id": "{{category_id}}",
  "is_pre_order": false,
  "pre_order_release_date": null
}
```

## Advanced Testing

### Filtering Products
Use query parameters to filter products:
```
GET /api/cms/products?page=1&pageSize=10&search=iPhone&minPrice=500&maxPrice=1500&inStock=true&sortBy=price&isAscending=false
```

### Filtering Categories
Use query parameters to filter categories:
```
GET /api/cms/categories?page=1&pageSize=10&search=Electronics&includeSubCategories=true&includeProductsCount=true
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Ensure you've run the Login request first
   - Check that `access_token` is saved in environment variables
   - Verify the token hasn't expired

2. **404 Not Found**
   - Verify services are running on correct ports
   - Check environment URLs are correct
   - Ensure endpoints match the API routes

3. **400 Bad Request**
   - Validate request body JSON format
   - Check required fields are provided
   - Verify data types match API expectations

4. **Connection Refused**
   - Ensure Docker services are running: `docker-compose ps`
   - Check service health: `docker-compose logs [service-name]`
   - Verify ports are not blocked by firewall

### Testing Workflow
1. Always start with Login to get authentication token
2. Create categories before creating products (products need category_id)
3. Use the auto-saved IDs for testing CRUD operations
4. Check service health endpoints if experiencing issues

## Security Notes
- Access tokens expire after 60 minutes (configurable)
- Refresh tokens expire after 7 days (configurable)
- All CUD operations (Create, Update, Delete) require authentication
- Read operations (GET) are public for testing purposes

## API Response Format
All APIs return responses in the following format:
```json
{
  "isSuccess": true,
  "data": { /* response data */ },
  "message": "Success message",
  "errors": []
}
```

For paginated responses:
```json
{
  "isSuccess": true,
  "data": {
    "items": [ /* array of items */ ],
    "totalCount": 100,
    "page": 1,
    "pageSize": 10,
    "totalPages": 10
  },
  "message": "Success message"
}
```