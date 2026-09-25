# =============================================================
# scripts/import_csv.ps1
# Import toàn bộ CSV vào MySQL - tương ứng với 3 database:
#   1. sql_interview_prep  (schema 01_original_employees.sql)
#   2. product_analytics   (schema 02_product_analytics.sql)
#   3. social_network      (schema 03_social_network.sql)
#
# Cách dùng:
#   .\scripts\import_csv.ps1 -User root -Password "yourpassword"
#   .\scripts\import_csv.ps1 -User root -Password "" -Host 127.0.0.1 -Port 3306
# =============================================================

param(
    [string]$User     = "root",
    [string]$Password = "",
    [string]$Host     = "127.0.0.1",
    [int]   $Port     = 3306
)

# ---------------------------------------------------------------
# Helper — chạy một lệnh mysql và hiển thị output
# ---------------------------------------------------------------
function Invoke-MySQL {
    param([string]$Database, [string]$SqlCommand)
    $passArg = if ($Password -ne "") { "-p`"$Password`"" } else { "" }
    $cmd = "mysql --local-infile=1 -h $Host -P $Port -u $User $passArg $Database -e `"$SqlCommand`""
    Write-Host "  [SQL] $SqlCommand" -ForegroundColor DarkGray
    Invoke-Expression $cmd
}

function Import-CSV {
    param(
        [string]$Database,
        [string]$TableName,
        [string]$CsvFile,
        [string]$FieldsTerminatedBy = ",",
        [string]$LinesTerminatedBy  = "\n",
        [int]   $IgnoreLines        = 1
    )
    $absPath = (Resolve-Path $CsvFile).Path -replace '\\', '/'
    Write-Host "`n[IMPORT] $TableName <- $CsvFile" -ForegroundColor Cyan
    Invoke-MySQL -Database $Database -SqlCommand @"
LOAD DATA LOCAL INFILE '$absPath'
INTO TABLE $TableName
FIELDS TERMINATED BY '$FieldsTerminatedBy'
OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE $IgnoreLines LINES;
"@
}

# ---------------------------------------------------------------
# Bước 1: Áp schema (tạo DB và bảng, xóa data cũ)
# ---------------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host " BƯỚC 1: Áp schema..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$passArg = if ($Password -ne "") { "-p`"$Password`"" } else { "" }
$schemaDir = "$PSScriptRoot\..\schemas"

foreach ($schemaFile in @("01_original_employees.sql","02_product_analytics.sql","03_social_network.sql")) {
    $fullPath = Join-Path $schemaDir $schemaFile
    Write-Host "`n[SCHEMA] $schemaFile" -ForegroundColor Magenta
    Invoke-Expression "mysql --local-infile=1 -h $Host -P $Port -u $User $passArg < `"$fullPath`""
}

# ---------------------------------------------------------------
# Bước 2: Import CSV vào sql_interview_prep
# ---------------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host " BƯỚC 2: Import sql_interview_prep..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$db   = "sql_interview_prep"
$ddir = "$PSScriptRoot\..\datasets"

# Thứ tự import phải đúng FK dependency
$tables = @(
    @{ table="Employee";            csv="employees.csv"             },
    @{ table="Bonus";               csv="bonus.csv"                 },
    @{ table="Title";               csv="title.csv"                 },
    @{ table="user_name";           csv="user_name.csv"             },
    @{ table="messages_detail";     csv="messages_detail.csv"       },
    @{ table="DIALOGLOG";           csv="dialoglog.csv"             },
    @{ table="user_details";        csv="user_details.csv"          },
    @{ table="event_session_details"; csv="event_session_details.csv" },
    @{ table="login_info";          csv="login_info.csv"            },
    @{ table="USER_ACTION";         csv="user_action.csv"           },
    @{ table="all_students";        csv="all_students.csv"          },
    @{ table="attendance_events";   csv="attendance_events.csv"     },
    @{ table="ad_accounts";         csv="ad_accounts.csv"           },
    @{ table="friend_request";      csv="friend_request.csv"        },
    @{ table="request_accepted";    csv="request_accepted.csv"      },
    @{ table="new_request_accepted";csv="new_request_accepted.csv"  },
    @{ table="count_request";       csv="count_request.csv"         },
    @{ table="confirmation_no";     csv="confirmation_no.csv"       },
    @{ table="confirmed_no";        csv="confirmed_no.csv"          },
    @{ table="user_interaction";    csv="user_interaction.csv"      },
    @{ table="salesperson";         csv="salesperson.csv"           },
    @{ table="customer";            csv="customer.csv"              },
    @{ table="orders";              csv="orders.csv"                },
    @{ table="event_log";           csv="event_log.csv"             }
)

foreach ($t in $tables) {
    Import-CSV -Database $db -TableName $t.table -CsvFile "$ddir\$($t.csv)"
}

# ---------------------------------------------------------------
# Bước 3: Import CSV vào product_analytics
# ---------------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host " BƯỚC 3: Import product_analytics..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$dbPa = "product_analytics"
$paTables = @(
    @{ table="users";  csv="pa_users.csv"  },
    @{ table="events"; csv="pa_events.csv" },
    @{ table="orders"; csv="pa_orders.csv" }
)
foreach ($t in $paTables) {
    Import-CSV -Database $dbPa -TableName $t.table -CsvFile "$ddir\$($t.csv)"
}

# ---------------------------------------------------------------
# Bước 4: Import CSV vào social_network
# ---------------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host " BƯỚC 4: Import social_network..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$dbSn = "social_network"
$snTables = @(
    @{ table="friendships"; csv="sn_friendships.csv" },
    @{ table="page_likes";  csv="sn_page_likes.csv"  }
)
foreach ($t in $snTables) {
    Import-CSV -Database $dbSn -TableName $t.table -CsvFile "$ddir\$($t.csv)"
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " XONG! Toàn bộ data đã được import." -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
