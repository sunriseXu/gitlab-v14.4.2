import { __, s__ } from '~/locale';

export default {
  new: __('New'),
  fixed: __('Fixed'),
  label: s__('ciReport|Security scanning'),
  loading: s__('ciReport|Security scanning is loading'),
  sastScanner: s__('ciReport|SAST'),
  dastScanner: s__('ciReport|DAST'),
  dependencyScanner: s__('ciReport|Dependency scanning'),
  secretDetectionScanner: s__('ciReport|Secret detection'),
  coverageFuzzing: s__('ciReport|Coverage fuzzing'),
  apiFuzzing: s__('ciReport|API fuzzing'),
  securityScanning: s__('ciReport|Security scanning'),
  error: s__('ciReport|Security reports failed loading results'),
  highlights: s__(
    'ciReport|%{criticalStart}critical%{criticalEnd}, %{highStart}high%{highEnd} and %{otherStart}others%{otherEnd}',
  ),
  noNewVulnerabilities: s__(
    'ciReport|%{scanner} detected no %{boldStart}new%{boldEnd} potential vulnerabilities',
  ),
  newVulnerabilities: s__('ciReport|%{scanner} detected %{number} new potential %{vulnStr}'),
};
