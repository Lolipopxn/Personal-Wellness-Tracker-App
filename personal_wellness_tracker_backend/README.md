# Personal Wellness Tracker API

A FastAPI-based backend for the Personal Wellness Tracker application with PostgreSQL database integration.

## 🚀 Quick Start

### Prerequisites
- Python 3.13+
- Docker and Docker Compose
- Poetry (Python package manager)

### Database Schema

The database includes these main entities:
- **Users**: User profiles and authentication
- **UserGoals**: Personal health and fitness goals
- **FoodLogs**: Daily food consumption tracking
- **Meals**: Available food items and nutrition info
- **DailyTasks**: User's daily task completions
- **Tasks**: Available tasks and activities
- **Achievements**: User achievements and badges

### 1. Setup Database (PostgreSQL in Docker)

Start the PostgreSQL container:
```bash
cd personal_wellness_tracker_backend
docker-compose -f docker-compose.dev.yml up -d
```

This will:
- Start PostgreSQL 15 container on port 5432
- Create the `wellness_tracker_db` database
- Initialize all tables with the schema from `init.sql`
- Set up user `wellness_user` with password `wellness_password`

### 2. Setup Python Environment

Install dependencies using Poetry:
```bash
poetry install
```

Activate the virtual environment:
```bash
poetry shell
```

### 3. Run the API

Start the FastAPI development server:
```bash
poetry run uvicorn personal_wellness_tracker_backend.main:app --reload --host 127.0.0.1 --port 8000
```

The API will be available at:
- **API Base URL**: http://127.0.0.1:8000
- **Interactive Docs**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc

## 📊 Database Management

### Check PostgreSQL Container Status
```bash
docker-compose -f docker-compose.dev.yml ps
```

### Connect to PostgreSQL Database
```bash
docker exec -it wellness_postgres psql -U wellness_user -d wellness_tracker_db
```

### Stop PostgreSQL Container
```bash
docker-compose -f docker-compose.dev.yml down
```

### Reset Database (Warning: This will delete all data)
```bash
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up -d
```

## 🗂️ API Documentation

The API is organized into the following categories:

### 👤 Users Management
- `POST /users/` - Create new user
- `GET /users/{user_id}` - Get user by ID
- `PUT /users/{user_id}` - Update user
- `DELETE /users/{user_id}` - Delete user

### 🎯 Goals & Tracking
- `POST /users/{user_id}/goals/` - Create user goals
- `GET /users/{user_id}/goals/` - Get user goals
- `PUT /goals/{goal_id}` - Update goals

### 🍽️ Food & Nutrition
- `POST /users/{user_id}/food-logs/` - Log food consumption
- `GET /users/{user_id}/food-logs/` - Get food logs
- `GET /meals/` - Get available meals
- `POST /meals/` - Create new meal

### ✅ Tasks & Activities
- `GET /users/{user_id}/daily-tasks/` - Get daily tasks
- `POST /users/{user_id}/daily-tasks/` - Create daily task
- `GET /tasks/` - Get available tasks
- `POST /tasks/` - Create new task
- `DELETE /tasks/{task_id}` - Delete task

### 🏆 Achievements
- `GET /users/{user_id}/achievements/` - Get user achievements
- `POST /users/{user_id}/achievements/` - Award achievement
- `GET /achievements/` - Get all achievements
- `POST /achievements/` - Create new achievement
- `DELETE /achievements/{achievement_id}` - Delete achievement

## 🔧 Development

### Environment Configuration

The `.env` file contains database connection settings:
```
DATABASE_URL=postgresql://wellness_user:wellness_password@localhost:5432/wellness_tracker_db
```

### Running Tests

```bash
poetry run pytest
```

## 🐳 Docker Configurations

- **`docker-compose.dev.yml`**: PostgreSQL only (for local development)
- **`docker-compose.yml`**: Full stack (API + PostgreSQL)

## 📝 Project Structure

```
personal_wellness_tracker_backend/
├── personal_wellness_tracker_backend/
│   ├── __init__.py
│   ├── main.py              # FastAPI app with endpoints
│   ├── models.py            # SQLAlchemy database models
│   ├── schemas.py           # Pydantic validation schemas
│   ├── database.py          # Database connection setup
│   └── crud.py              # Database operations
├── init.sql                 # Database schema initialization
├── docker-compose.dev.yml   # Docker PostgreSQL setup
├── pyproject.toml          # Poetry dependencies
├── .env                    # Environment configuration
└── README.md               # This file
```

## 🔒 Security Notes

- Change default passwords in production
- Use environment variables for sensitive data
- Enable HTTPS in production deployment
- Implement proper authentication/authorization

## 🆘 Troubleshooting

### API won't start
- Check if PostgreSQL container is running: `docker-compose -f docker-compose.dev.yml ps`
- Verify database connection in `.env` file
- Check logs: `docker-compose -f docker-compose.dev.yml logs`

### Database connection errors
- Ensure PostgreSQL container port 5432 is available
- Check database credentials in `.env` file
- Restart containers: `docker-compose -f docker-compose.dev.yml restart`

### Dependencies issues
- Update Poetry: `poetry self update`
- Clear cache: `poetry cache clear pypi --all`
- Reinstall: `poetry install --no-cache`
