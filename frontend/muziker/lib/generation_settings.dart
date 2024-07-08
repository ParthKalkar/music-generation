
class GenerationSettings {
  double guidanceScale;
  int maxNewTokens;
  bool doSample;
  double temperature;

  GenerationSettings({
    required this.guidanceScale,
    required this.maxNewTokens,
    required this.doSample,
    required this.temperature,
  });
}