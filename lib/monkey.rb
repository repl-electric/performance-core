#🐒
class SonicPi::Core::RingVector
  def rot(n)
    self.rotate(n)
  end
  def each_tick(thing)
    self.each{|c|
      tick(thing)
      yield c
    }
  end
  def take(n)
    SonicPi::Core::RingVector.new(self.to_a.take(n))
  end
  def shuffle
    SonicPi::Core::RingVector.new(self.to_a.shuffle)
  end
  def filter(&fun)
    SonicPi::Core::RingVector.new(self.to_a.filter(&fun))
  end
  def reject(&fun)
    SonicPi::Core::RingVector.new(self.to_a.reject(&fun))
  end
  def select(&fun)
    SonicPi::Core::RingVector.new(self.to_a.select(&fun))
  end
end

def note_to_semi(n1,n2)
  notes = ring(:F, :Fs, :G, :Gs, :A, :As, :B, :C, :Cs, :D, :Ds, :E)
  start_hit = notes.index(note_info(n1).pitch_class)
  goal_hit = notes.index(note_info(n2).pitch_class)
  octave_diff = note_info(n2).octave - note_info(n1).octave
  if octave_diff < 0
    diff = (start_hit - goal_hit) + octave_diff*12
  else
    diff = (goal_hit - start_hit) + octave_diff*12
  end
end

def smash(s,bits)
  total_time = sample_duration(s)
  positions = bits.reduce([0]){|acc,bit| acc << acc[-1]+(total_time/bit)}
  load_sample s
  s_idx=0
  data = positions.reduce([]) do |acc,p|
    s_pos = positions[s_idx]
    e_pos = (positions[s_idx+1] || total_time)
    s_idx+=1
    acc << [s_pos, e_pos]
  end
  {sample: s, data: data, total: total_time}
end

def sample_smash(sample_file, bits, *args, &block)
  if sample_file
    data = smash(sample_file, bits)
    opt = args[0]
    selection = data[:data].shuffle
    fx_selection = opt[:fx] || ring(:none,:none)
    opt.delete(:fx)
    at do
      selection.each do |d|
        opt[:start] = d[0]/data[:total]
        opt[:finish] = d[1]/data[:total]
        with_fx(fx_selection.tick(:fx), mix: 1.0) do
          sample(sample_file, *[opt])
        end
        yield block if block_given?
        sleep d[1]-d[0]
      end
    end
    selection
  end
end

def smp(*args)
  begin
  sample_thing = args.first
  if sample_thing
    smp_name = if sample_thing.is_a?(Hash)
      sample_file = sample_thing[:path]
      if sample_thing[:onset] && sample_thing[:offset]
        start = ratio_on(sample_thing) + (args.last[:start_offset] || 0)
        fini = ratio_off(sample_thing) + (args.last[:finish_offset] || 0)
      else
        start = 0
        fini = 1
      end
      options = {start: start, finish: fini}
      options = if sample_thing.keys.length > 1
        options.merge(args.last)
      else
        options
      end
      sample sample_file, *[options]
      sample_file
    else
      sample(*args)
      sample_thing
    end
    if smp_name =~ /kick/i
      dshader :decay, :iBeat, ((args[-1] && args[-1].is_a?(Hash) && args[-1][:v]) ? args[-1][:v] : 0.3), 0.005
    elsif smp_name =~ /hat/i
      @alien ||= 0.0
      @alien += 0.01
      @alien = @alien % 1.0
      dshader :iAlien, @alien
    end
  end
  rescue
    #puts $!
  end
end

def ratio_on(smp)
  if smp
    dur = sample_duration(smp[:path])
    smp[:onset]/dur+0.0
  end
end
def ratio_off(smp)
if smp
  dur = sample_duration(smp[:path])
  smp[:offset]/dur+0.0
  end
end

def spread_with(start_value,end_value, on_value, off_value)
  (spread start_value,end_value).map{|s| s ? on_value : off_value}
end
