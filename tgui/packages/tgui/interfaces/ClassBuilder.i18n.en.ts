import type { ClassBuilderLocale } from './ClassBuilderView';

const locale: ClassBuilderLocale = {
  lang: 'en',
  windowTitle: 'Class Builder',
  steps: {
    class: 'Class',
    background: 'Background',
    abilities: 'Abilities',
    skills: 'Skills',
    directions: 'Directions',
    spells: 'Spells',
    flaws: 'Flaws',
    equipment: 'Equipment',
    summary: 'Summary',
  },
  stepHints: {
    class: 'Pick the role this path belongs to and how you will be called.',
    background:
      'Your past grants free skill ranks and direction levels on top of your budget.',
    abilities:
      'Base 10. Lowering below 10 refunds points, down to 8. Each step has its own price.',
    skills:
      'Three separate pools. Free ranks from your background and talents are shown in gold.',
    directions:
      'Points invested in a direction are its level and pay for its talents. Higher levels open higher tiers.',
    spells:
      'Spells are talents of Magic, Miracles and Music. More levels invested means more to choose from.',
    flaws:
      'Each flaw pays direction points. Some flaws cannot be taken with certain talents.',
    equipment:
      'Click a doll slot, then an item. Carried items go to your bags; whatever does not fit waits in your stash.',
    summary: 'Check the build, then save it. Export shares it as text.',
  },
  pools: {
    combat: 'Combat',
    peaceful: 'Peaceful',
    adventure: 'Adventure',
  },
  groups: {
    adventurer: 'Adventurers',
    town: 'Townsfolk',
  },
  slots: {
    mask: 'Mask',
    head: 'Head',
    mouth: 'Mouth',
    backr: 'R Shoulder',
    cloak: 'Cloak',
    backl: 'L Shoulder',
    neck: 'Neck',
    armor: 'Armor',
    wrists: 'Wrists',
    ring: 'Ring',
    shirt: 'Shirt',
    gloves: 'Gloves',
    beltr: 'R Belt',
    belt: 'Belt',
    beltl: 'L Belt',
    r_hand: 'R Hand',
    pants: 'Legs',
    l_hand: 'L Hand',
    shoes: 'Boots',
  },
  categories: {
    head: 'Head',
    neck: 'Neck',
    cloak: 'Cloaks',
    armor: 'Armor',
    clothing: 'Clothing',
    storage: 'Bags and belts',
    weapons: 'Weapons',
    supplies: 'Supplies',
    misc: 'Misc',
  },
  labels: {
    builds: 'Build',
    noBuilds: 'This character has no builds yet. Pick a role to start one.',
    spawnBuild: 'Spawn build',
    makeSpawnBuild: 'Use for spawn',
    spawnBuildHint:
      'Each role spawns with its starred build. The first build of a role is starred on its own.',
    newBuild: 'New build',
    duplicate: 'Duplicate',
    delete: 'Delete',
    confirmDelete: 'Delete for good?',
    save: 'Save',
    revert: 'Revert',
    unsaved: 'Unsaved changes',
    saved: 'Saved',
    back: 'Back',
    next: 'Next',
    reset: 'Reset',
    resetAll: 'Reset all',
    budgets: 'Budgets',
    stats: 'Abilities',
    skills: 'Skills',
    directions: 'Directions',
    items: 'Equipment',
    flaws: 'Flaws',
    role: 'Role',
    buildName: 'Build name',
    classTitle: 'Class name on spawn',
    classTitleHint: 'Leave empty to use the role title.',
    noBackground: 'No background',
    cost: 'Cost',
    costStep: 'per step',
    max: 'max',
    cap: 'cap',
    free: 'free',
    tier: 'Tier',
    points: 'pts',
    level: 'Level',
    talents: 'Talents',
    spells: 'Spells',
    traits: 'Traits',
    languages: 'Languages',
    patrons: 'Patrons',
    requires: 'Requires',
    grants: 'Grants',
    search: 'Search…',
    pickSlot: 'Pick a slot on the doll.',
    noItemsForSlot: 'No items fit this slot.',
    clearSlot: 'Clear slot',
    carried: 'Carried',
    bag: 'Bags',
    stash: 'Stash',
    loadout: 'Loadout',
    toBag: 'To bags',
    toStash: 'To stash',
    move: 'Move',
    remove: 'Remove',
    empty: 'Empty',
    character: 'Character',
    species: 'Species',
    patron: 'Patron',
    preview: 'Preview',
    previewHint: 'Character preview arrives with the shared editor style.',
    errors: 'Problems',
    noErrors: 'The build follows every rule.',
    exchange: 'Exchange',
    export: 'Export',
    import: 'Import',
    importHint:
      'Paste a build here. The server checks it and resets whatever breaks the rules.',
    derived: 'derived',
    charisma: 'Charisma',
    charismaHint: 'Charisma = max(Intellect, Fortune), used for rolls.',
    freeKit: 'given for free if the slot stays empty',
  },
  block: (code, value) => {
    switch (code) {
      case 'tier':
        return `Needs direction level ${value}`;
      case 'patron':
        return 'Your patron does not grant this';
      case 'requires':
        return `Requires ${value}`;
      case 'excludes':
        return `Conflicts with ${value}`;
      case 'skill':
        return `Needs ${value}`;
      case 'talent':
        return `Needs talent ${value}`;
      case 'role':
        return 'Not available to this role';
      default:
        return 'Unavailable';
    }
  },
  error: (code, arg, nameOf) => {
    switch (code) {
      case 'no_role':
        return 'The build has no valid role.';
      case 'stat_over':
        return 'Too many ability points spent.';
      case 'skill_over':
        return `Too many skill points in ${arg}.`;
      case 'direction_over':
        return 'Too many direction points spent.';
      case 'flaw_over':
        return 'Too many flaws.';
      case 'talent_over':
        return `Talents of ${arg} cost more than its level.`;
      case 'item_over':
        return 'Equipment costs more than the budget.';
      case 'blocked':
        return `${nameOf(arg || '')} is not available.`;
      default:
        return code;
    }
  },
  notice: (code, arg) => {
    switch (code) {
      case 'slot_changed':
        return 'The active character changed, its builds were loaded.';
      case 'saved':
        return 'Build saved.';
      case 'activated':
        return `${arg} is now the spawn build of its role.`;
      case 'save_failed':
        return 'Could not write the character save.';
      case 'cannot_save':
        return 'Fix the problems before saving.';
      case 'max_builds':
        return 'No free build slots left.';
      case 'max_carried':
        return 'That list is full.';
      case 'imported':
        return 'Build imported. Save to keep it.';
      case 'import_failed':
        return 'That text is not a valid build.';
      case 'import_reset':
        return `Imported, but these parts were reset: ${arg}.`;
      case 'role_reset':
        return `Role changed, these parts were reset: ${arg}.`;
      default:
        return '';
    }
  },
};

export default locale;
