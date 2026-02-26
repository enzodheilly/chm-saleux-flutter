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
  fontSize: 24,
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
        backgroundColor: const Color(0xFF1C1C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Démo : $exerciseName",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
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
              style: TextStyle(color: Colors.white70),
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
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 18),
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                      color: Colors.white.withOpacity(0.1),
                    ),
                    _StatItem(
                      label: "VOLUME",
                      value: "${manager.calculateTotalVolume().toInt()} kg",
                      icon: Icons.fitness_center_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.1),
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
            GestureDetector(
              onTap: () => _showVideoDemo(exerciseName),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: clubOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "DÉMO",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLogHeader(),

        // Conteneur des séries
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C22),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
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
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            borderRadius: isLast
                ? const BorderRadius.only(bottomRight: Radius.circular(16))
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
              : Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
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
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${setIndex + 1}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w900,
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
                  color: isDone ? clubOrange : Colors.white24,
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
                Colors.white.withOpacity(0.05),
                icon: Icons.settings_rounded,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassActionBtn(
                "Abandonner",
                Colors.redAccent.withOpacity(0.1),
                textColor: Colors.redAccent,
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
    Color textColor = Colors.white,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: textColor.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, color: textColor.withOpacity(0.9), size: 18),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: clubOrange,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: clubOrange.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
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
              ? Colors.white.withOpacity(0.02)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isLocked
                ? clubOrange.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
            width: widget.isLocked ? 1.5 : 1,
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
            fontSize: 15,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
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
    this.valueColor = Colors.white,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
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
