import 'dart:async';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'file_provider.dart';
import 'settings_provider.dart';
import 'history_provider.dart';
import 'package:flutter/foundation.dart';
import '../src/native/image_processor_bindings.dart';

/// 图像处理参数模型
class ProcessingParams {
  final String inputPath;
  final String outputPath;
  final int width;
  final int height;
  final int quality;
  final int format;

  // Watermark
  final bool enableWm;
  final int wmType;
  final String wmText;
  final String? wmImagePath;
  final double wmOpacity;
  final int wmPosition;
  final double wmScale;
  final int wmFontSize;
  final double wmSpacing;

  ProcessingParams({
    required this.inputPath,
    required this.outputPath,
    required this.width,
    required this.height,
    required this.quality,
    required this.format,
    this.enableWm = false,
    this.wmType = 0,
    this.wmText = '',
    this.wmImagePath,
    this.wmOpacity = 0.5,
    this.wmPosition = 0,
    this.wmScale = 0.2,
    this.wmFontSize = 40,
    this.wmSpacing = 1.0,
  });
}

/// 线程池任务协议
class WorkerTask {
  final ProcessingParams params;
  final int workerId;
  final int sessionId; // 用于校验任务有效性
  WorkerTask(this.params, this.workerId, this.sessionId);
}

/// 线程池响应协议
class WorkerResponse {
  final int workerId;
  final int result;
  final int sessionId;
  WorkerResponse(this.workerId, this.result, this.sessionId);
}

/// 子线程入口函数
void _isolateEntry(SendPort mainSendPort) {
  final childReceivePort = ReceivePort();
  mainSendPort.send(childReceivePort.sendPort);

  childReceivePort.listen((message) {
    if (message is WorkerTask) {
      try {
        final res = imageProcessor.process(
          message.params.inputPath,
          message.params.outputPath,
          message.params.width,
          message.params.height,
          message.params.quality,
          message.params.format,
          message.params.enableWm,
          message.params.wmType,
          message.params.wmText,
          message.params.wmImagePath,
          message.params.wmOpacity,
          message.params.wmPosition,
          message.params.wmScale,
          message.params.wmFontSize,
          message.params.wmSpacing,
        );
        mainSendPort.send(WorkerResponse(message.workerId, res, message.sessionId));
      } catch (e, stack) {
        // 在子线程打印错误，这通常会出现在调试控制台中
        print('--- ISOLATE ERROR ---');
        print('Exception: $e');
        print('Stack: $stack');
        print('---------------------');
        mainSendPort.send(WorkerResponse(message.workerId, -99, message.sessionId));
      }
    }
  });
}

class ProcessingState {
  final bool isProcessing;
  final bool isPaused;
  final bool isInitializing;
  final double progress;
  final int current;
  final int total;
  final int failCount;
  final String currentFileName;

  ProcessingState({
    this.isProcessing = false,
    this.isPaused = false,
    this.isInitializing = false,
    this.progress = 0.0,
    this.current = 0,
    this.total = 0,
    this.failCount = 0,
    this.currentFileName = '',
  });

  ProcessingState copyWith({
    bool? isProcessing,
    bool? isPaused,
    bool? isInitializing,
    double? progress,
    int? current,
    int? total,
    int? failCount,
    String? currentFileName,
  }) {
    return ProcessingState(
      isProcessing: isProcessing ?? this.isProcessing,
      isPaused: isPaused ?? this.isPaused,
      isInitializing: isInitializing ?? this.isInitializing,
      progress: progress ?? this.progress,
      current: current ?? this.current,
      total: total ?? this.total,
      failCount: failCount ?? this.failCount,
      currentFileName: currentFileName ?? this.currentFileName,
    );
  }
}

class ProcessingNotifier extends Notifier<ProcessingState> {
  final List<Isolate> _isolates = [];
  final List<SendPort> _workerSendPorts = [];
  final List<bool> _workerBusyStatus = []; // 追踪是否忙碌
  final List<SelectedFile> _queue = [];
  final Map<int, SelectedFile> _processingFiles = {}; // 正在处理的文件
  
  ReceivePort? _receivePort;
  int _currentSessionId = 0; // 每批任务唯一 ID
  int _finishedCount = 0;
  int _totalCount = 0;
  DateTime? _startTime;
  ProcessingSettings? _settings;

  @override
  ProcessingState build() {
    ref.onDispose(() => _cleanupPool());
    return ProcessingState();
  }

  void _cleanupPool({bool isPausing = false}) {
    for (var iso in _isolates) {
      iso.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _workerSendPorts.clear();
    _workerBusyStatus.clear();
    
    if (isPausing) {
      // 将正在处理的文件放回队列头部，确保恢复时重新处理
      final activeFiles = _processingFiles.values.toList();
      _queue.insertAll(0, activeFiles);
    }
    _processingFiles.clear();
    
    _receivePort?.close();
    _receivePort = null;
  }

  Future<void> togglePause() async {
    if (state.isInitializing || !state.isProcessing) return;

    final willPause = !state.isPaused;
    state = state.copyWith(isPaused: willPause);

    if (willPause) {
      _cleanupPool(isPausing: true);
    } else {
      state = state.copyWith(isInitializing: true, progress: 0.0);
      try {
        final poolSize = _getOptimalPoolSize(Platform.numberOfProcessors, _queue.length);
        await _initPool(poolSize);
      } finally {
        state = state.copyWith(isInitializing: false);
      }
      _dispatchToAllIdle();
    }
  }

  void stop() {
    _currentSessionId++; // 变更 ID，立使所有在途消息失效
    _queue.clear();
    _cleanupPool();
    state = ProcessingState();
  }

  Future<void> _initPool(int size) async {
    _cleanupPool();
    _receivePort = ReceivePort();
    
    // 监听所有 Worker 的统一返回端口
    _receivePort!.listen((message) {
      if (message is SendPort) {
        _workerSendPorts.add(message);
        _workerBusyStatus.add(false);
      } else if (message is WorkerResponse) {
        _handleResponse(message);
      }
    });

    // 第一阶段：生成 Isolate (占 50% 进度)
    for (int i = 0; i < size; i++) {
      state = state.copyWith(
        currentFileName: 'Launching engine ${i + 1}/$size...',
        progress: (i + 1) / (size * 2),
      );
      final isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);
      _isolates.add(isolate);
    }

    // 第二阶段：等待握手完成 (占 50% 进度)
    while (_workerSendPorts.length < size) {
      state = state.copyWith(
        currentFileName: 'Handshaking with engines (${_workerSendPorts.length}/$size)...',
        progress: 0.5 + (_workerSendPorts.length / (size * 2)),
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _handleResponse(WorkerResponse response) {
    // 如果 SessionID 不匹配，说明任务已被取消或重置，直接忽略
    if (response.sessionId != _currentSessionId) return;
    
    // 安全检查：如果 WorkerID 超出当前状态列表，说明状态已重置
    if (response.workerId >= _workerBusyStatus.length) return;

    _workerBusyStatus[response.workerId] = false;
    _processingFiles.remove(response.workerId);
    _finishedCount++;
    
    final isError = response.result != 0;
    if (isError) {
      debugPrint('  ERROR: Native process returned ${response.result}');
    }
    
    state = state.copyWith(
      progress: _finishedCount / _totalCount,
      failCount: isError ? state.failCount + 1 : state.failCount,
    );

    if (_finishedCount >= _totalCount) {
      // 记录历史
      if (_startTime != null) {
        final duration = DateTime.now().difference(_startTime!);
        ref.read(historyProvider.notifier).add(HistoryItem(
          timestamp: DateTime.now(),
          count: _totalCount - state.failCount,
          targetDir: _settings?.customOutputPath ?? 'Default Output',
          duration: duration,
        ));
      }

      final statusMsg = state.failCount > 0 
          ? 'Done (with ${state.failCount} errors)' 
          : 'Done';
      state = state.copyWith(isProcessing: false, currentFileName: statusMsg);
      _cleanupPool();
    } else {
      _dispatchToWorker(response.workerId); // 派发下一个
    }
  }

  /// 计算最优线程池大小
  /// 优化目标：在高性能处理与 UI 流畅度之间取得平衡。
  /// [itemCount]：当前待处理的任务总数，用于小批量任务优化。
  int _getOptimalPoolSize(int systemProcessors, int itemCount) {
    // 策略优化：如果处理数量少于 100 个，仅使用单线程处理。
    // 原因：Isolate 启动和握手是有开销的。对于小批量任务，启动多个 Isolate 的总耗时
    // 可能反而超过了单线程串行处理的时间，且单线程更省内存，UI 响应也更平滑。
    if (itemCount < 100) return 1;

    if (systemProcessors <= 2) return 1;
    if (systemProcessors <= 4) return systemProcessors - 1;
    if (systemProcessors <= 8) return systemProcessors - 2;

    // 对于 8 核以上（如 12核、16核）且可能存在虚拟机占用的情况：
    // 预留 3 个核心给系统/UI/虚拟机，工作线程上限严格控制在 6。
    // 经验证明：在桌面端，6 个并发 Isolate 已经能跑满大多数 SSD 的随机写带宽。
    final recommended = systemProcessors - 3;
    return recommended.clamp(1, 6);
  }



  Future<void> startBatch(List<SelectedFile> files, ProcessingSettings settings) async {
    if (files.isEmpty) return;

    _currentSessionId++;
    _finishedCount = 0;
    _totalCount = files.length;
    _settings = settings;
    _startTime = DateTime.now();
    _queue.clear();
    _queue.addAll(files);

    state = state.copyWith(
      isProcessing: true,
      isInitializing: true,
      isPaused: false,
      total: _totalCount,
      current: 0,
      progress: 0.0,
    );

    final poolSize = _getOptimalPoolSize(Platform.numberOfProcessors, _totalCount);
    await _initPool(poolSize);

    state = state.copyWith(isInitializing: false);
    _dispatchToAllIdle();
  }

  void _dispatchToAllIdle() {
    for (int i = 0; i < _workerSendPorts.length; i++) {
      _dispatchToWorker(i);
    }
  }

  void _dispatchToWorker(int workerId) {
    if (state.isPaused || _queue.isEmpty || _workerBusyStatus[workerId]) return;

    final file = _queue.removeAt(0);
    _processingFiles[workerId] = file;
    _workerBusyStatus[workerId] = true;
    
    // 更新序号
    final currentIdx = _totalCount - _queue.length;
    state = state.copyWith(
      current: currentIdx,
      currentFileName: file.name,
    );

    final params = _prepareParams(file, _settings!);
    debugPrint('Processing: ${params.inputPath} -> ${params.outputPath}');
    _workerSendPorts[workerId].send(WorkerTask(params, workerId, _currentSessionId));
  }

  ProcessingParams _prepareParams(SelectedFile file, ProcessingSettings settings) {
    final inputPath = p.normalize(file.file.path);
    late final String outputPath;

    if (settings.exportMode == ExportMode.newDirectory) {
      final String baseOutputDir;
      if (settings.customOutputPath != null) {
        baseOutputDir = p.normalize(settings.customOutputPath!);
      } else {
        // 默认在拖入项的同级创建 oku_output
        baseOutputDir = p.normalize(p.join(p.dirname(file.sourceRoot), 'oku_output'));
      }

      // 严格按照：输出根目录 + 相对路径 拼接
      final fullTargetFilePath = p.join(baseOutputDir, file.relativePath);
      final extension = settings.format.toString().split('.').last;
      outputPath = p.setExtension(fullTargetFilePath, '.$extension');
      
      final outputSubDir = p.dirname(outputPath);
      if (!Directory(outputSubDir).existsSync()) {
        Directory(outputSubDir).createSync(recursive: true);
      }
    } else {
      outputPath = inputPath;
    }

    debugPrint('Native Process Call:');
    debugPrint('  Input:  $inputPath');
    debugPrint('  Output: $outputPath');

    int targetW = settings.width;
    int targetH = settings.height;
    if (settings.lockAspectRatio) {
      if (settings.dimensionLock == DimensionLock.width) targetH = 0;
      else if (settings.dimensionLock == DimensionLock.height) targetW = 0;
    }

    return ProcessingParams(
      inputPath: inputPath,
      outputPath: outputPath,
      width: targetW,
      height: targetH,
      quality: (settings.quality * 100).toInt(),
      format: settings.format.index,
      enableWm: settings.enableWatermark,
      wmType: settings.watermarkType.index,
      wmText: settings.watermarkText,
      wmImagePath: settings.watermarkImagePath,
      wmOpacity: settings.watermarkOpacity,
      wmPosition: settings.watermarkPosition.index,
      wmScale: settings.watermarkScale,
      wmFontSize: settings.watermarkFontSize,
      wmSpacing: settings.watermarkSpacing,
    );
  }
}

final processingProvider = NotifierProvider<ProcessingNotifier, ProcessingState>(ProcessingNotifier.new);
