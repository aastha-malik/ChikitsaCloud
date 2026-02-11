from sqlalchemy import text, inspect
from app.database import engine

def migrate():
    inspector = inspect(engine)
    print(f"Existing columns in auth_users: {inspector.get_columns('auth_users')}")

    with engine.connect() as conn:
        def add_column(table_name, name, type_str):
            existing_columns = [c['name'] for c in inspector.get_columns(table_name)]
            if name not in existing_columns:
                try:
                    conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {name} {type_str}"))
                    print(f"Added column: {name} to {table_name}")
                except Exception as e:
                    print(f"Failed to add {name} to {table_name}: {e}")
            else:
                print(f"Column {name} in {table_name} already exists.")

        # auth_users columns
        add_column("auth_users", "auth_provider", "VARCHAR DEFAULT 'email' NOT NULL")
        add_column("auth_users", "is_email_verified", "BOOLEAN DEFAULT FALSE")
        add_column("auth_users", "email_verification_code", "VARCHAR")
        add_column("auth_users", "email_verification_expires_at", "TIMESTAMP WITH TIME ZONE")
        add_column("auth_users", "created_at", "TIMESTAMP WITH TIME ZONE DEFAULT NOW()")
        add_column("auth_users", "updated_at", "TIMESTAMP WITH TIME ZONE DEFAULT NOW()")

        # user_profiles columns
        add_column("user_profiles", "height", "NUMERIC")
        add_column("user_profiles", "weight", "NUMERIC")
        add_column("user_profiles", "country", "VARCHAR")

        # medical_records columns
        add_column("medical_records", "title", "VARCHAR")
        add_column("medical_records", "record_type", "VARCHAR")
        add_column("medical_records", "ai_insight", "TEXT")
        add_column("medical_records", "created_at", "TIMESTAMP WITH TIME ZONE DEFAULT NOW()")

        # Drop old columns from medical_records to match new structure
        def drop_column(table_name, name):
            existing_columns = [c['name'] for c in inspector.get_columns(table_name)]
            if name in existing_columns:
                try:
                    conn.execute(text(f"ALTER TABLE {table_name} DROP COLUMN {name}"))
                    print(f"Dropped column: {name} from {table_name}")
                except Exception as e:
                    print(f"Failed to drop {name} from {table_name}: {e}")

        drop_column("medical_records", "file_type")
        drop_column("medical_records", "record_category")
        drop_column("medical_records", "original_filename")
        drop_column("medical_records", "uploaded_at")

        conn.commit()
        print("Migration complete.")

if __name__ == "__main__":
    migrate()
