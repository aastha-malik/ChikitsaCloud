from sqlalchemy import text, inspect
from app.database import engine

def migrate():
    inspector = inspect(engine)
    existing_columns = [c['name'] for c in inspector.get_columns('auth_users')]
    print(f"Existing columns in auth_users: {existing_columns}")

    with engine.connect() as conn:
        def add_column(name, type_str):
            if name not in existing_columns:
                try:
                    conn.execute(text(f"ALTER TABLE auth_users ADD COLUMN {name} {type_str}"))
                    print(f"Added column: {name}")
                except Exception as e:
                    print(f"Failed to add {name}: {e}")
            else:
                print(f"Column {name} already exists.")

        add_column("auth_provider", "VARCHAR DEFAULT 'email' NOT NULL")
        add_column("is_email_verified", "BOOLEAN DEFAULT FALSE")
        add_column("email_verification_code", "VARCHAR")
        add_column("email_verification_expires_at", "TIMESTAMP WITH TIME ZONE")
        add_column("created_at", "TIMESTAMP WITH TIME ZONE DEFAULT NOW()")
        add_column("updated_at", "TIMESTAMP WITH TIME ZONE DEFAULT NOW()")

        conn.commit()
        print("Migration complete.")

if __name__ == "__main__":
    migrate()
