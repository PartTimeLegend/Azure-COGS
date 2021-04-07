# Azure COGS

![Deploy to Azure](https://aka.ms/deploytoazurebutton)

## What Is Cost of Goods Sold (COGS)?
Cost of goods sold (COGS) refers to the direct costs of producing the goods sold by a company. This amount includes the cost of the materials and labor directly used to create the good. It excludes indirect expenses, such as distribution costs and sales force costs.

## TagUntagged.ps1

```powershell
./TagUntagged.ps1 -startDays "Monday Tuesday Wednesday Thursday Friday" -stopDays "Monday Tuesday Wednesday Thursday Friday" -startTime "08:45" -stopTime "18:30" -dryRun 1 -prefix "COGS_"
```

## Runner.ps1

```powershell
./Runner.ps1 -dryRun 1 -prefix "COGS_"
```

## Terrafrom
I'm sure you already know what [Terraform](https://terraform.io) is so no need to explain this.