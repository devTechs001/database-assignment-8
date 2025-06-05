@echo off
echo =====================================================
echo LIBRARY MANAGEMENT SYSTEM - DATABASE SETUP
echo =====================================================
echo.

echo This script will help you set up the Library Management System database.
echo.

echo Prerequisites:
echo - MySQL Server must be installed and running
echo - You need MySQL username and password
echo.

set /p username="Enter MySQL username (default: root): "
if "%username%"=="" set username=root

echo.
echo Connecting to MySQL and creating database...
echo.

mysql -u %username% -p < library_management_system.sql

if %errorlevel% equ 0 (
    echo.
    echo ✅ Database created successfully!
    echo.
    echo You can now:
    echo 1. Connect to MySQL and use the 'library_management' database
    echo 2. Run test queries from 'test_queries.sql'
    echo 3. Use the views and stored procedures as documented in README.md
    echo.
    echo Example connection:
    echo mysql -u %username% -p library_management
    echo.
) else (
    echo.
    echo ❌ Error creating database. Please check:
    echo 1. MySQL server is running
    echo 2. Username and password are correct
    echo 3. You have permission to create databases
    echo.
)

echo.
pause
