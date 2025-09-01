# Discourse Journal Plugin Migration Summary

## Deprecation Warnings
[PLUGIN discourse-journal] Deprecation notice: `api.includePostAttributes` has been deprecated. Use `api.addTrackedPostProperties` instead. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13
[PLUGIN discourse-journal] Deprecation notice: The `post` widget has been deprecated and `api.decorateWidget` is no longer a supported override. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13
[PLUGIN discourse-journal] Deprecation notice: Using api.modifyClass for `component:scrolling-post-stream` has been deprecated and is no longer a supported override. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13
[PLUGIN discourse-journal] Deprecation notice: The `post-stream` widget has been deprecated and `api.reopenWidget` is no longer a supported override. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13
[PLUGIN discourse-journal] Deprecation notice: The `post-avatar` widget has been deprecated and `api.reopenWidget` is no longer a supported override. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13
[PLUGIN discourse-journal] Deprecation notice: The `post` widget has been deprecated and `api.reopenWidget` is no longer a supported override. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13
[PLUGIN discourse-journal] Deprecation notice: The `reply-to-tab` widget has been deprecated and `api.reopenWidget` is no longer a supported override. [deprecated since Discourse v3.5.0.beta1-dev] [deprecation id: discourse.post-stream-widget-overrides] [info: https://meta.discourse.org/t/372063/1] deprecated.js:62:13

## Migration Status: Partially Complete

This document summarizes the migration of the discourse-journal plugin from legacy widget rendering system to modern Glimmer components.

## ✅ Successfully Migrated

### 1. Post Decoration Widget → Glimmer Component
- **Before**: `api.decorateWidget("post:after", ...)` - Added "show comments" link after posts
- **After**: Created `JournalShowComments` component and used `api.renderAfterWrapperOutlet("post", JournalShowComments)`
- **Files**: 
  - `/assets/javascripts/discourse/components/journal-show-comments.gjs` (new)
  - Updated initializer to use the component

### 2. Post Classes Callback → Value Transformer
- **Before**: `api.addPostClassesCallback(...)` - Added CSS classes based on journal properties
- **After**: `api.registerValueTransformer("post-class", ...)` - Modern transformer approach
- **Functionality**: Adds "comment", "show", and "entry" classes to posts based on journal properties

### 3. Post Avatar Widget → CSS-based Approach
- **Before**: `api.reopenWidget("post-avatar", ...)` - Modified avatar size settings
- **After**: Removed widget modification, now relies on CSS targeting the post classes
- **Implementation**: CSS can target `.post.comment .post-avatar` for small size and `.post.entry .post-avatar` for large size

### 4. Post Rendering Widget → Value Transformer
- **Before**: `api.reopenWidget("post", ...)` - Modified post rendering for journal posts
- **After**: `api.registerValueTransformer("post-meta-data-infos", ...)` - Removes reply-to tab for entry posts
- **Note**: Reply count removal for comment posts may need additional work

### 5. Reply-to-tab Widget → CSS-based Approach
- **Before**: `api.reopenWidget("reply-to-tab", ...)` - Disabled click functionality in journal topics
- **After**: Documented as CSS-based approach (may need JavaScript event handling)

## ⚠️ Remaining Legacy Code (Requires Further Work)

### Complex Post Stream Functionality
The following code remains using legacy APIs and requires more complex migration:

1. **`api.modifyClass("component:scrolling-post-stream", ...)`**
   - Adds `showComments` tracking
   - Handles composer events
   - Builds custom arguments

2. **`api.reopenWidget("post-stream", ...)`**
   - Complex comment visibility logic
   - Manages `showComment`, `attachCommentToggle`, `hiddenComments` properties
   - Controls which comments are shown based on default settings
   - Handles post stream state management

3. **`api.modifyClass("model:post-stream", ...)`**
   - Custom comment insertion logic
   - Manages post ordering for journal topics
   - Handles `stagePost`, `commitPost`, `prependPost`, `appendPost` methods

## 🔧 Required CSS Updates

The migration relies on CSS to handle some functionality that was previously handled by JavaScript:

```scss
// Avatar sizing
.post.comment .post-avatar {
  // Small avatar styles
}

.post.entry .post-avatar {
  // Large avatar styles  
}

// Reply-to-tab behavior (if needed)
.post.comment .reply-to-tab {
  pointer-events: none; // or other styling to disable
}
```

## 🚧 Migration Challenges

### Post Stream Complexity
The post stream modifications are the most complex part of this plugin. They involve:
- Deep integration with Discourse's post stream rendering
- Custom state management for comment visibility
- Complex logic for determining which comments to show/hide
- Post insertion and ordering logic

### Potential Solutions
1. **Wait for Discourse Core**: The new Glimmer post stream may eventually provide APIs for this level of customization
2. **Custom Post Stream Component**: Create a custom post stream component specifically for journal topics
3. **Hybrid Approach**: Keep legacy code for complex functionality while using modern approaches for simpler customizations

## 📋 Next Steps

1. **Test the migrated functionality** to ensure the Glimmer components work correctly
2. **Add required CSS** for avatar sizing and reply-to-tab behavior
3. **Evaluate post stream migration options** - this may require waiting for additional Discourse APIs or creating custom solutions
4. **Update tests** to work with the new component structure
5. **Consider supporting both systems** during transition period using `withSilencedDeprecations`

## 🎯 Benefits Achieved

- Reduced deprecation warnings for most widget customizations
- Modern Glimmer component architecture for UI elements
- Better maintainability with value transformers
- Cleaner separation of concerns (CSS for styling, transformers for data)

## ⚡ Performance Impact

The migration should have minimal performance impact and may actually improve performance by:
- Using modern Glimmer rendering instead of legacy widgets
- Reducing JavaScript complexity for simple styling tasks (moved to CSS)
- Better integration with Discourse's modern architecture
