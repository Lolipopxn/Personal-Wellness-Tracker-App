import datetime
from jose import jwt
from typing import Optional
from passlib.context import CryptContext
from . import config

settings = config.get_settings()
ALGORITHM = "HS256"

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[datetime.timedelta] = None) -> str:
    to_encode = data.copy()
    now = datetime.datetime.utcnow()
    expire = now + (expires_delta or datetime.timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    sub = data.get("sub")
    if sub is None:
        raise ValueError("Missing 'sub' claim in token data")

    to_encode.update({
        "exp": expire,
        "iat": now,
        "sub": str(sub),
        "scope": "access",
    })
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(data: dict, expires_delta: Optional[datetime.timedelta] = None) -> str:
    to_encode = data.copy()
    now = datetime.datetime.utcnow()
    expire = now + (expires_delta or datetime.timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES))

    to_encode.update({
        "exp": expire,
        "iat": now,
        "scope": "refresh",
    })
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)