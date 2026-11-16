import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/member_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../data/today_provider.dart';
import '../../core/prayer_times.dart';
import '../home/widgets/together_arc.dart';
import 'widgets.dart';
import '../../core/haptics.dart';
import '../../core/confetti.dart';
import '../../core/ui.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

enum _Mode { choose, invite, join, recolor, done }

/// Invite a partner, join with a code, or go solo. Used in onboarding and from the home menu.
class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key, this.onBack, this.onboarding = false});
  final VoidCallback? onBack;
  final bool onboarding;

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  _Mode _mode = _Mode.choose;
  String? _code;
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  UserProfile? _partner;
  Color? _newColor;

  String get _uid => ref.read(authUserProvider).value!.uid;
  Repository get _repo => ref.read(repositoryProvider);

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.onboarding) {
      if (mounted) setState(() => _mode = _Mode.done);
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _invite() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final me = ref.read(myProfileProvider).value;
      _code = me?.pairId ?? await _repo.createInvite(_uid, name: me?.nickname ?? '', color: (me?.color ?? memberPalette.first).toARGB32());
      _mode = _Mode.invite;
    } catch (e) {
      _error = 'Couldn\'t create a code. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Codes are 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await _repo.pairInfo(code);
      if (info == null) throw const PairError('No partner found with that code. Check it and try again.');
      if (info.members.contains(_uid)) throw const PairError('That\'s your own code. Send it to your partner instead.');
      if (info.members.length >= 2) throw const PairError('That code is already used by a pair.');
      if (info.members.isNotEmpty) {
        _partner = UserProfile(uid: info.members.first, nickname: info.ownerName, color: Color(info.ownerColor));
        final mine = ref.read(myProfileProvider).value?.color ?? memberPalette.first;
        if (isTooSimilar(mine, _partner!.color)) {
          // Prevent a clash: pick a different color before joining.
          _newColor = memberPalette.firstWhere((c) => !isTooSimilar(c, _partner!.color));
          setState(() => _mode = _Mode.recolor);
          return;
        }
      }
      await _join(code);
    } on PairError catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Couldn\'t join. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join(String code) async {
    if (_newColor != null) await _repo.saveProfile(_uid, {'color': _newColor!.toARGB32()});
    await _repo.joinPair(_uid, code);
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _Mode.choose => _choose(),
      _Mode.invite => _inviteView(),
      _Mode.join => _joinView(),
      _Mode.recolor => _recolorView(),
      _Mode.done => _doneView(),
    };
  }

  Widget _choose() {
    return StepFrame(
      step: widget.onboarding ? 3 : null,
      eyebrow: widget.onboarding ? 'Last step · Your suhbah' : null,
      title: "Who's on the\nother side?",
      subtitle: "A spouse, a sibling, a close friend. You'll see each other's progress live.",
      onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Builder(
            builder: (context) {
              final me = ref.watch(myProfileProvider).value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Seats(myName: me?.nickname ?? '', myColor: me?.color ?? AppColors.memberA),
              );
            },
          ),
          _Option(icon: Icons.favorite_rounded, title: 'Invite someone', body: 'Send a 6-letter code', onTap: _busy ? null : _invite, primary: true),
          const SizedBox(height: 10),
          _Option(
            icon: Icons.key_rounded,
            title: 'I have a code',
            body: 'Join someone who invited you',
            onTap: () => setState(() => _mode = _Mode.join),
          ),
          if (widget.onboarding) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _finish,
                child: Text(
                  "I'll start on my own",
                  style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.memberA),
                ),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: AppText.body(size: 13, color: AppColors.sub)),
            ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(16)),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '"A man is upon the religion of his close friend, so let each of you look at whom he befriends."',
                    style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.pillInk, height: 1.5),
                  ),
                  TextSpan(
                    text: '\nSunan Abi Dawud',
                    style: AppText.body(size: 11.5, color: AppColors.pillInk.withValues(alpha: .7), height: 1.9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const storeUrl = 'https://play.google.com/store/apps/details?id=com.ornobaadi.suhbah';

  /// The Play link with the code riding along, so scanning the QR in Suhbah fills the code,
  /// and scanning it with a phone camera opens the store.
  String get _inviteLink => '$storeUrl&referrer=code%3D$_code';

  String get _inviteText =>
      'Assalamu alaikum! Join me on Suhbah so we can pray together and fill one arc.\n\n'
      '1. Get Suhbah: $storeUrl\n'
      '2. Open it, tap "I have a code" and enter: $_code';

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _code ?? ''));
    HapticFeedback.selectionClick();
    if (mounted) toast(context, 'Code copied');
  }

  Future<void> _share() => SharePlus.instance.share(ShareParams(text: _inviteText, subject: 'Join me on Suhbah'));

  void _showQr() => showAppSheet<void>(
    context,
    title: 'Scan to join',
    subtitle: 'In Suhbah they tap "I have a code", then "Scan QR code". No app yet? Their phone camera opens the Play Store.',
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            QrImageView(
              data: _inviteLink,
              size: 220,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Text(_code ?? '', style: AppText.display(size: 22, spacing: 5)),
          ],
        ),
      ),
    ),
  );

  Widget _inviteView() {
    final partner = ref.watch(partnerProfileProvider).value;
    final me = ref.watch(myProfileProvider).value;
    final joined = ref.watch(partnerUidProvider).value != null;
    ref.listen(partnerUidProvider, (prev, next) {
      if (prev?.value == null && next.value != null) {
        Haptics.success();
        _repo.saveProfile(_uid, {'metPartner': next.value});
      }
    });
    final myColor = me?.color ?? AppColors.memberA;
    final theirColor = partner == null ? AppColors.memberB : displayPartnerColor(myColor, partner.color);
    final name = partner?.nickname ?? 'Partner';

    return Stack(
      children: [
        StepFrame(
          title: joined ? '$name joined you' : 'Send them\nthis code',
          subtitle: joined
              ? 'Your arc now fills from both sides. May Allah bless your suhbah.'
              : "They tap \"I have a code\" and type it in. Start logging now; they'll show up the moment they join.",
          onBack: () => setState(() => _mode = _Mode.choose),
          primaryLabel: joined ? (widget.onboarding ? 'Start together' : 'Done') : (widget.onboarding ? 'Go to today' : 'Done'),
          onPrimary: _finish,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Seats(myName: me?.nickname ?? '', myColor: myColor, partner: joined ? (name, theirColor) : null),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(a), child: c),
                  ),
                  child: joined ? _pairedCard(me?.nickname ?? 'You', myColor, name, theirColor) : _codeCard(),
                ),
              ],
            ),
          ),
        ),
        if (joined)
          Positioned.fill(
            child: ConfettiBurst(key: const ValueKey('paired'), colors: [myColor, theirColor, AppColors.flameTop]),
          ),
      ],
    );
  }

  Widget _codeCard() => Column(
    key: const ValueKey('code'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text('YOUR CODE', style: AppText.label(size: 10.5)),
            const SizedBox(height: 6),
            FlipCode(code: _code ?? ''),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyCode,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: const Text('Copy code'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _ShareTile(icon: Icons.ios_share_rounded, label: 'Share invite', body: 'WhatsApp, Messenger…', onTap: _share),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShareTile(icon: Icons.qr_code_2_rounded, label: 'Show QR', body: 'For someone nearby', onTap: _showQr),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6, color: AppColors.sub)),
          const SizedBox(width: 10),
          Text('Waiting for them to join…', style: AppText.body(size: 13, color: AppColors.sub)),
        ],
      ),
    ],
  );

  Widget _pairedCard(String myName, Color mine, String theirName, Color theirs) => Container(
    key: const ValueKey('paired'),
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [mine.withValues(alpha: .12), theirs.withValues(alpha: .12)]),
      border: Border.all(color: theirs.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        Text('$myName & $theirName', textAlign: TextAlign.center, style: AppText.display(size: 21, spacing: -.3)),
        const SizedBox(height: 4),
        Text('One arc, two halves', style: AppText.body(size: 13, color: AppColors.sub)),
      ],
    ),
  );

  /// Last onboarding screen: the arc fills all the way, the next prayer, and in.
  Widget _doneView() {
    final me = ref.watch(myProfileProvider).value;
    final partner = ref.watch(partnerProfileProvider).value;
    final myColor = me?.color ?? AppColors.memberA;
    final theirColor = partner == null ? null : displayPartnerColor(myColor, partner.color);
    final next = me != null && me.hasLocation
        ? nextPrayerAfter(lat: me.lat!, lng: me.lng!, method: me.method, asr: me.asr, now: DateTime.now())
        : null;
    return StepFrame(
      title: "You're all set,\n${me?.nickname ?? 'friend'}.",
      subtitle: "Tap a prayer when you've prayed it. That's the whole app.",
      primaryLabel: 'Open Today',
      busy: _busy,
      onPrimary: () async {
        setState(() => _busy = true);
        try {
          await _repo.saveProfile(_uid, {'onboarded': true}); // AuthGate moves to home
        } catch (_) {
          if (mounted) toast(context, "Couldn't save. Check your connection and try again.");
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: TogetherArc(
                    left: 1,
                    right: 1,
                    colorLeft: myColor,
                    colorRight: theirColor ?? myColor,
                    percent: 100,
                    label: theirColor == null ? 'MY DAY' : 'TOGETHER',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (next != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
                    decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFE9A21B)),
                        const SizedBox(width: 8),
                        Text(
                          'Next up: ${next.prayer.label}${next.tomorrow ? ' tomorrow' : ''} at ${TimeOfDay.fromDateTime(next.at).format(context)}',
                          style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.pillInk),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Positioned.fill(child: ConfettiBurst(colors: [myColor, ?theirColor, AppColors.flameTop])),
        ],
      ),
    );
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScanCodeScreen()));
    if (code == null || !mounted) return;
    _codeCtrl.text = code;
    Haptics.tap();
    _checkCode();
  }

  Widget _joinView() {
    return StepFrame(
      title: 'Enter their code',
      subtitle: 'Ask your partner for the 6-character code from their app.',
      onBack: () => setState(() {
        _mode = _Mode.choose;
        _error = null;
      }),
      primaryLabel: 'Join',
      busy: _busy,
      onPrimary: _checkCode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            autofocus: true,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: AppText.display(size: 30, spacing: 6),
            onSubmitted: (_) => _checkCode(),
            decoration: InputDecoration(
              hintText: 'ABC234',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan QR code'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null) Text(_error!, style: AppText.body(size: 13, color: AppColors.memberB)),
        ],
      ),
    );
  }

  Widget _recolorView() {
    final p = _partner!;
    return StepFrame(
      title: 'Pick your color for this pair',
      subtitle: '${p.nickname} already uses a color close to yours. Choose one that stands apart so your halves of the arc are easy to tell.',
      onBack: () => setState(() => _mode = _Mode.join),
      primaryLabel: 'Join ${p.nickname}',
      busy: _busy,
      onPrimary: () async {
        setState(() => _busy = true);
        try {
          await _join(_codeCtrl.text.trim().toUpperCase());
        } on PairError catch (e) {
          setState(() => _error = e.message);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      child: SingleChildScrollView(
        child: ColorGrid(selected: _newColor!, onSelect: (c) => setState(() => _newColor = c), takenBy: (p.color, p.nickname)),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.body, this.onTap, this.primary = false});
  final IconData icon;
  final String title, body;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : AppColors.ink;
    return Material(
      color: primary ? AppColors.ink : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: primary ? BorderSide.none : const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: primary ? Colors.white.withValues(alpha: .14) : AppColors.pill, shape: BoxShape.circle),
                child: Icon(icon, color: primary ? Colors.white : AppColors.pillInk, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.body(size: 15, weight: FontWeight.w700, color: fg),
                    ),
                    Text(body, style: AppText.body(size: 12.5, color: primary ? Colors.white.withValues(alpha: .7) : AppColors.sub)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primary ? Colors.white : AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.icon, required this.label, required this.body, required this.onTap});
  final IconData icon;
  final String label, body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: AppColors.pillInk),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 14, weight: FontWeight.w700),
            ),
            Text(
              body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 12, color: AppColors.sub),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Reads a 6-character code from an invite QR (the Play link with code=XXXXXX,
/// or a bare code).
String? codeFromScan(String raw) {
  final m =
      RegExp(r'code(?:%3D|=)([A-Za-z0-9]{6})').firstMatch(raw) ??
      RegExp(r'^\s*([A-Za-z0-9]{6})\s*$').firstMatch(raw) ??
      RegExp(r':\s*([A-Z0-9]{6})\s*$').firstMatch(raw);
  return m?.group(1)?.toUpperCase();
}

class ScanCodeScreen extends StatefulWidget {
  const ScanCodeScreen({super.key});
  @override
  State<ScanCodeScreen> createState() => _ScanCodeScreenState();
}

class _ScanCodeScreenState extends State<ScanCodeScreen> {
  bool _done = false;
  String? _hint;

  void _onDetect(BarcodeCapture cap) {
    if (_done) return;
    for (final b in cap.barcodes) {
      final code = codeFromScan(b.rawValue ?? '');
      if (code != null) {
        _done = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
    setState(() => _hint = "That QR isn't a Suhbah invite. Try the one on their invite screen.");
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text('Scan their code', style: AppText.display(size: 18, color: Colors.white)),
    ),
    body: Stack(
      children: [
        MobileScanner(
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Suhbah needs the camera to scan. Allow camera access in settings, or go back and type the code.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 15, color: Colors.white, height: 1.5),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            _hint ?? 'Point at the QR on their invite screen.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 14, color: Colors.white, weight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
