# Installation Instructions for FANUC Firebase Gateway

## Quick Install (Recommended)

Run the automated installation script:

```bash
cd rpi/fanuc_firebase_gateway
./install.sh
```

## Manual Installation

If the automated script doesn't work, follow these steps:

### Step 1: Activate Virtual Environment

```bash
cd /Users/franciszekzarebski/Documents/FanucControl/Aplikacja-do-sterowania-robotem-Fanuc
source .venv/bin/activate
```

### Step 2: Install FANUC Package

The `fanuc_package` needs to be installed in editable mode so the gateway can import it:

```bash
cd rpi/fanuc_package
pip install -e .
```

This will:
- Install the package in development mode
- Make `robot` module importable from anywhere
- Install dependencies (scipy, numpy)

### Step 3: Install Gateway Dependencies

```bash
cd ../fanuc_firebase_gateway
pip install -r requirements.txt
```

This will install:
- firebase-admin
- python-dotenv
- pytest (for testing)

### Step 4: Configure Environment

```bash
cp env.example .env
nano .env  # or use your preferred editor
```

Update `.env` with your Firebase credentials:
```bash
FIREBASE_SERVICE_ACCOUNT=/path/to/serviceAccountKey.json
FIREBASE_RTDB_URL=https://your-project.firebaseio.com
STATUS_PUBLISH_INTERVAL=0.2
LOG_LEVEL=INFO
```

### Step 5: Run the Gateway

```bash
python3 -m main
```

## Troubleshooting

### Issue: `ModuleNotFoundError: No module named 'fanuc_package'`

**Solution**: Install the fanuc_package in editable mode:
```bash
cd rpi/fanuc_package
pip install -e .
```

### Issue: `ModuleNotFoundError: No module named 'robot'`

**Solution**: Make sure you're in the virtual environment and fanuc_package is installed:
```bash
source .venv/bin/activate
cd rpi/fanuc_package
pip install -e .
```

### Issue: Import errors with relative imports

**Solution**: The `setup.py` and updated `__init__.py` files should fix this. Make sure you have the latest version:
- `rpi/fanuc_package/setup.py` (newly created)
- `rpi/fanuc_package/src/robot/__init__.py` (updated with relative imports)
- `rpi/fanuc_package/src/robot/robot.py` (updated with relative imports)

### Issue: SSL errors during pip install

**Solution**: This might be a network/firewall issue. Try:
```bash
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -e .
```

## Verification

To verify the installation worked:

```bash
python3 -c "from robot.robot import Robot; print('✓ Robot import successful')"
python3 -c "from robot.ftp import RobotFTP; print('✓ RobotFTP import successful')"
```

Both commands should print success messages without errors.

## What Was Fixed

1. **Created `setup.py`** in `fanuc_package/` to enable pip editable install
2. **Fixed imports** in `fanuc_package/src/robot/__init__.py` to use relative imports (`.robot` instead of `fanuc_package.src.robot.robot`)
3. **Fixed imports** in `fanuc_package/src/robot/robot.py` to use relative imports (`.ftp` instead of `fanuc_package.src.robot.ftp`)
4. **Updated `requirements.txt`** to include `fanuc_package` as an editable dependency
5. **Simplified imports** in `robot_adapter.py` and `ftp_bridge.py` with fallback path handling

## Architecture

```
rpi/
├── fanuc_package/          # Robot control package
│   ├── setup.py           # NEW: Enables pip install
│   ├── pyproject.toml     # Poetry config (original)
│   └── src/
│       └── robot/
│           ├── __init__.py    # FIXED: Relative imports
│           ├── robot.py       # FIXED: Relative imports
│           └── ftp.py
│
└── fanuc_firebase_gateway/  # Firebase gateway
    ├── requirements.txt     # UPDATED: Includes fanuc_package
    ├── install.sh          # NEW: Installation script
    ├── robot_adapter.py    # FIXED: Simplified imports
    ├── ftp_bridge.py       # FIXED: Simplified imports
    └── main.py
```

## Next Steps

After successful installation:

1. **Test device registration**:
   ```bash
   python3 test_device_registration.py
   ```

2. **Test commands** (requires robot selection in Firebase):
   ```bash
   python3 test_commands.py
   ```

3. **Run in production**:
   ```bash
   python3 -m main
   ```

4. **Set up systemd service** (optional, for auto-start):
   ```bash
   sudo cp fanuc-gateway.service /etc/systemd/system/
   sudo systemctl enable fanuc-gateway
   sudo systemctl start fanuc-gateway
   ```

