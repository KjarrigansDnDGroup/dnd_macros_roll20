require 'nokogiri'
require 'open-uri'

class Spell < Struct.new :name, :school, :attributes, :summary, :description
  # Example in Readableformat - the real one needs to be single line...
  # &{template:DnD35StdRoll}
  # {{spellflag=true}}
  # {{name= Magic Missles (Lv. 1) }}
  # {{*School:*=Evocation (Force)}}
  # {{*Components:*=V, S}}
  # {{*Casting Time:*= 1 std action}}
  # {{*Range:*= Medium ( [[ 100+10*@{selected|casterlevel} ]] ft)}}
  # {{*Target:*= up to five creatures, no two of which can be 15 ft. apart }}
  # {{*Duration:*= Instantaneous }}
  # {{*Saving Throw:*= None }}
  # {{*Spell Resist.*:= Yes }}
  # {{*Note:* = *The missile strikes unerringly, even if the target is in melee combat or has less than total cover or total concealment.* [**(more)**](http://www.dandwiki.com/wiki/SRD:Magic_Missle)}}
  # {{**Missle 1**:=[[ d4+1 ]]}}
  # {{**Missle 2:**=[[ d4+1 ]]}}
  # {{**Missle 3:**=[[ d4+1 ]]}}
  def to_macro_for(klass=:uni, caster_level=0, extended_text: false, readable: false)
    mac = ["&{template:DnD35StdRoll}"]
    mac << "{{spellflag=true}}"
    att = attributes.dup

    if klass == :uni
      mac << "{{name=#{self.name}}}"
    else
      lvl = parse_level(att.delete("Level"))[klass.to_s]
      mac << "{{name=#{self.name} (Lv. #{lvl})}}"
    end
    mac << "{{*School:*=#{self.school}}}"
    mac += att.map do |key,val|
      "{{*#{key}:*=#{val}}}"
    end
    mac << "{{notes=#{extended_text ? description : summary}}}"
    mac.join(readable ? "\n" : "")
  end

  def self.from_url(url)
    data = {}

    html = Nokogiri::HTML(open(url))
    name, school, *attributes = html.css("table.d20")[0].text.split("\n\n\n").map do |l|
      l.split("\n\n").map{|v| v.strip.chomp.tr(':', '') }
    end
    new name[0], school[0], attributes.to_h
  end

  def level
    parse_level attributes["Level"]
  end

  private
  def parse_level(str)
    list = str.split(',').map{|kl| kl.strip.split }.to_h
    list["Sor"] ||= list["Sor/Wiz"]
    list["Wiz"] ||= list["Sor/Wiz"]
    list
  end
end

if  __FILE__ == $0
  $stdin.sync = true
  $stdout.sync = true
  require 'fileutils'

  print "Klass and (Caster)Level?: "
  klass, lvl = STDIN.gets.chomp.split
  dirname = [klass, lvl].compact.join('-')
  FileUtils.mkdir_p dirname

  loop do
    print "Spellname(:Summary): "
    name, summary = STDIN.gets.chomp.split(':')
    begin
      spell = Spell.from_url("http://www.dandwiki.com/wiki/SRD:#{name}")
      spell.summary = summary

      File.open(File.join(dirname, spell.level[klass] +'-'+name+'.roll20'), 'w') do |f|
        f.print spell.to_macro_for(klass, lvl)
      end
    rescue => e
      puts "ERROR: Can't generate macro for #{name} (#{e.message})"
    end
  end
end