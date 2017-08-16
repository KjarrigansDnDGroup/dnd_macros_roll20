task :readable, [:pattern] do |t,args|
  Dir[args[:pattern]].each do |f|
    puts f
    File.write(f, File.read(f).gsub("}}", "}}\n"))
  end
end

task :minify, [:pattern] do |t,args|
  Dir[args[:pattern]].each do |f|
    puts f
    File.write(f, File.read(f).gsub("\n", ""))
  end
end

task :autoconvert, [:pattern] do |t,args|
  Dir[args[:pattern]].each do |f|
    print f

    spell = File.read(f)
    spell.gsub! "{{*Range:*=Close (25 ft. + 5 ft./2 levels)}}", "{{*Range:*=Close ([[ 25 + (floor(@{selected|casterlevel}/2)*5) ]] ft)}}"
    spell.gsub! "{{*Range:*=Medium (100 ft. + 10 ft./level)}}", "{{*Range:*=Medium ([[ 100 + [[ @{selected|casterlevel} * 10) ]] ]] ft. }}"

    level = $1 if spell =~ /Lv. (\d)/
    if spell =~ /Saving Throw:\*=(Fortitude|Will|Reflex) (negates|disblief|partial|half)/
      spell.gsub! $2, "**#{$2}** DC [[ 10 + #{level} + @{selected|cha-mod} ]]"
      puts '...Match'
    else
      puts '...Nope'
    end

    File.write(f, spell)
  end
end
