








filter_v2.py

```
import sys

# تعريف الألوان
class Colors:
    GREEN = '\033[92m'   # باسوورد صريح
    YELLOW = '\033[93m'  # يوزرات وهاشات
    BLUE = '\033[94m'    # مفاتيح النظام
    CYAN = '\033[96m'    # العناوين الفرعية
    RED = '\033[91m'     # أخطاء
    BOLD = '\033[1m'
    ENDC = '\033[0m'    # إعادة اللون للوضع الطبيعي

def filter_mimikatz(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        print(f"{Colors.BOLD}{Colors.CYAN}{'='*20} Colorized Mimikatz Filter {'='*20}{Colors.ENDC}\n")
        
        for line in lines:
            clean_line = line.strip()
            
            if "(null)" in clean_line or not clean_line:
                continue
            
            # 1. صيد الباسووردات الصريحة (الكنز) باللون الأخضر
            if any(key in clean_line for key in ["Password", "cur/text", "DefaultPassword"]):
                print(f"{Colors.BOLD}{Colors.GREEN}{line.rstrip()}{Colors.ENDC}")
            
            # 2. صيد اليوزرات والهاشات باللون الأصفر
            elif any(key in clean_line for key in ["User", "NTLM", "SHA1", "MsCacheV2"]):
                print(f"{Colors.YELLOW}{line.rstrip()}{Colors.ENDC}")
                
            # 3. صيد مفاتيح التشفير باللون الأزرق
            elif any(key in clean_line for key in ["SysKey", "SAMKey", "Secret"]):
                print(f"{Colors.BLUE}{line.rstrip()}{Colors.ENDC}")

            # 4. الأسطر اللي تبدأ بنجمة (معلومات إضافية)
            elif clean_line.startswith('*'):
                print(line.rstrip())

    except FileNotFoundError:
        print(f"{Colors.RED}Error: File '{file_path}' not found.{Colors.ENDC}")

if __name__ == "__main__":
    filter_mimikatz('aaa.txt')
```


















