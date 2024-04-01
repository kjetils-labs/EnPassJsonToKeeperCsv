# EnPassJsonToKeeperCsv

Created because I wanted to move from Enpass (https://www.enpass.io/) to KeePassXC (https://keepassxc.org/) but the export/import handling between the programs were not within my needs.

The PowerShell script creates a CSV formated file with the fields:

```
Title
Username
Password
Created
Last Modified
URL
Notes
```

For easy import into keePassXC as a CSV, the fields will auto-select in the import except for the delimiter, you'll have to select ";" manually for it to work.

Any fields not "covered" by the above, will be added to the notes if there's any so you don't lose any information.
