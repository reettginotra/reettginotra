import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const DAY_IN_MS = 24 * 60 * 60 * 1000;
const CARD_WIDTH = 860;
const CARD_HEIGHT = 360;
const username =
  process.env.GITHUB_USERNAME || process.env.GITHUB_REPOSITORY?.split("/")[0];
const token = process.env.GITHUB_TOKEN;
const outputPath = process.env.OUTPUT_PATH || "assets/github-activity-card.svg";

if (!username) {
  throw new Error("Missing GITHUB_USERNAME.");
}

if (!token) {
  throw new Error(
    "Missing GITHUB_TOKEN. Add PROFILE_STATS_TOKEN or use the built-in github.token.",
  );
}

const today = new Date();
const endDate = new Date(
  Date.UTC(
    today.getUTCFullYear(),
    today.getUTCMonth(),
    today.getUTCDate(),
    23,
    59,
    59,
  ),
);
const startDate = new Date(endDate.getTime() - 364 * DAY_IN_MS);

const query = `
  query ActivityCard($login: String!, $from: DateTime!, $to: DateTime!) {
    user(login: $login) {
      name
      contributionsCollection(from: $from, to: $to) {
        contributionCalendar {
          totalContributions
          weeks {
            contributionDays {
              contributionCount
              date
            }
          }
        }
      }
    }
  }
`;

const response = await fetch("https://api.github.com/graphql", {
  method: "POST",
  headers: {
    Authorization: `bearer ${token}`,
    "Content-Type": "application/json",
    "User-Agent": "github-activity-card-generator",
  },
  body: JSON.stringify({
    query,
    variables: {
      login: username,
      from: startDate.toISOString(),
      to: endDate.toISOString(),
    },
  }),
});

if (!response.ok) {
  throw new Error(
    `GitHub GraphQL request failed with ${response.status} ${response.statusText}.`,
  );
}

const payload = await response.json();

if (payload.errors?.length) {
  throw new Error(payload.errors.map((error) => error.message).join("; "));
}

const user = payload.data?.user;

if (!user) {
  throw new Error(`GitHub user "${username}" was not found.`);
}

const days = user.contributionsCollection.contributionCalendar.weeks
  .flatMap((week) => week.contributionDays)
  .map((day) => ({
    date: day.date,
    count: day.contributionCount,
  }))
  .sort((left, right) => left.date.localeCompare(right.date))
  .slice(-365);

if (days.length === 0) {
  throw new Error(`No contribution data returned for "${username}".`);
}

const totalContributions = days.reduce((sum, day) => sum + day.count, 0);
const activeDays = days.filter((day) => day.count > 0).length;
const { currentStreak, longestStreak } = calculateStreaks(days);
const recentDays = days.slice(-28);
const maxRecentCount = Math.max(...recentDays.map((day) => day.count), 1);

const metrics = [
  {
    label: "Current streak",
    value: `${currentStreak} day${currentStreak === 1 ? "" : "s"}`,
  },
  {
    label: "Longest streak",
    value: `${longestStreak} day${longestStreak === 1 ? "" : "s"}`,
  },
  {
    label: "Active days",
    value: `${activeDays} / 365`,
  },
  {
    label: "Total contributions",
    value: formatNumber(totalContributions),
  },
];

const metricMarkup = metrics
  .map((metric, index) => {
    const x = 32 + index * 199;
    return `
      <g transform="translate(${x} 96)">
        <rect width="179" height="96" rx="14" fill="#161b22" stroke="#30363d" />
        <text x="18" y="36" fill="#f0f6fc" font-size="28" font-weight="700">${escapeXml(metric.value)}</text>
        <text x="18" y="67" fill="#8b949e" font-size="15">${escapeXml(metric.label)}</text>
      </g>
    `;
  })
  .join("");

const barChartMarkup = recentDays
  .map((day, index) => {
    const barWidth = 20;
    const gap = 8;
    const x = 32 + index * (barWidth + gap);
    const normalizedHeight = day.count === 0 ? 10 : Math.max(14, Math.round((day.count / maxRecentCount) * 66));
    const y = 316 - normalizedHeight;
    return `
      <rect
        x="${x}"
        y="${y}"
        width="${barWidth}"
        height="${normalizedHeight}"
        rx="6"
        fill="${colorForCount(day.count, maxRecentCount)}"
      >
        <title>${escapeXml(`${day.date}: ${day.count} contribution${day.count === 1 ? "" : "s"}`)}</title>
      </rect>
    `;
  })
  .join("");

const displayName = user.name ? `${user.name} (@${username})` : `@${username}`;
const summary = `${currentStreak} day current streak, ${longestStreak} day longest streak, ${activeDays} active days, ${totalContributions} total contributions in the last 365 days.`;
const subtitle = `${displayName} - last 365 days`;
const chartRange = `${formatShortDate(recentDays[0].date)} to ${formatShortDate(recentDays[recentDays.length - 1].date)}`;
const updatedLabel = `Updated ${days[days.length - 1].date} UTC`;

const svg = `
<svg width="${CARD_WIDTH}" height="${CARD_HEIGHT}" viewBox="0 0 ${CARD_WIDTH} ${CARD_HEIGHT}" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="title desc">
  <title id="title">GitHub activity snapshot for ${escapeXml(username)}</title>
  <desc id="desc">${escapeXml(summary)}</desc>
  <rect width="${CARD_WIDTH}" height="${CARD_HEIGHT}" rx="20" fill="#0d1117" />
  <rect x="1" y="1" width="${CARD_WIDTH - 2}" height="${CARD_HEIGHT - 2}" rx="19" stroke="#30363d" />
  <text x="32" y="46" fill="#f0f6fc" font-size="28" font-weight="700">GitHub Activity Snapshot</text>
  <text x="32" y="72" fill="#8b949e" font-size="16">${escapeXml(subtitle)}</text>
  ${metricMarkup}
  <text x="32" y="232" fill="#f0f6fc" font-size="18" font-weight="600">Recent 28-day activity</text>
  <text x="32" y="254" fill="#8b949e" font-size="14">${escapeXml(chartRange)}</text>
  <line x1="32" y1="316.5" x2="828" y2="316.5" stroke="#30363d" />
  ${barChartMarkup}
  <text x="32" y="338" fill="#8b949e" font-size="13">${escapeXml(updatedLabel)}</text>
  <text x="828" y="338" fill="#8b949e" font-size="13" text-anchor="end">Generated in GitHub Actions</text>
</svg>
`.trimStart();

mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, svg);

function calculateStreaks(contributionDays) {
  let longest = 0;
  let currentRun = 0;

  for (const day of contributionDays) {
    if (day.count > 0) {
      currentRun += 1;
      longest = Math.max(longest, currentRun);
    } else {
      currentRun = 0;
    }
  }

  let current = 0;
  let startIndex = contributionDays.length - 1;

  if (contributionDays[startIndex]?.count === 0) {
    startIndex -= 1;
  }

  for (let index = startIndex; index >= 0; index -= 1) {
    if (contributionDays[index].count > 0) {
      current += 1;
    } else {
      break;
    }
  }

  return {
    currentStreak: current,
    longestStreak: longest,
  };
}

function colorForCount(count, maxCount) {
  if (count === 0) {
    return "#21262d";
  }

  const ratio = count / Math.max(maxCount, 1);

  if (ratio >= 0.85) {
    return "#39d353";
  }
  if (ratio >= 0.55) {
    return "#26a641";
  }
  if (ratio >= 0.3) {
    return "#0e9f6e";
  }
  return "#1f6feb";
}

function formatNumber(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

function formatShortDate(value) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
  }).format(new Date(`${value}T00:00:00Z`));
}

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}
