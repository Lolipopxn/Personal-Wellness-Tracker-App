from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date

from . import crud, models, schemas
from .database import SessionLocal, engine, get_db

# Create database tables (optional - only if database is available)
# Note: In Docker setup, tables are created via init.sql
try:
    # Only create tables if they don't exist (for development)
    if not engine.dialect.has_table(engine.connect(), "users"):
        models.Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully!")
    else:
        print("ℹ️  Database tables already exist")
except Exception as e:
    print(f"⚠️  Database not available: {e}")
    print("📝 API will run without database functionality for testing")

app = FastAPI(
    title="Personal Wellness Tracker API",
    description="API for Personal Wellness Tracker Application",
    version="1.0.0",
    tags_metadata=[
        {
            "name": "System",
            "description": "ระบบพื้นฐาน - การตรวจสอบสถานะและการทดสอบ API",
        },
        {
            "name": "Users",
            "description": "จัดการข้อมูลผู้ใช้ - การสร้าง อัปเดต และจัดการบัญชีผู้ใช้",
        },
        {
            "name": "User Goals", 
            "description": "จัดการเป้าหมายของผู้ใช้ - น้ำหนัก การออกกำลังกาย และการดื่มน้ำ",
        },
        {
            "name": "Food Logs",
            "description": "บันทึกการรับประทานอาหารรายวัน - ติดตามมื้ออาหารแต่ละวัน",
        },
        {
            "name": "Meals",
            "description": "จัดการรายละเอียดอาหาร - เพิ่ม แก้ไข และลบข้อมูลอาหาร",
        },
        {
            "name": "Daily Tasks",
            "description": "งานประจำวัน - ติดตามกิจกรรมและงานที่ต้องทำในแต่ละวัน",
        },
        {
            "name": "Tasks",
            "description": "จัดการงาน - รายละเอียดงานต่างๆ และสถานะการทำงาน",
        },
        {
            "name": "Achievements",
            "description": "ความสำเร็จ - ติดตามและจัดการความสำเร็จของผู้ใช้",
        },
        {
            "name": "Nutrition Database",
            "description": "ฐานข้อมูลโภชนาการ - ข้อมูลแคลอรี่และโภชนาการของอาหาร",
        },
        {
            "name": "User Preferences",
            "description": "การตั้งค่าผู้ใช้ - ธีม การแจ้งเตือน และการตั้งค่าส่วนตัว",
        },
        {
            "name": "App Statistics",
            "description": "สถิติแอปพลิเคชัน - ข้อมูลการใช้งานและสถิติทั่วไป",
        },
    ]
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["System"])
def read_root():
    return {"message": "Personal Wellness Tracker API", "version": "1.0.0"}

@app.get("/health", tags=["System"])
def health_check():
    """Health check endpoint that doesn't require database"""
    return {
        "status": "healthy",
        "message": "API is running",
        "endpoints": {
            "docs": "/docs",
            "redoc": "/redoc",
            "health": "/health"
        }
    }

@app.get("/test", tags=["System"])
def test_endpoint():
    """Test endpoint for API functionality"""
    return {
        "message": "Test endpoint working",
        "data": {
            "genders": ["male", "female", "other"],
            "meal_types": ["breakfast", "lunch", "dinner", "snack"],
            "themes": ["light", "dark", "system"]
        }
    }

# User endpoints
@app.post("/users/", response_model=schemas.User, tags=["Users"])
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db=db, user=user)

@app.get("/users/{user_id}", response_model=schemas.User, tags=["Users"])
def read_user(user_id: str, db: Session = Depends(get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.get("/users/", response_model=List[schemas.User], tags=["Users"])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = crud.get_users(db, skip=skip, limit=limit)
    return users

@app.put("/users/{user_id}", response_model=schemas.User, tags=["Users"])
def update_user(user_id: str, user_update: schemas.UserUpdate, db: Session = Depends(get_db)):
    db_user = crud.update_user(db, user_id=user_id, user_update=user_update)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.delete("/users/{user_id}", tags=["Users"])
def delete_user(user_id: str, db: Session = Depends(get_db)):
    db_user = crud.delete_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

# User Goals endpoints
@app.post("/users/{user_id}/goals/", response_model=schemas.UserGoal, tags=["User Goals"])
def create_user_goal(user_id: str, goal: schemas.UserGoalBase, db: Session = Depends(get_db)):
    goal_data = schemas.UserGoalCreate(**goal.dict(), user_id=user_id)
    return crud.create_user_goal(db=db, goal=goal_data)

@app.get("/users/{user_id}/goals/", response_model=List[schemas.UserGoal], tags=["User Goals"])
def read_user_goals(user_id: str, active_only: bool = True, db: Session = Depends(get_db)):
    return crud.get_user_goals(db, user_id=user_id, active_only=active_only)

@app.put("/goals/{goal_id}", response_model=schemas.UserGoal, tags=["User Goals"])
def update_user_goal(goal_id: str, goal_update: schemas.UserGoalUpdate, db: Session = Depends(get_db)):
    db_goal = crud.update_user_goal(db, goal_id=goal_id, goal_update=goal_update)
    if db_goal is None:
        raise HTTPException(status_code=404, detail="Goal not found")
    return db_goal

# Food Log endpoints
@app.post("/users/{user_id}/food-logs/", response_model=schemas.FoodLog, tags=["Food Logs"])
def create_food_log(user_id: str, food_log: schemas.FoodLogBase, db: Session = Depends(get_db)):
    # Check if food log already exists for this date
    existing_log = crud.get_food_log(db, user_id=user_id, date=food_log.date)
    if existing_log:
        return existing_log
    
    food_log_data = schemas.FoodLogCreate(**food_log.dict(), user_id=user_id)
    return crud.create_food_log(db=db, food_log=food_log_data)

@app.get("/users/{user_id}/food-logs/", response_model=List[schemas.FoodLog], tags=["Food Logs"])
def read_food_logs(user_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_food_logs(db, user_id=user_id, skip=skip, limit=limit)

@app.get("/users/{user_id}/food-logs/{log_date}", response_model=schemas.FoodLog, tags=["Food Logs"])
def read_food_log_by_date(user_id: str, log_date: date, db: Session = Depends(get_db)):
    db_food_log = crud.get_food_log(db, user_id=user_id, date=log_date)
    if db_food_log is None:
        raise HTTPException(status_code=404, detail="Food log not found")
    return db_food_log

# Meal endpoints
@app.post("/meals/", response_model=schemas.Meal, tags=["Meals"])
def create_meal(meal: schemas.MealCreate, db: Session = Depends(get_db)):
    return crud.create_meal(db=db, meal=meal)

@app.get("/users/{user_id}/meals/", response_model=List[schemas.Meal], tags=["Meals"])
def read_user_meals(user_id: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_meals_by_user(db, user_id=user_id, skip=skip, limit=limit)

@app.get("/food-logs/{food_log_id}/meals/", response_model=List[schemas.Meal], tags=["Meals"])
def read_meals_by_food_log(food_log_id: str, db: Session = Depends(get_db)):
    return crud.get_meals_by_food_log(db, food_log_id=food_log_id)

@app.put("/meals/{meal_id}", response_model=schemas.Meal, tags=["Meals"])
def update_meal(meal_id: str, meal_update: schemas.MealUpdate, db: Session = Depends(get_db)):
    db_meal = crud.update_meal(db, meal_id=meal_id, meal_update=meal_update)
    if db_meal is None:
        raise HTTPException(status_code=404, detail="Meal not found")
    return db_meal

@app.delete("/meals/{meal_id}", tags=["Meals"])
def delete_meal(meal_id: str, db: Session = Depends(get_db)):
    db_meal = crud.delete_meal(db, meal_id=meal_id)
    if db_meal is None:
        raise HTTPException(status_code=404, detail="Meal not found")
    return {"message": "Meal deleted successfully"}

# Daily Task endpoints
@app.post("/users/{user_id}/daily-tasks/", response_model=schemas.DailyTask, tags=["Daily Tasks"])
def create_daily_task(user_id: str, daily_task: schemas.DailyTaskBase, db: Session = Depends(get_db)):
    # Check if daily task already exists for this date
    existing_task = crud.get_daily_task(db, user_id=user_id, date=daily_task.date)
    if existing_task:
        return existing_task
    
    daily_task_data = schemas.DailyTaskCreate(**daily_task.dict(), user_id=user_id)
    return crud.create_daily_task(db=db, daily_task=daily_task_data)

@app.get("/users/{user_id}/daily-tasks/{task_date}", response_model=schemas.DailyTask, tags=["Daily Tasks"])
def read_daily_task_by_date(user_id: str, task_date: date, db: Session = Depends(get_db)):
    db_daily_task = crud.get_daily_task(db, user_id=user_id, date=task_date)
    if db_daily_task is None:
        raise HTTPException(status_code=404, detail="Daily task not found")
    return db_daily_task

# Task endpoints
@app.post("/tasks/", response_model=schemas.Task, tags=["Tasks"])
def create_task(task: schemas.TaskCreate, db: Session = Depends(get_db)):
    return crud.create_task(db=db, task=task)

@app.get("/daily-tasks/{daily_task_id}/tasks/", response_model=List[schemas.Task], tags=["Tasks"])
def read_tasks_by_daily_task(daily_task_id: str, db: Session = Depends(get_db)):
    return crud.get_tasks_by_daily_task(db, daily_task_id=daily_task_id)

@app.put("/tasks/{task_id}", response_model=schemas.Task, tags=["Tasks"])
def update_task(task_id: str, task_update: schemas.TaskUpdate, db: Session = Depends(get_db)):
    db_task = crud.update_task(db, task_id=task_id, task_update=task_update)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.delete("/tasks/{task_id}", tags=["Tasks"])
def delete_task(task_id: str, db: Session = Depends(get_db)):
    db_task = crud.get_task(db, task_id=task_id)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    crud.delete_task(db, task_id=task_id)
    return {"message": "Task deleted successfully"}

# Achievement endpoints
@app.post("/users/{user_id}/achievements/", response_model=schemas.Achievement, tags=["Achievements"])
def create_achievement(user_id: str, achievement: schemas.AchievementBase, db: Session = Depends(get_db)):
    achievement_data = schemas.AchievementCreate(**achievement.dict(), user_id=user_id)
    return crud.create_achievement(db=db, achievement=achievement_data)

@app.get("/users/{user_id}/achievements/", response_model=List[schemas.Achievement], tags=["Achievements"])
def read_user_achievements(user_id: str, db: Session = Depends(get_db)):
    return crud.get_user_achievements(db, user_id=user_id)

@app.put("/achievements/{achievement_id}", response_model=schemas.Achievement, tags=["Achievements"])
def update_achievement(achievement_id: str, achievement_update: schemas.AchievementUpdate, db: Session = Depends(get_db)):
    db_achievement = crud.update_achievement(db, achievement_id=achievement_id, achievement_update=achievement_update)
    if db_achievement is None:
        raise HTTPException(status_code=404, detail="Achievement not found")
    return db_achievement

@app.delete("/achievements/{achievement_id}", tags=["Achievements"])
def delete_achievement(achievement_id: str, db: Session = Depends(get_db)):
    db_achievement = crud.get_achievement(db, achievement_id=achievement_id)
    if db_achievement is None:
        raise HTTPException(status_code=404, detail="Achievement not found")
    crud.delete_achievement(db, achievement_id=achievement_id)
    return {"message": "Achievement deleted successfully"}

# Nutrition Database endpoints
@app.post("/nutrition/", response_model=schemas.NutritionDatabase, tags=["Nutrition Database"])
def create_nutrition_item(nutrition: schemas.NutritionDatabaseCreate, db: Session = Depends(get_db)):
    return crud.create_nutrition_item(db=db, nutrition=nutrition)

@app.get("/nutrition/search/", response_model=List[schemas.NutritionDatabase], tags=["Nutrition Database"])
def search_nutrition(food_name: str = Query(..., description="Food name to search"), db: Session = Depends(get_db)):
    return crud.get_nutrition_by_food_name(db, food_name=food_name)

@app.put("/nutrition/{nutrition_id}", response_model=schemas.NutritionDatabase, tags=["Nutrition Database"])
def update_nutrition_item(nutrition_id: str, nutrition_update: schemas.NutritionDatabaseUpdate, db: Session = Depends(get_db)):
    db_nutrition = crud.update_nutrition_item(db, nutrition_id=nutrition_id, nutrition_update=nutrition_update)
    if db_nutrition is None:
        raise HTTPException(status_code=404, detail="Nutrition item not found")
    return db_nutrition

# User Preferences endpoints
@app.post("/users/{user_id}/preferences/", response_model=schemas.UserPreference, tags=["User Preferences"])
def create_user_preferences(user_id: str, preferences: schemas.UserPreferenceBase, db: Session = Depends(get_db)):
    existing_preferences = crud.get_user_preferences(db, user_id=user_id)
    if existing_preferences:
        raise HTTPException(status_code=400, detail="User preferences already exist")
    
    preferences_data = schemas.UserPreferenceCreate(**preferences.dict(), user_id=user_id)
    return crud.create_user_preferences(db=db, preferences=preferences_data)

@app.get("/users/{user_id}/preferences/", response_model=schemas.UserPreference, tags=["User Preferences"])
def read_user_preferences(user_id: str, db: Session = Depends(get_db)):
    db_preferences = crud.get_user_preferences(db, user_id=user_id)
    if db_preferences is None:
        raise HTTPException(status_code=404, detail="User preferences not found")
    return db_preferences

@app.put("/users/{user_id}/preferences/", response_model=schemas.UserPreference, tags=["User Preferences"])
def update_user_preferences(user_id: str, preferences_update: schemas.UserPreferenceUpdate, db: Session = Depends(get_db)):
    db_preferences = crud.update_user_preferences(db, user_id=user_id, preferences_update=preferences_update)
    if db_preferences is None:
        raise HTTPException(status_code=404, detail="User preferences not found")
    return db_preferences

# App Statistics endpoints
@app.get("/statistics/", response_model=schemas.AppStatistics, tags=["App Statistics"])
def read_app_statistics(db: Session = Depends(get_db)):
    db_stats = crud.get_app_statistics(db)
    if db_stats is None:
        raise HTTPException(status_code=404, detail="App statistics not found")
    return db_stats

@app.put("/statistics/", response_model=schemas.AppStatistics, tags=["App Statistics"])
def update_app_statistics(stats_update: schemas.AppStatisticsUpdate, db: Session = Depends(get_db)):
    return crud.update_app_statistics(db=db, stats_update=stats_update)