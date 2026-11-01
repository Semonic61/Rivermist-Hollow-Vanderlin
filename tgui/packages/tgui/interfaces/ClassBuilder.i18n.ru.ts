import type { ClassBuilderLocale } from './ClassBuilderView';

const pools: Record<string, string> = {
  combat: 'Боевые',
  peaceful: 'Мирные',
  adventure: 'Приключенческие',
};

const locale: ClassBuilderLocale = {
  lang: 'ru',
  windowTitle: 'Конструктор класса',
  steps: {
    class: 'Класс',
    background: 'Предыстория',
    abilities: 'Характеристики',
    skills: 'Навыки',
    directions: 'Направления',
    spells: 'Заклинания',
    flaws: 'Изъяны',
    equipment: 'Снаряжение',
    summary: 'Итог',
  },
  stepHints: {
    class:
      'Выберите роль, к которой относится этот путь, и как вас будут звать.',
    background:
      'Прошлое даёт бесплатные ранги навыков и уровни направлений сверх бюджета.',
    abilities:
      'База 10. Понижение ниже 10 возвращает очки, но не ниже 8. У каждого шага своя цена.',
    skills:
      'Три отдельных пула. Бесплатные ранги от предыстории и талантов показаны золотом.',
    directions:
      'Очки в направлении — это его уровень и валюта для его талантов. Чем выше уровень, тем выше ярусы.',
    spells:
      'Заклинания — это таланты Магии, Чудес и Музыки. Чем больше вложено, тем больше выбор.',
    flaws:
      'Каждый изъян даёт очки направлений. Некоторые изъяны несовместимы с талантами.',
    equipment:
      'Кликните слот на кукле, затем предмет. Ноша кладётся в сумки, а что не влезло — ждёт в сундуке.',
    summary: 'Проверьте билд и сохраните его. Экспорт превращает его в текст.',
  },
  pools,
  groups: {
    adventurer: 'Авантюристы',
    town: 'Горожане',
  },
  slots: {
    mask: 'Маска',
    head: 'Голова',
    mouth: 'Рот',
    backr: 'П. плечо',
    cloak: 'Плащ',
    backl: 'Л. плечо',
    neck: 'Шея',
    armor: 'Броня',
    wrists: 'Запястья',
    ring: 'Кольцо',
    shirt: 'Одежда',
    gloves: 'Перчатки',
    beltr: 'П. пояс',
    belt: 'Пояс',
    beltl: 'Л. пояс',
    r_hand: 'П. рука',
    pants: 'Ноги',
    l_hand: 'Л. рука',
    shoes: 'Обувь',
  },
  categories: {
    head: 'Голова',
    neck: 'Шея',
    cloak: 'Плащи',
    armor: 'Броня',
    clothing: 'Одежда',
    storage: 'Сумки и пояса',
    weapons: 'Оружие',
    supplies: 'Припасы',
    misc: 'Прочее',
  },
  labels: {
    builds: 'Билд',
    noBuilds: 'У этого персонажа ещё нет билдов. Выберите роль, чтобы начать.',
    spawnBuild: 'Билд для спавна',
    makeSpawnBuild: 'Спавниться с ним',
    spawnBuildHint:
      'Каждая роль спавнится со своим билдом со звездой. Первый билд роли получает звезду сам.',
    newBuild: 'Новый билд',
    duplicate: 'Копия',
    delete: 'Удалить',
    confirmDelete: 'Удалить насовсем?',
    save: 'Сохранить',
    revert: 'Откатить',
    unsaved: 'Есть несохранённые изменения',
    saved: 'Сохранено',
    back: 'Назад',
    next: 'Далее',
    reset: 'Сброс',
    resetAll: 'Сбросить всё',
    budgets: 'Бюджеты',
    stats: 'Характеристики',
    skills: 'Навыки',
    directions: 'Направления',
    items: 'Снаряжение',
    flaws: 'Изъяны',
    role: 'Роль',
    buildName: 'Название билда',
    classTitle: 'Имя класса на спавне',
    classTitleHint: 'Оставьте пустым, чтобы использовать название роли.',
    noBackground: 'Без предыстории',
    cost: 'Цена',
    costStep: 'за шаг',
    max: 'макс.',
    cap: 'кап',
    free: 'бесплатно',
    tier: 'Ярус',
    points: 'очк.',
    level: 'Уровень',
    talents: 'Таланты',
    spells: 'Заклинания',
    traits: 'Черты',
    languages: 'Языки',
    patrons: 'Покровители',
    requires: 'Требует',
    grants: 'Даёт',
    search: 'Поиск…',
    pickSlot: 'Выберите слот на кукле.',
    noItemsForSlot: 'Для этого слота нет предметов.',
    clearSlot: 'Очистить слот',
    carried: 'Ноша',
    bag: 'Сумки',
    stash: 'Сундук',
    loadout: 'Лоадаут',
    toBag: 'В сумки',
    toStash: 'В сундук',
    move: 'Переложить',
    remove: 'Убрать',
    empty: 'Пусто',
    character: 'Персонаж',
    species: 'Раса',
    patron: 'Покровитель',
    preview: 'Превью',
    previewHint: 'Превью персонажа появится вместе с общим стилем редактора.',
    errors: 'Проблемы',
    noErrors: 'Билд соответствует всем правилам.',
    exchange: 'Обмен',
    export: 'Экспорт',
    import: 'Импорт',
    importHint:
      'Вставьте билд. Сервер проверит его и сбросит всё, что нарушает правила.',
    derived: 'производная',
    charisma: 'Харизма',
    charismaHint: 'Харизма = max(Интеллект, Удача), используется в бросках.',
    freeKit: 'выдаётся бесплатно, если слот пуст',
  },
  block: (code, value) => {
    switch (code) {
      case 'tier':
        return `Нужен уровень направления ${value}`;
      case 'patron':
        return 'Ваш покровитель этого не даёт';
      case 'requires':
        return `Требует: ${value}`;
      case 'excludes':
        return `Несовместимо с: ${value}`;
      case 'skill':
        return `Нужно: ${value}`;
      case 'talent':
        return `Нужен талант: ${value}`;
      case 'role':
        return 'Недоступно этой роли';
      default:
        return 'Недоступно';
    }
  },
  error: (code, arg, nameOf) => {
    switch (code) {
      case 'no_role':
        return 'У билда нет допустимой роли.';
      case 'stat_over':
        return 'Потрачено слишком много очков характеристик.';
      case 'skill_over':
        return `Перерасход очков навыков: ${pools[arg || ''] || arg}.`;
      case 'direction_over':
        return 'Потрачено слишком много очков направлений.';
      case 'flaw_over':
        return 'Слишком много изъянов.';
      case 'talent_over':
        return `Таланты направления «${arg}» стоят больше его уровня.`;
      case 'item_over':
        return 'Снаряжение дороже бюджета.';
      case 'blocked':
        return `«${nameOf(arg || '')}» сейчас недоступно.`;
      default:
        return code;
    }
  },
  notice: (code, arg) => {
    switch (code) {
      case 'slot_changed':
        return 'Активный персонаж сменился, загружены его билды.';
      case 'saved':
        return 'Билд сохранён.';
      case 'activated':
        return `${arg} теперь билд для спавна этой роли.`;
      case 'save_failed':
        return 'Не удалось записать сохранение персонажа.';
      case 'cannot_save':
        return 'Сначала исправьте проблемы.';
      case 'max_builds':
        return 'Свободных слотов под билды не осталось.';
      case 'max_carried':
        return 'Этот список заполнен.';
      case 'imported':
        return 'Билд импортирован. Сохраните, чтобы оставить его.';
      case 'import_failed':
        return 'Этот текст не похож на билд.';
      case 'import_reset':
        return `Импортировано, но сброшено: ${arg}.`;
      case 'role_reset':
        return `Роль сменена, сброшено: ${arg}.`;
      default:
        return '';
    }
  },
};

export default locale;
