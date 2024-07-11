class GenerationSettings {
  double guidanceScale;
  int maxNewTokens;
  bool doSample;
  double temperature;
  int numWords;
  String weightMethod;

  GenerationSettings({
    required this.guidanceScale,
    required this.maxNewTokens,
    required this.doSample,
    required this.temperature,
    required this.numWords,
    required this.weightMethod,
  });

  GenerationSettings copy() {
    return GenerationSettings(
      guidanceScale: this.guidanceScale,
      maxNewTokens: this.maxNewTokens,
      doSample: this.doSample,
      temperature: this.temperature,
      numWords: this.numWords,
      weightMethod: this.weightMethod,
    );
  }
}
