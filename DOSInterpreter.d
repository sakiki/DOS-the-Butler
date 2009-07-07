/**
===================================================
          DOS the Butler RPD
===================================================
    
Original Programmer: Stephen Akiki
		     http://akiscode.com

Objective:
    Allow for the Rapid Prototype and Development
    of a personal "butler" with the complete power
    of a hand-coded "butler".
  
  
Initial Language: Custom (DOScript)
Processing Language: D (www.digitalmars.com/d/)
Target Language: D - DMD Compiler 2.014 alpha
           DMC Linker and Util. 8.50

Compiling:
    To compile the DOScript, run the Build.pl or
    Build.bat script (depending on your OS).
    
    To compile the DOSInterpreter, run the
    appropriate "DOSInterpreter" script
    
Recovering:
    If for some reason the Build script doesn't move
    the executable and/or source back from ./dmd/bin,
    use the Recover.pl (or Recover.bat) to retrieve 
    your code automatically.

Licensing:
    There is none, you may use this code and/or
    program for whatever you want.  Although I 
    must ask that if you distribute the source
    that you leave this header alone.  Other 
    than that, enjoy!
    
Bugs or Comments:
   theangrybaby@gmail.com
         Make sure to include "DOS the Butler"
      somewhere in the subject field.
      

*/


import std.c.time;
import std.stdio; // Standard Input/Output
import std.process; // For system() calls
import std.file; // File IO stuff
import std.string; // All that stringy goodness
import std.regexp; // Regular expressions rule

version = DEBUG; // If your changing this source code, your gonna want to
       //  uncomment this; final product doesn't need the extra
       //  info
       
       
// Name of DOS script, change it to your whim
//----------------------------------------------------------
   const     string NameofDOSScript = "DOScript.txt"; 
//----------------------------------------------------------

// Name of DOS TL file, change it to your whim
//----------------------------------------------------------
   const     string NameofDOSTL = "DOS.d";        
//----------------------------------------------------------

// Name of DOS executable, change it to your whim
//----------------------------------------------------------
   const     string NameofDOSExecutable = "DOS.exe";     
//----------------------------------------------------------


// Header for TL file
const string TLHeader = "
import std.stdio;
import std.process;
import std.string;
import std.c.stdio;
import std.c.time;


auto time = 150;

void Process(string process_string) {
        writef(\"%s\", \"Starting \");
        write(process_string);
        msleep(time);
        printf(\" . \");
        msleep(time);
        printf(\". \");
        msleep(time);
        printf(\". \");
        msleep(time);
}

char ch;

";

// Color hash, for use in Preprocessor class for Color
string[string] ColorHash;

// Symbol hash, for use in Preprocessor class
string[string] SymbolHash;

// Begin Class and Function Delclarations

class Preprocessor {
   private {
   static int InstanceCount = 0;  // To keep track of number of instances of Preprocessor class
                   //   THERE CAN ONLY BE ONE INSTANCE OF THIS CLASS (SEE CONSTRUCTOR)
        static int InSubMenu = 0; // 1 if in a submenu
                   // 0 if not in a submenu
   }
   
   this() { // Preprocessor constructor
       if(InstanceCount == 0) { // If no instances have been made
       InstanceCount++; // Create class and increase InstanceCount
       }
       
       else { // If instances have been made
          assert(InstanceCount == 0, "Only one instance of the Preprocessor class can be made"); // This will fail and give an error that stops the program
       }
   }

   string OS; // Operating system
   string Title; // Title of console window
   
   int ProcessStatus; // 1 means process function is on
            // 0 means process function is off
   
   string Color; // Color you want the console to be
             // First character is background
             // Second character is foreground
             
   // For debugging purposes             
        int SingleFunctionCount;
        int SubMenuCount;

   void PreProcess(Preprocessor PP, string[] file) { // Guess what this does? :)
      foreach(string line; file) { // Cycle through the array (file), line by line 

         // For some reason, the std.regexp.find function returns 
         //  false when it finds "it", so I inverted the result to 
         //  get the correct one.  Confusing, I know...

         if (!(find(line, RegExp("#OS")))) {
            // OS
            PP.OS = sub(line, "#OS ", ""); // Replace #OS with a space and assign the 
                            //  remaining line to PP.OS
            
            version(DEBUG) writefln("---> BEGIN DEGUG INFO");
            version(DEBUG) writefln();
            version(DEBUG) writefln("PP.OS: %s", PP.OS); // Extra Info for debugging
         }

         else if (!(find(line, RegExp("#TITLE")))) {
            // Title
            PP.Title = sub(line, "#TITLE ", ""); // Same as #OS except with #TITLE
                     
            version(DEBUG) writefln("PP.Title: %s", PP.Title); // Extra Info for debugging
         }
         
         
         else if (!(find(line, RegExp("#SYMBOL")))) {
            // Symbol
            string[] Temp_SymbolString = std.string.split(sub(line, "#SYMBOL ", "")); // Remove #SYMBOL and split the remaining line based on spaces
            // e.g.
            //  #SYMBOL <<TAB>> \t
            //  Temp_SymbolString[0] = <<TAB>>
            //  Temp_SymbolString[1] = \t
            SymbolHash[Temp_SymbolString[0]] = Temp_SymbolString[1];
            
            version(DEBUG) writefln("Symbol: %s Result: %s", Temp_SymbolString[0], SymbolHash[Temp_SymbolString[0]]); // Extra Info for debugging
         }

         else if (!(find(line, RegExp("#PROCESS")))) { 
            // Process
            string Temp_Line = sub(line, "#PROCESS ", ""); // Same as #OS except with #PROCESS
            PP.ProcessStatus = atoi(Temp_Line);    //  and I cast it as int (from string) so it would
                            //  play nicely with my class setup
            
            version(DEBUG) writefln("PP.ProcessStatus: %s", PP.ProcessStatus); // Extra Info for debugging
         }

         else if (!(find(line, RegExp("#COLOR")))) { 
            // Color
            auto Temp_Line = sub(line, "#COLOR ", ""); // Get rid of #COLOR so we can split the line and store in temp variable
            auto string[] ColorArray = std.string.split(Temp_Line); // Split line into a string array based on white space
            foreach(Temp_ColorLine; ColorArray) { // Cycle through ColorArray
               if (ColorHash[Temp_ColorLine] != null) { // As long as something is there...
                  PP.Color ~= cast(string)(ColorHash[Temp_ColorLine]); // Append it to PP.Color
                                         //  Make sure to cast it
                                         //  so it plays nice with
                                         //  my class setup
               }
               
            }
            
            version(DEBUG) { // Extra Info for debugging
               writefln("PP.Color: %s", PP.Color); 
               writefln("ColorArray (background foreground): %s\n", ColorArray);
            }
         }
         
         else if (!(find(line, RegExp(".*=>")))) {
               // Start of Submenu
            PP.SubMenuCount++;
            PP.InSubMenu++; // We are in a submenu, so increase this to one so we don't count future ->'s
         }
         
         else if (!(find(line, RegExp(".*<=")))) {
            // End of Submenu
            PP.InSubMenu--; // We are out of a submenu, decrease count
         }
         
         else if (!(find(line, RegExp(".*->")))) {
            // Start of single function
            if(PP.InSubMenu == 0) { // If we are out of a submenu...
               PP.SingleFunctionCount++;
            }
               
         }

      }

   }

}


string HandleText(string TextLine) { // Removes #TEXT tag
   // Text
   auto Temp_TextLine = sub(TextLine, ".*#TEXT ", ""); // Replace #TEXT and return remaining line
                               
   return Temp_TextLine;
}


string HandleClearScreen() { // returns appropriate clear screen command based on OS
   // Clear screen
   // If Windows...
   version(Windows) return "system(\"cls\");";
   
   // If Linux...
   version(linux) return "system(\"clear\");";
}


string[] ReadFileLine(string fname) { // Read DOScript line by line to analyze
   auto file = fopen(fname); // Open file to read
   auto string FileArray; // Thing we will be returning (auto is for Garbage Collector)
   foreach(string line; lines(file)) { // Go through the DOScript line by line
           FileArray ~= line; // Combine them together (line has a newline at the end)
   }
   return std.string.split(FileArray, "\n"); // Returns an array of strings seperated by newlines
                    // Full import path to prevent confusion with regexp split
}

   
void ClearTL() {
   const void[] line = "";
   std.file.write(NameofDOSTL, line);
}

void AppendtoTL(const void[] line) {
   std.file.append(NameofDOSTL, line ~ "\n");
}


int WriteSymbols(string CharacterKey) { // For symbols picked up by preprocessor

   foreach(key, value; SymbolHash) { // Cycle through symbol hash
      if(CharacterKey == key) { // this is a special symbol
         std.file.append(NameofDOSTL, "case '" ~ value ~ "':" ~ "\n");// use std.file.append because AppendtoTL doesn't like special characters
         return -1;
      }
            
      
   }
   // Theres nothing there
   AppendtoTL("case '" ~ CharacterKey ~ "':");
   return 0;   
   
}


/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/

void MakeMenus(string[] File) { // Makes menus in TL before MAIN function

   // Minimum of 2 passes
   // First pass is for Main Menu
   // Rest is for rest of submenus
   
   
   AppendtoTL("void DisplayMenu_MainMenu() {");
   foreach(line; File) { 
      if (!(find(line, RegExp("[ \t\n\r\f]+#TEXT")))) { // [ \t\n\r\f] means any whitespace
         // Ignore nested text                  
      }
            
      else if (!(find(line, RegExp("[ \t\n\r\f]+#CLRSCR")))) { // [ \t\n\r\f] means any whitespace
         // Ignore nested clrscr
      }
      
   
      else if (!(find(line, RegExp("#TEXT")))) { 
         AppendtoTL("writefln(\"" ~ (HandleText(line)) ~ "\");"); // Take non-nested text and print to TL
      }
      
      else if (!(find(line, RegExp("#CLRSCR")))) { 
         AppendtoTL((HandleClearScreen())); // Take non-nested clrscr and print to TL
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+->")))) { // Ignore nested single functions   
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+=>")))) { // Ignore nested submenus
      }
      
      else if (!(find(line, RegExp("->")))) { // Handle non-nested single function and print to TL
         string[] Temp_SingleFunction = std.string.split(line, " - "); // Split line
         auto string CharacterKey = sub(Temp_SingleFunction[0], ".*-> ", ""); // Strip -> from character key
         AppendtoTL("writefln(\"" ~ CharacterKey ~ ". " ~ Temp_SingleFunction[1] ~ "\");");
         
      }
      
      else if (!(find(line, RegExp("=>")))) { // Handle non-nested sub menus and print to TL
         string[] Temp_SubMenu = std.string.split(line, " - "); // Split line
         auto string CharacterKey = sub(Temp_SubMenu[0], ".*=> ", ""); // Strip => from character key
         AppendtoTL("writefln(\"\t" ~ CharacterKey ~ ". " ~ Temp_SubMenu[1] ~ "\");");   
      }
      
      else if (!(find(line, RegExp("")))) { 
            
      }
      
   }
   AppendtoTL("ch = getch();");
   AppendtoTL("}");
   
   foreach(line; File) { // Second pass is for submenus
      if (!(find(line, RegExp("=>")))) { 
         string[] Temp_SubMenu = std.string.split(line, " - ");
         AppendtoTL("void DisplayMenu_" ~ Temp_SubMenu[2] ~ "() {");
                  
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+#CLRSCR")))) { 
         AppendtoTL((HandleClearScreen())); // Take nested clrscr and print to TL
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+#TEXT")))) { 
         AppendtoTL("writefln(\"" ~ (HandleText(line)) ~ "\");"); // Take nested text and print to TL         
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+->")))) { // Handle nested single functions
         string[] Temp_SingleFunction = std.string.split(line, " - ");
         auto string CharacterKey = sub(Temp_SingleFunction[0], ".*-> ", ""); // Strip -> from character key
         AppendtoTL("writefln(\"" ~ CharacterKey ~ ". " ~ Temp_SingleFunction[1] ~ "\");");         
      }
      
      else if (!(find(line, RegExp("<=")))) {
         AppendtoTL("ch = getch();");
         AppendtoTL("}");
      }
      
   }
   
}

void Validator(string[] File) { // Validates the DOScript
   int ErrorCount = 0;
   writefln();
   writefln("------------Validating-------------");
   writefln();
   foreach(int count, line; File) {
      if (!(find(line, RegExp(".*->")))) { 
         string[] Temp_SingleFunction = std.string.split(line, " - ");
         if(Temp_SingleFunction.length != 4) { // If the line does not split right theres an error here
            writefln("Line: %d -> Watch the spacing on the single function", count);
            writefln("\t   " ~ line); // Print the line in question
            writefln();
            ErrorCount++; // Increase error count
         }
                        
      }
      
      if (!(find(line, RegExp(".*=>")))) { 
         string[] Temp_SingleFunction = std.string.split(line, " - ");
         if(Temp_SingleFunction.length != 3) { // If the line does not split right theres an error here
            writefln("Line: %d -> Watch the spacing on the submenu", count);
            writefln("\t   " ~ line); // Print the line in question
            writefln();
            ErrorCount++; // Increase error count
         }
                        
      }
   }
   writefln();
   writefln("You have %d error(s)", ErrorCount);
   writefln();
   writefln("-----------End Validating------------");
   writefln();
   if (ErrorCount != 0) { // If theres an error...
      writefln("You have errors in your DOScript");
      writefln("The building of this script will fail");
      system("pause");
   }
}

/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/

// End Class and Function Declarations

void main()
{

// For ColorHash and PP.Color
ColorHash["black"] = "0";
ColorHash["blue"] = "1";
ColorHash["green"] = "2";
ColorHash["aqua"] = "3";
ColorHash["red"] = "4";
ColorHash["purple"] = "5";
ColorHash["yellow"] = "6";
ColorHash["white"] = "7";
ColorHash["gray"] = "8";
ColorHash["ltblue"] = "9"; // lt = light
ColorHash["ltgreen"] = "a";
ColorHash["ltaqua"] = "b";
ColorHash["ltred"] = "c";
ColorHash["ltpurple"] = "d";
ColorHash["ltyellow"] = "e";
ColorHash["btwhite"] = "f"; // bt = bright


/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/
Preprocessor PreProcessor = new Preprocessor;// Make an instance of the Preprocessor class
                         //  Watch the capitalization!!!
                         //  YOU CAN ONLY MAKE ONE INSTANCE OF THIS CLASS
/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/

string[] File = ReadFileLine(NameofDOSScript); // Holds entire file in memory in a string array for line-by-line reading

/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/                   

Validator(File);                              
PreProcessor.PreProcess(PreProcessor, File); // PreProcess the script

ClearTL(); // Clears the target language file

         
/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/


void MakeSwitchStatements(string[] File) { // Make the switch hierarchy
   AppendtoTL("void main() {");
   
   AppendtoTL("system(\"color " ~ PreProcessor.Color ~ "\");"); // Color Command
   AppendtoTL("int EXIT = 0;");
   AppendtoTL("while(EXIT == 0) {");
   AppendtoTL("system(\"title " ~ PreProcessor.Title ~ "\");"); // Title Command
   foreach(line; File) {
      if (!(find(line, RegExp("#START")))) { // [ \t\n\r\f] means any whitespace
         AppendtoTL("DisplayMenu_MainMenu();");
         AppendtoTL("switch(ch) {");
      }
      
      else if (!(find(line, RegExp(".*->")))) { // Handle nested SF before non-nested ones
         string[] Temp_SingleFunction = std.string.split(line, " - ");
         auto string CharacterKey = sub(Temp_SingleFunction[0], ".*-> ", ""); // Strip -> from character key
         
         WriteSymbols(CharacterKey);
         
         if(PreProcessor.ProcessStatus == 1) { // If you want processes
            if(Temp_SingleFunction[3] != "NONE") { // As long as it doesn't equal NONE
               AppendtoTL("Process(\"" ~ Temp_SingleFunction[3] ~ "\");"); // Add process line
            }
         }
         AppendtoTL(Temp_SingleFunction[2]); // This is the actual command
         AppendtoTL("break;");
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+#CLRSCR")))) { // Ignore
      }
      
      else if (!(find(line, RegExp("[ \t\n\r\f]+#TEXT")))) { // Ignore
      }

      // Maybe handle nested submenus here?
      /+
      else if (!(find(line, RegExp("[ \t\n\r\f]+=>")))) { 
      }
      +/
      else if (!(find(line, RegExp("=>")))) { 
         string[] Temp_SubMenu = std.string.split(line, " - ");
         auto string CharacterKey = sub(Temp_SubMenu[0], ".*=> ", ""); // Strip => from character key
         WriteSymbols(CharacterKey);
         
         
         AppendtoTL("DisplayMenu_" ~ Temp_SubMenu[2] ~ "();");
         AppendtoTL("switch(ch) {");
         
      }
      
      else if (!(find(line, RegExp("<=")))) { 
         AppendtoTL("default:");
         AppendtoTL("break;");
         AppendtoTL("}");
         AppendtoTL("break;");
      }
      
      else if (!(find(line, RegExp("#END")))) { 
         AppendtoTL("default:");
         AppendtoTL("break;");
         AppendtoTL("}");
         AppendtoTL("}");
         AppendtoTL("}");
      }

   }
}

/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/

AppendtoTL(TLHeader); // Print standard header (see above)
MakeMenus(File);
MakeSwitchStatements(File);
      

/++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/

   version(DEBUG) {
      writefln("PreProcessor.SingleFunctionCount: %d", PreProcessor.SingleFunctionCount);
      writefln("PreProcessor.SubMenuCount: %d", PreProcessor.SubMenuCount);
      writefln();
      writefln("<--- END DEGUG INFO");
   }

writefln();
writefln("------------------BUILDING--------------------");
writefln();
   
version(Windows) {
   writefln("Building using Build.bat");
   system("del DOS.exe");
   system("Build.bat");
}

version(linux) {
   writefln("Building using Build.pl");
   system("perl Build.pl");


}

version(Windows) system("pause"); // Pause to read   
}
