require 'nokogiri'
require 'open-uri'
require 'fileutils'

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
    raise "This spell can't use this spell (only #{spell.attributes['Level']})" if klass != :uni && level[klass].nil?

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

  def save_macro_file_for(klass, lvl, directory: '.')
    FileUtils.mkdir_p directory

    File.open(File.join(directory, level[klass] +'-'+name.tr(' ','_')+'.roll20'), 'w') do |f|
      f.print self.to_macro_for(klass, lvl)
    end
  end

  private
  def parse_level(str)
    # There are some spells where the Level is missing behind the Klassname
    # -> requested a wikichange as this is certainly a mistake.
    list = str.split(',').map{|kl| kl.strip.split }.delete_if{|e| e.size != 2}.to_h
    list["Sor"] ||= list["Sor/Wiz"]
    list["Wiz"] ||= list["Sor/Wiz"]
    list
  end
end

if  __FILE__ == $0
  $stdin.sync = true
  $stdout.sync = true


  print "Klass and (Caster)Level?: "
  klass, lvl = STDIN.gets.chomp.split
  dirname = [klass, lvl].compact.join('-')

  loop do
    print "Spellname(:Summary): "
    name, summary = STDIN.gets.chomp.split(':')

    # correctly parse spells like "Name, Greater/Lesser"
    name = name.split(',').map(&:strip).reverse.join(' ')

    if name =~ /(.*)(F|M|X)$/
      name = $1
      special_cost = $2
    end
    name = name.tr(' ', '_')
    begin
      spell = Spell.from_url("http://www.dandwiki.com/wiki/SRD:#{name}")
      spell.summary = summary
      spell.save_macro_file_for(klass, lvl, directory: dirname)
    rescue => e
      if name =~ /Spell/
        puts "ERROR: Can't generate macro for #{name} (#{e.message})"
        puts e.backtrace if ENV['DEBUG']
      else
        # There are some spells which are named after effects and therefore need
        # the Spell postfix in the url (e.g. darkvision -> Darkvision_(Spell)
        name += "_(Spell)"
        retry
      end
    end
  end
end