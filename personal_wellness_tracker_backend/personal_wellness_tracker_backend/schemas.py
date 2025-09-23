from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from enum import Enum

# Enums for Pydantic
class GenderEnum(str, Enum):
    male = "male"
    female = "female"
    other = "other"

class MealTypeEnum(str, Enum):
    breakfast = "breakfast"
    lunch = "lunch"
    dinner = "dinner"
    snack = "snack"

class ThemeEnum(str, Enum):
    light = "light"
    dark = "dark"
    system = "system"

# Base schemas
class UserBase(BaseModel):
    email: str
    username: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[GenderEnum] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    blood_pressure: Optional[str] = None
    heart_rate: Optional[int] = None
    health_problems: Optional[List[str]] = None

class UserCreate(UserBase):
    uid: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[GenderEnum] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    blood_pressure: Optional[str] = None
    heart_rate: Optional[int] = None
    health_problems: Optional[List[str]] = None
    profile_completed: Optional[bool] = None

class User(UserBase):
    uid: str
    profile_completed: bool
    created_at: datetime
    updated_at: datetime
    saved_days_count: int
    day_streak: int
    last_updated: datetime

    class Config:
        from_attributes = True

# User Goals schemas
class UserGoalBase(BaseModel):
    goal_weight: Optional[float] = None
    goal_exercise_frequency: Optional[int] = None
    goal_exercise_minutes: Optional[int] = None
    goal_water_intake: Optional[int] = None
    effective_date: Optional[date] = None
    end_date: Optional[date] = None

class ChangePassword(BaseModel):
    current_password: str
    new_password: str

class UserGoalCreate(UserGoalBase):
    user_id: str

class UserGoalUpdate(UserGoalBase):
    is_active: Optional[bool] = None

class UserGoal(UserGoalBase):
    id: str
    user_id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Food Log schemas
class FoodLogBase(BaseModel):
    date: date

class FoodLogCreate(FoodLogBase):
    user_id: str

class FoodLog(FoodLogBase):
    id: str
    user_id: str
    meal_count: int

    class Config:
        from_attributes = True

# Meal schemas
class MealBase(BaseModel):
    food_name: Optional[str] = None
    meal_type: Optional[MealTypeEnum] = None
    calories: Optional[int] = 0  # เพิ่มฟิลด์แคลอรี่
    image_url: Optional[str] = None

class MealCreate(MealBase):
    food_log_id: str
    user_id: str

class MealUpdate(MealBase):
    pass

class Meal(MealBase):
    id: str
    food_log_id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Schema สำหรับการอัปโหลดรูปภาพ
class ImageUploadResponse(BaseModel):
    image_url: str
    file_size: int
    file_type: str
    uploaded_at: datetime

# Schema สำหรับ meal พร้อมข้อมูลโภชนาการ (ถ้าต้องการ)
class MealWithNutrition(Meal):
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None

# Daily Task schemas
class DailyTaskBase(BaseModel):
    date: date

class DailyTaskCreate(DailyTaskBase):
    user_id: str

class DailyTask(DailyTaskBase):
    id: str
    user_id: str

    class Config:
        from_attributes = True

# Task schemas
class TaskBase(BaseModel):
    task_type: Optional[str] = None
    value_text: Optional[str] = None
    value_number: Optional[float] = None
    completed: bool = False
    task_quality: Optional[str] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None

class TaskCreate(TaskBase):
    daily_task_id: str

class TaskUpdate(BaseModel):
    task_type: Optional[str] = None
    value_text: Optional[str] = None
    value_number: Optional[float] = None
    completed: Optional[bool] = None
    task_quality: Optional[str] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None

class Task(TaskBase):
    id: str
    daily_task_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Achievement schemas
class AchievementBase(BaseModel):
    type: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    target: Optional[int] = None
    current: Optional[int] = None

class AchievementCreate(AchievementBase):
    user_id: str

class AchievementUpdate(BaseModel):
    current: Optional[int] = None
    achieved: Optional[bool] = None
    achieved_at: Optional[datetime] = None

class Achievement(AchievementBase):
    id: str
    user_id: str
    achieved: bool
    achieved_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Nutrition Database schemas
class NutritionDatabaseBase(BaseModel):
    food_name: str
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None

class NutritionDatabaseCreate(NutritionDatabaseBase):
    pass

class NutritionDatabaseUpdate(BaseModel):
    food_name: Optional[str] = None
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None

class NutritionDatabase(NutritionDatabaseBase):
    id: str
    last_updated: datetime

    class Config:
        from_attributes = True

# User Preferences schemas
class UserPreferenceBase(BaseModel):
    theme: ThemeEnum = ThemeEnum.system
    notifications_enabled: bool = True
    reminder_times: Optional[str] = None

class UserPreferenceCreate(UserPreferenceBase):
    user_id: str

class UserPreferenceUpdate(UserPreferenceBase):
    pass

class UserPreference(UserPreferenceBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Health Info schemas (สำหรับข้อมูลสุขภาพที่อาจจะเก็บใน preferences หรือใช้แยกต่างหาก)
class HealthInfoBase(BaseModel):
    health_problems: Optional[List[str]] = None
    blood_pressure: Optional[str] = None
    heart_rate: Optional[int] = None

class HealthInfoCreate(HealthInfoBase):
    user_id: str

class HealthInfoUpdate(HealthInfoBase):
    pass

# App Statistics schemas
class AppStatisticsBase(BaseModel):
    total_users: int = 0
    total_meals_logged: int = 0
    total_days_tracked: int = 0
    api_calls_this_month: int = 0

class AppStatisticsUpdate(AppStatisticsBase):
    pass

class AppStatistics(AppStatisticsBase):
    id: str
    last_updated: datetime

    class Config:
        from_attributes = True

# Response schemas
class StandardResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class PaginatedResponse(BaseModel):
    success: bool
    message: str
    data: List[dict]
    total: int
    page: int
    size: int
    total_pages: int

# Authentication schemas
class UserRegister(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="User password (minimum 6 characters)")
    username: Optional[str] = None

class UserLogin(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., description="User password")

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[str] = None
