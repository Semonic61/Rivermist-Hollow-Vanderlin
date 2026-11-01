import { type CSSProperties, type ReactNode, useState } from 'react';
import {
  Box,
  Button,
  DmIcon,
  Icon,
  Input,
  NoticeBox,
  Stack,
  TextArea,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ---------------------------------------------------------------------------
// Data contract (mirrors class_builder.dm)
// ---------------------------------------------------------------------------

type BooleanLike = boolean | number;

type Entry = {
  id: string;
  name: string;
  name_ru?: string | null;
  desc?: string | null;
  desc_ru?: string | null;
  icon?: string;
  icon_state?: string;
  roles?: string[];
  excludes?: string[];
};

type TraitInfo = { name: string; desc?: string | null };
type SkillBonus = { name: string; rank: number };

type StatEntry = Entry & { cost: number; max: number };
type SkillEntry = Entry & { pool: string; cap: number; cost: number };
type DirectionEntry = Entry & { color: string; max: number };
type BackgroundEntry = Entry & {
  skills: SkillBonus[];
  directions: Record<string, number>;
  traits: TraitInfo[];
  languages: string[];
};
type TalentEntry = Entry & {
  direction: string;
  tier: number;
  cost: number;
  is_spell: BooleanLike;
  traits: TraitInfo[];
  skills: SkillBonus[];
  spells: string[];
  patrons: string[];
  requires: string[];
};
type FlawEntry = Entry & { points: number; traits: TraitInfo[] };
type ItemEntry = Entry & {
  cost: number;
  category: string;
  slots: string[];
  required_skill?: SkillBonus;
  required_talent?: string;
};

type Role = {
  type: string;
  title: string;
  group: string;
  stat_points: number;
  skill_points: Record<string, number>;
  direction_points: number;
  item_points: number;
  max_flaws: number;
  direction_caps: Record<string, number>;
  free_kit: Record<string, LoadoutInfo>;
};

type Block = { code: string; value?: string | number };
type BuildError = { code: string; arg?: string };

type Build = {
  name: string;
  role: string;
  title: string;
  background: string | null;
  stats: Record<string, number>;
  skills: Record<string, number>;
  directions: Record<string, number>;
  talents: string[];
  flaws: string[];
  equipment: Record<string, string>;
  bag: string[];
  stash: string[];
};

type Computed = {
  errors: BuildError[];
  stat_spent?: number;
  stat_budget?: number;
  skill_spent?: Record<string, number>;
  skill_budget?: Record<string, number>;
  direction_spent?: number;
  direction_budget?: number;
  flaw_points?: number;
  flaw_count?: number;
  flaw_max?: number;
  direction_levels?: Record<string, number>;
  direction_caps?: Record<string, number>;
  talent_spent?: Record<string, number>;
  final_skills?: Record<string, number>;
  item_spent?: number;
  item_budget?: number;
  blocked?: Record<string, Block>;
};

type SlotInfo = {
  index: number;
  name: string;
  role: string;
  role_title: string;
  active: BooleanLike;
};
type LoadoutInfo = { name: string; icon: string; icon_state: string };

type Data = {
  // static
  backgrounds: BackgroundEntry[];
  stats: StatEntry[];
  skills: SkillEntry[];
  directions: DirectionEntry[];
  talents: TalentEntry[];
  flaws: FlawEntry[];
  items: ItemEntry[];
  roles: Role[];
  doll_slots: string[];
  limits: {
    stat_base: number;
    stat_floor: number;
    skill_max_rank: number;
    max_builds: number;
    name_max: number;
    import_max: number;
    max_carried: number;
  };
  // dynamic
  character_name: string;
  species: string | null;
  patron: string | null;
  build_slots: SlotInfo[];
  active_index: number;
  dirty: BooleanLike;
  build: Build | null;
  computed: Computed | null;
  loadout: LoadoutInfo[];
  export_text: string | null;
  notice: BuildError | null;
};

const STEPS = [
  'class',
  'background',
  'abilities',
  'skills',
  'directions',
  'spells',
  'flaws',
  'equipment',
  'summary',
] as const;

type StepId = (typeof STEPS)[number];

const POOLS = ['combat', 'peaceful', 'adventure'];
const MAGIC_DIRECTIONS = ['magic', 'miracles', 'music'];

export type ClassBuilderLocale = {
  lang: 'en' | 'ru';
  windowTitle: string;
  steps: Record<StepId, string>;
  stepHints: Record<StepId, string>;
  pools: Record<string, string>;
  groups: Record<string, string>;
  slots: Record<string, string>;
  categories: Record<string, string>;
  labels: {
    builds: string;
    noBuilds: string;
    spawnBuild: string;
    makeSpawnBuild: string;
    spawnBuildHint: string;
    newBuild: string;
    duplicate: string;
    delete: string;
    confirmDelete: string;
    save: string;
    revert: string;
    unsaved: string;
    saved: string;
    back: string;
    next: string;
    reset: string;
    resetAll: string;
    budgets: string;
    stats: string;
    skills: string;
    directions: string;
    items: string;
    flaws: string;
    role: string;
    buildName: string;
    classTitle: string;
    classTitleHint: string;
    noBackground: string;
    cost: string;
    costStep: string;
    max: string;
    cap: string;
    free: string;
    tier: string;
    points: string;
    level: string;
    talents: string;
    spells: string;
    traits: string;
    languages: string;
    patrons: string;
    requires: string;
    grants: string;
    search: string;
    pickSlot: string;
    noItemsForSlot: string;
    clearSlot: string;
    carried: string;
    bag: string;
    stash: string;
    loadout: string;
    toBag: string;
    toStash: string;
    move: string;
    remove: string;
    empty: string;
    character: string;
    species: string;
    patron: string;
    preview: string;
    previewHint: string;
    errors: string;
    noErrors: string;
    exchange: string;
    export: string;
    import: string;
    importHint: string;
    derived: string;
    charisma: string;
    charismaHint: string;
    freeKit: string;
  };
  block: (code: string, value?: string | number) => string;
  error: (
    code: string,
    arg: string | undefined,
    nameOf: (id: string) => string,
  ) => string;
  notice: (code: string, arg?: string) => string;
};

// ---------------------------------------------------------------------------
// Look: BG3-like parchment-and-gold on dark leather
// ---------------------------------------------------------------------------

const C = {
  bg: '#16110d',
  panel: '#1e1812',
  panelDark: '#130f0b',
  border: '#5a4632',
  borderSoft: '#3c3024',
  gold: '#c9a25f',
  title: '#e0a93b',
  text: '#c7bba8',
  label: '#8a7a66',
  dim: '#5c5246',
  active: '#3a2c1c',
  ok: '#78be6e',
  bad: '#cd5a46',
  neg: '#aa5050',
};

const panelStyle: CSSProperties = {
  background: C.panel,
  border: `2px solid ${C.border}`,
  borderRadius: '6px',
  padding: '10px 12px',
};

const cardStyle = (
  state: 'selected' | 'available' | 'blocked' | 'negative' | 'negativeSelected',
): CSSProperties => {
  const map = {
    selected: { bg: '#2c3a24', border: C.ok, color: C.text },
    available: { bg: '#282018', border: C.border, color: C.text },
    blocked: { bg: C.panelDark, border: C.borderSoft, color: C.dim },
    negative: { bg: '#281a18', border: '#64372f', color: C.text },
    negativeSelected: { bg: '#46201c', border: C.neg, color: '#ebc8be' },
  }[state];
  return {
    background: map.bg,
    border: `${state.endsWith('elected') ? 2 : 1}px solid ${map.border}`,
    borderRadius: '4px',
    color: map.color,
    padding: '6px 8px',
    cursor: state === 'blocked' ? 'default' : 'pointer',
    minHeight: '44px',
  };
};

// ---------------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------------

const Ornament = () => (
  <Box
    style={{
      position: 'relative',
      height: '1px',
      background: C.border,
      margin: '6px 0 10px',
    }}
  >
    <Box
      style={{
        position: 'absolute',
        left: '50%',
        top: '-4px',
        width: '8px',
        height: '8px',
        background: C.gold,
        transform: 'translateX(-50%) rotate(45deg)',
      }}
    />
  </Box>
);

const Panel = (props: {
  title?: ReactNode;
  right?: ReactNode;
  children: ReactNode;
  fill?: boolean;
  style?: CSSProperties;
}) => (
  <Box
    style={{
      ...panelStyle,
      height: props.fill ? '100%' : undefined,
      overflowY: props.fill ? 'auto' : undefined,
      ...props.style,
    }}
  >
    {props.title ? (
      <>
        <Stack align="center">
          <Stack.Item grow>
            <Box
              bold
              color={C.gold}
              style={{ textTransform: 'uppercase', letterSpacing: '1px' }}
            >
              {props.title}
            </Box>
          </Stack.Item>
          {props.right ? (
            <Stack.Item>
              <Box color={C.label} fontSize="0.9em">
                {props.right}
              </Box>
            </Stack.Item>
          ) : null}
        </Stack>
        <Ornament />
      </>
    ) : null}
    {props.children}
  </Box>
);

const Pips = (props: {
  value: number;
  total: number;
  color?: string;
  bonus?: number;
  size?: number;
}) => {
  const size = props.size ?? 10;
  const bonus = props.bonus ?? 0;
  return (
    <Box inline style={{ whiteSpace: 'nowrap' }}>
      {Array.from({ length: props.total }, (_, i) => {
        const filled = i < props.value;
        const isBonus = !filled && i < props.value + bonus;
        return (
          <Box
            key={i}
            inline
            style={{
              width: `${size}px`,
              height: `${size}px`,
              marginRight: '2px',
              borderRadius: '2px',
              border: `1px solid ${C.border}`,
              background: filled
                ? props.color || C.gold
                : isBonus
                  ? C.title
                  : 'transparent',
              opacity: isBonus ? 0.55 : 1,
            }}
          />
        );
      })}
    </Box>
  );
};

const Counter = (props: {
  value: ReactNode;
  color?: string;
  canDec: boolean;
  canInc: boolean;
  onDec: () => void;
  onInc: () => void;
}) => (
  <Box style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
    <Button compact disabled={!props.canDec} onClick={props.onDec}>
      −
    </Button>
    <Box
      bold
      textAlign="center"
      color={props.color || C.text}
      style={{ minWidth: '28px', fontSize: '1.15em' }}
    >
      {props.value}
    </Box>
    <Button compact disabled={!props.canInc} onClick={props.onInc}>
      +
    </Button>
  </Box>
);

const BudgetBar = (props: {
  label: string;
  used: number;
  total: number;
  color?: string;
}) => {
  const over = props.used > props.total;
  const frac = props.total > 0 ? Math.min(1, props.used / props.total) : 0;
  return (
    <Box mb={1}>
      <Stack>
        <Stack.Item grow>
          <Box color={C.label} fontSize="0.85em">
            {props.label}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box color={over ? C.bad : C.text} fontSize="0.85em" bold>
            {fmt(props.used)} / {fmt(props.total)}
          </Box>
        </Stack.Item>
      </Stack>
      <Box
        style={{
          height: '6px',
          background: C.panelDark,
          border: `1px solid ${C.borderSoft}`,
          borderRadius: '3px',
          marginTop: '2px',
        }}
      >
        <Box
          style={{
            width: `${frac * 100}%`,
            height: '100%',
            borderRadius: '2px',
            background: over ? C.bad : props.color || C.gold,
          }}
        />
      </Box>
    </Box>
  );
};

const ItemIcon = (props: { item?: Entry | LoadoutInfo; size?: number }) => {
  const size = props.size ?? 32;
  if (!props.item?.icon || !props.item.icon_state) {
    return <Box style={{ width: `${size}px`, height: `${size}px` }} />;
  }
  return (
    <DmIcon
      icon={props.item.icon}
      icon_state={props.item.icon_state}
      width={`${size}px`}
      height={`${size}px`}
      fallback={<Icon name="box" color={C.dim} />}
    />
  );
};

const fmt = (value: number | undefined) =>
  value === undefined
    ? '0'
    : Number.isInteger(value)
      ? `${value}`
      : value.toFixed(1);

const asArray = <T,>(value: T[] | Record<string, T> | null | undefined): T[] =>
  Array.isArray(value) ? value : value ? Object.values(value) : [];

const asMap = <T,>(value: Record<string, T> | T[] | null | undefined) =>
  (Array.isArray(value) ? {} : value || {}) as Record<string, T>;

// ---------------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------------

export const ClassBuilderView = (props: { locale: ClassBuilderLocale }) => {
  const { locale } = props;
  const { act, data } = useBackend<Data>();
  const [step, setStep] = useState<StepId>('class');

  const t = (entry?: Entry | null) =>
    !entry
      ? ''
      : locale.lang === 'ru' && entry.name_ru
        ? entry.name_ru
        : entry.name;
  const d = (entry?: Entry | null) =>
    !entry
      ? ''
      : (locale.lang === 'ru' && entry.desc_ru ? entry.desc_ru : entry.desc) ||
        '';

  const byId: Record<string, Entry> = {};
  for (const list of [
    data.backgrounds,
    data.stats,
    data.skills,
    data.directions,
    data.talents,
    data.flaws,
    data.items,
  ]) {
    for (const entry of asArray<Entry>(list)) {
      byId[entry.id] = entry;
    }
  }
  const nameOf = (id: string) => (byId[id] ? t(byId[id]) : id);

  const savedSlots = asArray<SlotInfo>(data.build_slots);
  const ctx: Ctx = {
    act,
    data,
    locale,
    t,
    d,
    nameOf,
    build: data.build,
    computed: data.computed || { errors: [] },
    role: data.roles.find((role) => role.type === data.build?.role),
  };

  const noticeText = data.notice
    ? locale.notice(data.notice.code, data.notice.arg) ||
      locale.error(data.notice.code, data.notice.arg, nameOf)
    : null;

  return (
    <Window title={locale.windowTitle} width={1320} height={840}>
      <Window.Content style={{ background: C.bg }}>
        <Stack vertical fill>
          <Stack.Item>
            <TopBar ctx={ctx} savedSlots={savedSlots} />
          </Stack.Item>
          {noticeText ? (
            <Stack.Item>
              {data.notice?.code === 'saved' ||
              data.notice?.code === 'imported' ||
              data.notice?.code === 'activated' ? (
                <NoticeBox success>{noticeText}</NoticeBox>
              ) : (
                <NoticeBox danger>{noticeText}</NoticeBox>
              )}
            </Stack.Item>
          ) : null}
          <Stack.Item grow>
            {!data.build ? (
              <EmptyState ctx={ctx} />
            ) : (
              <Stack fill>
                <Stack.Item basis="210px">
                  <StepRail ctx={ctx} step={step} setStep={setStep} />
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Panel
                    fill
                    title={`${STEPS.indexOf(step) + 1}. ${locale.steps[step]}`}
                    right={<StepReset ctx={ctx} step={step} />}
                  >
                    <Box color={C.label} italic mb={1}>
                      {locale.stepHints[step]}
                    </Box>
                    <StepContent ctx={ctx} step={step} />
                  </Panel>
                </Stack.Item>
                <Stack.Item basis="330px">
                  <Summary ctx={ctx} />
                </Stack.Item>
              </Stack>
            )}
          </Stack.Item>
          {data.build ? (
            <Stack.Item>
              <BottomBar ctx={ctx} step={step} setStep={setStep} />
            </Stack.Item>
          ) : null}
        </Stack>
      </Window.Content>
    </Window>
  );
};

type Ctx = {
  act: (action: string, params?: Record<string, unknown>) => void;
  data: Data;
  locale: ClassBuilderLocale;
  t: (entry?: Entry | null) => string;
  d: (entry?: Entry | null) => string;
  nameOf: (id: string) => string;
  build: Build | null;
  computed: Computed;
  role?: Role;
};

// ---------------------------------------------------------------------------
// Frame: top bar, step rail, bottom bar
// ---------------------------------------------------------------------------

const TopBar = (props: { ctx: Ctx; savedSlots: SlotInfo[] }) => {
  const { act, data, locale } = props.ctx;
  const [confirmDelete, setConfirmDelete] = useState(false);
  const slots = props.savedSlots;
  const current = slots.find((slot) => slot.index === data.active_index);
  return (
    <Box style={{ ...panelStyle, padding: '6px 10px' }}>
      <Stack align="center">
        <Stack.Item>
          <Box bold color={C.gold} style={{ letterSpacing: '1px' }}>
            {locale.labels.builds.toUpperCase()}
          </Box>
        </Stack.Item>
        <Stack.Item grow>
          {slots.map((slot) => (
            <Button
              key={slot.index}
              icon={slot.active ? 'star' : undefined}
              selected={slot.index === data.active_index}
              tooltip={
                slot.active
                  ? `${slot.role_title} · ${locale.labels.spawnBuild}`
                  : slot.role_title
              }
              onClick={() => act('slot_select', { index: slot.index })}
            >
              {slot.name}
            </Button>
          ))}
        </Stack.Item>
        {data.dirty ? (
          <Stack.Item>
            <Box
              bold
              color="#f0d296"
              style={{
                border: '1px solid #d2a046',
                background: 'rgba(90,70,30,0.5)',
                borderRadius: '4px',
                padding: '2px 8px',
              }}
            >
              {locale.labels.unsaved}
            </Box>
          </Stack.Item>
        ) : null}
        {current ? (
          <Stack.Item>
            <Button
              icon="star"
              color={current.active ? 'good' : undefined}
              disabled={!!current.active}
              tooltip={locale.labels.spawnBuildHint}
              onClick={() => act('slot_activate')}
            >
              {current.active
                ? locale.labels.spawnBuild
                : locale.labels.makeSpawnBuild}
            </Button>
          </Stack.Item>
        ) : null}
        <Stack.Item>
          <Button
            icon="copy"
            disabled={!data.build || slots.length >= data.limits.max_builds}
            onClick={() => act('slot_duplicate')}
          >
            {locale.labels.duplicate}
          </Button>
          {confirmDelete ? (
            <Button
              icon="trash"
              color="bad"
              onClick={() => {
                setConfirmDelete(false);
                act('slot_delete');
              }}
            >
              {locale.labels.confirmDelete}
            </Button>
          ) : (
            <Button
              icon="trash"
              disabled={!data.build}
              onClick={() => setConfirmDelete(true)}
            >
              {locale.labels.delete}
            </Button>
          )}
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const EmptyState = (props: { ctx: Ctx }) => {
  const { locale } = props.ctx;
  return (
    <Panel fill title={locale.labels.newBuild}>
      <Box color={C.text} mb={2}>
        {locale.labels.noBuilds}
      </Box>
      <RolePicker ctx={props.ctx} action="slot_new" />
    </Panel>
  );
};

const StepRail = (props: {
  ctx: Ctx;
  step: StepId;
  setStep: (step: StepId) => void;
}) => {
  const { locale, computed, role } = props.ctx;
  const errors = computed.errors || [];
  const stepHasError = (step: StepId) =>
    errors.some((error) => {
      switch (step) {
        case 'abilities':
          return error.code === 'stat_over';
        case 'skills':
          return error.code === 'skill_over';
        case 'directions':
          return (
            error.code === 'direction_over' || error.code === 'talent_over'
          );
        case 'flaws':
          return error.code === 'flaw_over';
        case 'equipment':
          return error.code === 'item_over';
        case 'class':
          return error.code === 'no_role';
        default:
          return false;
      }
    });
  const skillSpent = asMap(computed.skill_spent);
  const skillBudget = asMap(computed.skill_budget);
  return (
    <Box style={{ ...panelStyle, height: '100%', overflowY: 'auto' }}>
      {STEPS.map((step, index) => {
        const active = step === props.step;
        const bad = stepHasError(step);
        return (
          <Box
            key={step}
            onClick={() => props.setStep(step)}
            style={{
              display: 'flex',
              alignItems: 'center',
              padding: '5px 6px',
              marginBottom: '4px',
              borderRadius: '5px',
              cursor: 'pointer',
              background: active ? C.active : 'transparent',
              border: `1px solid ${active ? C.gold : 'transparent'}`,
            }}
          >
            <Box
              style={{
                width: '26px',
                height: '26px',
                borderRadius: '50%',
                border: `2px solid ${active ? C.gold : C.border}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: '8px',
                color: active ? C.gold : C.label,
                fontSize: '0.85em',
                flexShrink: 0,
              }}
            >
              {index + 1}
            </Box>
            <Box
              bold={active}
              color={active ? '#f5e1b9' : C.text}
              style={{ flexGrow: 1 }}
            >
              {locale.steps[step]}
            </Box>
            {bad ? <Icon name="exclamation-triangle" color={C.bad} /> : null}
          </Box>
        );
      })}
      <Ornament />
      <Box bold color={C.gold} mb={1}>
        {locale.labels.budgets.toUpperCase()}
      </Box>
      {role ? (
        <>
          <BudgetBar
            label={locale.labels.stats}
            used={computed.stat_spent || 0}
            total={computed.stat_budget || 0}
          />
          {POOLS.map((pool) => (
            <BudgetBar
              key={pool}
              label={`${locale.labels.skills}: ${locale.pools[pool]}`}
              used={skillSpent[pool] || 0}
              total={skillBudget[pool] || 0}
            />
          ))}
          <BudgetBar
            label={locale.labels.directions}
            used={computed.direction_spent || 0}
            total={computed.direction_budget || 0}
            color="#aa82d2"
          />
          <BudgetBar
            label={locale.labels.items}
            used={computed.item_spent || 0}
            total={computed.item_budget || 0}
          />
        </>
      ) : null}
    </Box>
  );
};

const StepReset = (props: { ctx: Ctx; step: StepId }) => {
  const { act, locale } = props.ctx;
  const section = {
    class: null,
    background: null,
    abilities: 'stats',
    skills: 'skills',
    directions: 'directions',
    spells: 'directions',
    flaws: 'traits',
    equipment: 'items',
    summary: 'all',
  }[props.step];
  if (!section) {
    return null;
  }
  return (
    <Button compact icon="undo" onClick={() => act('reset', { section })}>
      {section === 'all' ? locale.labels.resetAll : locale.labels.reset}
    </Button>
  );
};

const BottomBar = (props: {
  ctx: Ctx;
  step: StepId;
  setStep: (step: StepId) => void;
}) => {
  const { act, data, locale, computed } = props.ctx;
  const index = STEPS.indexOf(props.step);
  const hasErrors = (computed.errors || []).length > 0;
  return (
    <Box style={{ ...panelStyle, padding: '6px 10px' }}>
      <Stack align="center">
        <Stack.Item>
          <Button
            icon="history"
            disabled={!data.dirty}
            onClick={() => act('revert')}
          >
            {locale.labels.revert}
          </Button>
        </Stack.Item>
        <Stack.Item grow textAlign="center">
          <Button
            icon="chevron-left"
            disabled={index <= 0}
            onClick={() => props.setStep(STEPS[index - 1])}
          >
            {locale.labels.back}
          </Button>
          <Button
            iconPosition="right"
            icon="chevron-right"
            disabled={index >= STEPS.length - 1}
            onClick={() => props.setStep(STEPS[index + 1])}
          >
            {locale.labels.next}
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="save"
            color={hasErrors ? 'bad' : 'good'}
            disabled={!data.dirty}
            tooltip={hasErrors ? locale.notice('cannot_save') : undefined}
            onClick={() => act('save')}
          >
            {locale.labels.save}
          </Button>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

// ---------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------

const StepContent = (props: { ctx: Ctx; step: StepId }) => {
  switch (props.step) {
    case 'class':
      return <ClassStep ctx={props.ctx} />;
    case 'background':
      return <BackgroundStep ctx={props.ctx} />;
    case 'abilities':
      return <AbilitiesStep ctx={props.ctx} />;
    case 'skills':
      return <SkillsStep ctx={props.ctx} />;
    case 'directions':
      return <DirectionsStep ctx={props.ctx} spells={false} />;
    case 'spells':
      return <DirectionsStep ctx={props.ctx} spells />;
    case 'flaws':
      return <FlawsStep ctx={props.ctx} />;
    case 'equipment':
      return <EquipmentStep ctx={props.ctx} />;
    case 'summary':
      return <SummaryStep ctx={props.ctx} />;
    default:
      return null;
  }
};

const RolePicker = (props: { ctx: Ctx; action: 'slot_new' | 'set_role' }) => {
  const { act, data, locale, build } = props.ctx;
  const groups = Array.from(new Set(data.roles.map((role) => role.group)));
  return (
    <>
      {groups.map((group) => (
        <Box key={group} mb={2}>
          <Box bold color={C.label} mb={1}>
            {locale.groups[group] || group}
          </Box>
          <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {data.roles
              .filter((role) => role.group === group)
              .map((role) => {
                const selected =
                  props.action === 'set_role' && build?.role === role.type;
                return (
                  <Box
                    key={role.type}
                    onClick={() => act(props.action, { role: role.type })}
                    style={{
                      ...cardStyle(selected ? 'selected' : 'available'),
                      width: '150px',
                      textAlign: 'center',
                    }}
                  >
                    <Box bold>{role.title}</Box>
                    <Box color={C.label} fontSize="0.8em">
                      {locale.labels.stats} {role.stat_points} ·{' '}
                      {locale.labels.directions} {role.direction_points} ·{' '}
                      {locale.labels.items} {role.item_points}
                    </Box>
                  </Box>
                );
              })}
          </Box>
        </Box>
      ))}
    </>
  );
};

const ClassStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, build } = props.ctx;
  if (!build) {
    return null;
  }
  return (
    <>
      <Stack mb={2}>
        <Stack.Item grow>
          <Box color={C.label} mb={0.5}>
            {locale.labels.buildName}
          </Box>
          <Input
            fluid
            value={build.name}
            maxLength={data.limits.name_max}
            onBlur={(value) =>
              value !== build.name && act('set_name', { value })
            }
          />
        </Stack.Item>
        <Stack.Item grow>
          <Box color={C.label} mb={0.5}>
            {locale.labels.classTitle}
          </Box>
          <Input
            fluid
            value={build.title}
            placeholder={props.ctx.role?.title}
            maxLength={data.limits.name_max}
            onBlur={(value) =>
              value !== build.title && act('set_title', { value })
            }
          />
          <Box color={C.dim} fontSize="0.8em" mt={0.5}>
            {locale.labels.classTitleHint}
          </Box>
        </Stack.Item>
      </Stack>
      <Box bold color={C.gold} mb={1}>
        {locale.labels.role}
      </Box>
      <RolePicker ctx={props.ctx} action="set_role" />
    </>
  );
};

const BackgroundStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, build, computed, t, d } = props.ctx;
  const blocked = asMap(computed.blocked);
  const selected = asArray(data.backgrounds).find(
    (bg) => bg.id === build?.background,
  );
  return (
    <Stack fill>
      <Stack.Item basis="45%">
        <Box
          onClick={() => act('set_background', { id: null })}
          style={{
            ...cardStyle(build?.background ? 'available' : 'selected'),
            marginBottom: '6px',
          }}
        >
          <Box bold>{locale.labels.noBackground}</Box>
        </Box>
        {asArray(data.backgrounds).map((bg) => {
          const block = blocked[bg.id];
          const isSelected = bg.id === build?.background;
          return (
            <Box
              key={bg.id}
              onClick={() => !block && act('set_background', { id: bg.id })}
              style={{
                ...cardStyle(
                  isSelected ? 'selected' : block ? 'blocked' : 'available',
                ),
                marginBottom: '6px',
              }}
            >
              <Box bold>{t(bg)}</Box>
              <Box fontSize="0.8em" color="#be9edc">
                {Object.entries(asMap(bg.directions))
                  .map(([id, levels]) => `+${levels} ${props.ctx.nameOf(id)}`)
                  .join(', ')}
              </Box>
              {block ? (
                <Box fontSize="0.8em" color={C.bad}>
                  {locale.block(block.code, block.value)}
                </Box>
              ) : null}
            </Box>
          );
        })}
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <Box style={{ ...panelStyle, background: C.panelDark }}>
            <Box bold color={C.title} fontSize="1.2em" mb={1}>
              {t(selected)}
            </Box>
            <Box color={C.text} mb={2}>
              {d(selected)}
            </Box>
            <DetailList
              title={locale.labels.skills}
              items={selected.skills.map((s) => `${s.name} +${s.rank}`)}
            />
            <DetailList
              title={locale.labels.directions}
              items={Object.entries(asMap(selected.directions)).map(
                ([id, levels]) => `${props.ctx.nameOf(id)} +${levels}`,
              )}
            />
            <DetailList
              title={locale.labels.traits}
              items={selected.traits.map((tr) => tr.name)}
            />
            <DetailList
              title={locale.labels.languages}
              items={selected.languages}
            />
          </Box>
        ) : null}
      </Stack.Item>
    </Stack>
  );
};

const DetailList = (props: { title: string; items: string[] }) =>
  props.items.length ? (
    <Box mb={1}>
      <Box bold color={C.label}>
        {props.title}
      </Box>
      {props.items.map((item) => (
        <Box key={item} color={C.text} ml={1}>
          • {item}
        </Box>
      ))}
    </Box>
  ) : null;

const AbilitiesStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, build, t } = props.ctx;
  if (!build) {
    return null;
  }
  const stats = asMap(build.stats);
  const base = data.limits.stat_base;
  const floor = data.limits.stat_floor;
  return (
    <>
      {asArray(data.stats).map((stat) => {
        const value = stats[stat.id] ?? base;
        return (
          <Box
            key={stat.id}
            style={{
              ...cardStyle('available'),
              display: 'flex',
              alignItems: 'center',
              marginBottom: '6px',
              cursor: 'default',
            }}
          >
            <Box style={{ width: '170px' }}>
              <Box bold>{t(stat)}</Box>
              <Box color={C.label} fontSize="0.8em">
                {locale.labels.cost} {stat.cost} {locale.labels.costStep} ·{' '}
                {locale.labels.max} {stat.max}
              </Box>
            </Box>
            <Box style={{ flexGrow: 1 }}>
              <Pips
                value={value - floor + 1}
                total={stat.max - floor + 1}
                size={12}
              />
            </Box>
            <Counter
              value={value}
              color={value > base ? C.title : value < base ? C.bad : C.text}
              canDec={value > floor}
              canInc={value < stat.max}
              onDec={() => act('stat_adjust', { id: stat.id, delta: -1 })}
              onInc={() => act('stat_adjust', { id: stat.id, delta: 1 })}
            />
          </Box>
        );
      })}
      <Box
        style={{
          ...cardStyle('blocked'),
          display: 'flex',
          alignItems: 'center',
        }}
      >
        <Box style={{ flexGrow: 1 }}>
          <Box bold color={C.label}>
            {locale.labels.charisma} ({locale.labels.derived})
          </Box>
          <Box fontSize="0.8em">{locale.labels.charismaHint}</Box>
        </Box>
        <Box bold color={C.label} fontSize="1.15em" mr={4}>
          {Math.max(stats.int ?? base, stats.for ?? base)}
        </Box>
      </Box>
    </>
  );
};

const SkillsStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, build, computed, t } = props.ctx;
  const [search, setSearch] = useState('');
  if (!build) {
    return null;
  }
  const purchased = asMap(build.skills);
  const finals = asMap(computed.final_skills);
  const spent = asMap(computed.skill_spent);
  const budget = asMap(computed.skill_budget);
  const query = search.toLowerCase();
  return (
    <>
      <Input
        fluid
        placeholder={locale.labels.search}
        value={search}
        onChange={setSearch}
        mb={1}
      />
      <Stack>
        {POOLS.map((pool) => (
          <Stack.Item key={pool} grow basis={0}>
            <Box
              bold
              color={(spent[pool] || 0) > (budget[pool] || 0) ? C.bad : C.gold}
              mb={1}
            >
              {locale.pools[pool]} {fmt(spent[pool])} / {fmt(budget[pool])}
            </Box>
            {asArray(data.skills)
              .filter((skill) => skill.pool === pool)
              .filter(
                (skill) => !query || t(skill).toLowerCase().includes(query),
              )
              .map((skill) => {
                const rank = purchased[skill.id] || 0;
                const final = finals[skill.id] || 0;
                return (
                  <Box
                    key={skill.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      padding: '3px 4px',
                      borderBottom: `1px solid ${C.borderSoft}`,
                    }}
                  >
                    <Box style={{ flexGrow: 1 }}>
                      <Box>{t(skill)}</Box>
                      <Pips
                        value={rank}
                        bonus={Math.max(0, final - rank)}
                        total={data.limits.skill_max_rank}
                        size={8}
                      />
                    </Box>
                    <Counter
                      value={final > rank ? `${rank}(${final})` : rank}
                      color={final > rank ? C.title : C.text}
                      canDec={rank > 0}
                      canInc={rank < skill.cap}
                      onDec={() =>
                        act('skill_adjust', { id: skill.id, delta: -1 })
                      }
                      onInc={() =>
                        act('skill_adjust', { id: skill.id, delta: 1 })
                      }
                    />
                  </Box>
                );
              })}
          </Stack.Item>
        ))}
      </Stack>
    </>
  );
};

const DirectionsStep = (props: { ctx: Ctx; spells: boolean }) => {
  const { act, data, locale, build, computed } = props.ctx;
  const directions = asArray(data.directions).filter(
    (dir) => !props.spells || MAGIC_DIRECTIONS.includes(dir.id),
  );
  const [focus, setFocus] = useState<string>(directions[0]?.id || '');
  if (!build) {
    return null;
  }
  const invested = asMap(build.directions);
  const levels = asMap(computed.direction_levels);
  const caps = asMap(computed.direction_caps);
  const talentSpent = asMap(computed.talent_spent);
  const current = directions.find((dir) => dir.id === focus) || directions[0];
  const talents = asArray(data.talents).filter(
    (talent) =>
      talent.direction === current?.id && !!talent.is_spell === props.spells,
  );
  const tiers = Array.from(new Set(talents.map((talent) => talent.tier))).sort(
    (a, b) => a - b,
  );
  return (
    <>
      <Box style={{ display: 'flex', gap: '6px', marginBottom: '10px' }}>
        {directions.map((dir) => {
          const active = dir.id === current?.id;
          const level = levels[dir.id] || 0;
          const cap = caps[dir.id] ?? dir.max;
          const points = invested[dir.id] || 0;
          return (
            <Box
              key={dir.id}
              onClick={() => setFocus(dir.id)}
              style={{
                ...cardStyle(
                  active ? 'selected' : cap ? 'available' : 'blocked',
                ),
                borderColor: active ? dir.color : undefined,
                flex: '1 1 0',
                textAlign: 'center',
              }}
            >
              <Box bold fontSize="1.6em" color={level ? dir.color : C.dim}>
                {level}
              </Box>
              <Box fontSize="0.85em">{props.ctx.t(dir)}</Box>
              <Box fontSize="0.75em" color={C.label}>
                {locale.labels.talents} {fmt(talentSpent[dir.id])}/{level}
              </Box>
              <Box mt={0.5} onClick={(e) => e.stopPropagation()}>
                <Counter
                  value={points}
                  canDec={points > 0}
                  canInc={points < cap}
                  onDec={() =>
                    act('direction_adjust', { id: dir.id, delta: -1 })
                  }
                  onInc={() =>
                    act('direction_adjust', { id: dir.id, delta: 1 })
                  }
                />
              </Box>
            </Box>
          );
        })}
      </Box>
      {tiers.length === 0 ? (
        <Box color={C.dim} italic>
          {locale.labels.empty}
        </Box>
      ) : null}
      {tiers.map((tier) => (
        <Box
          key={tier}
          style={{
            display: 'flex',
            borderBottom: `1px solid ${C.borderSoft}`,
            padding: '6px 0',
          }}
        >
          <Box style={{ width: '80px', flexShrink: 0 }}>
            <Box bold color={C.gold}>
              {locale.labels.tier} {tier}
            </Box>
            <Box fontSize="0.8em" color={C.label}>
              {props.ctx.t(current)} {tier}
            </Box>
          </Box>
          <Box
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '6px',
              flexGrow: 1,
            }}
          >
            {talents
              .filter((talent) => talent.tier === tier)
              .map((talent) => (
                <TalentCard key={talent.id} ctx={props.ctx} talent={talent} />
              ))}
          </Box>
        </Box>
      ))}
    </>
  );
};

const EntryTooltip = (props: {
  ctx: Ctx;
  entry: Entry;
  lines: (string | null | undefined)[];
  block?: Block;
}) => {
  const { t, d, locale } = props.ctx;
  return (
    <Box style={{ maxWidth: '320px' }}>
      <Box bold color={C.title}>
        {t(props.entry)}
      </Box>
      {d(props.entry) ? <Box mt={0.5}>{d(props.entry)}</Box> : null}
      {props.lines
        .filter((line): line is string => !!line)
        .map((line) => (
          <Box key={line} mt={0.5} color={C.label}>
            {line}
          </Box>
        ))}
      {props.block ? (
        <Box mt={0.5} color={C.bad}>
          {locale.block(props.block.code, props.block.value)}
        </Box>
      ) : null}
    </Box>
  );
};

const TalentCard = (props: { ctx: Ctx; talent: TalentEntry }) => {
  const { act, locale, build, computed, t, nameOf } = props.ctx;
  const { talent } = props;
  const selected = !!build?.talents.includes(talent.id);
  const block = asMap(computed.blocked)[talent.id];
  const state = selected ? 'selected' : block ? 'blocked' : 'available';
  const lines = [
    talent.spells.length
      ? `${locale.labels.spells}: ${talent.spells.join(', ')}`
      : null,
    talent.traits.length
      ? `${locale.labels.traits}: ${talent.traits.map((tr) => tr.desc || tr.name).join('; ')}`
      : null,
    talent.skills.length
      ? `${locale.labels.grants}: ${talent.skills.map((s) => `${s.name} +${s.rank}`).join(', ')}`
      : null,
    talent.patrons.length
      ? `${locale.labels.patrons}: ${talent.patrons.join(', ')}`
      : null,
    talent.requires.length
      ? `${locale.labels.requires}: ${talent.requires.map(nameOf).join(', ')}`
      : null,
  ];
  return (
    <Tooltip
      position="bottom"
      content={
        <EntryTooltip
          ctx={props.ctx}
          entry={talent}
          lines={lines}
          block={block}
        />
      }
    >
      <div
        onClick={() =>
          (selected || !block) && act('talent_toggle', { id: talent.id })
        }
        style={{ ...cardStyle(state), width: '200px', position: 'relative' }}
      >
        <Box bold>{t(talent)}</Box>
        <Box fontSize="0.8em" color={state === 'blocked' ? C.dim : C.title}>
          {locale.labels.cost} {talent.cost}
        </Box>
        {selected ? (
          <Box style={{ position: 'absolute', right: '6px', bottom: '4px' }}>
            <Icon name="check" color={C.ok} />
          </Box>
        ) : null}
      </div>
    </Tooltip>
  );
};

const FlawsStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, build, computed, t } = props.ctx;
  if (!build) {
    return null;
  }
  const blocked = asMap(computed.blocked);
  return (
    <>
      <Box color={C.label} mb={1}>
        {locale.labels.flaws}: {computed.flaw_count || 0} /{' '}
        {computed.flaw_max || 0} · +{computed.flaw_points || 0}{' '}
        {locale.labels.points}
      </Box>
      <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
        {asArray(data.flaws).map((flaw) => {
          const selected = build.flaws.includes(flaw.id);
          const block = blocked[flaw.id];
          const lines = [
            flaw.traits.length
              ? `${locale.labels.traits}: ${flaw.traits.map((tr) => tr.desc || tr.name).join('; ')}`
              : null,
          ];
          return (
            <Tooltip
              key={flaw.id}
              position="bottom"
              content={
                <EntryTooltip
                  ctx={props.ctx}
                  entry={flaw}
                  lines={lines}
                  block={block}
                />
              }
            >
              <div
                onClick={() =>
                  (selected || !block) && act('flaw_toggle', { id: flaw.id })
                }
                style={{
                  ...cardStyle(
                    selected
                      ? 'negativeSelected'
                      : block
                        ? 'blocked'
                        : 'negative',
                  ),
                  width: '200px',
                }}
              >
                <Box bold>{t(flaw)}</Box>
                <Box fontSize="0.8em" color={C.neg}>
                  +{flaw.points} {locale.labels.points}
                </Box>
              </div>
            </Tooltip>
          );
        })}
      </Box>
    </>
  );
};

const EquipmentStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, build, computed, t } = props.ctx;
  const [slot, setSlot] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  if (!build) {
    return null;
  }
  const equipment = asMap(build.equipment);
  const freeKit = asMap(props.ctx.role?.free_kit);
  const blocked = asMap(computed.blocked);
  const items = asArray(data.items);
  const itemById = (id?: string) => items.find((item) => item.id === id);
  const query = search.toLowerCase();
  const pool = items
    .filter((item) => (slot ? item.slots.includes(slot) : true))
    .filter((item) => !query || t(item).toLowerCase().includes(query));
  const categories = Array.from(new Set(pool.map((item) => item.category)));

  const itemLines = (item: ItemEntry) => [
    `${locale.labels.cost}: ${fmt(item.cost)}`,
    item.slots.length
      ? item.slots.map((s) => locale.slots[s] || s).join(', ')
      : locale.labels.carried,
    item.required_skill
      ? `${locale.labels.requires}: ${item.required_skill.name} ${item.required_skill.rank}`
      : null,
    item.required_talent
      ? `${locale.labels.requires}: ${item.required_talent}`
      : null,
  ];

  return (
    <Stack fill>
      <Stack.Item basis="230px">
        <Box
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 64px)',
            gap: '6px',
            justifyContent: 'center',
          }}
        >
          {data.doll_slots.map((slotId) => {
            const item = itemById(equipment[slotId]);
            const freeItem = item ? undefined : freeKit[slotId];
            const active = slot === slotId;
            return (
              <Tooltip
                key={slotId}
                position="right"
                content={
                  item ? (
                    <EntryTooltip
                      ctx={props.ctx}
                      entry={item}
                      lines={itemLines(item)}
                    />
                  ) : freeItem ? (
                    `${locale.slots[slotId] || slotId}: ${freeItem.name} (${locale.labels.freeKit})`
                  ) : (
                    locale.slots[slotId] || slotId
                  )
                }
              >
                <div
                  onClick={() => setSlot(active ? null : slotId)}
                  style={{
                    width: '64px',
                    height: '64px',
                    gridColumn: slotId === 'shoes' ? '2' : undefined,
                    background: item ? '#33281a' : '#282018',
                    border: `${active ? 2 : 1}px solid ${active ? C.gold : item ? '#8a6a3c' : C.border}`,
                    borderRadius: '4px',
                    position: 'relative',
                    cursor: 'pointer',
                  }}
                >
                  <Box
                    style={{ position: 'absolute', left: '3px', top: '1px' }}
                    fontSize="0.7em"
                    color={C.label}
                  >
                    {locale.slots[slotId] || slotId}
                  </Box>
                  <Box
                    style={{ position: 'absolute', left: '16px', top: '14px' }}
                  >
                    <Box style={{ opacity: freeItem ? 0.45 : 1 }}>
                      <ItemIcon item={item || freeItem} />
                    </Box>
                  </Box>
                  {item || freeItem ? (
                    <Box
                      style={{
                        position: 'absolute',
                        left: '2px',
                        right: '2px',
                        bottom: '1px',
                        overflow: 'hidden',
                        whiteSpace: 'nowrap',
                        textOverflow: 'ellipsis',
                      }}
                      fontSize="0.65em"
                      color={item ? C.title : C.dim}
                      textAlign="center"
                    >
                      {item ? t(item) : freeItem?.name}
                    </Box>
                  ) : null}
                </div>
              </Tooltip>
            );
          })}
        </Box>
        {slot && equipment[slot] ? (
          <Box textAlign="center" mt={1}>
            <Button
              icon="times"
              onClick={() => act('equip', { slot, id: null })}
            >
              {locale.labels.clearSlot}
            </Button>
          </Box>
        ) : null}
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Input
          fluid
          placeholder={locale.labels.search}
          value={search}
          onChange={setSearch}
          mb={1}
        />
        <Box color={C.label} mb={1}>
          {slot
            ? locale.slots[slot] || slot
            : `${locale.labels.carried} · ${locale.labels.pickSlot}`}
        </Box>
        {pool.length === 0 ? (
          <Box color={C.dim} italic>
            {locale.labels.noItemsForSlot}
          </Box>
        ) : null}
        {categories.map((category) => (
          <Box key={category} mb={1}>
            <Box bold color={C.title}>
              {locale.categories[category] || category}
            </Box>
            <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
              {pool
                .filter((item) => item.category === category)
                .map((item) => {
                  const block = blocked[item.id];
                  return (
                    <Tooltip
                      key={item.id}
                      position="bottom"
                      content={
                        <EntryTooltip
                          ctx={props.ctx}
                          entry={item}
                          lines={itemLines(item)}
                          block={block}
                        />
                      }
                    >
                      <div
                        style={{
                          ...cardStyle(
                            block
                              ? 'blocked'
                              : equipment[slot || ''] === item.id
                                ? 'selected'
                                : 'available',
                          ),
                          width: '84px',
                          minHeight: '78px',
                          textAlign: 'center',
                          position: 'relative',
                        }}
                        onClick={() => {
                          if (block) {
                            return;
                          }
                          if (slot) {
                            act('equip', { slot, id: item.id });
                          } else {
                            act('carry_add', { id: item.id, zone: 'bag' });
                          }
                        }}
                      >
                        <Box
                          style={{
                            position: 'absolute',
                            right: '4px',
                            top: '2px',
                          }}
                          fontSize="0.75em"
                          bold
                          color={block ? C.dim : C.title}
                        >
                          {fmt(item.cost)}
                        </Box>
                        <ItemIcon item={item} />
                        <Box
                          fontSize="0.75em"
                          style={{ overflow: 'hidden', maxHeight: '2.6em' }}
                        >
                          {t(item)}
                        </Box>
                      </div>
                    </Tooltip>
                  );
                })}
            </Box>
          </Box>
        ))}
        <CarriedList
          ctx={props.ctx}
          zone="bag"
          title={locale.labels.bag}
          itemById={itemById}
        />
        <CarriedList
          ctx={props.ctx}
          zone="stash"
          title={locale.labels.stash}
          itemById={itemById}
        />
        {data.loadout.length ? (
          <Box mt={1}>
            <Box bold color={C.label}>
              {locale.labels.loadout} → {locale.labels.stash}
            </Box>
            <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
              {data.loadout.map((entry, i) => (
                <Tooltip key={`${entry.name}${i}`} content={entry.name}>
                  <div
                    style={{
                      ...cardStyle('blocked'),
                      minHeight: 0,
                      padding: '2px',
                    }}
                  >
                    <ItemIcon item={entry} />
                  </div>
                </Tooltip>
              ))}
            </Box>
          </Box>
        ) : null}
      </Stack.Item>
    </Stack>
  );
};

const CarriedList = (props: {
  ctx: Ctx;
  zone: 'bag' | 'stash';
  title: string;
  itemById: (id?: string) => ItemEntry | undefined;
}) => {
  const { act, data, locale, build, t } = props.ctx;
  const list = build ? build[props.zone] : [];
  return (
    <Box mt={1}>
      <Box bold color={C.gold}>
        {props.title} ({list.length}/{data.limits.max_carried})
      </Box>
      {list.length === 0 ? (
        <Box color={C.dim} italic>
          {locale.labels.empty}
        </Box>
      ) : null}
      <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
        {list.map((id, index) => {
          const item = props.itemById(id);
          return (
            <Box
              key={`${id}-${index}`}
              style={{
                ...cardStyle('available'),
                minHeight: 0,
                padding: '2px 4px',
                cursor: 'default',
              }}
            >
              <Stack align="center">
                <Stack.Item>
                  <ItemIcon item={item} size={24} />
                </Stack.Item>
                <Stack.Item>
                  <Box fontSize="0.8em">{item ? t(item) : id}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    compact
                    icon="exchange-alt"
                    tooltip={
                      props.zone === 'bag'
                        ? locale.labels.toStash
                        : locale.labels.toBag
                    }
                    onClick={() =>
                      act('carry_move', { zone: props.zone, index: index + 1 })
                    }
                  />
                  <Button
                    compact
                    icon="times"
                    tooltip={locale.labels.remove}
                    onClick={() =>
                      act('carry_remove', {
                        zone: props.zone,
                        index: index + 1,
                      })
                    }
                  />
                </Stack.Item>
              </Stack>
            </Box>
          );
        })}
      </Box>
    </Box>
  );
};

const SummaryStep = (props: { ctx: Ctx }) => {
  const { act, data, locale, computed, nameOf } = props.ctx;
  const [importText, setImportText] = useState('');
  const errors = computed.errors || [];
  return (
    <>
      <Box bold color={C.gold} mb={1}>
        {locale.labels.errors}
      </Box>
      {errors.length === 0 ? (
        <Box color={C.ok} mb={2}>
          <Icon name="check" /> {locale.labels.noErrors}
        </Box>
      ) : (
        <Box mb={2}>
          {errors.map((error) => (
            <Box key={`${error.code}:${error.arg}`} color={C.bad}>
              <Icon name="exclamation-triangle" />{' '}
              {locale.error(
                error.code,
                error.code === 'skill_over'
                  ? locale.pools[error.arg || '']
                  : error.code === 'talent_over'
                    ? nameOf(error.arg || '')
                    : error.arg,
                nameOf,
              )}
            </Box>
          ))}
        </Box>
      )}
      <Box bold color={C.gold} mb={1}>
        {locale.labels.exchange}
      </Box>
      <Stack mb={1}>
        <Stack.Item>
          <Button icon="file-export" onClick={() => act('export')}>
            {locale.labels.export}
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="file-import"
            disabled={!importText}
            onClick={() => act('import', { text: importText })}
          >
            {locale.labels.import}
          </Button>
        </Stack.Item>
      </Stack>
      {data.export_text ? (
        <TextArea fluid height="80px" value={data.export_text} mb={1} />
      ) : null}
      <Box color={C.label} fontSize="0.85em" mb={0.5}>
        {locale.labels.importHint}
      </Box>
      <TextArea
        fluid
        height="80px"
        value={importText}
        maxLength={data.limits.import_max}
        onChange={setImportText}
      />
    </>
  );
};

// ---------------------------------------------------------------------------
// Right column: BG3-style summary
// ---------------------------------------------------------------------------

const Summary = (props: { ctx: Ctx }) => {
  const { data, locale, build, computed, role, t } = props.ctx;
  if (!build) {
    return null;
  }
  const stats = asMap(build.stats);
  const finals = asMap(computed.final_skills);
  const levels = asMap(computed.direction_levels);
  const equipment = asMap(build.equipment);
  const background = asArray(data.backgrounds).find(
    (bg) => bg.id === build.background,
  );
  const base = data.limits.stat_base;
  const statBoxes = [
    ...asArray(data.stats).map((stat) => ({
      key: stat.id,
      label: stat.id.toUpperCase(),
      value: stats[stat.id] ?? base,
      derived: false,
    })),
    {
      key: 'cha',
      label: 'CHA',
      value: Math.max(stats.int ?? base, stats.for ?? base),
      derived: true,
    },
  ];
  return (
    <Panel fill title={build.title || role?.title || build.name}>
      <Box
        style={{
          ...panelStyle,
          background: C.panelDark,
          textAlign: 'center',
          marginBottom: '8px',
        }}
      >
        <Box bold color="#f0e1c8" fontSize="1.15em">
          {data.character_name}
        </Box>
        <Box color={C.label} fontSize="0.85em">
          {[data.species, data.patron].filter(Boolean).join(' · ')}
        </Box>
        <Box
          style={{
            height: '90px',
            margin: '6px auto 0',
            width: '64px',
            border: `1px dashed ${C.borderSoft}`,
            borderRadius: '4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Tooltip content={locale.labels.previewHint}>
            <Icon name="user" size={2} color={C.dim} />
          </Tooltip>
        </Box>
      </Box>
      <Box color={C.label} fontSize="0.85em">
        {locale.steps.background}:{' '}
        <Box as="span" color={C.text} bold>
          {background ? t(background) : '—'}
        </Box>
      </Box>
      <Box style={{ display: 'flex', gap: '3px', margin: '8px 0' }}>
        {statBoxes.map((box) => (
          <Box
            key={box.key}
            style={{
              flex: '1 1 0',
              background: C.panelDark,
              border: `1px solid ${box.derived ? C.borderSoft : C.border}`,
              borderRadius: '4px',
              textAlign: 'center',
              padding: '2px 0',
            }}
          >
            <Box fontSize="0.7em" color={C.label}>
              {box.label}
            </Box>
            <Box
              bold
              color={
                box.derived
                  ? C.label
                  : box.value > base
                    ? C.title
                    : box.value < base
                      ? C.bad
                      : C.text
              }
            >
              {box.value}
            </Box>
          </Box>
        ))}
      </Box>
      <Ornament />
      <Box bold color={C.gold} mb={0.5}>
        {locale.labels.skills}
      </Box>
      {asArray(data.skills)
        .filter((skill) => finals[skill.id])
        .map((skill) => (
          <Stack key={skill.id} align="center">
            <Stack.Item grow>
              <Box fontSize="0.9em">{t(skill)}</Box>
            </Stack.Item>
            <Stack.Item>
              <Pips
                value={finals[skill.id]}
                total={data.limits.skill_max_rank}
                size={8}
              />
            </Stack.Item>
          </Stack>
        ))}
      <Ornament />
      <Box bold color={C.gold} mb={0.5}>
        {locale.labels.directions}
      </Box>
      {asArray(data.directions)
        .filter((dir) => levels[dir.id])
        .map((dir) => (
          <Stack key={dir.id} align="center">
            <Stack.Item grow>
              <Box fontSize="0.9em">{t(dir)}</Box>
            </Stack.Item>
            <Stack.Item>
              <Pips
                value={levels[dir.id]}
                total={dir.max}
                color={dir.color}
                size={8}
              />
            </Stack.Item>
          </Stack>
        ))}
      <Ornament />
      <Box bold color={C.gold} mb={0.5}>
        {locale.labels.talents} / {locale.labels.flaws}
      </Box>
      <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
        {build.talents.map((id) => (
          <Box
            key={id}
            style={{
              ...cardStyle('selected'),
              minHeight: 0,
              padding: '1px 6px',
            }}
            fontSize="0.8em"
          >
            {props.ctx.nameOf(id)}
          </Box>
        ))}
        {build.flaws.map((id) => (
          <Box
            key={id}
            style={{
              ...cardStyle('negativeSelected'),
              minHeight: 0,
              padding: '1px 6px',
            }}
            fontSize="0.8em"
          >
            {props.ctx.nameOf(id)}
          </Box>
        ))}
      </Box>
      <Ornament />
      <Box bold color={C.gold} mb={0.5}>
        {locale.labels.items}
      </Box>
      <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '3px' }}>
        {Object.values(equipment).map((id) => {
          const item = asArray(data.items).find((entry) => entry.id === id);
          return (
            <Tooltip key={id} content={item ? t(item) : id}>
              <div
                style={{
                  ...cardStyle('available'),
                  minHeight: 0,
                  padding: '2px',
                  cursor: 'default',
                }}
              >
                <ItemIcon item={item} size={28} />
              </div>
            </Tooltip>
          );
        })}
      </Box>
    </Panel>
  );
};
