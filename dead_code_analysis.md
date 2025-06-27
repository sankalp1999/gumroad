# Dead Code Analysis - Models Directory

## Summary
This analysis identifies potentially unused models in the `app/models/` directory based on code references, associations, and usage patterns.

## Methodology
1. Searched for all ActiveRecord models in the models directory
2. Analyzed references to each model across the codebase
3. Checked for associations in other models
4. Identified models with minimal or no usage
5. Categorized by confidence level for removal

## High Confidence - Likely Dead Code

### 1. YearlyStat
- **File**: `app/models/yearly_stat.rb`
- **Size**: 6 lines
- **Usage**: Only has association in User model (`has_one :yearly_stat`)
- **References**: Only found in migration, spec, and association
- **Reason**: Appears to be a placeholder model with no actual functionality

### 2. Tip
- **File**: `app/models/tip.rb`
- **Size**: 7 lines
- **Usage**: No associations found in other models, only schema reference
- **References**: Only in migration and schema
- **Reason**: Model exists but no code uses it for creating or querying tips

## Medium Confidence - Potentially Dead Code

### 3. PurchaseWalletType
- **File**: `app/models/purchase_wallet_type.rb`
- **Size**: 6 lines
- **Usage**: Only used in one service test
- **References**: Created in `Purchase::CreateService` but minimal usage
- **Reason**: Very limited functionality, only used for tracking wallet types

### 4. SignupEvent
- **File**: `app/models/signup_event.rb`
- **Size**: 7 lines
- **Usage**: Inherits from Event, used in concerns and controller
- **References**: Limited to signup tracking
- **Reason**: Simple event tracking that might be replaceable

### 5. ProductTagging
- **File**: `app/models/product_tagging.rb`
- **Usage**: Has some methods but limited references
- **References**: Only in specs and model itself
- **Reason**: Tagging functionality that may be unused

## Low Confidence - Likely Still Used

### 6. RecurringService
- **File**: `app/models/recurring_service.rb`
- **Size**: 31 lines
- **Usage**: Has association in User model and includes modules
- **References**: Has related modules and functionality
- **Reason**: Part of subscription/recurring billing system

### 7. LegacyPermalink
- **File**: `app/models/legacy_permalink.rb`
- **Usage**: Referenced in Link model for permalink resolution
- **References**: Used in Link.visible lookup
- **Reason**: Important for backward compatibility

### 8. StampedPdf
- **File**: `app/models/stamped_pdf.rb`
- **Usage**: Has associations, used in jobs and workers
- **References**: Part of PDF processing system
- **Reason**: Active functionality for PDF stamping

### 9. SentAbandonedCartEmail
- **File**: `app/models/sent_abandoned_cart_email.rb`
- **Usage**: Created in CustomerMailer
- **References**: Part of email tracking system
- **Reason**: Active email functionality

## Models with Active Usage

### 10. TaxonomyStat
- **File**: `app/models/taxonomy_stat.rb`
- **Usage**: Used in UpdateTaxonomyStatsJob
- **References**: Part of discover/taxonomy system
- **Reason**: Active analytics functionality

### 11. UtmLinkDrivenSale
- **File**: `app/models/utm_link_driven_sale.rb`
- **Usage**: Used in UTM tracking system
- **References**: Recent addition for analytics
- **Reason**: Active UTM tracking functionality

### 12. VideoFile
- **File**: `app/models/video_file.rb`
- **Usage**: Used in video processing and review system
- **References**: Active video functionality
- **Reason**: Core video processing functionality

## Recommendations

### Immediate Removal Candidates
1. **YearlyStat** - Remove unless there are plans to use it
2. **Tip** - Remove if tipping functionality is not implemented

### Further Investigation Needed
1. **PurchaseWalletType** - Check if wallet type tracking is needed
2. **ProductTagging** - Verify if tagging system is used in production
3. **SignupEvent** - Check if event tracking is used for analytics

### Keep for Now
- All other models appear to have active usage or are part of core functionality

## Notes
- Some models marked as "unused" may be used in data migrations or background jobs not easily found through code search
- Models with database tables should be checked for actual data before removal
- Consider deprecation warnings before complete removal
- Some models may be used in admin interfaces or internal tools not covered in this analysis

## Next Steps
1. Verify database usage for identified models
2. Check admin interfaces and internal tools
3. Add deprecation warnings before removal
4. Create migration plan for removing unused tables
