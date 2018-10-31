package parse;

import error.ErrorHelper;

import java_cup.runtime.Symbol;
import java_cup.runtime.SymbolFactory;
import java_cup.runtime.ComplexSymbolFactory.Location;
import java_cup.runtime.ComplexSymbolFactory;

%%

%public
%final
%class Lexer
%implements Terminals
%cupsym Terminals
%cup
%line
%column
%char

%eofval{
    return tok(EOF);
%eofval}

%ctorarg String unitName

%init{
   this.unit = unitName;
%init}

%{
   private String unit;

   private ComplexSymbolFactory complexSymbolFactory = new ComplexSymbolFactory();

   public SymbolFactory getSymbolFactory() {
      return complexSymbolFactory;
   }

   // auxiliary methods to construct terminal symbols at current location

   private Location locLeft() {
      return new Location(unit, yyline + 1, yycolumn + 1, yychar);
   }

   private Location locRight() {
      return new Location(unit, yyline + 1, yycolumn + 1 + yylength(), yychar + yylength());
   }

   private java_cup.runtime.Symbol tok(int type, Object value, Location left, Location right) {
      return complexSymbolFactory.newSymbol(yytext(), type, left, right, value);
    }

   private Symbol tok(int type, String lexeme, Object value) {
      return complexSymbolFactory.newSymbol(lexeme, type, locLeft(), locRight(), value);
   }

   private Symbol tok(int type, Object value) {
      return tok(type, yytext(), value);
   }

   private Symbol tok(int type) {
      return tok(type, null);
   }

   // Error handling
   private void error(String format, Object... args) {
      throw ErrorHelper.error(
         Loc.loc(new Location(unit, yyline+1, yycolumn+1),
                 new Location(unit, yyline+1, yycolumn+1+yylength())),
         "lexical error: " + format,
         args);
   }

   // Auxiliary variables
   private int commentLevel;
   private StringBuilder builder = new StringBuilder();
   private Location strLeft;
%}

%state COMMENT
%state STR

litint  = -?[0-9]+
lfloat   = -?[0-9]+"."[0-9]+

id        = [a-zA-Z][a-zA-Z0-9_]*

%%

<YYINITIAL>{
[ \t\n]+     { /* skip */ }
"$" .*       { /* skip */ }
"{$"         { yybegin(COMMENT); commentLevel = 1; }

true         { return tok(LITBOOL, true); }
false        { return tok(LITBOOL, false); }
{litint}     { return tok(LITINT, yytext()); }
{lfloat}      { return tok(LFLOAT, yytext()); }

\"           { builder.setLength(0); strLeft = locLeft(); yybegin(STR); }

bool         { return tok(BOOL); }
int          { return tok(INT); }
string       { return tok(STRING); }
if           { return tok(IF); }
then         { return tok(THEN); }
else         { return tok(ELSE); }
while        { return tok(WHILE); }
do           { return tok(DO); }
print        { return tok(PRINT); }

{id}         { return tok(ID, yytext().intern()); }

":="         { return tok(ASSIGN); }
"+"          { return tok(PLUS); }
"-"          { return tok(MINUS); }
"*"          { return tok(TIMES); }
"/"          { return tok(DIV); }
"="          { return tok(EQ); }
"!="         { return tok(NE); }
"<"          { return tok(LT); }
"<="         { return tok(LE); }
">"          { return tok(GT); }
">="         { return tok(GE); }
"&&"         { return tok(AND); }
"||"         { return tok(OR); }
"&&"         { return tok(AND); }
"!!"         { return tok(NG); }
"("          { return tok(LPAREN); }
")"          { return tok(RPAREN); }
","          { return tok(COMMA); }
"-"[0-9]*    { return tok(UMINUS); }
}

<COMMENT>{
"{$"         { ++commentLevel; }
"$}"         { if (--commentLevel == 0) yybegin(YYINITIAL); }
[^]          { }
<<EOF>>      { yybegin(YYINITIAL); error("unclosed comment"); }
}

<STR>{
\"           { yybegin(YYINITIAL); return tok(LITSTRING, builder.toString(), strLeft, locRight()); }
\\ t         { builder.append('\t'); }
\\ n         { builder.append('\n'); }
\\ \\        { builder.append('\\'); }
\\ \"        { builder.append('"'); }
\\ [0-9]{3}  { builder.append((char)(Integer.parseInt(yytext().substring(1)))); }
\\ .         { error("invalid escape sequence in string literal"); }
[^\"\n\\]+   { builder.append(yytext()); }
\n           { error("invalid newline in string literal"); }
<<EOF>>      { yybegin(YYINITIAL); error("unclosed string literal"); }
}

.            { error("invalid character '%s'", yytext()); }
