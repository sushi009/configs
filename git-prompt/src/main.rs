//! Print something like `master@ccceihceu2682 ` for shell prompt

use std::io::{Write, stdout};

use compact_str::{CompactString, ToCompactString};
use git2::*;

type Result<T> = std::result::Result<T, Box<dyn std::error::Error + 'static>>;

macro_rules! exit {
    ($s:expr) => {{
        print!("{}", $s);
        ::std::process::exit(0)
    }};
}

fn main() -> Result<()> {
    let repo = Repository::open_from_env().unwrap_or_else(|_| exit!(""));
    let repo = PromptRepo::new(repo);
    let head = repo.head();
    let mut prompt = CompactString::const_new(":");

    let name = head.shorthand().unwrap_or_else(|| exit!("???"));
    prompt.push_str(name);
    prompt.push_str("@");
    prompt.push_str(&head.target().expect("rev").to_compact_string()[0..7]);

    if head.is_branch()
        && let Some(remote) = repo.remote(name)
        && !remote.is_empty()
    {
        prompt.push_str(" ");
        prompt.push_str(remote.as_str());
    }
    if let Some(status) = repo.status()
        && !status.is_empty()
    {
        prompt.push_str(" ");
        prompt.push_str(status.as_str());
    }
    if let Some(state) = repo.state()
        && !state.is_empty()
    {
        prompt.push_str(" ");
        prompt.push_str(state);
    }

    stdout().lock().write_all(prompt.as_bytes())?;
    Ok(())
}

struct PromptRepo(Repository);

impl PromptRepo {
    fn new(repo: Repository) -> Self {
        Self(repo)
    }

    fn head(&self) -> Reference<'_> {
        self.0.head().unwrap_or_else(|_| exit!("[no head]"))
    }

    fn state(&self) -> Option<&'static str> {
        use git2::RepositoryState::*;

        match self.0.state() {
            Clean => None,
            Merge => Some("merge"),
            Revert => Some("revert"),
            RevertSequence => Some("revert"),
            CherryPick => Some("cherry-pick"),
            CherryPickSequence => Some("cherry-pick"),
            Bisect => Some("bisect"),
            Rebase => Some("rebase"),
            RebaseInteractive => Some("rebase"),
            RebaseMerge => Some("rebase-merge"),
            ApplyMailbox => Some("apply-mailbox"),
            ApplyMailboxOrRebase => Some("apply-mailbox"),
        }
    }

    fn status(&self) -> Option<CompactString> {
        use git2::Delta::*;

        if let Ok(statuses) = self.0.statuses(None) {
            let mut out = CompactString::const_new("");
            let mut seen = Vec::new();
            let mut staged = false;

            for entry in statuses.iter() {
                if !staged {
                    let status = entry.status();
                    if status.is_index_new()
                        || status.is_index_modified()
                        || status.is_index_deleted()
                    {
                        out.push('✓');
                        staged = true
                    }
                }
                if let Some(diff_delta) = entry.index_to_workdir() {
                    let delta = diff_delta.status();

                    if seen.contains(&delta) {
                        continue;
                    }
                    seen.push(delta);

                    match delta {
                        Unmodified => {}
                        Added => out.push('+'),
                        Deleted => out.push('-'),
                        Modified | Renamed | Typechange => out.push('*'),
                        Copied => {}
                        Ignored => {}
                        Untracked => out.push('?'),
                        Unreadable => {}
                        Conflicted => out.push('x'),
                    }
                }
            }

            match out.is_empty() {
                true => return None,
                false => return Some(out),
            }
        }

        None
    }

    fn remote(&self, name: &str) -> Option<CompactString> {
        let local = self.0.find_branch(name, BranchType::Local).ok()?;
        let upstream = local.upstream().ok()?;

        // Get the local and remote commits
        let local = local.get().target()?;
        let upstream = upstream.get().target()?;

        // Compare the local and remote commits
        let (ahead, behind) = self.0.graph_ahead_behind(local, upstream).ok()?;
        let mut out = CompactString::const_new("");

        match (ahead, behind) {
            (0, 0) => {}
            (a, 0) => out.push_str(&format!("↑{a}")),
            (0, b) => out.push_str(&format!("↓{b}")),
            (a, b) => out.push_str(&format!("↑{a}↓{b}")),
        }

        Some(out)
    }
}
