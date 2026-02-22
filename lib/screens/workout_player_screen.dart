import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../services/routine_service.dart';
import '../services/workout_manager.dart';

const Color clubOrange = Color(0xFFF57809);
const Color darkBg = Color(0xFF0B0B0F);

// =====================
// TYPO (cohérence Progrès)
// =====================
const TextStyle kScreenTitle = TextStyle(
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.w900,
  fontStyle: FontStyle.italic,
  letterSpacing: 0.4,
);

const TextStyle kSectionTitle = TextStyle(
  color: Colors.white,
  fontSize: 18,
  fontWeight: FontWeight.w900,
  fontStyle: FontStyle.italic,
  letterSpacing: -0.2,
);

const TextStyle kLabelSmall = TextStyle(
  color: Colors.white54,
  fontSize: 10,
  fontWeight: FontWeight.w900,
  letterSpacing: 1.1,
);

const TextStyle kMeta = TextStyle(
  color: Colors.white70,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

const TextStyle kButtonText = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w900,
  fontSize: 12,
  letterSpacing: 0.8,
);

class WorkoutPlayerScreen extends StatefulWidget {
  final int routineId;
  final String routineName;

  const WorkoutPlayerScreen({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // On initialise le manager au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = Provider.of<WorkoutManager>(context, listen: false);
      _initializeSession(manager);
    });
  }

  void _initializeSession(WorkoutManager manager) async {
    // Si la séance n'est pas déjà active ou si c'est une différente, on charge les données
    if (!manager.isActive || manager.routineId != widget.routineId) {
      final data = await RoutineService().getRoutineDetails(widget.routineId);
      if (data != null && data['templateExercises'] != null) {
        manager.startOrResumeWorkout(
          widget.routineId,
          widget.routineName,
          data['templateExercises'],
        );
      }
    }
  }

  String _formatTime(int s) =>
      "${(s ~/ 60).toString().padLeft(2, '0')}min ${(s % 60).toString().padLeft(2, '0')}s";

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<WorkoutManager>(context);

    return Scaffold(
      backgroundColor: darkBg,
      body: manager.dynamicExercises.isEmpty
          ? const Center(child: CircularProgressIndicator(color: clubOrange))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(manager),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 22,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, exIndex) =>
                          _buildExerciseSection(manager, exIndex),
                      childCount: manager.dynamicExercises.length,
                    ),
                  ),
                ),
                _buildBottomButtons(manager),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(WorkoutManager manager) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: darkBg,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildTopFinishBtn(manager),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              "https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=1000",
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, darkBg],
                ),
              ),
            ),

            // ✅ TITRE / SOUS-TITRE (lisible, cohérent)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.routineName.toUpperCase(), style: kScreenTitle),
                    const SizedBox(height: 6),
                    const Text("SUIVI DE SÉANCE", style: kLabelSmall),
                  ],
                ),
              ),
            ),

            // ✅ STATS en bas
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: "CHRONO",
                    value: _formatTime(manager.seconds),
                    valueColor: clubOrange,
                  ),
                  _StatItem(
                    label: "VOLUME",
                    value: "${manager.calculateTotalVolume().toInt()} kg",
                  ),
                  _StatItem(
                    label: "SÉRIES",
                    value: "${manager.totalCompletedSets}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection(WorkoutManager manager, int exIndex) {
    final ex = manager.dynamicExercises[exIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ex['exercise']['name'].toString().toUpperCase(),
          style: kSectionTitle,
        ),
        const SizedBox(height: 12),
        _buildLogHeader(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(
              ex['sets'] ?? 0,
              (setIndex) => _buildSetRow(
                manager,
                exIndex,
                setIndex,
                ex['reps']?.toString() ?? "0",
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildGlassActionBtn(
          "+ Ajouter une série",
          clubOrange.withOpacity(0.14),
          textColor: Colors.white,
          icon: Icons.add_rounded,
          onTap: () => manager.addNewSet(exIndex),
        ),
        const SizedBox(height: 34),
      ],
    );
  }

  Widget _buildLogHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("SÉRIE", style: kLabelSmall)),
          Expanded(flex: 2, child: Text("PRÉCÉDENT", style: kLabelSmall)),
          Expanded(flex: 2, child: Text("KG", style: kLabelSmall)),
          Expanded(flex: 2, child: Text("REPS", style: kLabelSmall)),
          SizedBox(
            width: 35,
            child: Center(
              child: Icon(Icons.done_all, color: Colors.white38, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(
    WorkoutManager manager,
    int exIndex,
    int setIndex,
    String defaultReps,
  ) {
    String prefix = "${exIndex}_$setIndex";
    bool isDone = manager.completedSets["${prefix}_done"] ?? false;

    return Slidable(
      key: Key("set_${exIndex}_$setIndex"),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => manager.removeSet(exIndex, setIndex),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDone
              ? clubOrange.withOpacity(0.18)
              : (setIndex % 2 == 0
                    ? Colors.white.withOpacity(0.04)
                    : Colors.transparent),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                "${setIndex + 1}",
                style: TextStyle(
                  color: isDone ? clubOrange : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 20,
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(right: 8),
            ),
            const Expanded(flex: 2, child: Text("—", style: kMeta)),
            StableInput(
              initialValue: manager.workoutData["${prefix}_kg"] ?? "",
              hint: "10",
              isLocked: isDone,
              onChanged: (v) => manager.updateSetData("${prefix}_kg", v),
            ),
            StableInput(
              initialValue:
                  manager.workoutData["${prefix}_reps"] ?? defaultReps,
              hint: defaultReps,
              isLocked: isDone,
              onChanged: (v) => manager.updateSetData("${prefix}_reps", v),
            ),
            InkWell(
              onTap: () => manager.toggleSetDone("${prefix}_done"),
              child: SizedBox(
                width: 35,
                child: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_off,
                  color: isDone ? clubOrange : Colors.white38,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(WorkoutManager manager) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Row(
          children: [
            Expanded(
              child: _buildGlassActionBtn(
                "Paramètres",
                Colors.white.withOpacity(0.08),
                icon: Icons.settings,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassActionBtn(
                "Abandonner",
                Colors.redAccent.withOpacity(0.18),
                icon: Icons.delete_outline,
                onTap: () {
                  manager.stopWorkout();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassActionBtn(
    String label,
    Color color, {
    Color textColor = Colors.white,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, color: textColor.withOpacity(0.9), size: 16),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: kButtonText.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFinishBtn(WorkoutManager manager) {
    return InkWell(
      onTap: () async {
        await manager.finishWorkout(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: clubOrange,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: clubOrange.withOpacity(0.35), blurRadius: 12),
          ],
        ),
        child: const Text("TERMINER", style: kButtonText),
      ),
    );
  }
}

class StableInput extends StatefulWidget {
  final String initialValue;
  final String hint;
  final bool isLocked;
  final Function(String) onChanged;

  const StableInput({
    super.key,
    required this.initialValue,
    required this.hint,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  State<StableInput> createState() => _StableInputState();
}

class _StableInputState extends State<StableInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    String displayValue =
        (widget.initialValue == "0" || widget.initialValue == "")
        ? ""
        : widget.initialValue;
    _controller = TextEditingController(text: displayValue);
  }

  @override
  void didUpdateWidget(StableInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text &&
        !FocusScope.of(context).hasFocus) {
      _controller.text = (widget.initialValue == "0")
          ? ""
          : widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: widget.isLocked
              ? Colors.black45
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isLocked
                ? clubOrange.withOpacity(0.45)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: TextField(
          controller: _controller,
          enabled: !widget.isLocked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isLocked ? clubOrange : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
          onChanged: (value) => widget.onChanged(value.isEmpty ? "0" : value),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        const Text("", style: TextStyle(fontSize: 0)), // garde l'espace stable
        Text(label, style: kLabelSmall),
      ],
    );
  }
}
