
extends Control

# ServiceNow Career Lab V2
# Mobile-first, responsive, game-like learning shell.
# Important: no proprietary ServiceNow training content is bundled.

const BG := Color("#060A16")
const SURFACE := Color("#0D1428")
const SURFACE_2 := Color("#121D36")
const SURFACE_3 := Color("#192846")
const CYAN := Color("#31E7FF")
const BLUE := Color("#6672FF")
const PURPLE := Color("#9B6CFF")
const GREEN := Color("#4DE6A1")
const GOOD := GREEN # shared success state used by quiz/game feedback
const GOLD := Color("#FFC857")
const RED := Color("#FF6B87")
const WHITE := Color("#F4F7FF")
const MUTED := Color("#8F9DB8")
const LINE := Color("#243251")

const LegacyContent = preload("res://scripts/legacy_content.gd")
const SAVE := "user://career_save.json"

var root_v: VBoxContainer
var scroll: ScrollContainer
var content: VBoxContainer
var bottom_bar: HBoxContainer
var header_xp: Label
var toast: PanelContainer
var toast_label: Label
var answer_box: TextEdit
var voice_status: Label
var current_mode := "HOME"
var xp := 0
var streak := 0
var level := 1
var save: Dictionary = {}
var TOPICS: Array = []
var IV: Array = []
var GAME: Array = []
var quiz_score := 0
var game_i := 0
var game_lives := 3
var game_score := 0
var interview_index := 0
var interview_order: Array = []
var current_course := ""
var voice_recording := false

var puzzles = [
    {"title":"P1 COMMANDER","type":"SCENARIO","difficulty":"MEDIUM","xp":80,
     "question":"A P1 production outage affects 400 users. What are your first three actions and why?"},
    {"title":"SCRIPT DETECTIVE","type":"DEBUGGING","difficulty":"HARD","xp":100,
     "question":"A GlideRecord query unexpectedly returns zero records. Explain your debugging sequence."},
    {"title":"FLOW ARCHITECT","type":"LOGIC","difficulty":"EASY","xp":70,
     "question":"Design a safe approval flow. Explain the trigger, conditions, approvals, updates and notifications."},
    {"title":"API RESCUE","type":"ARCHITECTURE","difficulty":"HARD","xp":120,
     "question":"An external REST endpoint intermittently returns 503. Design a resilient integration strategy."},
    {"title":"CMDB MATCH","type":"DATA MODEL","difficulty":"HARD","xp":90,
     "question":"Two records appear to represent the same CI. Explain how you would investigate identity and reconciliation."}
]

var courses = [
    {"title":"ServiceNow Fundamentals","tag":"STARTER","subtitle":"Platform, tables, records and forms","progress":0.36,"color":CYAN},
    {"title":"ITSM Mastery","tag":"CORE","subtitle":"Incident, Problem, Change, Request and Knowledge","progress":0.58,"color":BLUE},
    {"title":"Scripting Arena","tag":"BUILD","subtitle":"GlideRecord, Business Rules, Client Scripts","progress":0.22,"color":PURPLE},
    {"title":"Flow Designer","tag":"BUILD","subtitle":"Triggers, actions, conditions and approvals","progress":0.31,"color":CYAN},
    {"title":"CMDB & Architecture","tag":"ADVANCED","subtitle":"CI classes, relationships and data design","progress":0.11,"color":GREEN},
    {"title":"REST Integrations","tag":"ADVANCED","subtitle":"Auth, APIs, errors, retries and logging","progress":0.18,"color":GOLD},
    {"title":"Release & Major Incident","tag":"CAREER","subtitle":"Real operational scenarios","progress":0.08,"color":RED}
]

func _ready() -> void:
    TOPICS = LegacyContent.topics()
    IV = LegacyContent.interview()
    GAME = LegacyContent.game()
    save = _defaults()
    build_shell()
    _load()
    _streak()
    _sync_stats()
    show_home()
    get_viewport().size_changed.connect(_on_viewport_changed)
    call_deferred("_on_viewport_changed")
    call_deferred("_animate_screen")

func _defaults() -> Dictionary:
    return {"xp": 0, "streak": 0, "last_day": 0, "acc": {}, "iv_done": 0, "game_best": 0}

func _load() -> void:
    if not FileAccess.file_exists(SAVE):
        return
    var f := FileAccess.open(SAVE, FileAccess.READ)
    if not f:
        return
    var d = JSON.parse_string(f.get_as_text())
    if d is Dictionary:
        for k in d:
            save[k] = d[k]
    for k in ["xp", "streak", "last_day", "iv_done", "game_best"]:
        save[k] = int(save.get(k, 0))
    if not save.has("acc") or not (save.acc is Dictionary):
        save.acc = {}
    for k in save.acc:
        var a = save.acc[k]
        if a is Array and a.size() >= 2:
            save.acc[k] = [int(a[0]), int(a[1])]

func _save() -> void:
    var f := FileAccess.open(SAVE, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(save))

func _streak() -> void:
    var today := int(Time.get_unix_time_from_system() / 86400.0)
    if int(save.last_day) == today:
        return
    if int(save.last_day) == today - 1:
        save.streak = int(save.streak) + 1
    else:
        save.streak = 1
    save.last_day = today
    _save()

func _sync_stats() -> void:
    xp = int(save.xp)
    streak = int(save.streak)
    level = floori(xp / 100.0) + 1
    if header_xp and is_instance_valid(header_xp):
        header_xp.text = "⭐ %d XP" % xp

func _pct(name: String) -> float:
    var a = save.acc.get(name, [0, 0])
    if a[1] == 0:
        return 0.0
    return float(a[0]) / float(a[1])

func _record_answer(name: String, ok: bool) -> void:
    var a = save.acc.get(name, [0, 0])
    a[1] += 1
    if ok:
        a[0] += 1
        save.xp += 10
    _save()
    _sync_stats()

func _process(_delta: float) -> void:
    # Android keyboard can reduce the usable screen height. Keep the input page
    # scrollable and remove the bottom navigation while the keyboard is visible.
    var keyboard_h := DisplayServer.virtual_keyboard_get_height()
    if bottom_bar:
        bottom_bar.visible = keyboard_h < 40
    if keyboard_h > 40 and answer_box and is_instance_valid(answer_box) and answer_box.has_focus():
        call_deferred("_keep_answer_visible")

func _keep_answer_visible() -> void:
    if scroll and answer_box and is_instance_valid(answer_box):
        scroll.ensure_control_visible(answer_box)

func _on_viewport_changed() -> void:
    var viewport_size := get_viewport_rect().size
    if viewport_size.x <= 0.0:
        return
    if content:
        # Match the actual viewport. The content itself remains naturally
        # tall so the ScrollContainer can move through every section.
        content.custom_minimum_size.x = max(1.0, viewport_size.x - 36.0)
        content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if bottom_bar:
        bottom_bar.custom_minimum_size.x = viewport_size.x

func _animate_screen() -> void:
    if not content:
        return
    content.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(content, "modulate:a", 1.0, 0.22)

func make_style(bg:Color, radius:int = 20, border:Color = Color.TRANSPARENT, width:int = 0) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.border_color = border
    s.border_width_left = width
    s.border_width_right = width
    s.border_width_top = width
    s.border_width_bottom = width
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 15
    s.content_margin_bottom = 15
    return s

func make_label(value:String, size:int = 18, color:Color = WHITE) -> Label:
    var l := Label.new()
    l.text = value
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func make_button(value:String, callback:Callable, primary:bool = false) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size = Vector2(0, 58)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", WHITE)
    b.add_theme_stylebox_override("normal", make_style(CYAN if primary else SURFACE_3, 17))
    b.add_theme_stylebox_override("hover", make_style(Color("#57E9FF") if primary else Color("#25395F"), 17))
    b.add_theme_stylebox_override("pressed", make_style(Color("#24BFD8") if primary else Color("#203150"), 17))
    b.pressed.connect(callback)
    return b

func make_card(border:Color = Color.TRANSPARENT) -> PanelContainer:
    var p := PanelContainer.new()
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.add_theme_stylebox_override("panel", make_style(SURFACE, 22, border, 1 if border != Color.TRANSPARENT else 0))
    return p

func add_text(parent:Container, value:String, size:int, color:Color) -> Label:
    var l := make_label(value, size, color)
    parent.add_child(l)
    return l

func progress_bar(value:float, color:Color = CYAN) -> ProgressBar:
    var p := ProgressBar.new()
    p.min_value = 0
    p.max_value = 1
    p.value = value
    p.show_percentage = false
    p.custom_minimum_size = Vector2(0, 9)
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.add_theme_stylebox_override("background", make_style(Color("#202B47"), 5))
    p.add_theme_stylebox_override("fill", make_style(color, 5))
    return p

func clear_content() -> void:
    # Free immediately so a new page never renders on top of stale controls.
    for child in content.get_children():
        child.free()
    answer_box = null
    voice_status = null
    if scroll:
        scroll.scroll_vertical = 0

func page_title(title:String, subtitle:String) -> void:
    var p := make_card()
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 5)
    m.add_child(v)
    add_text(v, title, 28, WHITE)
    add_text(v, subtitle, 15, MUTED)
    content.add_child(p)

func build_shell() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var background := ColorRect.new()
    background.color = BG
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    # 2D ambient decoration — lightweight, no 3D rendering.
    var glow_a := ColorRect.new()
    glow_a.color = Color(0.19, 0.91, 1.0, 0.035)
    glow_a.position = Vector2(-180, 90)
    glow_a.size = Vector2(650, 650)
    background.add_child(glow_a)

    var glow_b := ColorRect.new()
    glow_b.color = Color(0.60, 0.35, 1.0, 0.025)
    glow_b.position = Vector2(650, 500)
    glow_b.size = Vector2(600, 600)
    background.add_child(glow_b)

    root_v = VBoxContainer.new()
    root_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_v.add_theme_constant_override("separation", 0)
    add_child(root_v)

    build_header()
    build_scroll()
    build_bottom_bar()
    build_toast()

func build_header() -> void:
    var header := PanelContainer.new()
    header.custom_minimum_size = Vector2(0, 108)
    header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_theme_stylebox_override("panel", make_style(BG, 0))
    root_v.add_child(header)

    var m := MarginContainer.new()
    m.add_theme_constant_override("margin_left", 18)
    m.add_theme_constant_override("margin_right", 18)
    m.add_theme_constant_override("margin_top", 13)
    m.add_theme_constant_override("margin_bottom", 10)
    header.add_child(m)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    m.add_child(row)

    var logo := Label.new()
    logo.text = "✦"
    logo.add_theme_font_size_override("font_size", 34)
    logo.add_theme_color_override("font_color", CYAN)
    row.add_child(logo)

    var brand := VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(brand)
    add_text(brand, "CAREER LAB  •  SEASON 01", 11, CYAN)
    add_text(brand, "ServiceNow Learning", 20, WHITE)

    var stats := VBoxContainer.new()
    stats.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_child(stats)
    header_xp = add_text(stats, "⭐ %d XP" % xp, 16, GOLD)
    add_text(stats, "🔥 %d day streak" % streak, 12, GOLD)

func build_scroll() -> void:
    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.follow_focus = true
    root_v.add_child(scroll)

    # Use the proven direct VBox-under-ScrollContainer pattern from the
    # earlier Career Lab build. This gives the ScrollContainer the full
    # natural content height instead of a shrink-wrapped intermediate node.
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 13)
    content.custom_minimum_size.x = 1
    scroll.add_child(content)

func build_bottom_bar() -> void:
    var bar := PanelContainer.new()
    bar.custom_minimum_size = Vector2(0, 94)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.add_theme_stylebox_override("panel", make_style(BG, 0))
    root_v.add_child(bar)

    bottom_bar = HBoxContainer.new()
    bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom_bar.add_theme_constant_override("separation", 2)
    bar.add_child(bottom_bar)

    var items = [
        ["⌂", "HOME"],
        ["▣", "LEARN"],
        ["⚔", "ARENA"],
        ["◉", "INTERVIEW"],
        ["●", "PROFILE"]
    ]
    for item in items:
        var b := Button.new()
        b.text = item[0] + "\n" + item[1]
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.custom_minimum_size = Vector2(0, 88)
        b.add_theme_font_size_override("font_size", 13)
        b.add_theme_color_override("font_color", MUTED)
        b.add_theme_stylebox_override("normal", make_style(BG, 0))
        b.add_theme_stylebox_override("hover", make_style(SURFACE_2, 0))
        b.pressed.connect(func(): navigate(item[1]))
        bottom_bar.add_child(b)

func build_toast() -> void:
    toast = PanelContainer.new()
    toast.visible = false
    toast.z_index = 100
    toast.position = Vector2(18, 118)
    toast.size = Vector2(1000, 62)
    toast.add_theme_stylebox_override("panel", make_style(Color("#142B4A"), 16, CYAN, 1))
    toast_label = make_label("", 16, WHITE)
    toast.add_child(toast_label)
    add_child(toast)

func navigate(where:String) -> void:
    match where:
        "HOME": show_home()
        "LEARN": show_learn()
        "ARENA": show_arena()
        "INTERVIEW": show_interview()
        "PROFILE": show_profile()

func add_stat_cards() -> void:
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 8)
    var data = [
        ["⚡","5","ENERGY",CYAN],
        ["⭐",str(xp),"XP",GOLD],
        ["🔥",str(streak),"STREAK",GOLD]
    ]
    for item in data:
        var p := make_card()
        p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var m := MarginContainer.new()
        p.add_child(m)
        var v := VBoxContainer.new()
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        m.add_child(v)
        add_text(v, item[0], 22, item[3])
        add_text(v, item[1], 18, WHITE)
        add_text(v, item[2], 10, MUTED)
        row.add_child(p)
    content.add_child(row)

func show_home() -> void:
    clear_content()
    page_title("Welcome back 👋", "Level %d • Learn something useful today." % (floori(xp / 100.0) + 1))
    add_stat_cards()

    var hero := make_card(CYAN)
    var hm := MarginContainer.new()
    hero.add_child(hm)
    var hv := VBoxContainer.new()
    hv.add_theme_constant_override("separation", 8)
    hm.add_child(hv)
    add_text(hv, "⚡ TODAY'S QUEST", 11, CYAN)
    add_text(hv, "Incident Commander", 28, WHITE)
    add_text(hv, "Production outage • Think like the person on call.", 15, MUTED)
    hv.add_child(progress_bar(0.35, CYAN))
    add_text(hv, "+80 XP   •   5–8 minutes", 12, GOLD)
    hv.add_child(make_button("START QUEST  →", func(): start_puzzle(0), true))
    content.add_child(hero)

    page_title("Skill Map", "Build knowledge you can explain, not just memorize.")
    for item in [
        ["ITSM","91%",0.91,CYAN],
        ["Scripting","63%",0.63,PURPLE],
        ["CMDB","72%",0.72,GREEN],
        ["Integrations","81%",0.81,GOLD]
    ]:
        var p := make_card()
        var m := MarginContainer.new()
        p.add_child(m)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        m.add_child(v)
        var r := HBoxContainer.new()
        v.add_child(r)
        var skill_name := add_text(r, item[0], 16, WHITE)
        skill_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        skill_name.custom_minimum_size.x = 90
        add_text(r, item[1], 13, item[3])
        v.add_child(progress_bar(item[2], item[3]))
        content.add_child(p)

    page_title("Daily Missions", "Three small wins keep the learning loop moving.")
    var mission := make_card()
    var mm := MarginContainer.new()
    mission.add_child(mm)
    var mv := VBoxContainer.new()
    mv.add_theme_constant_override("separation", 7)
    mm.add_child(mv)
    add_text(mv, "✓  Read one quick lesson                         +20 XP", 14, GREEN)
    add_text(mv, "□  Solve one arena puzzle                       +40 XP", 14, MUTED)
    add_text(mv, "□  Answer one interview question              +60 XP", 14, MUTED)
    content.add_child(mission)

    page_title("Jump In", "Pick an activity — everything is connected.")
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    for item in [
        ["📚  LEARN","5 min lesson",func(): show_learn()],
        ["⚔  ARENA","Solve scenarios",func(): show_arena()],
        ["🎤  INTERVIEW","Practice answers",func(): show_interview()],
        ["📄  RESUME AI","Improve your CV",func(): show_profile()]
    ]:
        var b := Button.new()
        b.text = item[0] + "\n" + item[1]
        b.custom_minimum_size = Vector2(0, 92)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 16)
        b.add_theme_stylebox_override("normal", make_style(SURFACE_2, 18))
        b.add_theme_stylebox_override("hover", make_style(SURFACE_3, 18, CYAN, 1))
        b.pressed.connect(item[2])
        grid.add_child(b)
    content.add_child(grid)

    var insight := make_card()
    var im := MarginContainer.new()
    insight.add_child(im)
    var iv := VBoxContainer.new()
    iv.add_theme_constant_override("separation", 7)
    im.add_child(iv)
    add_text(iv, "💡 30-SECOND INSIGHT", 11, GREEN)
    add_text(iv, "Knowing a definition is level 1. Explaining when and why to use it is level 2. Defending your design is level 3.", 15, WHITE)
    iv.add_child(make_button("TEST MY KNOWLEDGE", func(): knowledge_duel(), false))
    content.add_child(insight)

func show_learn() -> void:
    clear_content()
    page_title("Learn Hub", "Learn → example → quiz → feedback → interview.")
    for i in TOPICS.size():
        var t = TOPICS[i]
        var p := make_card()
        var m := MarginContainer.new()
        p.add_child(m)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 7)
        m.add_child(v)
        add_text(v, "TOPIC %02d" % (i + 1), 10, CYAN)
        add_text(v, t.name, 21, WHITE)
        add_text(v, t.lesson, 14, MUTED)
        v.add_child(progress_bar(_pct(t.name), CYAN))
        add_text(v, "%d%% readiness" % int(_pct(t.name) * 100.0), 11, MUTED)
        v.add_child(make_button("OPEN LESSON  →", func(index=i): show_lesson(index), false))
        content.add_child(p)

func show_lesson(i: int) -> void:
    var t = TOPICS[i]
    clear_content()
    page_title(t.name, "Understand the idea, then prove you can use it.")
    var p := make_card(CYAN)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 9)
    m.add_child(v)
    add_text(v, "THE IDEA", 11, CYAN)
    add_text(v, t.lesson, 17, WHITE)
    add_text(v, "PROJECT EXAMPLE", 11, GREEN)
    add_text(v, t.ex, 16, MUTED)
    v.add_child(make_button("START QUIZ  →", func(): show_quiz(i, 0), true))
    content.add_child(p)
    content.add_child(make_button("BACK TO LEARN", show_learn, false))

func show_quiz(ti: int, qi: int) -> void:
    var t = TOPICS[ti]
    if qi == 0:
        quiz_score = 0
    if qi >= t.qs.size():
        _quiz_done(ti)
        return
    clear_content()
    var q = t.qs[qi]
    page_title("%s • Quiz" % t.name, "Question %d of %d" % [qi + 1, t.qs.size()])
    var p := make_card()
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 9)
    m.add_child(v)
    add_text(v, q.q, 21, WHITE)
    var feedback := make_label("", 14, MUTED)
    var next_btn := make_button("NEXT  →", func(): show_quiz(ti, qi + 1), true)
    next_btn.visible = false
    var choices: Array[Button] = []
    for oi in q.o.size():
        var b := make_button(q.o[oi], func(): _pick_quiz(ti, qi, oi, choices, feedback, next_btn), false)
        choices.append(b)
        v.add_child(b)
    v.add_child(feedback)
    v.add_child(next_btn)
    content.add_child(p)

func _pick_quiz(ti: int, qi: int, oi: int, choices: Array[Button], feedback: Label, next_btn: Button) -> void:
    var t = TOPICS[ti]
    var q = t.qs[qi]
    var ok: bool = oi == q.a
    for b in choices:
        b.disabled = true
    if q.a < choices.size():
        choices[q.a].add_theme_stylebox_override("disabled", make_style(GOOD.darkened(0.45), 17))
    if not ok:
        choices[oi].add_theme_stylebox_override("disabled", make_style(RED.darkened(0.45), 17))
    if ok:
        quiz_score += 1
    _record_answer(t.name, ok)
    feedback.text = ("Correct! +10 XP. " if ok else "Not quite. ") + q.why
    feedback.add_theme_color_override("font_color", GREEN if ok else RED)
    next_btn.visible = true

func _quiz_done(ti: int) -> void:
    var t = TOPICS[ti]
    clear_content()
    page_title("Quiz Result", t.name)
    var total: int = t.qs.size()
    var p := make_card(GREEN if quiz_score == total else GOLD)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    m.add_child(v)
    add_text(v, "%d / %d correct" % [quiz_score, total], 34, WHITE)
    if quiz_score == total:
        save.xp += 20
        _save()
        _sync_stats()
        add_text(v, "Perfect score! +20 bonus XP", 17, GREEN)
    else:
        add_text(v, "Review the lesson and try again to improve your readiness.", 15, MUTED)
    v.add_child(make_button("BACK TO LEARN", show_learn, true))
    content.add_child(p)

func show_arena() -> void:
    clear_content()
    page_title("⚔ Arena", "Scenario + reasoning + feedback = XP.")
    var rank := make_card()
    var rm := MarginContainer.new()
    rank.add_child(rm)
    var rv := VBoxContainer.new()
    rv.add_theme_constant_override("separation", 7)
    rm.add_child(rv)
    add_text(rv, "CAREER RANK 7", 18, WHITE)
    rv.add_child(progress_bar(0.72, GOLD))
    add_text(rv, "72% to next rank", 11, MUTED)
    content.add_child(rank)

    content.add_child(make_button("🎮 QUICK GAME: FIX THE INCIDENT", show_game, false))

    for i in puzzles.size():
        var q = puzzles[i]
        var p := make_card()
        var m := MarginContainer.new()
        p.add_child(m)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        m.add_child(v)
        add_text(v, "%s  •  %s" % [q["type"], q["difficulty"]], 10, CYAN if i % 2 == 0 else PURPLE)
        add_text(v, q["title"], 21, WHITE)
        add_text(v, q["question"], 14, MUTED)
        v.add_child(make_button("PLAY   +%d XP  →" % q["xp"], func(index=i): start_puzzle(index), i == 0))
        content.add_child(p)

func start_puzzle(index:int) -> void:
    var q = puzzles[index]
    clear_content()
    page_title("⚔ %s" % q["title"], "%s • +%d XP" % [q["difficulty"], q["xp"]])

    var p := make_card(CYAN)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 9)
    m.add_child(v)
    add_text(v, q["question"], 21, WHITE)
    add_text(v, "Use your own words. Explain assumptions and how you would verify the result.", 14, MUTED)

    answer_box = TextEdit.new()
    answer_box.custom_minimum_size = Vector2(0, 270)
    answer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    answer_box.placeholder_text = "Type your answer..."
    answer_box.add_theme_font_size_override("font_size", 18)
    answer_box.focus_mode = Control.FOCUS_ALL
    answer_box.focus_entered.connect(_on_answer_focus)
    v.add_child(answer_box)

    # Voice-to-text UI: native Android bridge can fill this field.
    var voice_row := HBoxContainer.new()
    voice_row.add_theme_constant_override("separation", 8)
    v.add_child(voice_row)
    var voice_btn := Button.new()
    voice_btn.text = "🎙  VOICE TYPE"
    voice_btn.custom_minimum_size = Vector2(0, 58)
    voice_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    voice_btn.add_theme_font_size_override("font_size", 16)
    voice_btn.add_theme_stylebox_override("normal", make_style(SURFACE_3, 17, PURPLE, 1))
    voice_btn.pressed.connect(toggle_voice_input)
    voice_row.add_child(voice_btn)
    voice_status = make_label("Voice input ready", 13, MUTED)
    voice_row.add_child(voice_status)

    var action_row := HBoxContainer.new()
    action_row.add_theme_constant_override("separation", 8)
    var clear_btn := make_button("CLEAR", func(): answer_box.clear(), false)
    clear_btn.custom_minimum_size.x = 130
    action_row.add_child(clear_btn)
    var submit_btn := make_button("SUBMIT & GET FEEDBACK  →", func(): grade_puzzle(index), true)
    submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    action_row.add_child(submit_btn)
    v.add_child(action_row)
    content.add_child(p)

func _on_answer_focus() -> void:
    # Give the Android keyboard a moment to appear, then move the answer box
    # into view so typing never happens behind the keyboard.
    await get_tree().process_frame
    if scroll and answer_box and is_instance_valid(answer_box):
        scroll.ensure_control_visible(answer_box)


func toggle_voice_input() -> void:
    if not answer_box or not is_instance_valid(answer_box):
        return

    # Godot can show the Android virtual keyboard natively. On phones with
    # Gboard/Samsung Keyboard, the microphone button converts speech to text
    # directly into the focused TextEdit. This works without storing audio.
    answer_box.grab_focus()
    var rect := answer_box.get_global_rect()
    DisplayServer.virtual_keyboard_show(answer_box.text, rect, DisplayServer.KEYBOARD_TYPE_MULTILINE, -1, answer_box.caret_column, answer_box.caret_column)
    if voice_status:
        voice_status.text = "🎙 Speak using the keyboard microphone"
        voice_status.add_theme_color_override("font_color", GREEN)
    toast_message("🎙 Voice typing ready — tap the microphone on your keyboard.")

func grade_puzzle(index:int) -> void:
    var text_value := answer_box.text.to_lower()
    var score := 40
    var keywords = ["impact","check","log","priority","error","retry","timeout","approval","condition","trigger","monitor","communication","root cause","validation"]
    for word in keywords:
        if text_value.contains(word):
            score += 5
    score = clamp(score, 40, 100)

    xp += puzzles[index]["xp"] if score >= 70 else int(puzzles[index]["xp"] / 2)
    header_xp.text = "⭐ %d XP" % xp

    clear_content()
    page_title("Mission Complete", "Feedback is based on observable concepts in your answer.")
    var p := make_card(GREEN if score >= 70 else GOLD)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    m.add_child(v)
    add_text(v, "%d%%" % score, 48, GREEN if score >= 70 else GOLD)
    add_text(v, "Reasoning score", 13, MUTED)
    add_text(v, "✓ You attempted the scenario.\n✓ Strong answers state assumptions.\n→ Explain trade-offs.\n→ Explain how you would verify success.", 16, WHITE)
    v.add_child(make_button("BACK TO ARENA", func(): show_arena(), true))
    content.add_child(p)
    toast_message("⭐ XP updated — keep the streak moving!")

func show_game() -> void:
    game_i = 0
    game_lives = 3
    game_score = 0
    _game_round()

func _game_next() -> void:
    game_i += 1
    _game_round()

func _game_round() -> void:
    clear_content()
    page_title("🎮 Fix the Incident", "Fast decisions. 3 lives. Learn from every mistake.")
    if game_lives <= 0 or game_i >= GAME.size():
        var p := make_card(GREEN if game_lives > 0 else RED)
        var m := MarginContainer.new()
        p.add_child(m)
        var v := VBoxContainer.new()
        m.add_child(v)
        add_text(v, "You fixed them all!" if game_lives > 0 else "Out of lives!", 30, GREEN if game_lives > 0 else RED)
        add_text(v, "Score: %d" % game_score, 24, WHITE)
        add_text(v, "Best: %d" % int(save.game_best), 16, MUTED)
        v.add_child(make_button("PLAY AGAIN", show_game, true))
        content.add_child(p)
        if game_score > int(save.game_best):
            save.game_best = game_score
            _save()
        return
    var s = GAME[game_i]
    var p := make_card()
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 9)
    m.add_child(v)
    add_text(v, "❤️ %d LIVES     ⭐ %d SCORE" % [game_lives, game_score], 15, GOLD)
    add_text(v, s.d, 20, WHITE)
    var feedback := make_label("", 14, MUTED)
    var next_btn := make_button("NEXT  →", _game_next, true)
    next_btn.visible = false
    var choices: Array[Button] = []
    for oi in s.o.size():
        var b := make_button(s.o[oi], func(): _game_pick(s, oi, choices, feedback, next_btn), false)
        choices.append(b)
        v.add_child(b)
    v.add_child(feedback)
    v.add_child(next_btn)
    content.add_child(p)

func _game_pick(s: Dictionary, oi: int, choices: Array[Button], feedback: Label, next_btn: Button) -> void:
    var ok: bool = oi == s.a
    for b in choices:
        b.disabled = true
    if s.a < choices.size():
        choices[s.a].add_theme_stylebox_override("disabled", make_style(GOOD.darkened(0.45), 17))
    if not ok:
        choices[oi].add_theme_stylebox_override("disabled", make_style(RED.darkened(0.45), 17))
        game_lives -= 1
    else:
        game_score += 15
        save.xp += 15
        _save()
        _sync_stats()
    feedback.text = ("Correct! +15 XP. " if ok else "Wrong. ") + s.why
    feedback.add_theme_color_override("font_color", GREEN if ok else RED)
    next_btn.visible = true


func knowledge_duel() -> void:
    clear_content()
    page_title("🧠 Knowledge Duel", "Exact wording does not matter. We look for the important concepts.")
    add_text(content, "What is the difference between a Client Script and a Business Rule?", 23, WHITE)

    answer_box = TextEdit.new()
    answer_box.custom_minimum_size = Vector2(0, 280)
    answer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    answer_box.placeholder_text = "Explain it like you are teaching a teammate..."
    answer_box.add_theme_font_size_override("font_size", 18)
    answer_box.focus_mode = Control.FOCUS_ALL
    answer_box.focus_entered.connect(_on_answer_focus)
    content.add_child(answer_box)

    var voice_row := HBoxContainer.new()
    voice_row.add_theme_constant_override("separation", 8)
    content.add_child(voice_row)
    var b := Button.new()
    b.text = "🎙 VOICE TYPE"
    b.custom_minimum_size = Vector2(0, 58)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_stylebox_override("normal", make_style(SURFACE_3, 17, PURPLE, 1))
    b.pressed.connect(toggle_voice_input)
    voice_row.add_child(b)
    voice_status = make_label("Tap and speak", 13, MUTED)
    voice_row.add_child(voice_status)

    content.add_child(make_button("CHECK MY ANSWER  →", func(): grade_knowledge(), true))

func grade_knowledge() -> void:
    var a := answer_box.text.to_lower()
    var score := 35
    for k in ["client","browser","server","form","business rule","server-side"]:
        if a.contains(k):
            score += 11
    score = clamp(score, 0, 100)
    xp += 15 if score >= 70 else 8
    header_xp.text = "⭐ %d XP" % xp

    clear_content()
    page_title("Answer Review", "Learn the gap, then retry.")
    var p := make_card()
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    m.add_child(v)
    add_text(v, "%d%%" % score, 45, GREEN if score >= 70 else GOLD)
    add_text(v, "Key idea", 19, WHITE)
    add_text(v, "Client Scripts primarily control form behaviour in the browser. Business Rules execute server-side for server-side business logic.", 15, MUTED)
    add_text(v, "Interview upgrade", 19, WHITE)
    add_text(v, "Add a real example and explain why you selected the execution context.", 15, MUTED)
    v.add_child(make_button("TRY ANOTHER", func(): show_arena(), true))
    content.add_child(p)

func show_interview() -> void:
    clear_content()
    page_title("🎤 Interview Simulator", "Practice thinking, explaining and handling follow-ups.")
    var hero := make_card(PURPLE)
    var m := MarginContainer.new()
    hero.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 7)
    m.add_child(v)
    add_text(v, "QUESTION BANK", 11, CYAN)
    add_text(v, "%d ServiceNow questions with model answers and self-scoring." % IV.size(), 18, WHITE)
    v.add_child(make_button("START INTERVIEW ROUND", func(): interview_round("ServiceNow Developer"), true))
    content.add_child(hero)
    for item in [["🧠","TECHNICAL","ServiceNow Developer","20 min"],["🏗","PROJECT","Project Deep Dive","15 min"],["⚡","PRESSURE","Pressure Interview","12 min"],["💬","COMMUNICATION","HR & Communication","10 min"]]:
        var p := make_card()
        var pm := MarginContainer.new()
        p.add_child(pm)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        pm.add_child(h)
        add_text(h, item[0], 25, CYAN)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        h.add_child(info)
        add_text(info, item[1], 10, CYAN)
        add_text(info, item[2], 18, WHITE)
        add_text(info, item[3], 12, MUTED)
        h.add_child(make_button("START", func(mode=item[2]): interview_round(mode), false))
        content.add_child(p)

func interview_round(mode:String) -> void:
    if interview_order.is_empty():
        interview_order = range(IV.size())
        interview_order.shuffle()
        interview_index = 0
    if interview_index >= interview_order.size():
        interview_order.clear()
        interview_index = 0
        show_interview()
        return
    clear_content()
    var item = IV[interview_order[interview_index]]
    page_title(mode, "Question %d of %d • Answer naturally, then compare with the model answer." % [interview_index + 1, interview_order.size()])
    var p := make_card(PURPLE)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 9)
    m.add_child(v)
    add_text(v, "INTERVIEWER", 11, CYAN)
    add_text(v, item.q, 21, WHITE)
    answer_box = TextEdit.new()
    answer_box.custom_minimum_size = Vector2(0, 240)
    answer_box.placeholder_text = "Type your response or use voice..."
    answer_box.add_theme_font_size_override("font_size", 18)
    answer_box.focus_mode = Control.FOCUS_ALL
    answer_box.focus_entered.connect(_on_answer_focus)
    v.add_child(answer_box)
    var voice := Button.new()
    voice.text = "🎙  VOICE TYPE"
    voice.custom_minimum_size = Vector2(0, 60)
    voice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    voice.add_theme_stylebox_override("normal", make_style(SURFACE_3, 17, PURPLE, 1))
    voice.pressed.connect(toggle_voice_input)
    v.add_child(voice)
    voice_status = make_label("Voice input ready", 13, MUTED)
    v.add_child(voice_status)
    var submit := make_button("SUBMIT & REVIEW", func(): interview_feedback(mode), true)
    v.add_child(submit)
    content.add_child(p)

func interview_feedback(mode:String) -> void:
    var a := answer_box.text.to_lower()
    var item = IV[interview_order[interview_index]]
    var score := 40
    if a.length() > 100:
        score += 15
    if a.length() > 220:
        score += 10
    for k in ["experience","project","servicenow","role","team","develop","impact","because","example","verify"]:
        if a.contains(k):
            score += 4
    score = clamp(score, 35, 100)
    if score >= 70:
        save.xp += 20
        save.iv_done = int(save.iv_done) + 1
        _save()
        _sync_stats()
    clear_content()
    page_title("Interview Feedback", "Observable communication practice — not a personality or intelligence diagnosis.")
    var p := make_card(GREEN if score >= 70 else GOLD)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    m.add_child(v)
    add_text(v, "%d%%" % score, 46, GREEN if score >= 70 else GOLD)
    add_text(v, "Answer structure", 13, MUTED)
    v.add_child(progress_bar(float(score) / 100.0, GREEN if score >= 70 else GOLD))
    add_text(v, "MODEL ANSWER", 11, CYAN)
    add_text(v, item.a, 15, WHITE)
    add_text(v, "Upgrade: add your personal contribution, one concrete example, and how you verified the outcome.", 14, MUTED)
    v.add_child(make_button("NEXT QUESTION", func(): interview_index += 1; interview_round(mode), true))
    content.add_child(p)

func show_profile() -> void:
    clear_content()
    page_title("Profile & Resume AI", "Build your skill map and turn your resume into interview practice.")

    var p := make_card()
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 7)
    m.add_child(v)
    add_text(v, "LEVEL %d  •  DEVELOPER" % (floori(xp / 100.0) + 1), 23, WHITE)
    add_text(v, "⭐ %d XP   🔥 %d day streak" % [xp, streak], 14, GOLD)
    v.add_child(progress_bar(0.74, CYAN))
    add_text(v, "74% to next career rank", 11, MUTED)
    content.add_child(p)

    var resume := make_card(GOLD)
    var rm := MarginContainer.new()
    resume.add_child(rm)
    var rv := VBoxContainer.new()
    rv.add_theme_constant_override("separation", 8)
    rm.add_child(rv)
    add_text(rv, "📄 RESUME AI", 11, GOLD)
    add_text(rv, "Choose a PDF/DOCX from your phone. Analyze it, improve it and create resume-based interview questions.", 16, WHITE)
    rv.add_child(make_button("CHOOSE RESUME FROM PHONE", func(): choose_resume(), true))
    content.add_child(resume)

    for item in [
        ["ITSM",0.91,CYAN],
        ["Scripting",0.63,PURPLE],
        ["CMDB",0.72,GREEN],
        ["Integrations",0.81,GOLD]
    ]:
        var q := make_card()
        var qm := MarginContainer.new()
        q.add_child(qm)
        var qv := VBoxContainer.new()
        qm.add_child(qv)
        add_text(qv, item[0], 16, WHITE)
        qv.add_child(progress_bar(item[1], item[2]))
        add_text(qv, "%d%%" % int(item[1] * 100.0), 11, MUTED)
        content.add_child(q)

func choose_resume() -> void:
    var fd := FileDialog.new()
    fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    fd.access = FileDialog.ACCESS_FILESYSTEM
    fd.filters = PackedStringArray(["*.pdf ; PDF Resume", "*.docx ; Word Resume"])
    fd.file_selected.connect(_resume_selected)
    add_child(fd)
    fd.popup_centered(Vector2(850, 1100))

func _resume_selected(path:String) -> void:
    clear_content()
    page_title("Resume Intelligence", "Selected: " + path.get_file())
    var p := make_card(GOLD)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    m.add_child(v)
    add_text(v, "78 / 100", 46, GREEN)
    add_text(v, "Resume quality prototype", 13, MUTED)
    for item in [
        ["ATS clarity",0.76,CYAN],
        ["Skills evidence",0.88,PURPLE],
        ["Achievements",0.58,GOLD],
        ["Project depth",0.71,GREEN]
    ]:
        add_text(v, item[0], 14, WHITE)
        v.add_child(progress_bar(item[1], item[2]))
    add_text(v, "💡 Improvement", 18, GOLD)
    add_text(v, "Turn responsibility-only bullets into truthful achievement statements. Then use the resume to generate interview follow-ups.", 15, MUTED)
    v.add_child(make_button("BUILD RESUME INTERVIEW", func(): interview_round("Resume Interview"), true))
    content.add_child(p)

func show_progress() -> void:
    clear_content()
    page_title("My Progress", "Track what you can answer, explain and apply.")
    var p := make_card(CYAN)
    var m := MarginContainer.new()
    p.add_child(m)
    var v := VBoxContainer.new()
    m.add_child(v)
    add_text(v, "LEVEL %d  •  %d XP" % [floori(xp / 100.0) + 1, xp], 28, WHITE)
    v.add_child(progress_bar(float(xp % 100) / 100.0, CYAN))
    add_text(v, "%d day streak" % streak, 15, GOLD)
    content.add_child(p)
    var r := make_card()
    var rm := MarginContainer.new()
    r.add_child(rm)
    var rv := VBoxContainer.new()
    rv.add_theme_constant_override("separation", 7)
    rm.add_child(rv)
    add_text(rv, "TOPIC READINESS", 18, WHITE)
    var total := 0.0
    for t in TOPICS:
        var pct := _pct(t.name)
        total += pct
        add_text(rv, "%s  •  %d%%" % [t.name, int(pct * 100.0)], 14, MUTED)
        rv.add_child(progress_bar(pct, CYAN))
    add_text(rv, "Overall readiness: %d%%" % int(total / max(1, TOPICS.size()) * 100.0), 16, GREEN)
    content.add_child(r)
    var w := make_card()
    var wm := MarginContainer.new()
    w.add_child(wm)
    var wv := VBoxContainer.new()
    wm.add_child(wv)
    add_text(wv, "WEAK AREAS", 18, WHITE)
    var weak := 0
    for t in TOPICS:
        var a = save.acc.get(t.name, [0, 0])
        if a[1] > 0 and _pct(t.name) < 0.7:
            add_text(wv, "Practise: " + t.name, 14, RED)
            weak += 1
    if weak == 0:
        add_text(wv, "Take quizzes to reveal your weak areas.", 14, MUTED)
    add_text(wv, "Interview rounds completed: %d" % int(save.iv_done), 14, WHITE)
    add_text(wv, "Best quick-game score: %d" % int(save.game_best), 14, WHITE)
    content.add_child(w)
    content.add_child(make_button("RESET PROGRESS", _reset_progress, false))

func _reset_progress() -> void:
    save = _defaults()
    _streak()
    _sync_stats()
    show_progress()


func toast_message(message:String) -> void:
    toast_label.text = message
    toast.visible = true
    toast.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(toast, "modulate:a", 1.0, 0.15)
    tween.tween_interval(1.3)
    tween.tween_property(toast, "modulate:a", 0.0, 0.25)
    tween.tween_callback(func(): toast.visible = false)
