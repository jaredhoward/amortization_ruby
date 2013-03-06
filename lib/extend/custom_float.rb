class Float

  # Rounds the number up to the next eighth
  def next_eighth
    thisnum = (self * 1000.0).ceil
    thisnum += 1 while thisnum / 125 != (thisnum / 125.0).ceil
    return thisnum / 1000.0
  end

  # Rounds the number up to the next eighth
  def last_eighth
    thisnum = (self * 1000.0).ceil
    thisnum -= 1 while thisnum / 125 != (thisnum / 125.0).ceil
    return thisnum / 1000.0
  end

  # Rounds the number up to the next fourth
  def next_fourth
    thisnum = (self * 1000.0).ceil
    thisnum += 1 while thisnum / 250 != (thisnum / 250.0).ceil
    return thisnum / 1000.0
  end

  # Rounds the number up to the next fourth
  def last_fourth
    thisnum = (self * 1000.0).ceil
    thisnum -= 1 while thisnum / 250 != (thisnum / 250.0).ceil
    return thisnum / 1000.0
  end

end
