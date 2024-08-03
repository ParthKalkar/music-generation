import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:aws_common/aws_common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'theme_manager.dart';
import 'package:provider/provider.dart';
import 'audio_player_widget.dart';
import 'settings_provider.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const modelName = '';
const k1 = '';
const k2 = '';
// const awsAccessKey = '';
// const awsSecretKey = '';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  User? _firebaseUser;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    _loadInitialMessage();
  }

  types.User get _user {
    return types.User(
      id: _firebaseUser?.uid ?? '',
    );
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // Cancel any ongoing polling
    _cancelToken?.cancel();

    // Create a new CancelToken for the new request
    _cancelToken = CancelToken();

    // Collect all user messages
    List<String> userMessages = _messages
        .where((msg) => msg is types.TextMessage && msg.author.id == _firebaseUser?.uid)
        .map((msg) => (msg as types.TextMessage).text)
        .toList();

    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    // Calculate weights
    List<Map<String, dynamic>> weightedMessages = _calculateWeights(userMessages, settings.weightMethod);

    // Use appropriate URL depending on the platform
    final url = (Platform.isAndroid) ? 'http://10.0.2.2:5000/significant-words' : 'http://127.0.0.1:5000/significant-words';

    // Send to backend
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text_weight_pairs': weightedMessages,
        'num_words': settings.numWords,
      }),
    );

    String combinedKeywords = '';
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> significantWords = List<String>.from(data['significant_words']);
      print('Significant words: $significantWords');

      // Combine significant words into a single string
      String combinedKeywords = significantWords.join(" ");
      print('Combined Keywords: $combinedKeywords');
    } else {
      throw Exception('Failed to load significant words');
    }

    // Create JSON payload
    final jsonPayload = jsonEncode({
      "texts": combinedKeywords.isNotEmpty ? [combinedKeywords] : [message.text],
      "bucket_name": 'sagemaker-eu-central-1-471112987728',
      "generation_params": {
        "guidance_scale": settings.guidanceScale,
        "max_new_tokens": settings.maxNewTokens,
        "do_sample": settings.doSample,
        "temperature": settings.temperature,
      }
    });
    print(settings.weightMethod);
    print(settings.numWords);
    print(settings.doSample);
    print(settings.guidanceScale);
    print(settings.maxNewTokens);
    print(settings.temperature);
    final uuid = Uuid();
    final fileName = 'payload_${uuid.v4()}.json';
    final filePath = 'musicgen_small/input_payload/$fileName';

    // Debugging output to verify file name generation
    print('Generated file name: $fileName');
    print('File path: $filePath');

    // Upload JSON file to S3
    final s3Uri = await _uploadToS3(jsonPayload, filePath);

    // Call the SageMaker endpoint
    final outputUri = await _callSageMaker(s3Uri);
    print(outputUri);

    // Poll the SageMaker endpoint to get the result
    final audioUri = await _pollSageMakerResult(outputUri, _cancelToken!);
    if (audioUri != null) {
      print(audioUri);

      // Save to Firestore
      _saveToFirestore(audioUri, message.text);

      // Add music message
      _addMusicMessage(audioUri, message.text);
    } else {
      print('Polling was cancelled or failed.');
    }
  }

  Future<String> _uploadToS3(String jsonPayload, String filePath) async {
    final s3Bucket = 'sagemaker-eu-central-1-471112987728';
    final region = 'eu-central-1';
    final endpoint = 'https://$s3Bucket.s3.$region.amazonaws.com/$filePath';

    final credentialsProvider = AWSCredentialsProvider(
      AWSCredentials(k1, k2),
    );
    final signer = AWSSigV4Signer(
      credentialsProvider: credentialsProvider,
    );

    final request = AWSHttpRequest(
      method: AWSHttpMethod.put,
      uri: Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: utf8.encode(jsonPayload),
    );

    final scope = AWSCredentialScope(
      region: region,
      service: AWSService.s3,
    );

    final signedRequest = await signer.sign(
      request,
      credentialScope: scope,
    );

    final client = http.Client();
    final response = await client.send(
      http.Request(signedRequest.method.value, signedRequest.uri)
        ..headers.addAll(signedRequest.headers)
        ..bodyBytes = await signedRequest.bodyBytes,
    );

    if (response.statusCode == 200) {
      return 's3://$s3Bucket/$filePath';
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to upload to S3: ${response.statusCode} $responseBody');
    }
  }

  Future<String> _callSageMaker(String s3Uri) async {
    final region = 'eu-central-1';
    final endpoint = 'https://runtime.sagemaker.eu-central-1.amazonaws.com/endpoints/$modelName/async-invocations';

    final credentialsProvider = AWSCredentialsProvider(
      AWSCredentials(k1, k2),
    );
    final signer = AWSSigV4Signer(
      credentialsProvider: credentialsProvider,
    );

    final request = AWSHttpRequest(
      method: AWSHttpMethod.post,
      uri: Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Amzn-SageMaker-InvocationTimeoutSeconds': '3600',
        'X-Amzn-SageMaker-InputLocation': s3Uri,
        'X-Amzn-SageMaker-EndpointName': modelName,
      },
    );

    final scope = AWSCredentialScope(
      region: region,
      service: AWSService.sageMaker,
    );

    final signedRequest = await signer.sign(
      request,
      credentialScope: scope,
    );

    final client = http.Client();
    final response = await client.send(
      http.Request(signedRequest.method.value, signedRequest.uri)
        ..headers.addAll(signedRequest.headers)
        ..bodyBytes = await signedRequest.bodyBytes,
    );

    if (response.statusCode == 202) {
      final headers = response.headers;
      return headers['x-amzn-sagemaker-outputlocation']!;
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to call SageMaker: ${response.statusCode} $responseBody');
    }
  }

  String s3ToHttp(String url) {
    if (url.startsWith('s3://')) {
      final s3Path = url.substring(5);
      final bucket = s3Path.split('/')[0];
      final objectName = s3Path.split('/').sublist(1).join('/');
      return 'https://$bucket.s3.eu-central-1.amazonaws.com/$objectName';
    } else {
      return url;
    }
  }

  Future<String?> _pollSageMakerResult(String outputUri, CancelToken cancelToken) async {
    final region = 'eu-central-1';

    final credentialsProvider = AWSCredentialsProvider(
      AWSCredentials(k1, k2),
    );
    final signer = AWSSigV4Signer(
      credentialsProvider: credentialsProvider,
    );

    // Convert the s3 URI to a https URI
    final httpsUri = Uri.parse(s3ToHttp(outputUri));

    final request = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: httpsUri,
    );

    final scope = AWSCredentialScope(
      region: region,
      service: AWSService.s3,
    );

    while (!cancelToken.isCancelled) {
      final signedRequest = await signer.sign(
        request,
        credentialScope: scope,
      );

      final client = http.Client();
      final response = await client.send(
        http.Request(signedRequest.method.value, signedRequest.uri)
          ..headers.addAll(signedRequest.headers),
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        print("SageMaker result: $jsonResponse");
        final s3Uri = jsonResponse['generated_output_s3'];
        final output = s3Uri;
        print(output);

        return output;
      } else if (response.statusCode == 202) {
        print("Job is still in progress, retrying...");
      } else {
        print("Polling failed: ${response.statusCode}");
      }

      // Wait for a few seconds before polling again
      await Future.delayed(Duration(seconds: 5));
    }

    return null;
  }

  Future<void> _saveToFirestore(String url, String name) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('musics').add({
        'uid': user.uid,
        'uri': url,
        'name': name,
        'isLiked': false,
      });
    } else {
      print('No user is signed in');
    }
  }

  void _addMusicMessage(String url, String prompt) {
    final musicMessage = types.CustomMessage(
      author: types.User(
        id: 'muziker_ai',
        firstName: 'Muziker',
        lastName: 'AI',
        imageUrl: 'assets/logo.png',
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      metadata: {
        'type': 'audio',
        'url': url,
        'name': prompt,
      },
    );

    print(url);
    _addMessage(musicMessage);
  }

  List<Map<String, dynamic>> _calculateWeights(List<String> messages, String weightMethod) {
    int n = messages.length;
    List<Map<String, dynamic>> weightedMessages = [];
    print(messages);
    for (int i = 0; i < n; i++) {
      double weight;
      switch (weightMethod) {
        case 'logarithmic':
          weight = log(n - i + 1);
          break;
        case 'exponential':
          weight = pow(2, n - i - 1) / (pow(2, n) - 1);
          break;
        case 'balanced':
        default:
          weight = (n - i) / ((n * (n + 1)) / 2);
          break;
      }
      weightedMessages.add({
        'text': messages[i],
        'weight': weight,
      });
    }
    return weightedMessages;
  }

  void _loadInitialMessage() async {
    final random = Random();
    final response = await rootBundle.loadString('assets/messages.json');
    final List initialMessages = jsonDecode(response);
    int randomIndex = random.nextInt(initialMessages.length);
    var selectedMessage = initialMessages[randomIndex];

    var initialMessage;
    if (selectedMessage['type'] == 'text') {
      initialMessage = types.TextMessage(
        author: types.User(
          id: selectedMessage['author']['id'],
          firstName: selectedMessage['author']['firstName'],
          lastName: selectedMessage['author']['lastName'],
          imageUrl: selectedMessage['author']['imageUrl'],
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch, // dynamic date
        id: selectedMessage['id'],
        text: selectedMessage['text'],
        type: types.MessageType.text,
      );
    } else if (selectedMessage['type'] == 'custom' && selectedMessage['metadata']['type'] == 'audio') {
      initialMessage = types.CustomMessage(
        author: types.User(
          id: selectedMessage['author']['id'],
          firstName: selectedMessage['author']['firstName'],
          lastName: selectedMessage['author']['lastName'],
          imageUrl: selectedMessage['author']['imageUrl'],
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch, // dynamic date
        id: selectedMessage['id'],
        metadata: {
          'type': 'audio',
          'url': selectedMessage['metadata']['url'],
        },
      );
    }

    if (initialMessage != null) {
      _addMessage(initialMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Accessing the current theme data from ThemeManager
    final themeManager = Provider.of<ThemeManager>(context);
    final chatTheme = DefaultChatTheme(
      inputBackgroundColor: themeManager.themeData.inputDecorationTheme.fillColor ?? Color(0xFF7B2CBF)!,
      backgroundColor: themeManager.themeData.scaffoldBackgroundColor,
      sentMessageBodyTextStyle: TextStyle(color: themeManager.themeData.colorScheme.onPrimary),
      sentMessageCaptionTextStyle: TextStyle(color: themeManager.themeData.colorScheme.onPrimary),
      sentMessageDocumentIconColor: themeManager.themeData.primaryColor,
      primaryColor: themeManager.themeData.primaryColor,
      secondaryColor: themeManager.themeData.colorScheme.secondary,
      receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
      receivedMessageCaptionTextStyle: TextStyle(color: themeManager.themeData.colorScheme.onSecondary),
      receivedMessageDocumentIconColor: themeManager.themeData.colorScheme.inverseSurface,
      inputTextColor: Colors.white,
      inputTextCursorColor: themeManager.themeData.primaryColor,
      dateDividerTextStyle: TextStyle(color: Colors.white),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Muziker')),
      body: Chat(
        messages: _messages,
        onAttachmentPressed: _handleAttachmentPressed,
        onMessageTap: _handleMessageTap,
        onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        showUserAvatars: true,
        showUserNames: true,
        user: _user,
        theme: chatTheme,
        customMessageBuilder: _buildCustomMessage,
      ),
    );
  }

  Widget _buildCustomMessage(types.CustomMessage message, {required int messageWidth}) {
    if (message.metadata?['type'] == 'audio') {
      final String url = message.metadata!['url'];
      final bool isAsset = url.startsWith('assets/');
      return AudioPlayerWidget(url: url, isAsset: isAsset);
    }
    return const SizedBox.shrink();
  }
}
