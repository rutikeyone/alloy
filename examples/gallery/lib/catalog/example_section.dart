import 'package:flutter/widgets.dart';
import 'package:gallery/l10n/gallery_l10n.dart';

/// What an example is about, which is how the gallery is organised.
///
/// Sections are framework capabilities rather than projects: a reader arrives
/// wanting to know how scopes end, not wanting to see `notes_app`. That is
/// why one package can supply entries to several sections, and why one
/// section can draw on several packages.
enum ExampleSection {
  startup,
  injection,
  scopes,
  codegen,
  observability,
  testing,
}

/// What a section is called and what it covers, in the reader's language.
///
/// Held here rather than on the enum because the enum is identity — it is
/// what an entry points at and what the hub groups by — and identity must not
/// change when the language does.
extension ExampleSectionText on ExampleSection {
  /// The heading.
  String title(GalleryL10n l10n) => switch (this) {
    ExampleSection.startup => l10n.sectionStartup,
    ExampleSection.injection => l10n.sectionInjection,
    ExampleSection.scopes => l10n.sectionScopes,
    ExampleSection.codegen => l10n.sectionCodegen,
    ExampleSection.observability => l10n.sectionObservability,
    ExampleSection.testing => l10n.sectionTesting,
  };

  /// The line under the heading.
  String blurb(GalleryL10n l10n) => switch (this) {
    ExampleSection.startup => l10n.sectionStartupBlurb,
    ExampleSection.injection => l10n.sectionInjectionBlurb,
    ExampleSection.scopes => l10n.sectionScopesBlurb,
    ExampleSection.codegen => l10n.sectionCodegenBlurb,
    ExampleSection.observability => l10n.sectionObservabilityBlurb,
    ExampleSection.testing => l10n.sectionTestingBlurb,
  };
}

@immutable
class SectionedEntries<T> {
  const SectionedEntries({required this.section, required this.entries});

  final ExampleSection section;
  final List<T> entries;
}
