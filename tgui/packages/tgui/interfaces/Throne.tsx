// RMH: visual adaptation of PatapoIIIa's Twilight-Axis Throne TGUI, PR #1279.
// Design commit 34fef544c90a21223b6c0c04a93a1f283cc2ea8a; upstream AGPL-3.0.
// Uses RMH's existing THROAT actions and authority checks.
import { type CSSProperties, useState } from 'react';
import {
  Button,
  DmIcon,
  Icon,
  Input,
  Section,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { decodeHtmlEntities } from 'tgui-core/string';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import '../styles/interfaces/RmhThrone.scss';
import { Prose } from './RmhScribeStand/Layout';
import { RmhLocaleProvider, useRmhLanguage } from './RmhScribeStand/locale';

export type ThroneData = {
  language?: string;
  wearing_crown: BooleanLike;
  is_ruler: BooleanLike;
  is_regent: BooleanLike;
  worthy: BooleanLike;
  cooldown_ok: BooleanLike;
  can_command: BooleanLike;
  can_announce: BooleanLike;
  ruler_name: string;
  regent_name: string;
  tax_percent: number;
  lord_primary: string | null;
  lord_secondary: string | null;
  flag_icon: string;
  flag_state: string;
  throat_mode: string;
  crown_present: BooleanLike;
  key_present: BooleanLike;
  decree_records: {
    id: string;
    text: string;
    text_en?: string;
    revision: number;
  }[];
  outlaws: string[];
  voice_commands: string[];
};
type Act = (action: string, params?: Record<string, unknown>) => void;
type Text = (russian: string, english: string) => string;
type Page =
  | 'overview'
  | 'decrees'
  | 'commands'
  | 'justice'
  | 'heraldry'
  | 'voice';
const pages: { id: Page; ru: string; en: string; icon: string }[] = [
  { id: 'overview', ru: 'Двор', en: 'Court', icon: 'crown' },
  { id: 'decrees', ru: 'Указы', en: 'Decrees', icon: 'scroll' },
  { id: 'commands', ru: 'Управление', en: 'Governance', icon: 'landmark' },
  { id: 'justice', ru: 'Правосудие', en: 'Justice', icon: 'scale-balanced' },
  { id: 'heraldry', ru: 'Геральдика', en: 'Heraldry', icon: 'shield-halved' },
  {
    id: 'voice',
    ru: 'Голосовые команды',
    en: 'Voice commands',
    icon: 'bullhorn',
  },
];
function useCourtText(): Text {
  const language = useRmhLanguage();
  return (ru, en) => (language === 'ru' ? ru : en);
}
export function Throne() {
  const { data, act } = useBackend<ThroneData>();
  const width = Math.min(1180, (window.screen.availWidth || 1280) - 40);
  const height = Math.min(760, (window.screen.availHeight || 900) - 60);
  return (
    <RmhLocaleProvider language={data.language}>
      <Window width={width} height={height} theme="rmh-court">
        <Window.Content>
          <CourtWorkspace data={data} act={act} />
        </Window.Content>
      </Window>
    </RmhLocaleProvider>
  );
}
export function CourtWorkspace({ data, act }: { data: ThroneData; act: Act }) {
  const t = useCourtText();
  const [page, setPage] = useState<Page>('overview');
  const [selected, setSelected] = useState<string | null>(null);
  const [previewEnglish, setPreviewEnglish] = useState(
    useRmhLanguage() === 'en',
  );
  const command = !!data.can_command && !!data.cooldown_ok;
  const announcement = !!data.can_announce && !!data.cooldown_ok;
  const reason = !data.wearing_crown
    ? t('Нужна корона.', 'The crown is required.')
    : !data.worthy
      ? t('Только правитель или регент.', 'Ruler or regent required.')
      : !data.cooldown_ok
        ? t('THROAT набирается сил.', 'THROAT is gathering strength.')
        : '';
  const records = data.decree_records || [];
  return (
    <div className="RmhThrone">
      <div
        className="RmhThrone__board"
        style={
          {
            '--ducal-primary': data.lord_primary || '#183a56',
            '--ducal-secondary': data.lord_secondary || '#e0cc9b',
          } as CSSProperties
        }
      >
        <CourtHeader data={data} act={act} t={t} />
        <div className="RmhThrone__courtShell">
          <CourtNavigation page={page} onPage={setPage} t={t} />
          <main className="RmhThrone__centerPanel">
            <div className="RmhThrone__statusGrid">
              <CourtStatus
                label={t('Корона', 'Crown')}
                value={
                  data.wearing_crown
                    ? t('Надета', 'Worn')
                    : t('Не надета', 'Not worn')
                }
                icon="crown"
                good={!!data.wearing_crown}
              />
              <CourtStatus
                label={t('Налог', 'Tax')}
                value={`${data.tax_percent}%`}
                icon="coins"
                good
              />
              <CourtStatus
                label={t('Глас трона', 'Throne voice')}
                value={
                  data.cooldown_ok
                    ? t('Готов', 'Ready')
                    : t('Набирается сил', 'Gathering strength')
                }
                icon="bullhorn"
                good={!!data.cooldown_ok}
              />
            </div>
            <div className="RmhThrone__contentStack">
              {page === 'overview' && (
                <Section title={t('Положение двора', 'Court standing')}>
                  <div className="RmhThrone__overviewFacts">
                    <CourtFact
                      label={t('Действующие указы', 'Active decrees')}
                      value={String(records.length)}
                    />
                    <CourtFact
                      label={t('Вне закона', 'Outlaws')}
                      value={String(data.outlaws.length)}
                    />
                    <CourtFact
                      label={t('Корона в землях', 'Crown in the realm')}
                      value={
                        data.crown_present
                          ? t('Есть', 'Present')
                          : t('Не найдена', 'Not registered')
                      }
                    />
                    <CourtFact
                      label={t('Ключ правителя', 'Ruler key')}
                      value={
                        data.key_present
                          ? t('Есть', 'Present')
                          : t('Не найден', 'Not registered')
                      }
                    />
                  </div>
                  <p>
                    {t(
                      'Законы града публикуются на стенде писаря. Здесь издаются и отзываются указы.',
                      'Town laws are published at the scribe stand. Issue and revoke decrees here.',
                    )}
                  </p>
                  {!!data.throat_mode && data.throat_mode !== 'None' && (
                    <p>
                      {t('Голосовой режим: ', 'Voice mode: ')}
                      <b>{data.throat_mode}</b>
                    </p>
                  )}
                </Section>
              )}
              {page === 'decrees' && (
                <Section
                  title={t('Действующие указы', 'Active decrees')}
                  buttons={
                    <Button onClick={() => setPreviewEnglish(!previewEnglish)}>
                      {previewEnglish ? 'RU' : 'EN'}
                    </Button>
                  }
                >
                  {!records.length && (
                    <p>
                      {t(
                        'Действующих указов нет.',
                        'There are no active decrees.',
                      )}
                    </p>
                  )}
                  {records.map((entry, index) => (
                    <div className="RmhThrone__decree" key={entry.id}>
                      <Button
                        className="RmhThrone__decreeHeading"
                        selected={selected === entry.id}
                        onClick={() =>
                          setSelected(selected === entry.id ? null : entry.id)
                        }
                      >
                        {t('Указ', 'Decree')} {index + 1}
                      </Button>
                      {(selected === entry.id || records.length === 1) && (
                        <Prose
                          text={
                            previewEnglish && entry.text_en?.trim()
                              ? entry.text_en
                              : entry.text
                          }
                        />
                      )}
                      <Button.Confirm
                        icon="ban"
                        color="bad"
                        disabled={!command}
                        tooltip={reason}
                        confirmContent={t('Подтвердить', 'Confirm')}
                        onClick={() =>
                          act('remove_decree', {
                            index: String(index + 1),
                            id: entry.id,
                            revision: entry.revision,
                          })
                        }
                      >
                        {t('Отозвать', 'Revoke')}
                      </Button.Confirm>
                    </div>
                  ))}
                  <CourtTextForm
                    action="make_decree"
                    param="text"
                    title={t('Новый указ', 'New decree')}
                    button={t('Издать указ', 'Issue decree')}
                    enabled={command}
                    reason={reason}
                    act={act}
                  />
                </Section>
              )}
              {page === 'commands' && (
                <Governance
                  data={data}
                  act={act}
                  command={command}
                  announcement={announcement}
                  reason={reason}
                />
              )}
              {page === 'justice' && (
                <Justice
                  data={data}
                  act={act}
                  enabled={command}
                  reason={reason}
                />
              )}
              {page === 'heraldry' && (
                <Section title={t('Знамя града', 'Town standard')}>
                  <div className="RmhThrone__heraldry">
                    <DmIcon
                      icon={data.flag_icon}
                      icon_state={data.flag_state}
                      width="96px"
                      height="96px"
                    />
                    <span
                      style={{ background: data.lord_primary || '#183a56' }}
                    >
                      {t('Основной цвет', 'Primary')}
                    </span>
                    <span
                      style={{ background: data.lord_secondary || '#e0cc9b' }}
                    >
                      {t('Второй цвет', 'Secondary')}
                    </span>
                  </div>
                  <CourtAction
                    icon="palette"
                    title={t('Изменить цвета', 'Change colours')}
                    description={t(
                      'Выбрать гербовые цвета существующим порядком.',
                      'Choose heraldic colours through the existing selectors.',
                    )}
                    enabled={command}
                    reason={reason}
                    onClick={() => act('change_colors')}
                  />
                </Section>
              )}
              {page === 'voice' && (
                <Section
                  title={t('Голосовые команды THROAT', 'THROAT voice commands')}
                >
                  <p>
                    {t(
                      'Команды произносятся рядом с троном. Действуют обычные проверки полномочий.',
                      'Speak commands beside the throne. The normal authority checks apply.',
                    )}
                  </p>
                  <ul className="RmhThrone__voiceList">
                    {(data.voice_commands || []).map((text) => (
                      <li key={text}>
                        <code className="RmhThrone__voiceCommand">{text}</code>
                      </li>
                    ))}
                  </ul>
                  <Button icon="circle-question" onClick={() => act('help')}>
                    {t('Справка THROAT', 'THROAT help')}
                  </Button>
                </Section>
              )}
            </div>
          </main>
          <CourtRegalia
            data={data}
            act={act}
            command={command}
            announcement={announcement}
            reason={reason}
            t={t}
          />
        </div>
      </div>
    </div>
  );
}
function CourtStatus({
  label,
  value,
  icon,
  good,
}: {
  label: string;
  value: string;
  icon: string;
  good: boolean;
}) {
  return (
    <div
      className={`RmhThrone__statusCard RmhThrone__statusCard--${good ? 'good' : 'warning'}`}
    >
      <span className="RmhThrone__statusIcon">
        <Icon name={icon} />
      </span>
      <div className="RmhThrone__statusBody">
        <div className="RmhThrone__statusLabel">{label}</div>
        <div className="RmhThrone__statusValue">{value}</div>
      </div>
    </div>
  );
}
function CourtFact({ label, value }: { label: string; value: string }) {
  return (
    <div className="RmhThrone__overviewFact">
      <b>{label}</b>
      <span>{value}</span>
    </div>
  );
}
function CourtAction({
  icon,
  title,
  description,
  enabled,
  reason,
  onClick,
}: {
  icon: string;
  title: string;
  description: string;
  enabled: BooleanLike;
  reason?: string;
  onClick: () => void;
}) {
  return (
    <Button
      className="RmhThrone__action"
      disabled={!enabled}
      tooltip={!enabled ? reason : description}
      onClick={onClick}
    >
      <span className="RmhThrone__actionIcon">
        <Icon name={icon} />
      </span>
      <span className="RmhThrone__actionBody">
        <span className="RmhThrone__actionTitle">{title}</span>
        <span className="RmhThrone__actionDesc">{description}</span>
      </span>
    </Button>
  );
}
function CourtTextForm({
  action,
  param,
  title,
  button,
  enabled,
  reason,
  act,
}: {
  action: string;
  param: string;
  title: string;
  button: string;
  enabled: boolean;
  reason: string;
  act: Act;
}) {
  const [text, setText] = useState('');
  return (
    <div className="RmhThrone__desk">
      <h3>{title}</h3>
      <TextArea
        fluid
        height={6}
        maxLength={500}
        value={text}
        onChange={setText}
      />
      <div className="RmhThrone__deskFooter">
        <span>{Array.from(text).length} / 500</span>
        <Button
          icon="stamp"
          disabled={!enabled || !text.trim()}
          tooltip={!enabled ? reason : undefined}
          onClick={() => {
            act(action, { [param]: text });
            setText('');
          }}
        >
          {button}
        </Button>
      </div>
    </div>
  );
}
function Governance({
  data,
  act,
  command,
  announcement,
  reason,
}: {
  data: ThroneData;
  act: Act;
  command: boolean;
  announcement: boolean;
  reason: string;
}) {
  const t = useCourtText();
  return (
    <>
      <Section title={t('Объявления', 'Announcements')}>
        <CourtTextForm
          action="make_announcement"
          param="text"
          title={t('Объявить всем землям', 'Address the realm')}
          button={t('Объявить', 'Announce')}
          enabled={announcement}
          reason={
            !data.wearing_crown
              ? t('Нужна корона.', 'The crown is required.')
              : t('THROAT набирается сил.', 'THROAT is gathering strength.')
          }
          act={act}
        />
      </Section>
      <Section title={t('Управление градом', 'Town governance')}>
        <CourtFact
          label={t('Текущий налог', 'Current tax')}
          value={`${data.tax_percent}%`}
        />
        <CourtAction
          icon="coins"
          title={t('Изменить налог', 'Set taxes')}
          description={t(
            'Открыть существующий выбор налога.',
            'Open the existing tax selector.',
          )}
          enabled={command}
          reason={reason}
          onClick={() => act('set_taxes')}
        />
      </Section>
    </>
  );
}
function Justice({
  data,
  act,
  enabled,
  reason,
}: {
  data: ThroneData;
  act: Act;
  enabled: boolean;
  reason: string;
}) {
  const t = useCourtText();
  const [outlaw, setOutlaw] = useState(''),
    [pardon, setPardon] = useState('');
  return (
    <Section title={t('Правосудие', 'Justice')}>
      <h3>{t('Объявить вне закона', 'Declare outlaw')}</h3>
      <Input fluid value={outlaw} onChange={setOutlaw} maxLength={128} />
      <Button
        color="bad"
        disabled={!enabled || !outlaw.trim()}
        tooltip={reason}
        onClick={() => {
          act('declare_outlaw', { name: outlaw });
          setOutlaw('');
        }}
      >
        {t('Объявить вне закона', 'Declare outlaw')}
      </Button>
      <h3>{t('Помиловать', 'Pardon')}</h3>
      <Input fluid value={pardon} onChange={setPardon} maxLength={128} />
      <Button
        color="good"
        disabled={!enabled || !pardon.trim()}
        tooltip={reason}
        onClick={() => {
          act('pardon_outlaw', { name: pardon });
          setPardon('');
        }}
      >
        {t('Помиловать', 'Pardon')}
      </Button>
      <ul>
        {data.outlaws.map((name) => (
          <li key={name}>{decodeHtmlEntities(name)}</li>
        ))}
      </ul>
    </Section>
  );
}

function CourtHeader({
  data,
  act,
  t,
}: {
  data: ThroneData;
  act: Act;
  t: Text;
}) {
  return (
    <header className="RmhThrone__titleRow">
      <span className="RmhThrone__standard RmhThrone__standard--left">
        <Icon name="crown" />
      </span>
      <div className="RmhThrone__rulerBlock">
        <div>
          <b>{t('Правитель', 'Ruler')}</b>
          <span>
            {data.ruler_name === 'None' ? t('Нет', 'None') : data.ruler_name}
          </span>
        </div>
        <div>
          <b>{t('Регент', 'Regent')}</b>
          <span>
            {data.regent_name === 'None' ? t('Нет', 'None') : data.regent_name}
          </span>
        </div>
      </div>
      <div>
        <div className="RmhThrone__eyebrow">Rivermist Hollow</div>
        <h1 className="RmhThrone__title">
          {t('Двор Ривермиста', 'Court of Rivermist')}
        </h1>
        <div className="RmhThrone__subtitle">
          {t(
            'Воля града звучит через THROAT',
            'The voice of the town speaks through THROAT',
          )}
        </div>
      </div>
      <div className="RmhThrone__rulerBlock">
        <div>
          <b>{t('Ваш статус', 'Your standing')}</b>
          <span>
            {data.is_ruler
              ? t('Правитель', 'Ruler')
              : data.is_regent
                ? t('Регент', 'Regent')
                : t('Подданный', 'Subject')}
          </span>
        </div>
        <Button icon="rotate" onClick={() => act('refresh')}>
          {t('Обновить', 'Refresh')}
        </Button>
      </div>
      <span className="RmhThrone__standard RmhThrone__standard--right">
        <Icon name="shield-halved" />
      </span>
    </header>
  );
}

function CourtNavigation({
  page,
  onPage,
  t,
}: {
  page: Page;
  onPage: (page: Page) => void;
  t: Text;
}) {
  return (
    <aside className="RmhThrone__leftRail">
      <div className="RmhThrone__throneEmblem">
        <Icon name="chess-king" />
      </div>
      <nav
        className="RmhThrone__nav"
        aria-label={t('Разделы двора', 'Court sections')}
      >
        {pages.map((item) => (
          <Button
            key={item.id}
            className={`RmhThrone__navButton${page === item.id ? ' RmhThrone__navButton--active' : ''}`}
            icon={item.icon}
            onClick={() => onPage(item.id)}
          >
            {t(item.ru, item.en)}
          </Button>
        ))}
      </nav>
    </aside>
  );
}

function CourtRegalia({
  data,
  act,
  command,
  announcement,
  reason,
  t,
}: {
  data: ThroneData;
  act: Act;
  command: boolean;
  announcement: boolean;
  reason: string;
  t: Text;
}) {
  return (
    <aside className="RmhThrone__rightRail">
      <Section title={t('Регалии', 'Regalia')}>
        <CourtAction
          icon="crown"
          title={t('Призвать корону', 'Summon crown')}
          description={t(
            'Позвать существующую корону.',
            'Call the existing crown.',
          )}
          enabled
          onClick={() => act('summon_crown')}
        />
        <CourtAction
          icon="key"
          title={t('Призвать ключ', 'Summon key')}
          description={t('Нужна надетая корона.', 'Requires the worn crown.')}
          enabled={announcement}
          reason={
            !data.wearing_crown
              ? t('Нужна корона.', 'The crown is required.')
              : t('THROAT набирается сил.', 'THROAT is gathering strength.')
          }
          onClick={() => act('summon_key')}
        />
      </Section>
      <Section title={t('Приказы двору', 'Court orders')}>
        <CourtAction
          icon="user-tie"
          title={t('Назначить регента', 'Appoint regent')}
          description={t(
            'Назначить представителя правителя.',
            'Appoint the ruler’s representative.',
          )}
          enabled={command}
          reason={reason}
          onClick={() => act('appoint_regent')}
        />
        <CourtAction
          icon="users"
          title={t('Изменить должность', 'Change position')}
          description={t(
            'Изменить службу подданного.',
            'Change a subject’s office.',
          )}
          enabled={command}
          reason={reason}
          onClick={() => act('change_position')}
        />
        <CourtAction
          icon="volume-xmark"
          title="SILENCE!!"
          description={t(
            'Потребовать тишины в зале.',
            'Demand silence in the hall.',
          )}
          enabled={command}
          reason={reason}
          onClick={() => act('silence')}
        />
      </Section>
    </aside>
  );
}
