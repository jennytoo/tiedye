RESERVED_WORDS = (
    'and',      'break',    'do',       'else',     'elseif',   'end',
    'false',    'for',      'function', 'if',       'in',       'local',
    'nil',      'not',      'or',       'repeat',   'return',   'then',
    'true',     'until',    'while')

class Lua(object):
  def __init__(self):
    self.depth = 0
    self.newline = '\n'
    self.tab = '  '

  def encode(self, obj):
    if not obj:
      return
    self.depth = 0
    return self.__encode(obj)

  @staticmethod
  def __filter(obj):
    return isinstance(obj, (int, float, long)) or (
        isinstance(obj, basestring) and len(obj) < 10)

  @staticmethod
  def __sanitize_key(key):
    if str(key).isalpha() and key not in RESERVED_WORDS:
      return key
    else:
      return '[' + repr(key) + ']'
  #@staticmethod
  #def __sanitize_key(key):
  #  if str(key).isalpha() and k not in RESERVED_WORDS else '["%s"]'
  def __encode(self, obj):
    s = ''
    tab = self.tab
    newline = self.newline
    if isinstance(obj, basestring):
      s += '"%s"' % obj.replace(r'"', r'\"')
    elif isinstance(obj, (int, float, long, complex)):
      s += str(obj)
    elif isinstance(obj, bool):
      s += str(obj).lower()
    elif isinstance(obj, (list, tuple, dict)):
      self.depth += 1
      if not obj or (
          not isinstance(obj, dict) and len(
            filter(self.__filter, obj)) == len(obj)):
        newline = tab = ''
      dp = tab * self.depth
      s += "%s{%s" % (tab * (self.depth - 2), newline)
      if isinstance(obj, dict):
        s += (',%s' % newline).join(
          dp + '%s = %s' % (self.__sanitize_key(k), self.__encode(v))
          for k, v in sorted(obj.iteritems()))
      else:
        s += (',%s' % newline).join(
          [dp + self.__encode(el) for el in obj])
      self.depth -= 1
      s += "%s%s}" % (newline, tab * self.depth)
    return s
