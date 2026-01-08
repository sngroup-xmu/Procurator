/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_MNT_E_P4_VERIFY_P4B_TRANSLATOR_BUILD_HOST_TOOLS_IR_GENERATOR_IR_GENERATOR_HPP_INCLUDED
# define YY_YY_MNT_E_P4_VERIFY_P4B_TRANSLATOR_BUILD_HOST_TOOLS_IR_GENERATOR_IR_GENERATOR_HPP_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    ABSTRACT = 258,                /* ABSTRACT  */
    APPLY = 259,                   /* APPLY  */
    CLASS = 260,                   /* CLASS  */
    CONST = 261,                   /* CONST  */
    DBLCOL = 262,                  /* DBLCOL  */
    DEFAULT = 263,                 /* DEFAULT  */
    DELETE = 264,                  /* DELETE  */
    INLINE = 265,                  /* INLINE  */
    INTERFACE = 266,               /* INTERFACE  */
    NAMESPACE = 267,               /* NAMESPACE  */
    NEW = 268,                     /* NEW  */
    NULLOK = 269,                  /* NULLOK  */
    OPERATOR = 270,                /* OPERATOR  */
    OPTIONAL = 271,                /* OPTIONAL  */
    PRIVATE = 272,                 /* PRIVATE  */
    PROTECTED = 273,               /* PROTECTED  */
    PUBLIC = 274,                  /* PUBLIC  */
    STATIC = 275,                  /* STATIC  */
    VIRTUAL = 276,                 /* VIRTUAL  */
    BLOCK = 277,                   /* BLOCK  */
    COMMENTBLOCK = 278,            /* COMMENTBLOCK  */
    IDENTIFIER = 279,              /* IDENTIFIER  */
    INTEGER = 280,                 /* INTEGER  */
    NO = 281,                      /* NO  */
    STRING = 282,                  /* STRING  */
    ZERO = 283,                    /* ZERO  */
    EMITBLOCK = 284                /* EMITBLOCK  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 57 "ir-generator.ypp"

    YYSTYPE() {}
    int                         i;
    cstring                     str;
    IrClass                     *irClass;
    IrElement                   *irElement;
    IrField                     *irField;
    IrMethod                    *irMethod;
    IrNamespace                 *irNamespace;
    ConstFieldInitializer       *constFieldInit;
    LookupScope                 *lookup;
    std::vector<const Type *>   *types;
    Type                        *type;
    NodeKind                    kind;
    struct {
        bool                    impl;
        cstring                 block;
    }                           emit;

#line 113 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.hpp"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif

/* Location type.  */
#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE YYLTYPE;
struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
};
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif


extern YYSTYPE yylval;
extern YYLTYPE yylloc;

int yyparse (void);


#endif /* !YY_YY_MNT_E_P4_VERIFY_P4B_TRANSLATOR_BUILD_HOST_TOOLS_IR_GENERATOR_IR_GENERATOR_HPP_INCLUDED  */
