import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/schedule_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiKeyCtrl;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController(text: context.read<ScheduleProvider>().apiKey);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: AppTheme.surface),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'AI Configuration', icon: Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          _Card(children: [
            const Text('Anthropic API Key',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Required to generate AI schedules. Get your key at console.anthropic.com',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppTheme.textMuted, size: 20,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
              onChanged: (v) => provider.setApiKey(v),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x1AEF9F27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your API key is stored locally on your device and never shared.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Working Hours', icon: Icons.schedule_rounded),
          const SizedBox(height: 12),
          _Card(children: [
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start time', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  _TimeBtn(time: provider.startTime, onChanged: (t) => provider.setStartTime(t)),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('End time', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  _TimeBtn(time: provider.endTime, onChanged: (t) => provider.setEndTime(t)),
                ],
              )),
            ]),
          ]),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Break Preferences', icon: Icons.coffee_outlined),
          const SizedBox(height: 12),
          _Card(children: [
            const Text('Break duration',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...[0, 15, 30, 45, 60].map((mins) => _BreakOption(
              minutes: mins,
              selected: provider.breakDuration,
              onTap: () => provider.setBreakDuration(mins),
            )),
          ]),
          const SizedBox(height: 24),
          _SectionHeader(title: 'About', icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _Card(children: [
            _AboutRow(label: 'App', value: 'Schedule AI'),
            const Divider(height: 20),
            _AboutRow(label: 'Version', value: '1.0.0'),
            const Divider(height: 20),
            _AboutRow(label: 'AI Model', value: 'Claude claude-opus-4-5'),
            const Divider(height: 20),
            _AboutRow(label: 'Built with', value: 'Flutter + Anthropic API'),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 8),
      Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.8)),
    ]);
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String time;
  final ValueChanged<String> onChanged;
  const _TimeBtn({required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = time.split(' ');
        final tp = parts[0].split(':');
        int h = int.parse(tp[0]);
        final m = int.parse(tp[1]);
        final isPm = parts.length > 1 && parts[1] == 'PM';
        if (isPm && h != 12) h += 12;
        if (!isPm && h == 12) h = 0;
        final result = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: h, minute: m),
        );
        if (result != null) {
          final hh = result.hourOfPeriod == 0 ? 12 : result.hourOfPeriod;
          final ampm = result.period == DayPeriod.am ? 'AM' : 'PM';
          onChanged('$hh:${result.minute.toString().padLeft(2, '0')} $ampm');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x106C5CE7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x336C5CE7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            const Icon(Icons.edit_rounded, size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _BreakOption extends StatelessWidget {
  final int minutes;
  final int selected;
  final VoidCallback onTap;
  const _BreakOption({required this.minutes, required this.selected, required this.onTap});

  String get label => minutes == 0 ? 'No breaks' : '$minutes min break';

  @override
  Widget build(BuildContext context) {
    final isSelected = minutes == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x106C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderColor),
        ),
        child: Row(children: [
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
        ]),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ],
    );
  }
}
