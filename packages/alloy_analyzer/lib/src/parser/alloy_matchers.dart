import 'package:alloy_analyzer/src/parser/annotation_matcher.dart';

const injectMatcher = AlloyAnnotationMatcher('AlloyInject');
const injectedMatcher = AlloyAnnotationMatcher('Injected');
const namedMatcher = AlloyAnnotationMatcher('Named');
const bootstrapMatcher = AlloyAnnotationMatcher('AlloyBootstrap');
const initMatcher = AlloyAnnotationMatcher('AlloyInit');
const environmentMatcher = AlloyAnnotationMatcher('AlloyEnvironment');
const scopeRootMatcher = AlloyAnnotationMatcher('AlloyScopeRoot');
const moduleMatcher = AlloyAnnotationMatcher('AlloyModule');
