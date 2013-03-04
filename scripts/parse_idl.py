from ply import lex, yacc
from ply.lex import TOKEN

class IDLParser:
    literals = "[]();,"

    digit      = r'([0-9])'
    nondigit   = r'([_A-Za-z])'
    identifier = r'(' + nondigit + r'(' + digit + r'|' + nondigit + r')*)'

    tokens = [ 'ID' ]
    t_ignore = ' \t\r'

    def build(self, **kwargs):
        self.lexer  = lex.lex(module=self, **kwargs)
        self.parser = yacc.yacc(module=self,**kwargs)

    def lex(self, data):
        self.lexer.input(data)
        while True:
            tok = self.lexer.token()
            if not tok:
                break
            yield tok

    def parse(self, data):
        return self.parser.parse(data, lexer=self.lexer)

    @TOKEN(identifier)
    def t_ID(self, t):
        return t

    def t_newline(self, t):
        r'\n+'
        t.lexer.lineno += len(t.value) / 2
        pass

    def t_ignore_comment(self, t):
        r'(/\*(.|\n)*?\*/)|(//.*)'
        t.lexer.lineno += t.value.count('\n') / 2
        pass

    def t_error(self, t):
        print("Illegal character '%s' at line %d" % (t.value[0], t.lexer.lineno))
        t.lexer.skip(1)

    def p_decllist_1(self, p):
        '''decllist : decllist decl'''
        p[0] = p[1] + [p[2]]

    def p_decllist_2(self, p):
        '''decllist : empty'''
        p[0] = []

    def p_decl(self, p):
        '''decl : opt_attributes ID ID '(' arglist ')' ';' '''
        p[0] = { 'attributes'  : p[1],
                 'return_type' : p[2],
                 'name'        : p[3],
                 'arguments'   : p[5]
               }

    def p_opt_attributes_1(self, p):
        '''opt_attributes : '[' attributelist ']' '''
        p[0] = p[2]

    def p_opt_attributes_2(self, p):
        '''opt_attributes : empty '''
        p[0] = []

    def p_empty(self, p):
        ''' empty : '''
        pass

    def p_attributelist_1(self, p):
        ''' attributelist : attributelist ',' attribute'''
        p[0] = p[1] + [p[3]]

    def p_attributelist_2(self, p):
        ''' attributelist : attribute '''
        p[0] = [p[1]]

    def p_attribute(self, p):
        '''attribute : ID '''
        p[0] = p[1]

    def p_arglist_1(self, p):
        '''arglist : arglist ',' argument'''
        p[0] = p[1] + [p[3]]

    def p_arglist_2(self, p):
        '''arglist : argument'''
        p[0] = [p[1]]

    def p_arglist_3(self, p):
        '''arglist : empty '''
        p[0] = []

    def p_argument(self, p):
        '''argument : opt_attributes ID ID'''
        p[0] = { 'attributes': p[1], 'type': p[2], 'name': p[3] }
    
    # Error rule for syntax errors
    def p_error(self, p):
        print "Syntax error in input!", p, self.lexer.lineno
