module ReplElectric
  module Midi
    include SonicPi::Lang::Support::DocSystem
    include SonicPi::Util
    MODE_NOTE = 13
    #helpers
    def linear_map(x0, x1, y0, y1, x)
      dydx = (y1 - y0) / (x1- x0)
      dx = (x- x0)
      (y0 + (dydx * dx))
    end

    def find_chord(note)
      chord(note,ct(note))
    end

    def strpat(s)
      p=nil
      s.gsub(/\s+/,'').split('').reduce([]){|ac,x|
        if x != '[' && x!= "]" && x!= "\n"
          ac << x
        elsif x == "]"
          ac[-1] = "[#{ac[-1]}#{x}"
        end
        ac
      }.map{|x| eval(x)}.ring
    end
  end
end
