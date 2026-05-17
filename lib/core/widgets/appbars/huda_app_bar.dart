import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/app_theme.dart';

/// HudaAppBar
///
/// A flexible, production-ready AppBar designed for the Huda app. Features:
/// - Works with light/dark themes defined in `AppTheme`/`AppColors`.
/// - Optional built-in bottom search bar (Arabic-friendly by default).
/// - Accepts custom `leading`, `actions`, or a full `title` widget.
/// - Implements `PreferredSizeWidget` so it can be used directly as `appBar:`.
///
/// Usage examples are provided at the bottom of this file.
class HudaAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// A custom title widget. If provided, `titleText` is ignored.
  final Widget? titleWidget;

  /// A short title string. Used when `titleWidget` is null.
  final String? titleText;

  /// Optional leading widget (e.g., back button).
  final Widget? leading;

  /// Optional action widgets (icons, menus, etc.).
  final List<Widget>? actions;

  /// Whether title should be centered (default true for Arabic apps).
  final bool centerTitle;

  /// Optional background color; falls back to theme-aware surface color.
  final Color? backgroundColor;

  /// Optional shape for the app bar. By default it's a rounded bottom radius.
  final ShapeBorder? shape;

  /// Optional custom bottom. If provided, it takes precedence over `showSearch`.
  final PreferredSizeWidget? bottom;

  /// If true and `bottom` is null, shows a built-in search field in the bottom area.
  final bool showSearch;

  /// Controller for the built-in search field (if used).
  final TextEditingController? searchController;

  /// Called on each search text change.
  final ValueChanged<String>? onSearchChanged;

  /// Hint text for the search field.
  final String? searchHint;

  /// Text alignment for the search field (use TextAlign.right for Arabic).
  final TextAlign searchTextAlign;

  /// Height of the built-in bottom area (default matches sample: 60).
  final double bottomHeight;

  /// Elevation of the bar.
  final double elevation;
  final double toolbarHeight;

  const HudaAppBar({
    super.key,
    this.titleWidget,
    this.titleText,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.shape,
    this.bottom,
    this.showSearch = false,
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
    this.searchTextAlign = TextAlign.right,
    this.bottomHeight = 70,
    this.elevation = 0,
    this.toolbarHeight = 90,
  });

  PreferredSizeWidget? get _effectiveBottom {
    if (bottom != null) return bottom;
    if (!showSearch) return null;

    return PreferredSize(
      preferredSize: Size.fromHeight(bottomHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: _buildSearchContainer(),
      ),
    );
  }

  Widget _buildSearchContainer() {
    // Use the current theme brightness to select surface color
    // but keep all colors defined in AppColors for consistency.
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final fillColor =
            backgroundColor ??
            (isDark ? AppColors.darkSurface : AppColors.lightSurface);
        final prefixColor = isDark ? AppColors.goldAccent : AppColors.primary;
        final hintStyle = TextStyle(
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
        );

        return Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: TextField(
            controller: searchController,
            textAlign: searchTextAlign,
            onChanged: onSearchChanged,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
            ),
            decoration: InputDecoration(
              hintText: searchHint ?? 'ابحث...',
              hintStyle: hintStyle,
              prefixIcon: Icon(Icons.search, color: prefixColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 12.h,
                horizontal: 16.w,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize {
    final double bottomPart = _effectiveBottom?.preferredSize.height ?? 0;
    return Size.fromHeight(toolbarHeight + bottomPart);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,

      colors: isDark
          ? [AppColors.secondary, AppColors.primary]
          : [AppColors.primary, AppColors.primaryLight],
    );

    final defaultTitle =
        titleWidget ??
        (titleText != null
            ? Text(
                titleText!,
                style:
                    theme.appBarTheme.titleTextStyle ??
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              )
            : null);

    return AppBar(
      title: defaultTitle,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: Colors.transparent,
      // flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      flexibleSpace: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(7.r)),

        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),

      shape:
          shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(5.r)),
          ),

      bottom: _effectiveBottom,
      iconTheme:
          Theme.of(context).appBarTheme.iconTheme ??
          IconThemeData(
            color: isDark ? AppColors.goldAccent : AppColors.primary,
          ),
      automaticallyImplyLeading: leading == null ? true : false,
    );
  }
}

/*
Usage examples:

1) Simple title with built-in search (Arabic alignment by default):

appBar: const HudaAppBar(
  titleText: 'قائمة السور',
  showSearch: true,
  searchHint: 'ابحث عن سورة...',
),

2) With custom leading and actions:

appBar: HudaAppBar(
  titleText: 'الصفحة',
  leading: IconButton(
    icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(icon: Icon(Icons.share, color: AppColors.primary), onPressed: () {}),
  ],
),

3) Using a custom bottom widget (takes precedence over showSearch):

appBar: HudaAppBar(
  titleText: 'بحث متقدم',
  bottom: PreferredSize(
    preferredSize: Size.fromHeight(80),
    child: YourCustomWidget(),
  ),
),

Notes:
- Colors are taken from `AppColors` and respect the current theme brightness.
- The built-in search uses `TextField` and calls `onSearchChanged` on input.
*/
