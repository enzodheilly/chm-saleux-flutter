import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../services/routine_service.dart';
import '../services/workout_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

const Color clubOrange = AppColors.accent;
const Color darkBg = AppColors.bg;

// =====================
// TYPO (cohérence Progrès)
// =====================
const TextStyle kScreenTitle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 24,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.4,
);

const TextStyle kSectionTitle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 18,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.2,
);

const TextStyle kLabelSmall = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.1,
);

const TextStyle kMeta = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

const TextStyle kButtonText = TextStyle(
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w800,
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
      "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  // ✅ LOGIQUE D'IMAGE LOCALE (ASSETS)
  String _getBackgroundImage() {
    final name = widget.routineName.toLowerCase().trim();
    if (name.contains("pec") ||
        name.contains("chest") ||
        name.contains("push")) {
      return "assets/images/pecs.jpg";
    }
    if (name.contains("dos") ||
        name.contains("back") ||
        name.contains("pull")) {
      return "assets/images/dos.jpg";
    }
    if (name.contains("jambe") ||
        name.contains("leg") ||
        name.contains("bas")) {
      return "assets/images/jambes.jpg";
    }
    if (name.contains("bras") ||
        name.contains("arm") ||
        name.contains("biceps") ||
        name.contains("triceps")) {
      return "assets/images/bras.jpg";
    }
    if (name.contains("epaule") || name.contains("épaule")) {
      return "assets/images/epaules.jpg";
    }
    if (name.contains("abdo") || name.contains("abs")) {
      return "assets/images/abdos.jpg";
    }
    if (name.contains("cardio") || name.contains("run")) {
      return "assets/images/cardio.jpg";
    }
    if (name.contains("mobil")) {
      return "assets/images/mobilite.jpg";
    }
    if (name.contains("perte") || name.contains("poids")) {
      return "assets/images/perte_poids.jpg";
    }
    if (name.contains("full") ||
        name.contains("body") ||
        name.contains("haut")) {
      return "assets/images/fullbody.jpg";
    }
    return "assets/images/default.jpg";
  }

  void _showVideoDemo(String exerciseName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          "Démo : $exerciseName",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: clubOrange,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "La vidéo de démonstration sera intégrée ici.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "FERMER",
              style: TextStyle(color: clubOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<WorkoutManager>(context);
    final bgImage = _getBackgroundImage();

    return Scaffold(
      backgroundColor: darkBg,
      body: manager.dynamicExercises.isEmpty
          ? const Center(child: CircularProgressIndicator(color: clubOrange))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(manager, bgImage),
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

  Widget _buildSliverAppBar(WorkoutManager manager, String bgImage) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: darkBg,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(Icons.close, color: AppColors.textPrimary, size: 18),
        ),
        // ✅ CORRECTION ICI : Retour à l'accueil
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: _buildTopFinishBtn(manager),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ GESTION IMAGE LOCALE
            bgImage.startsWith('http')
                ? Image.network(bgImage, fit: BoxFit.cover)
                : Image.asset(bgImage, fit: BoxFit.cover),

            // ✅ DÉGRADÉ PREMIUM PROFOND
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    darkBg.withOpacity(0.8),
                    darkBg,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.routineName.toUpperCase(), style: kScreenTitle),
                  ],
                ),
              ),
            ),

            // ✅ STATS MODERNISÉES
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      label: "CHRONO",
                      value: _formatTime(manager.seconds),
                      valueColor: clubOrange,
                      icon: Icons.timer_outlined,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.line,
                    ),
                    _StatItem(
                      label: "VOLUME",
                      value: "${manager.calculateTotalVolume().toInt()} kg",
                      icon: Icons.fitness_center_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.line,
                    ),
                    _StatItem(
                      label: "SÉRIES",
                      value: "${manager.totalCompletedSets}",
                      icon: Icons.layers_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection(WorkoutManager manager, int exIndex) {
    final ex = manager.dynamicExercises[exIndex];
    final exerciseName = ex['exercise']['name'].toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ HEADER EXERCICE AVEC BOUTON VIDEO
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(exerciseName.toUpperCase(), style: kSectionTitle),
            ),
            GhostButton(
              label: "Démo",
              icon: Icons.play_circle_outline_rounded,
              onPressed: () => _showVideoDemo(exerciseName),
              color: clubOrange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLogHeader(),

        // Conteneur des séries
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: List.generate(
              ex['sets'] ?? 0,
              (setIndex) => _buildSetRow(
                manager,
                exIndex,
                setIndex,
                ex['reps']?.toString() ?? "0",
                isLast: setIndex == (ex['sets'] - 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildGlassActionBtn(
          "+ Ajouter une série",
          clubOrange.withOpacity(0.15),
          textColor: clubOrange,
          icon: Icons.add_rounded,
          onTap: () => manager.addNewSet(exIndex),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLogHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("SÉRIE", style: kLabelSmall)),
          Expanded(flex: 2, child: Text("PRÉCÉDENT", style: kLabelSmall)),
          Expanded(flex: 2, child: Text("KG", style: kLabelSmall)),
          Expanded(flex: 2, child: Text("REPS", style: kLabelSmall)),
          SizedBox(
            width: 35,
            child: Center(
              child: Icon(Icons.done_all, color: AppColors.textSecondary, size: 14),
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
    String defaultReps, {
    required bool isLast,
  }) {
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
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.textPrimary,
            icon: Icons.delete_outline_rounded,
            borderRadius: isLast
                ? const BorderRadius.only(bottomRight: Radius.circular(AppRadius.md))
                : BorderRadius.zero,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDone ? clubOrange.withOpacity(0.1) : Colors.transparent,
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.line),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDone ? clubOrange : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  "${setIndex + 1}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDone ? AppColors.bg : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                  isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isDone ? clubOrange : AppColors.textSecondary.withOpacity(0.4),
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
                AppColors.surface,
                icon: Icons.settings_rounded,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassActionBtn(
                "Abandonner",
                AppColors.danger.withOpacity(0.08),
                textColor: AppColors.danger,
                icon: Icons.close_rounded,
                onTap: () {
                  manager.stopWorkout();
                  // ✅ CORRECTION ICI : Retour à l'accueil
                  Navigator.popUntil(context, (route) => route.isFirst);
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
    Color textColor = AppColors.textPrimary,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: textColor.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: textColor, size: 18),
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
    );
  }

  Widget _buildTopFinishBtn(WorkoutManager manager) {
    return InkWell(
      onTap: () async {
        await manager.finishWorkout(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: clubOrange,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Text("TERMINER", style: TextStyle(
          color: AppColors.bg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.8,
        )),
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
              ? AppColors.surface
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: widget.isLocked
                ? clubOrange.withOpacity(0.3)
                : AppColors.line,
            width: widget.isLocked ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: _controller,
          enabled: !widget.isLocked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isLocked ? clubOrange : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 13,
            ),
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
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: kLabelSmall),
      ],
    );
  }
}
