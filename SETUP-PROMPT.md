# The paste prompt

Copy everything inside the fence into Claude Code and press enter. That's the whole install.

```
Install + run the full-stack-builder-pack for me, end to end.

1. Detect my OS (Mac/Windows). Make ~/.claude/skills/ if it doesn't exist.
2. Clone https://github.com/Mr-heka/full-stack-builder-pack.git into
   ~/.claude/skills/full-stack-builder-pack (Mac) or
   $HOME\.claude\skills\full-stack-builder-pack (Windows).
   No git on this machine yet? Install it first (Windows: winget install --id Git.Git -e,
   Mac: xcode-select --install, which brings git with it and needs no package manager — or
   brew install git if this Mac already has Homebrew), open a fresh shell, then clone.
   Folder already there from an earlier attempt? Don't clone on top of it and don't pull into it —
   first work out what it is: run git remote -v inside it. Does that name full-stack-builder-pack?
   Then it is this pack, so delete it and clone fresh — nothing of mine lives in there, it's a
   read-only copy of the pack. Anything else — a different repo, or not a git repo at all so that
   command errors — delete nothing: rename it to full-stack-builder-pack-old, clone fresh, and
   tell me where the old one is so I can look at it later.
3. Install the pack's ten skills where Claude Code actually looks. Claude Code only loads
   personal skills laid out as ~/.claude/skills/<skill-name>/SKILL.md — the pack sitting there
   as one nested folder is invisible to it. So copy each folder inside the clone's skills/
   directory into ~/.claude/skills/ individually:
   Mac:      cp -R ~/.claude/skills/full-stack-builder-pack/skills/* ~/.claude/skills/
   Windows:  Copy-Item -Recurse -Force "$HOME\.claude\skills\full-stack-builder-pack\skills\*" "$HOME\.claude\skills\"
   Leave the full-stack-builder-pack clone itself in place — the skills reach back into it for
   template/, modules/, and CONVENTIONS.md. Re-running this copy on a later paste is safe: it
   just refreshes the ten folders. When it's done, confirm
   ~/.claude/skills/app-foundation-setup/SKILL.md exists.
4. Connect my everyday browser — read ~/.claude/skills/browser-connect/SKILL.md and follow it.
   Run its detect script (bash ~/.claude/skills/browser-connect/scripts/detect.sh on Mac,
   pwsh ~/.claude/skills/browser-connect/scripts/detect.ps1 on Windows), tell me which browser
   and profile you picked (I can override with a word), and store the pin. If my browser is Chrome or Edge: register the Playwright MCP
   server in extension mode —
   claude mcp add --scope user playwright -- npx @playwright/mcp@latest --extension
   — then open the Chrome Web Store page for "Playwright MCP Bridge" pinned to my picked
   profile, and I'll do my two clicks: Add to Chrome, then Add extension. That done, tell me
   to restart Claude Code and paste this same prompt again — it resumes right here, and on
   the way through I can paste the extension's one-time token so future connections are
   silent. If my browser isn't Chrome or Edge, or I say no to the extension: record the
   fallback in the pin and move on — nothing else changes.
5. Read ~/.claude/skills/app-foundation-setup/SKILL.md and follow it: run foundation-check,
   fix whatever fails in order, re-check until everything is PASS.
6. The only things I'll type are my own passwords and MFA codes when a sign-in
   page opens, two clicks in my browser to add the extension (plus that optional
   token paste), and quick answers to a few questions (my name, my business email,
   where my recovery codes are saved). Everything else is yours.
7. When the full-screen PASS banner is up, tell me I'm ready to build my first app.
   If it ends on the red FAIL banner instead, don't call it done — tell me plainly
   what's still failing, who has to act on each one, and what to do next.

If anything interrupts us I'll paste this same prompt again — that must always be
safe: detect first, and only touch what is actually broken at that moment.

Just go.
```

After the green PASS banner: tell Claude what you want your site or app to do, in plain
English. The pack's `app-builder` skill takes over — it scaffolds from the template, wires
your database, pushes to GitHub, and your app goes live on Vercel at a real URL.
From then on, push = deploy.
