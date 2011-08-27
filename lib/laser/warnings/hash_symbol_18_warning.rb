# Warning for rescuing "Exception" or "Object".
class Laser::HashSymbol18Warning < Laser::FileWarning
  severity 1
  type :style
  short_desc 'symbol hash key in 1.8 style'
  desc { "The Hash key :#{tokens[1][1]} is used in a Hash literal in 1.8 style." }
  fixable true
  setting_accessor :tokens
  setting_accessor :line_adjustments
  
  MATCH_18 = ObjectRegex.new('symbeg (ident | kw) sp? hashrocket')

  # Must implement reg_desc slightly differently from LexicalAnalysis::Token
  HS18Token = Struct.new(:type, :body, :line, :col) do
    # Unpacks the token from Ripper and breaks it into its separate components.
    #
    # @param [Array<Array<Integer, Integer>, Symbol, String>] token the token
    #     from Ripper that we're wrapping
    def initialize(token)
      (self.line, self.col), self.type, self.body = token
    end
    
    def width
      body.size
    end
    
    def reg_desc
      if type == :on_op && body == '=>'
        'hashrocket'
      else
        type.to_s.sub(/^on_/, '')
      end
    end
  end

  def match?(body = self.body)
    tokens = lex(body, HS18Token)
    matches = MATCH_18.all_matches(tokens)
    line_adjustments = Hash.new(0)
    matches.map do |match_tokens|
      result = Laser::HashSymbol18Warning.new(file, body,
          tokens: match_tokens,
          line_adjustments: line_adjustments)
      result.line_number = match_tokens[0].line
      result
    end
  end

  def fix(body = self.body)
    lines = body.lines.to_a  # eagerly expand lines
    symbeg, ident, *spacing_and_comments, rocket = tokens
    lines[symbeg.line - 1][symbeg.col + line_adjustments[symbeg.line],1] = ''
    lines[ident.line - 1].insert(ident.col + line_adjustments[ident.line] + ident.width - 1, ':')
    lines[rocket.line - 1][rocket.col + line_adjustments[rocket.line],2] = ''
    if spacing_and_comments.last != nil && spacing_and_comments.last.type == :on_sp
      lines[rocket.line - 1][rocket.col + line_adjustments[rocket.line] - 1,1] = ''
      line_adjustments[rocket.line] -= 3  # chomped " =>"
    else
      line_adjustments[rocket.line] -= 2  # only chomped the "=>"
    end
    lines.join
  end
end
