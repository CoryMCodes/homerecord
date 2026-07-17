use client"

import { Search, Plus, FileText, MapPin, ChevronRight } from "lucide-react"
import {
  categoryMeta,
  categoryOrder,
  entries,
  formatDate,
  formatMoney,
  home,
} from "@/lib/home-data"
import { useTimeline } from "@/lib/use-timeline"

export function WarmDirection({ themeClass = "theme-c-forest" }: { themeClass?: string }) {
  const { query, setQuery, active, setActive, groups, count } = useTimeline()

  return (
    <div className={`${themeClass} min-h-screen bg-background font-sans text-foreground`}>
      <div className="mx-auto w-full max-w-[520px] px-5 pb-32">
        {/* Greeting header */}
        <header className="pt-11">
          <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-muted-foreground">
            Welcome home
          </p>
          <h1 className="mt-3 text-pretty text-[2.35rem] font-semibold leading-[1.02] tracking-[-0.035em]">
            {home.name}
          </h1>
          <p className="mt-3 text-[14px] leading-relaxed text-muted-foreground">
            {home.cityState} · Cared for since {home.ownedSince}
          </p>

          {/* Quiet record summary */}
          <div className="mt-7 flex items-center gap-7 border-t border-border pt-5">
            <Stat value={String(entries.length)} label="Entries" />
            <span className="h-9 w-px bg-border" aria-hidden="true" />
            <Stat
              value={String(entries.filter((e) => e.hasManual).length)}
              label="Manuals"
            />
            <span className="h-9 w-px bg-border" aria-hidden="true" />
            <Stat
              value={String(entries.filter((e) => e.warrantyUntil).length)}
              label="Warranties"
            />
          </div>
        </header>

        {/* Search — luxurious, lightweight */}
        <div className="mt-8">
          <label className="group flex items-center gap-3 rounded-2xl border border-border/80 bg-card px-4 py-3.5 shadow-[0_1px_2px_rgba(20,35,28,0.04),0_8px_24px_-12px_rgba(20,35,28,0.12)] transition-all focus-within:border-primary/40 focus-within:shadow-[0_1px_2px_rgba(20,35,28,0.04),0_12px_28px_-10px_rgba(18,74,55,0.22)]">
            <Search
              className="size-[18px] shrink-0 text-muted-foreground transition-colors group-focus-within:text-primary"
              aria-hidden="true"
            />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Find an appliance manual…"
              className="w-full bg-transparent text-[15px] outline-none placeholder:text-muted-foreground"
              aria-label="Search entries and manuals"
            />
          </label>
        </div>

        {/* Filters — quiet, secondary, obvious when selected */}
        <div
          className="mt-4 flex items-center gap-1.5 overflow-x-auto pb-0.5"
          role="tablist"
          aria-label="Filter entries by category"
        >
          <Filter
            label="All"
            isActive={active === "all"}
            onClick={() => setActive("all")}
          />
          {categoryOrder.map((c) => (
            <Filter
              key={c}
              label={categoryMeta[c].label}
              isActive={active === c}
              onClick={() => setActive(c)}
            />
          ))}
        </div>

        {/* Timeline */}
        <div className="mt-9">
          {groups.map((group) => (
            <section key={group.key} className="mb-3">
              <h2 className="sticky top-0 z-10 -mx-5 bg-background/80 px-5 py-2.5 text-[12px] font-semibold uppercase tracking-[0.12em] text-muted-foreground backdrop-blur-md">
                {group.label}
              </h2>
              <div className="relative">
                {/* continuous rail */}
                <span
                  className="absolute bottom-8 left-[23px] top-8 w-px bg-border"
                  aria-hidden="true"
                />
                <ul className="space-y-1">
                  {group.items.map((entry) => {
                    const Icon = categoryMeta[entry.category].icon
                    return (
                      <li key={entry.id}>
                        <button
                          type="button"
                          className="group relative flex w-full gap-4 rounded-2xl p-3.5 text-left transition-all duration-200 hover:bg-card hover:shadow-[0_1px_2px_rgba(20,35,28,0.04),0_10px_30px_-16px_rgba(20,35,28,0.2)]"
                        >
                          {/* Icon bubble */}
                          <span className="relative z-10 mt-0.5 flex size-11 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm ring-[3px] ring-background transition-colors">
                            <Icon className="size-[19px]" strokeWidth={1.75} aria-hidden="true" />
                          </span>

                          <div className="min-w-0 flex-1 pb-1">
                            <div className="flex items-baseline justify-between gap-3">
                              <span className="text-[11px] font-semibold uppercase tracking-[0.1em] text-primary">
                                {categoryMeta[entry.category].label}
                              </span>
                              <time className="shrink-0 text-[12px] font-medium tabular-nums text-muted-foreground">
                                {formatDate(entry.date, {
                                  month: "short",
                                  day: "numeric",
                                })}
                              </time>
                            </div>

                            <h3 className="mt-1.5 text-pretty text-[17px] font-semibold leading-snug tracking-[-0.01em]">
                              {entry.title}
                            </h3>
                            <p className="mt-1 text-[14px] leading-relaxed text-muted-foreground">
                              {entry.summary}
                            </p>

                            {/* Meta row */}
                            <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1.5 text-[12.5px] text-muted-foreground">
                              <span className="inline-flex items-center gap-1.5">
                                <MapPin
                                  className="size-3.5"
                                  strokeWidth={1.75}
                                  aria-hidden="true"
                                />
                                {entry.room}
                              </span>
                              {typeof entry.cost === "number" && (
                                <span className="font-medium tabular-nums text-foreground/70">
                                  {formatMoney(entry.cost)}
                                </span>
                              )}
                              {entry.warrantyUntil && (
                                <span className="inline-flex items-center gap-1.5 rounded-full bg-accent px-2.5 py-0.5 text-[11.5px] font-medium text-accent-foreground">
                                  Covered to{" "}
                                  {formatDate(entry.warrantyUntil, {
                                    month: "short",
                                    year: "numeric",
                                  })}
                                </span>
                              )}
                              {entry.hasManual && (
                                <span className="inline-flex items-center gap-1.5 font-medium text-primary">
                                  <FileText
                                    className="size-3.5"
                                    strokeWidth={1.75}
                                    aria-hidden="true"
                                  />
                                  Manual
                                </span>
                              )}
                            </div>
                          </div>

                          <ChevronRight
                            className="mt-3 size-4 shrink-0 self-start text-muted-foreground/40 transition-all group-hover:translate-x-0.5 group-hover:text-muted-foreground"
                            aria-hidden="true"
                          />
                        </button>
                      </li>
                    )
                  })}
                </ul>
              </div>
            </section>
          ))}

          {count === 0 && (
            <p className="py-16 text-center text-[15px] text-muted-foreground">
              Nothing here yet — try a different search.
            </p>
          )}
        </div>
      </div>

      {/* Floating add button */}
      <div className="pointer-events-none fixed inset-x-0 bottom-7 z-30 flex justify-center">
        <button
          type="button"
          className="pointer-events-auto inline-flex items-center gap-2 rounded-full bg-primary px-5 py-3.5 text-[15px] font-semibold text-primary-foreground shadow-[0_8px_28px_-8px_rgba(18,74,55,0.5)] ring-1 ring-black/5 transition-[transform,background-color] duration-200 hover:bg-primary-hover active:scale-[0.97]"
        >
          <Plus className="size-[18px]" strokeWidth={2.25} aria-hidden="true" />
          Add entry
        </button>
      </div>
    </div>
  )
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-[1.35rem] font-semibold tabular-nums leading-none tracking-[-0.02em]">
        {value}
      </span>
      <span className="text-[12.5px] text-muted-foreground">{label}</span>
    </div>
  )
}

function Filter({
  label,
  isActive,
  onClick,
}: {
  label: string
  isActive: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={isActive}
      onClick={onClick}
      className={
        "shrink-0 rounded-full px-3 py-1 text-[13px] font-medium transition-all duration-200 " +
        (isActive
          ? "bg-card text-foreground shadow-[0_1px_2px_rgba(20,35,28,0.06),0_4px_12px_-6px_rgba(20,35,28,0.18)] ring-1 ring-border"
          : "text-muted-foreground hover:text-foreground")
      }
    >
      {label}
    </button>
  )
}
