"""
Script to create database tables and initial data
Run this script to set up the database
"""

from personal_wellness_tracker_backend.database import engine
from personal_wellness_tracker_backend.models import Base
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_tables():
    """Create all tables in the database"""
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created successfully!")
    except Exception as e:
        logger.error(f"❌ Error creating tables: {e}")
        raise

def main():
    """Main function to set up the database"""
    logger.info("🔧 Setting up database...")
    create_tables()
    logger.info("🎉 Database setup completed!")

if __name__ == "__main__":
    main()
