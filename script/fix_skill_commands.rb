#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'json'

TARGET_PATH = ARGV[0] || '/Users/roalcantara/Work/dots/config/kodexb/sources/skills.yml'
KNOWN_REPOS = {
  'academic-cv-builder' => 'paramchoudhary/resumeskills',
  'acreadiness-policy' => 'github/awesome-copilot',
}.freeze

class SkillCommandFixer
  def initialize(path)
    @path = path
    @source_map = load_source_map
  end

  def load_source_map
    # 1. READ SKILL FOLDER NAMES FROM ~/.agents/skills
    map = {}
    File.read(File.expand_path('~/.agents/skills')).each_line do |line|
      puts line
      # skill = match[1]
      # source = match[2].strip
      # next if source == 'local' || source.empty?
      # source = source.sub(%r{^https://github.com/}, '').sub(/\.git\z/, '')
      # map[skill] = source
    end
    map
  rescue StandardError
    {}
  end

  def run
    data = YAML.load_file(@path)
    unless data.is_a?(Hash) && data['skills'].is_a?(Hash)
      raise "Expected a top-level 'skills' hash in #{@path}"
    end

    updated = {}
    fixed = 0
    skipped = 0

    data['skills'].each do |cmd, meta|
      next unless cmd.is_a?(String)

      skill_name = cmd[/--skill\s+([A-Za-z0-9_.-]+)/, 1]
      if skill_name.nil?
        updated[cmd] = meta
        next
      end

      repo_name = @source_map[skill_name] || KNOWN_REPOS[skill_name]
      if repo_name.nil?
        updated[cmd] = meta
        skipped += 1
        next
      end

      skill_cmd = "skills add -yg https://github.com/#{repo_name} --skill #{skill_name}"
      new_key = "/#{skill_name}"
      updated[new_key] = normalize_meta(meta, skill_cmd)
      fixed += 1
    end

    data['skills'] = updated
    File.write(@path, YAML.dump(data))
    puts "fixed=#{fixed} skipped=#{skipped} path=#{@path}"
  end

  private

  def normalize_meta(meta, skill_cmd)
    normalized = meta.is_a?(Hash) ? meta.dup : {}
    # normalized['links'] = [link_url]
    normalized['notes'] ||= []
    normalized['notes'] += [{ sh: skill_cmd }]
    normalized
  end

end

SkillCommandFixer.new(TARGET_PATH)
