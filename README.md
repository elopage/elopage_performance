# elopage_performance

A new Flutter project to set some metrics for elopage teams

# Run project
In order to run project define api_token and user fields in launch.json file
```
"args": [
                "--dart-define=api_token=API_TOKEN",
                "--dart-define=user=USER@MAIL.COM",
            ],
```

or execute command
```flutter run --dart-define=api_token=API_TOKEN --dart-define=user=USER@MAIL.COM```

# Build project
In order to build project read instruction

in short:
1. install appdmg ```npm install -g appdmg```
2. build project ```flutter build macos --release --dart-define=api_token=API_TOKEN --dart-define=user=USER@MAIL.COM``` 
3. go to installers fold ```cd installers```
4. generate dmg ```appdmg ./config.json ./elopage_performance.dmg```