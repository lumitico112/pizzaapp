# Modelo de datos lógico

Los nombres pueden adaptarse a la convención real del proyecto. Lo importante es que una misma realidad no tenga múltiples modelos equivalentes.

> **Vigencia (18/10/2026):** este documento es el **modelo lógico de diseño** (nombres orientativos). El **esquema físico verificado v25** (37 tablas, 24 índices, 4 triggers; `PRAGMA foreign_keys = ON`) y su diccionario están en `kimi_pizza_ai_framework/docs/DATA_MODEL.md` y en la fuente de verdad `lib/core/database/db_schema.dart`. En caso de discrepancia, prevalece el esquema físico.

## Entidades principales

### User
- id
- role
- profile
- status

### AppConfiguration
- id
- salesQrImage
- otras configuraciones globales

### Asset
- id
- name
- category
- quantity
- acquisitionType
- acquisitionCost
- paymentType
- installments
- advance
- rentalPeriodType
- unitValue cuando aplique
- status
- date
- notes
- image

### Ingredient
- id
- name
- category
- baseUnit
- packageContent cuando aplique
- minimumStock
- image
- status

### Supplier
- id
- datos identificatorios
- status

### Product
- id
- name
- category
- basePrice
- variants
- recipe
- status

### ProductVariant
- id
- productId
- name
- price u otros atributos

### Recipe
- id
- productId/variantId según diseño
- items

### RecipeItem
- ingredientId
- quantity
- formulationUnit

### Promotion
- id
- image
- description
- price
- productItems
- ingredientItems
- status

### Purchase
- id
- date
- supplierId
- totalCost
- paymentStatus
- advance
- note
- image/photo
- invoiceData
- type

### PurchaseItem
- purchaseId
- ingredientId/assetId
- quantity
- totalCost
- unitCost

### PayableAccount
- id
- purchaseId
- supplierId
- total
- advance
- balance
- status

### Preparation
- id
- operationalDate
- notes
- items

### PreparationItem
- product/variant/promotion reference
- preparedQuantity
- requestedNegativeQuantity
- unit/availability data
- note

### ProductTransformation
- id
- baseProduct/variant
- targetProduct/variant
- additionalRequirements

### Sale
- id
- operationalDate
- timestamp
- userId
- total
- paymentMethod
- documentPath
- notes

### SaleItem
- saleId
- product/variant/promotion reference
- quantity
- unitPriceApplied
- subtotal
- complimentary flag

### Waste
- id
- sourceType
- sourceId
- quantity
- date
- reason
- notes
- userId

### StockMovement
- id
- itemType
- itemId
- movementType
- quantity
- unit
- sourceType
- sourceId
- timestamp
- userId
- notes

### CashSession
- id
- operationalDate
- openedAt
- openedBy
- closedAt
- closedBy
- openingAmount
- cashSales
- transferSales
- expenses
- expectedCash
- actualCash
- balance
- difference
- notes
- status

## Relaciones críticas

Product -> Recipe -> RecipeItem -> Ingredient

Purchase -> PurchaseItem -> Ingredient/Asset

Purchase -> PayableAccount cuando existe deuda

Preparation -> PreparationItem -> Product/Variant/Promotion

Sale -> SaleItem -> Product/Variant/Promotion

Sale -> StockMovement

Purchase -> StockMovement

Waste -> StockMovement

CashSession <- Sale

CashSession <- Expense

Configuration -> Sales QR

## Regla

No crear una entidad paralela para representar el mismo concepto. Si el proyecto existente ya tiene un modelo equivalente, extender/refactorizar ese modelo en vez de duplicarlo.
