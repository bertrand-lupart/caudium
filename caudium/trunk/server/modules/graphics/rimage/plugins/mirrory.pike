constant doc="Mirror the image along the Y axis";

void render(mapping args, mapping this, string channel, object id, object m)
{
  if(this[channel])
    this[ channel ] = this[ channel ]->mirrory();
}
