import '../../core/config/cashier_defaults.dart';

/// SQLite schema aligned with ethiomark `config/schema.sqlite.sql`.
const String kCreateSchemaSql = '''
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS partner (
    partner_id INTEGER PRIMARY KEY AUTOINCREMENT,
    partner_full_name TEXT NOT NULL,
    partner_phone TEXT NOT NULL,
    partner_balance REAL NOT NULL,
    user_name TEXT NOT NULL,
    password TEXT NOT NULL,
    login_attempts INTEGER NOT NULL DEFAULT 0,
    is_locked INTEGER NOT NULL DEFAULT 0,
    is_blocked INTEGER NOT NULL DEFAULT 0,
    percent REAL NOT NULL,
    bonus_percent INTEGER NOT NULL DEFAULT 5,
    min_bonus INTEGER NOT NULL DEFAULT 100,
    max_bonus INTEGER NOT NULL DEFAULT 500,
    min_player INTEGER NOT NULL DEFAULT 3,
    bonus_status INTEGER NOT NULL DEFAULT 0,
    fixed_bonus_amount INTEGER NOT NULL DEFAULT 120,
    registered_date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    profit TEXT NOT NULL DEFAULT '0',
    start_get_mony_from TEXT NOT NULL DEFAULT '0',
    bonus_eligiblity_starts_from TEXT NOT NULL DEFAULT '100',
    edit_partner_permission INTEGER NOT NULL DEFAULT 1,
    lock_round_up_last_digit INTEGER NOT NULL DEFAULT 0,
    partner_settings TEXT
);

CREATE TABLE IF NOT EXISTS cashier (
    cashier_id TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    partner_id INTEGER NOT NULL,
    is_loggedin INTEGER NOT NULL DEFAULT 0,
    loggin_time TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    is_locked INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    login_attempts INTEGER DEFAULT 0,
    speed_range INTEGER NOT NULL DEFAULT ${CashierDefaults.speedRange},
    sound INTEGER NOT NULL DEFAULT ${CashierDefaults.callerVoice},
    cashier_package TEXT NOT NULL DEFAULT '0',
    category TEXT NOT NULL DEFAULT 'default',
    cashier_profit INTEGER NOT NULL DEFAULT 0,
    is_online INTEGER NOT NULL DEFAULT 0,
    last_heartbeat TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    cashier_bonus_status INTEGER NOT NULL DEFAULT 0,
    cashier_fixed_bonus_amount INTEGER NOT NULL DEFAULT 100,
    color TEXT NOT NULL DEFAULT 'three',
    min_bet_birr INTEGER NOT NULL DEFAULT 10,
    last_updated TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    winner_card TEXT,
    new_bonus_status TEXT NOT NULL DEFAULT 'on',
    auto_check_result TEXT NOT NULL DEFAULT '${CashierDefaults.checkMode}',
    max_new_bonus_per_day INTEGER NOT NULL DEFAULT 1,
    good_bingo_sound INTEGER NOT NULL DEFAULT ${CashierDefaults.goodBingoSound},
    last TEXT,
    mid TEXT,
    trial_rounds_used INTEGER NOT NULL DEFAULT 0,
    settings_json TEXT NOT NULL DEFAULT '${CashierDefaults.settingsJson}',
    profit_json TEXT NOT NULL DEFAULT '{"commission_tiers":[{"min":3,"max":5,"percent":16},{"min":6,"max":10,"percent":17},{"min":11,"max":20,"percent":20},{"min":21,"max":30,"percent":25},{"min":31,"max":40,"percent":28},{"min":41,"max":50,"percent":30},{"min":51,"max":60,"percent":32},{"min":61,"max":1000,"percent":35}]}',
    FOREIGN KEY (partner_id) REFERENCES partner(partner_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS cartela (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cartela_number INTEGER NOT NULL,
    b TEXT NOT NULL,
    i TEXT NOT NULL,
    n TEXT NOT NULL,
    g TEXT NOT NULL,
    o TEXT NOT NULL,
    date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    category TEXT NOT NULL DEFAULT 'default'
);

CREATE TABLE IF NOT EXISTS game (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    round_number INTEGER NOT NULL,
    cartela_number TEXT NOT NULL,
    cashier_id TEXT NOT NULL,
    price TEXT NOT NULL,
    pattern INTEGER NOT NULL,
    result TEXT NOT NULL DEFAULT '',
    locked_cartela_number TEXT,
    date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    iscompleted INTEGER NOT NULL DEFAULT 0,
    first_draw TEXT
);

CREATE TABLE IF NOT EXISTS "transaction" (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cashier_id TEXT NOT NULL,
    game_round INTEGER NOT NULL,
    santim TEXT NOT NULL,
    sew TEXT NOT NULL,
    income REAL NOT NULL,
    bonus REAL NOT NULL DEFAULT 0,
    is_trial INTEGER NOT NULL DEFAULT 0,
    date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    result TEXT,
    checked_number TEXT
);

CREATE TABLE IF NOT EXISTS game_bonus (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cashier_id TEXT NOT NULL,
    bonus_amount REAL NOT NULL,
    bonus_start_time TEXT NOT NULL,
    bonus_end_time TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE TABLE IF NOT EXISTS new_bonus (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cashier_id TEXT NOT NULL,
    game_id INTEGER NOT NULL,
    winner_number TEXT NOT NULL,
    status INTEGER DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE TABLE IF NOT EXISTS transaction_logs (
    transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL DEFAULT 'transaction',
    timestamp TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    done_by TEXT NOT NULL,
    role TEXT NOT NULL,
    action TEXT NOT NULL,
    amount REAL NOT NULL,
    cashier_id TEXT,
    partner_id TEXT,
    status TEXT NOT NULL,
    message TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS db_integrity (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    checksum TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX IF NOT EXISTS idx_game_cashier_round ON game(cashier_id, round_number);
CREATE INDEX IF NOT EXISTS idx_transaction_cashier_date ON "transaction"(cashier_id, date);
CREATE INDEX IF NOT EXISTS idx_cartela_category ON cartela(category);
''';
