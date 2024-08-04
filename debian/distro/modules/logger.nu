#!/usr/bin/env nu

export def log_info [message: string] {
  print $"(ansi blue)\(INFO\): ($message)(ansi reset)"
}

export def log_debug [message: string] {
  print $"(ansi yellow)\(DEBUG\): ($message)(ansi reset)"
}

export def log_error [message: string] {
  print $"(ansi red)\(ERROR\): ($message)(ansi reset)"
}

export def log_warn [message: string] {
  print $"(ansi purple)\(WARN\): ($message)(ansi reset)"
}