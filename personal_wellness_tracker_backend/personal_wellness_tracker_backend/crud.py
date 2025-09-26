from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import List, Optional
from datetime import datetime, date
import uuid

from . import models, schemas

# User CRUD operations
def get_user(db: Session, user_id: str):
    return db.query(models.User).filter(models.User.uid == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    db_user = models.User(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: str, user_update: schemas.UserUpdate):
    db_user = db.query(models.User).filter(models.User.uid == user_id).first()
    if db_user:
        update_data = user_update.dict(exclude_unset=True)
        
        for field, value in update_data.items():
            setattr(db_user, field, value)
        db_user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: str):
    db_user = db.query(models.User).filter(models.User.uid == user_id).first()
    if db_user:
        db.delete(db_user)
        db.commit()
    return db_user

# User Goals CRUD operations
def get_user_goals(db: Session, user_id: str, active_only: bool = True):
    query = db.query(models.UserGoal).filter(models.UserGoal.user_id == user_id)
    if active_only:
        query = query.filter(models.UserGoal.is_active == True)
    return query.all()

def get_user_goal(db: Session, goal_id: str):
    return db.query(models.UserGoal).filter(models.UserGoal.id == goal_id).first()

def create_user_goal(db: Session, goal: schemas.UserGoalCreate):
    goal_data = goal.dict()
    goal_data['id'] = str(uuid.uuid4())
    db_goal = models.UserGoal(**goal_data)
    db.add(db_goal)
    db.commit()
    db.refresh(db_goal)
    return db_goal

def update_user_goal(db: Session, goal_id: str, goal_update: schemas.UserGoalUpdate):
    db_goal = db.query(models.UserGoal).filter(models.UserGoal.id == goal_id).first()
    if db_goal:
        update_data = goal_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_goal, field, value)
        db_goal.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_goal)
    return db_goal

# Food Log CRUD operations
def get_food_log(db: Session, user_id: str, date: date):
    return db.query(models.FoodLog).filter(
        and_(models.FoodLog.user_id == user_id, models.FoodLog.date == date)
    ).first()

def get_food_logs(db: Session, user_id: str, skip: int = 0, limit: int = 100):
    return db.query(models.FoodLog).filter(
        models.FoodLog.user_id == user_id
    ).order_by(desc(models.FoodLog.date)).offset(skip).limit(limit).all()

def create_food_log(db: Session, food_log: schemas.FoodLogCreate):
    food_log_data = food_log.dict()
    food_log_data['id'] = str(uuid.uuid4())
    db_food_log = models.FoodLog(**food_log_data)
    db.add(db_food_log)
    db.commit()
    db.refresh(db_food_log)
    return db_food_log

def update_food_log_meal_count(db: Session, food_log_id: str, meal_count: int):
    db_food_log = db.query(models.FoodLog).filter(models.FoodLog.id == food_log_id).first()
    if db_food_log:
        db_food_log.meal_count = meal_count
        db.commit()
        db.refresh(db_food_log)
    return db_food_log

# Meal CRUD operations
def get_meals_by_food_log(db: Session, food_log_id: str):
    return db.query(models.Meal).filter(models.Meal.food_log_id == food_log_id).all()

def get_meals_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 100):
    return db.query(models.Meal).filter(
        models.Meal.user_id == user_id
    ).order_by(desc(models.Meal.created_at)).offset(skip).limit(limit).all()

def get_meal(db: Session, meal_id: str):
    return db.query(models.Meal).filter(models.Meal.id == meal_id).first()

def create_meal(db: Session, meal: schemas.MealCreate):
    meal_data = meal.dict()
    meal_data['id'] = str(uuid.uuid4())
    db_meal = models.Meal(**meal_data)
    db.add(db_meal)
    db.commit()
    db.refresh(db_meal)
    
    # Update meal count in food log
    food_log = db.query(models.FoodLog).filter(models.FoodLog.id == meal.food_log_id).first()
    if food_log:
        food_log.meal_count += 1
        db.commit()
    
    return db_meal

def update_meal(db: Session, meal_id: str, meal_update: schemas.MealUpdate):
    db_meal = db.query(models.Meal).filter(models.Meal.id == meal_id).first()
    if db_meal:
        update_data = meal_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_meal, field, value)
        db_meal.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_meal)
    return db_meal

def delete_meal(db: Session, meal_id: str):
    db_meal = db.query(models.Meal).filter(models.Meal.id == meal_id).first()
    if db_meal:
        food_log_id = db_meal.food_log_id
        db.delete(db_meal)
        db.commit()
        
        # Update meal count in food log
        food_log = db.query(models.FoodLog).filter(models.FoodLog.id == food_log_id).first()
        if food_log and food_log.meal_count > 0:
            food_log.meal_count -= 1
            db.commit()
    
    return db_meal

# Daily Task CRUD operations
def get_daily_task(db: Session, user_id: str, date: date):
    return db.query(models.DailyTask).filter(
        and_(models.DailyTask.user_id == user_id, models.DailyTask.date == date)
    ).first()

def create_daily_task(db: Session, daily_task: schemas.DailyTaskCreate):
    daily_task_data = daily_task.dict()
    daily_task_data['id'] = str(uuid.uuid4())
    db_daily_task = models.DailyTask(**daily_task_data)
    db.add(db_daily_task)
    db.commit()
    db.refresh(db_daily_task)
    return db_daily_task

# Task CRUD operations
def get_tasks_by_daily_task(db: Session, daily_task_id: str):
    return db.query(models.Task).filter(models.Task.daily_task_id == daily_task_id).all()

def get_task(db: Session, task_id: str):
    return db.query(models.Task).filter(models.Task.id == task_id).first()

def create_task(db: Session, task: schemas.TaskCreate):
    task_data = task.dict()
    task_data['id'] = str(uuid.uuid4())
    db_task = models.Task(**task_data)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

def update_task(db: Session, task_id: str, task_update: schemas.TaskUpdate):
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task:
        update_data = task_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_task, field, value)
        db_task.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_task)
    return db_task

def delete_task(db: Session, task_id: str):
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task:
        db.delete(db_task)
        db.commit()
    return db_task

# Achievement CRUD operations
def get_user_achievements(db: Session, user_id: str):
    return db.query(models.Achievement).filter(
        models.Achievement.user_id == user_id
    ).order_by(models.Achievement.created_at).all()

def get_achievement_by_type(db: Session, user_id: str, achievement_type: str):
    return db.query(models.Achievement).filter(
        and_(
            models.Achievement.user_id == user_id,
            models.Achievement.type == achievement_type
        )
    ).first()

def get_achievement(db: Session, achievement_id: str):
    return db.query(models.Achievement).filter(models.Achievement.id == achievement_id).first()

def create_achievement(db: Session, achievement: schemas.AchievementCreate):
    achievement_data = achievement.dict()
    achievement_data['id'] = str(uuid.uuid4())
    db_achievement = models.Achievement(**achievement_data)
    db.add(db_achievement)
    db.commit()
    db.refresh(db_achievement)
    return db_achievement

def update_achievement(db: Session, achievement_id: str, achievement_update: schemas.AchievementUpdate):
    db_achievement = db.query(models.Achievement).filter(models.Achievement.id == achievement_id).first()
    if db_achievement:
        update_data = achievement_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_achievement, field, value)
        db_achievement.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_achievement)
    return db_achievement

def delete_achievement(db: Session, achievement_id: str):
    db_achievement = db.query(models.Achievement).filter(models.Achievement.id == achievement_id).first()
    if db_achievement:
        db.delete(db_achievement)
        db.commit()
    return db_achievement

# Nutrition Database CRUD operations
def get_nutrition_by_food_name(db: Session, food_name: str):
    return db.query(models.NutritionDatabase).filter(
        models.NutritionDatabase.food_name.ilike(f"%{food_name}%")
    ).all()

def get_nutrition_item(db: Session, nutrition_id: str):
    return db.query(models.NutritionDatabase).filter(models.NutritionDatabase.id == nutrition_id).first()

def create_nutrition_item(db: Session, nutrition: schemas.NutritionDatabaseCreate):
    nutrition_data = nutrition.dict()
    nutrition_data['id'] = str(uuid.uuid4())
    db_nutrition = models.NutritionDatabase(**nutrition_data)
    db.add(db_nutrition)
    db.commit()
    db.refresh(db_nutrition)
    return db_nutrition

def update_nutrition_item(db: Session, nutrition_id: str, nutrition_update: schemas.NutritionDatabaseUpdate):
    db_nutrition = db.query(models.NutritionDatabase).filter(models.NutritionDatabase.id == nutrition_id).first()
    if db_nutrition:
        update_data = nutrition_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_nutrition, field, value)
        db_nutrition.last_updated = datetime.utcnow()
        db.commit()
        db.refresh(db_nutrition)
    return db_nutrition

# User Preferences CRUD operations
def get_user_preferences(db: Session, user_id: str):
    return db.query(models.UserPreference).filter(models.UserPreference.user_id == user_id).first()

def create_user_preferences(db: Session, preferences: schemas.UserPreferenceCreate):
    preferences_data = preferences.dict()
    preferences_data['id'] = str(uuid.uuid4())
    db_preferences = models.UserPreference(**preferences_data)
    db.add(db_preferences)
    db.commit()
    db.refresh(db_preferences)
    return db_preferences

def update_user_preferences(db: Session, user_id: str, preferences_update: schemas.UserPreferenceUpdate):
    db_preferences = db.query(models.UserPreference).filter(models.UserPreference.user_id == user_id).first()
    if db_preferences:
        update_data = preferences_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_preferences, field, value)
        db_preferences.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_preferences)
    return db_preferences

# App Statistics CRUD operations
def get_app_statistics(db: Session):
    return db.query(models.AppStatistics).first()

def update_app_statistics(db: Session, stats_update: schemas.AppStatisticsUpdate):
    db_stats = db.query(models.AppStatistics).first()
    if not db_stats:
        # Create if doesn't exist
        stats_data = stats_update.dict()
        stats_data['id'] = str(uuid.uuid4())
        db_stats = models.AppStatistics(**stats_data)
        db.add(db_stats)
    else:
        update_data = stats_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_stats, field, value)
        db_stats.last_updated = datetime.utcnow()
    
    db.commit()
    db.refresh(db_stats)
    return db_stats
