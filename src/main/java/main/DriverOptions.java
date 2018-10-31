package main;

import com.beust.jcommander.Parameter;

import java.util.ArrayList;
import java.util.List;

// command line options
class DriverOptions {
   @Parameter(description = "<source file>")
   public List<String> parameters = new ArrayList<>();

   @Parameter(names = {"--help", "-h"}, description = "Usage help", help = true)
   public boolean help = false;

   @Parameter(names = {"--lexer", "-l"}, description = "Lexical analysis")
   public boolean lexer = true;
}
