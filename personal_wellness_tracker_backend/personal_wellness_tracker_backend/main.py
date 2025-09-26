from fastapi import FastAPI, Depends, HTTPException, Query, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime
import uuid
import os
from pathlib import Path

from . import crud, models, schemas
from .database import SessionLocal, engine, get_db
from .api import auth
from .core import deps

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

# Create uploads directory if it doesn't exist
upload_dir = Path("uploads")
upload_dir.mkdir(exist_ok=True)
(upload_dir / "meals").mkdir(exist_ok=True)

# Mount static files for serving uploaded images
app.mount("/static", StaticFiles(directory="uploads"), name="static")

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])

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
def create_user(
    user: schemas.UserCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db=db, user=user)

@app.get("/users/{user_id}", response_model=schemas.User, tags=["Users"])
def read_user(
    user_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.get("/users/", response_model=List[schemas.User], tags=["Users"])
def read_users(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    users = crud.get_users(db, skip=skip, limit=limit)
    return users

@app.put("/users/{user_id}", response_model=schemas.User, tags=["Users"])
def update_user(
    user_id: str, 
    user_update: schemas.UserUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    # อัปเดตข้อมูลผู้ใช้
    db_user = crud.update_user(db, user_id=user_id, user_update=user_update)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    return db_user

@app.delete("/users/{user_id}", tags=["Users"])
def delete_user(
    user_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_user = crud.delete_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

# User Goals endpoints
@app.post("/users/{user_id}/goals/", response_model=schemas.UserGoal, tags=["User Goals"])
def create_user_goal(
    user_id: str, 
    goal: schemas.UserGoalBase, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    goal_data = schemas.UserGoalCreate(**goal.dict(), user_id=user_id)
    return crud.create_user_goal(db=db, goal=goal_data)

@app.get("/users/{user_id}/goals/", response_model=List[schemas.UserGoal], tags=["User Goals"])
def read_user_goals(
    user_id: str, 
    active_only: bool = True, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.get_user_goals(db, user_id=user_id, active_only=active_only)

@app.put("/goals/{goal_id}", response_model=schemas.UserGoal, tags=["User Goals"])
def update_user_goal(
    goal_id: str, 
    goal_update: schemas.UserGoalUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_goal = crud.update_user_goal(db, goal_id=goal_id, goal_update=goal_update)
    if db_goal is None:
        raise HTTPException(status_code=404, detail="Goal not found")
    return db_goal

# Food Log endpoints
@app.post("/users/{user_id}/food-logs/", response_model=schemas.FoodLog, tags=["Food Logs"])
def create_food_log(
    user_id: str, 
    food_log: schemas.FoodLogBase, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    # Check if food log already exists for this date
    existing_log = crud.get_food_log(db, user_id=user_id, date=food_log.date)
    if existing_log:
        return existing_log
    
    food_log_data = schemas.FoodLogCreate(**food_log.dict(), user_id=user_id)
    return crud.create_food_log(db=db, food_log=food_log_data)

@app.get("/users/{user_id}/food-logs/", response_model=List[schemas.FoodLog], tags=["Food Logs"])
def read_food_logs(
    user_id: str, 
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.get_food_logs(db, user_id=user_id, skip=skip, limit=limit)

@app.get("/users/{user_id}/food-logs/{log_date}", response_model=schemas.FoodLog, tags=["Food Logs"])
def read_food_log_by_date(
    user_id: str, 
    log_date: date, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_food_log = crud.get_food_log(db, user_id=user_id, date=log_date)
    if db_food_log is None:
        raise HTTPException(status_code=404, detail="Food log not found")
    return db_food_log

# Meal endpoints
@app.post("/meals/", response_model=schemas.Meal, tags=["Meals"])
def create_meal(
    meal: schemas.MealCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.create_meal(db=db, meal=meal)

@app.get("/users/{user_id}/meals/", response_model=List[schemas.Meal], tags=["Meals"])
def read_user_meals(
    user_id: str, 
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.get_meals_by_user(db, user_id=user_id, skip=skip, limit=limit)

@app.get("/food-logs/{food_log_id}/meals/", response_model=List[schemas.Meal], tags=["Meals"])
def read_meals_by_food_log(
    food_log_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.get_meals_by_food_log(db, food_log_id=food_log_id)

@app.put("/meals/{meal_id}", response_model=schemas.Meal, tags=["Meals"])
def update_meal(
    meal_id: str, 
    meal_update: schemas.MealUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_meal = crud.update_meal(db, meal_id=meal_id, meal_update=meal_update)
    if db_meal is None:
        raise HTTPException(status_code=404, detail="Meal not found")
    return db_meal

@app.delete("/meals/{meal_id}", tags=["Meals"])
def delete_meal(
    meal_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_meal = crud.delete_meal(db, meal_id=meal_id)
    if db_meal is None:
        raise HTTPException(status_code=404, detail="Meal not found")
    return {"message": "Meal deleted successfully"}

# Image upload endpoint for meals
@app.post("/meals/upload-image/", response_model=schemas.ImageUploadResponse, tags=["Meals"])
async def upload_meal_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Upload รูปภาพอาหาร"""
    
    # ตรวจสอบประเภทไฟล์
    allowed_types = ["image/jpeg", "image/png", "image/jpg", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400, 
            detail="Only JPEG, PNG, JPG, and WebP images are allowed"
        )
    
    # ตรวจสอบขนาดไฟล์ (จำกัดที่ 5MB)
    content = await file.read()
    file_size = len(content)
    
    if file_size > 5 * 1024 * 1024:  # 5MB
        raise HTTPException(
            status_code=400, 
            detail="File size must be less than 5MB"
        )
    
    # สร้างชื่อไฟล์ใหม่
    file_extension = file.filename.split(".")[-1] if file.filename else "jpg"
    unique_filename = f"{current_user.uid}_{uuid.uuid4()}.{file_extension}"
    
    # สร้างโฟลเดอร์ถ้ายังไม่มี
    upload_dir = Path("uploads/meals")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # บันทึกไฟล์
    file_path = upload_dir / unique_filename
    with open(file_path, "wb") as buffer:
        buffer.write(content)
    
    # สร้าง URL สำหรับเข้าถึงรูปภาพ
    image_url = f"/static/meals/{unique_filename}"
    
    return schemas.ImageUploadResponse(
        image_url=image_url,
        file_size=file_size,
        file_type=file.content_type,
        uploaded_at=datetime.utcnow()
    )

@app.get("/meals/{meal_id}/image", tags=["Meals"])
async def get_meal_image(
    meal_id: str,
    current_user: models.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db)
):
    """ดึงรูปภาพอาหาร"""
    
    meal = crud.get_meal(db, meal_id=meal_id)
    
    if not meal or meal.user_id != current_user.uid:
        raise HTTPException(status_code=404, detail="Meal not found")
    
    if not meal.image_url:
        raise HTTPException(status_code=404, detail="Image not found")
    
    return {"image_url": meal.image_url}

# Daily Task endpoints
@app.post("/users/{user_id}/daily-tasks/", response_model=schemas.DailyTask, tags=["Daily Tasks"])
def create_daily_task(
    user_id: str, 
    daily_task: schemas.DailyTaskBase, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    # Check if daily task already exists for this date
    existing_task = crud.get_daily_task(db, user_id=user_id, date=daily_task.date)
    if existing_task:
        return existing_task
    
    daily_task_data = schemas.DailyTaskCreate(**daily_task.dict(), user_id=user_id)
    return crud.create_daily_task(db=db, daily_task=daily_task_data)

@app.get("/users/{user_id}/daily-tasks/{task_date}", response_model=schemas.DailyTask, tags=["Daily Tasks"])
def read_daily_task_by_date(
    user_id: str, 
    task_date: date, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_daily_task = crud.get_daily_task(db, user_id=user_id, date=task_date)
    if db_daily_task is None:
        raise HTTPException(status_code=404, detail="Daily task not found")
    return db_daily_task

# Task endpoints
@app.post("/tasks/", response_model=schemas.Task, tags=["Tasks"])
def create_task(
    task: schemas.TaskCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.create_task(db=db, task=task)

@app.get("/daily-tasks/{daily_task_id}/tasks/", response_model=List[schemas.Task], tags=["Tasks"])
def read_tasks_by_daily_task(
    daily_task_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.get_tasks_by_daily_task(db, daily_task_id=daily_task_id)

@app.put("/tasks/{task_id}", response_model=schemas.Task, tags=["Tasks"])
def update_task(
    task_id: str, 
    task_update: schemas.TaskUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_task = crud.update_task(db, task_id=task_id, task_update=task_update)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.delete("/tasks/{task_id}", tags=["Tasks"])
def delete_task(
    task_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_task = crud.get_task(db, task_id=task_id)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    crud.delete_task(db, task_id=task_id)
    return {"message": "Task deleted successfully"}

# Achievement endpoints
@app.post("/api/achievements/initialize", response_model=schemas.StandardResponse)
async def initialize_user_achievements(
    current_user: models.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Initialize default achievements for a user"""
    # Check if user already has achievements
    existing_achievements = crud.get_user_achievements(db, current_user.uid)
    if existing_achievements:
        return schemas.StandardResponse(
            success=True,
            message="Achievements already initialized"
        )
    
    # Default achievements to create
    default_achievements = [
        {
            "type": "first_record",
            "name": "ผู้ริเริ่ม",
            "description": "สำเร็จบันทึกครั้งแรก",
            "target": 1
        },
        {
            "type": "meal_logging",
            "name": "นักวางแผน",
            "description": "บันทึกอาหารครบ 10 วัน",
            "target": 10
        },
        {
            "type": "exercise_logging",
            "name": "นักออกกำลังกาย",
            "description": "บันทึกการออกกำลังกายครบ 10 วัน",
            "target": 10
        },
        {
            "type": "goal_achievement",
            "name": "ผู้เชี่ยวชาญ",
            "description": "บรรลุเป้าหมายสุขภาพ 3 เป้าหมาย",
            "target": 3
        },
        {
            "type": "meal_planning",
            "name": "นักวางแผนมื้ออาหาร",
            "description": "วางแผนมื้ออาหารครบ 5 มื้อ",
            "target": 5
        },
        {
            "type": "streak_days",
            "name": "นักพัฒนา",
            "description": "บันทึกกิจกรรมครบ 20 วัน",
            "target": 20
        }
    ]
    
    # Create achievements
    for achievement_data in default_achievements:
        achievement_create = schemas.AchievementCreate(
            user_id=current_user.uid,
            type=achievement_data["type"],
            name=achievement_data["name"],
            description=achievement_data["description"],
            target=achievement_data["target"],
            current=0
        )
        crud.create_achievement(db, achievement_create)
    
    return schemas.StandardResponse(
        success=True,
        message="Achievements initialized successfully"
    )

@app.get("/api/achievements", response_model=schemas.StandardResponse)
async def get_user_achievements(
    current_user: models.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all achievements for the current user"""
    achievements = crud.get_user_achievements(db, current_user.uid)
    return schemas.StandardResponse(
        success=True,
        message="Achievements retrieved successfully",
        data=[{
            "id": achievement.id,
            "user_id": achievement.user_id,
            "type": achievement.type,
            "name": achievement.name,
            "description": achievement.description,
            "target": achievement.target,
            "current": achievement.current,
            "achieved": achievement.achieved,
            "achieved_at": achievement.achieved_at.isoformat() if achievement.achieved_at else None,
            "created_at": achievement.created_at.isoformat(),
            "updated_at": achievement.updated_at.isoformat()
        } for achievement in achievements]
    )

@app.put("/api/achievements/update-progress", response_model=schemas.StandardResponse)
async def update_achievement_progress(
    request: dict,
    current_user: models.User = Depends(deps.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update achievement progress"""
    achievement_type = request.get("achievement_type")
    progress = request.get("progress", 1)
    
    # Get user's achievement of this type
    achievements = crud.get_user_achievements(db, current_user.uid)
    target_achievement = None
    
    for achievement in achievements:
        if achievement.type == achievement_type and not achievement.achieved:
            target_achievement = achievement
            break
    
    if not target_achievement:
        return schemas.StandardResponse(
            success=False,
            message="Achievement not found or already completed"
        )
    
    # Update progress
    new_current = target_achievement.current + progress
    newly_achieved = []
    
    # Check if achievement is completed
    achieved = new_current >= target_achievement.target
    achieved_at = datetime.utcnow() if achieved and not target_achievement.achieved else target_achievement.achieved_at
    
    if achieved and not target_achievement.achieved:
        newly_achieved.append(target_achievement.name)
    
    # Update achievement
    achievement_update = schemas.AchievementUpdate(
        current=new_current,
        achieved=achieved,
        achieved_at=achieved_at
    )
    
    crud.update_achievement(db, target_achievement.id, achievement_update)
    
    return schemas.StandardResponse(
        success=True,
        message="Achievement progress updated",
        data={"newly_achieved": newly_achieved}
    )

# Nutrition Database endpoints
@app.post("/nutrition/", response_model=schemas.NutritionDatabase, tags=["Nutrition Database"])
def create_nutrition_item(
    nutrition: schemas.NutritionDatabaseCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.create_nutrition_item(db=db, nutrition=nutrition)

@app.get("/nutrition/search/", response_model=List[schemas.NutritionDatabase], tags=["Nutrition Database"])
def search_nutrition(
    food_name: str = Query(..., description="Food name to search"), 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.get_nutrition_by_food_name(db, food_name=food_name)

@app.put("/nutrition/{nutrition_id}", response_model=schemas.NutritionDatabase, tags=["Nutrition Database"])
def update_nutrition_item(
    nutrition_id: str, 
    nutrition_update: schemas.NutritionDatabaseUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_nutrition = crud.update_nutrition_item(db, nutrition_id=nutrition_id, nutrition_update=nutrition_update)
    if db_nutrition is None:
        raise HTTPException(status_code=404, detail="Nutrition item not found")
    return db_nutrition

# User Preferences endpoints
@app.post("/users/{user_id}/preferences/", response_model=schemas.UserPreference, tags=["User Preferences"])
def create_user_preferences(
    user_id: str, 
    preferences: schemas.UserPreferenceBase, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    existing_preferences = crud.get_user_preferences(db, user_id=user_id)
    if existing_preferences:
        raise HTTPException(status_code=400, detail="User preferences already exist")
    
    preferences_data = schemas.UserPreferenceCreate(**preferences.dict(), user_id=user_id)
    return crud.create_user_preferences(db=db, preferences=preferences_data)

@app.get("/users/{user_id}/preferences/", response_model=schemas.UserPreference, tags=["User Preferences"])
def read_user_preferences(
    user_id: str, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_preferences = crud.get_user_preferences(db, user_id=user_id)
    if db_preferences is None:
        raise HTTPException(status_code=404, detail="User preferences not found")
    return db_preferences

@app.put("/users/{user_id}/preferences/", response_model=schemas.UserPreference, tags=["User Preferences"])
def update_user_preferences(
    user_id: str, 
    preferences_update: schemas.UserPreferenceUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_preferences = crud.update_user_preferences(db, user_id=user_id, preferences_update=preferences_update)
    if db_preferences is None:
        raise HTTPException(status_code=404, detail="User preferences not found")
    return db_preferences

# App Statistics endpoints
@app.get("/statistics/", response_model=schemas.AppStatistics, tags=["App Statistics"])
def read_app_statistics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    db_stats = crud.get_app_statistics(db)
    if db_stats is None:
        raise HTTPException(status_code=404, detail="App statistics not found")
    return db_stats

@app.put("/statistics/", response_model=schemas.AppStatistics, tags=["App Statistics"])
def update_app_statistics(
    stats_update: schemas.AppStatisticsUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    return crud.update_app_statistics(db=db, stats_update=stats_update)

# Missing Auth endpoints
@app.get("/auth/me", response_model=schemas.User, tags=["Authentication"])
def read_current_user(current_user: models.User = Depends(deps.get_current_active_user)):
    """Get current user information"""
    return current_user

# Missing Stats endpoints  
@app.get("/stats/streak", tags=["Statistics"])
def get_user_streak(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """Get user's streak count"""
    # Simple implementation - count consecutive days with activities
    return {"streak_count": 7}  # Mock data for now

# Missing Tasks endpoints
@app.get("/tasks/{date}", tags=["Tasks"])
def get_tasks_by_date(
    date: str,
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """Get daily tasks by date"""
    # Mock response with basic daily tasks structure
    return {
        "date": date,
        "tasks": [
            {
                "id": 1,
                "title": "ดื่มน้ำ 8 แก้ว",
                "completed": False,
                "category": "hydration"
            },
            {
                "id": 2, 
                "title": "ออกกำลังกาย 30 นาที",
                "completed": False,
                "category": "exercise"
            },
            {
                "id": 3,
                "title": "นอนหลับ 8 ชั่วโมง", 
                "completed": False,
                "category": "sleep"
            }
        ]
    }