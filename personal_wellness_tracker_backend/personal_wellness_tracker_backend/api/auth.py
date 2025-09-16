from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Annotated
import uuid

from ..database import get_db
from .. import models, schemas, crud
from ..core import security, deps

router = APIRouter()

@router.post("/register", response_model=schemas.StandardResponse)
def register_user(
    user_data: schemas.UserRegister,
    db: Annotated[Session, Depends(get_db)]
):
    """
    Register a new user
    """
    # Check if user already exists
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Hash password
    hashed_password = security.get_password_hash(user_data.password)
    
    # Create new user
    user_id = str(uuid.uuid4())
    db_user = models.User(
        uid=user_id,
        email=user_data.email,
        password_hash=hashed_password,
        username=user_data.username,
        profile_completed=False
    )
    
    try:
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        return schemas.StandardResponse(
            success=True,
            message="User registered successfully",
            data={
                "user_id": db_user.uid,
                "email": db_user.email,
                "username": db_user.username
            }
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to register user"
        )

@router.post("/login", response_model=schemas.Token)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Login user and return access token
    """
    # Authenticate user
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    
    if not user or not security.verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token = security.create_access_token(data={"sub": user.uid})
    refresh_token = security.create_refresh_token(data={"sub": user.uid})
    
    return schemas.Token(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )

# @router.post("/login-json", response_model=schemas.Token)
# def login_user_json(
#     user_data: schemas.UserLogin,
#     db: Session = Depends(get_db)
# ):
#     """
#     Login user with JSON payload and return access token
#     """
#     # Authenticate user
#     user = db.query(models.User).filter(models.User.email == user_data.email).first()
    
#     if not user or not security.verify_password(user_data.password, user.password_hash):
#         raise HTTPException(
#             status_code=status.HTTP_401_UNAUTHORIZED,
#             detail="Incorrect email or password",
#             headers={"WWW-Authenticate": "Bearer"},
#         )
    
#     # Create access token
#     access_token = security.create_access_token(data={"sub": user.uid})
#     refresh_token = security.create_refresh_token(data={"sub": user.uid})
    
#     return schemas.Token(
#         access_token=access_token,
#         refresh_token=refresh_token,
#         token_type="bearer"
#     )

@router.get("/me", response_model=schemas.User)
def get_current_user_info(
    current_user: Annotated[models.User, Depends(deps.get_current_active_user)]
):
    """
    Get current user information
    """
    return current_user

@router.post("/refresh", response_model=schemas.Token)
def refresh_access_token(
    refresh_token: str,
    db: Session = Depends(get_db)
):
    """
    Refresh access token using refresh token
    """
    try:
        from ..core import config
        from jose import jwt
        
        settings = config.get_settings()
        payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])
        
        if payload.get("scope") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        # Verify user exists
        user = db.query(models.User).filter(models.User.uid == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        # Create new tokens
        new_access_token = security.create_access_token(data={"sub": user.uid})
        new_refresh_token = security.create_refresh_token(data={"sub": user.uid})
        
        return schemas.Token(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            token_type="bearer"
        )
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
