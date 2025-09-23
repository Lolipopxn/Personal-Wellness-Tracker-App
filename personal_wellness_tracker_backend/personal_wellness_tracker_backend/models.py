from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Date, Text, ForeignKey, Enum, ARRAY
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

Base = declarative_base()

# Enums
class GenderEnum(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"

class MealTypeEnum(str, enum.Enum):
    breakfast = "breakfast"
    lunch = "lunch"
    dinner = "dinner"
    snack = "snack"

class ThemeEnum(str, enum.Enum):
    light = "light"
    dark = "dark"
    system = "system"

class WeightUnitEnum(str, enum.Enum):
    kg = "kg"
    lbs = "lbs"

class HeightUnitEnum(str, enum.Enum):
    cm = "cm"
    ft_in = "ft_in"

class TemperatureUnitEnum(str, enum.Enum):
    celsius = "celsius"
    fahrenheit = "fahrenheit"

# Models
class User(Base):
    __tablename__ = "users"
    
    uid = Column(String, primary_key=True)
    email = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)  # เพิ่ม password hash field
    username = Column(String)
    age = Column(Integer)
    gender = Column(Enum(GenderEnum))
    weight = Column(Float)
    height = Column(Float)
    profile_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    blood_pressure = Column(String)
    heart_rate = Column(Integer)
    health_problems = Column(ARRAY(String))
    saved_days_count = Column(Integer, default=0)
    day_streak = Column(Integer, default=0)
    last_updated = Column(DateTime, default=func.now())
    
    # Relationships
    goals = relationship("UserGoal", back_populates="user")
    food_logs = relationship("FoodLog", back_populates="user")
    meals = relationship("Meal", back_populates="user")
    daily_tasks = relationship("DailyTask", back_populates="user")
    achievements = relationship("Achievement", back_populates="user")
    preferences = relationship("UserPreference", back_populates="user", uselist=False)

class UserGoal(Base):
    __tablename__ = "user_goals"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.uid"), nullable=False)
    goal_weight = Column(Float)
    goal_exercise_frequency = Column(Integer)
    goal_exercise_minutes = Column(Integer)
    goal_water_intake = Column(Integer)
    effective_date = Column(Date)
    end_date = Column(Date)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="goals")

class FoodLog(Base):
    __tablename__ = "food_logs"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.uid"), nullable=False)
    date = Column(Date, nullable=False)
    meal_count = Column(Integer, default=0)
    
    # Relationships
    user = relationship("User", back_populates="food_logs")
    meals = relationship("Meal", back_populates="food_log")

class Meal(Base):
    __tablename__ = "meals"
    
    id = Column(String, primary_key=True)
    food_log_id = Column(String, ForeignKey("food_logs.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.uid"), nullable=False)
    food_name = Column(String)
    meal_type = Column(Enum(MealTypeEnum))
    image_url = Column(String)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    food_log = relationship("FoodLog", back_populates="meals")
    user = relationship("User", back_populates="meals")

class DailyTask(Base):
    __tablename__ = "daily_tasks"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.uid"), nullable=False)
    date = Column(Date, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="daily_tasks")
    tasks = relationship("Task", back_populates="daily_task")

class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(String, primary_key=True)
    daily_task_id = Column(String, ForeignKey("daily_tasks.id"), nullable=False)
    task_type = Column(String)
    value_text = Column(Text)
    value_number = Column(Float)
    completed = Column(Boolean, default=False)
    task_quality = Column(String)
    started_at = Column(DateTime, nullable=False)
    ended_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    daily_task = relationship("DailyTask", back_populates="tasks")

class Achievement(Base):
    __tablename__ = "achievements"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.uid"), nullable=False)
    type = Column(String)
    name = Column(String)
    description = Column(Text)
    target = Column(Integer)
    current = Column(Integer)
    achieved = Column(Boolean, default=False)
    achieved_at = Column(DateTime)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="achievements")

class NutritionDatabase(Base):
    __tablename__ = "nutrition_database"
    
    id = Column(String, primary_key=True)
    food_name = Column(String, nullable=False, unique=True)
    calories = Column(Float)
    protein = Column(Float)
    carbs = Column(Float)
    fat = Column(Float)
    fiber = Column(Float)
    sugar = Column(Float)
    last_updated = Column(DateTime, default=func.now())

class UserPreference(Base):
    __tablename__ = "user_preferences"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.uid"), nullable=False, unique=True)
    theme = Column(Enum(ThemeEnum), default=ThemeEnum.system)
    notifications_enabled = Column(Boolean, default=True)
    reminder_times = Column(Text)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="preferences")

class AppStatistics(Base):
    __tablename__ = "app_statistics"
    
    id = Column(String, primary_key=True)
    total_users = Column(Integer, default=0)
    total_meals_logged = Column(Integer, default=0)
    total_days_tracked = Column(Integer, default=0)
    api_calls_this_month = Column(Integer, default=0)
    last_updated = Column(DateTime, default=func.now())
