#!/usr/bin/env ruby

require 'optparse'
require_relative 'colorize'

FORCE_STASH = true

def stash_message(branch_name)
  "smart-switch|#{branch_name}"
end

def stash(branch_name, prompt)
  return if `git status -s`.lines.length == 0

  if prompt then
    puts 'There are uncommitted changes. Stash them before checking out new branch? y/n/c'.bold
    puts '  y: Yes, stash and then checkout the new branch'
    puts '  n: No, don\'t stash, just checkout the new branch'
    puts '  c: Cancel'
    case STDIN.gets.chomp.downcase
    when 'n'
      return
    when 'c'
      exit
    when 'y'
    else
      abort('Unknown response')
    end
  end

  puts "#{'Stashing changes'.green} #{'for'.dim} #{branch_name.yellow}"
  puts `git stash -u -m '#{stash_message(branch_name)}'`
  puts
end

def switch(current_branch, dest_branch, create)
  apply_stashes = current_branch != dest_branch

  if apply_stashes then
    stash(current_branch, create)
  end

  if create then
    puts "Creating branch #{dest_branch.yellow}".yellow
    `git checkout -b #{dest_branch}`
  else 
    puts "Switching from #{current_branch.yellow} #{'-->'.dim} #{dest_branch.yellow}".dim
    `git checkout #{dest_branch}`
  end

  if !create && apply_stashes then
    dest_stash_message = stash_message(dest_branch)
    found_stashes = `git stash list`.lines.select {|line| line.strip.end_with?(dest_stash_message)}

    if found_stashes.length > 0 then
      puts
      puts "#{"Applying stash".green} #{"found for".dim} #{dest_branch.yellow}"

      matches = found_stashes[0].match /stash@{(\d+)}/
      index = matches[1]

      # This requires git 2.32.0 or higher
      stash_summary = `git stash show -u stash@{#{index}}`
      show_stash_summary = $?.success?

      if show_stash_summary then
        puts stash_summary
      end
      puts `git stash pop --index #{index} --quiet`
    end
  end
end

# Option parsing
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: git-ss [-b] [branch-pattern]'
  opts.banner += "\nFYI: Running without specifying branch-pattern will list all branches"

  opts.separator ""
  opts.separator "Specific options:"

  if !FORCE_STASH then
    opts.on('-f', '--force-stash', 'Force stashing without prompting') do
      options[:force_stash?] = true
    end
  end

  opts.on('-b', '--new-branch', 'Create new branch') do
    options[:new_branch?] = true
  end

  opts.on('-o', '--stash-only', 'Stash only, don\'t switch branches') do
    options[:stash_only?] = true
  end

  opts.on_tail("-h", "--help", "Show help") do |v|
    puts opts
    exit
  end
end.parse!

options[:branch_pattern] = case ARGV.length
  when 0 then
    abort('Bad arguments: missing branch name to create.') if options[:new_branch?]
    nil
  when 1 then
    abort('Bad arguments: don\'t provide a branch pattern with --stash-only') if options[:stash_only?]
    ARGV[0]
  else 
    abort('Provide only one branch pattern')
  end

current_branch = `git branch --show-current`.strip

# Handle stash-only mode
if options[:stash_only?] then
  stash(current_branch)
  exit
end

branch_output = `git branch --list "#{options[:branch_pattern]}"`.lines
if branch_output.length != 1 then
  branch_output = `git branch --list "*#{options[:branch_pattern]}*"`.lines
end

# Handle new branch mode
if options[:new_branch?] then
  abort("A branch named #{options[:branch_pattern].yellow} already exists") if branch_output.length > 0
  switch(current_branch, options[:branch_pattern], true)
  exit
end

if options[:branch_pattern] != nil && branch_output.length == 1 then
  # Handle standard switch
  branch_line = branch_output[0].strip
  branch_line_tokens = branch_line.split(' ')

  for token in branch_line_tokens
    if !token.eql?('*') then
      puts "Found branch matching '#{options[:branch_pattern]}': #{token.yellow}.".bold
      puts

      switch(current_branch, token, false)
      break
    end
  end
elsif branch_output.length == 0 then
  # Handle no branches found
  puts "No branches found matching '#{options[:branch_pattern]}'"
else
  # Handle show branches
  if options[:branch_pattern].nil? then
    puts "Listing branches:".bold
  else
    puts "Found multiple branches matching '#{options[:branch_pattern]}':".yellow
  end
  puts branch_output.map { |line| line.gsub(/ #{current_branch}$/, " #{current_branch.green}") }
end
