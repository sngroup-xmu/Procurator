/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

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

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 17 "ir-generator.ypp"
 /* -*-C++-*- */
// some of these includes are needed by lex-generated file

#include <assert.h>
#include <limits.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include <iostream>
#include <cerrno>
#include <vector>

#include "lib/cstring.h"
#include "lib/stringref.h"
#include "lib/source_file.h"
#include "lib/error.h"
#include "tools/ir-generator/irclass.h"

#ifndef YYDEBUG
#define YYDEBUG 1
#endif

#define YYLTYPE Util::SourceInfo
#define YYLLOC_DEFAULT(Cur, Rhs, N)                                     \
    ((Cur) = (N) ? YYRHSLOC(Rhs, 1) + YYRHSLOC(Rhs, N)                  \
                 : Util::SourceInfo(sources, YYRHSLOC(Rhs, 0).getEnd()))

static void yyerror(const char *fmt, ...);
static std::vector<IrElement*> global;
static CommentBlock *currCommentBlock = nullptr;

namespace {  // anonymous namespace
static int yylex();

static Util::InputSources *sources = new Util::InputSources;
static IrNamespace *current_namespace = LookupScope().resolve(0);


#line 111 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "ir-generator.hpp"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_ABSTRACT = 3,                   /* ABSTRACT  */
  YYSYMBOL_APPLY = 4,                      /* APPLY  */
  YYSYMBOL_CLASS = 5,                      /* CLASS  */
  YYSYMBOL_CONST = 6,                      /* CONST  */
  YYSYMBOL_DBLCOL = 7,                     /* DBLCOL  */
  YYSYMBOL_DEFAULT = 8,                    /* DEFAULT  */
  YYSYMBOL_DELETE = 9,                     /* DELETE  */
  YYSYMBOL_INLINE = 10,                    /* INLINE  */
  YYSYMBOL_INTERFACE = 11,                 /* INTERFACE  */
  YYSYMBOL_NAMESPACE = 12,                 /* NAMESPACE  */
  YYSYMBOL_NEW = 13,                       /* NEW  */
  YYSYMBOL_NULLOK = 14,                    /* NULLOK  */
  YYSYMBOL_OPERATOR = 15,                  /* OPERATOR  */
  YYSYMBOL_OPTIONAL = 16,                  /* OPTIONAL  */
  YYSYMBOL_PRIVATE = 17,                   /* PRIVATE  */
  YYSYMBOL_PROTECTED = 18,                 /* PROTECTED  */
  YYSYMBOL_PUBLIC = 19,                    /* PUBLIC  */
  YYSYMBOL_STATIC = 20,                    /* STATIC  */
  YYSYMBOL_VIRTUAL = 21,                   /* VIRTUAL  */
  YYSYMBOL_BLOCK = 22,                     /* BLOCK  */
  YYSYMBOL_COMMENTBLOCK = 23,              /* COMMENTBLOCK  */
  YYSYMBOL_IDENTIFIER = 24,                /* IDENTIFIER  */
  YYSYMBOL_INTEGER = 25,                   /* INTEGER  */
  YYSYMBOL_NO = 26,                        /* NO  */
  YYSYMBOL_STRING = 27,                    /* STRING  */
  YYSYMBOL_ZERO = 28,                      /* ZERO  */
  YYSYMBOL_EMITBLOCK = 29,                 /* EMITBLOCK  */
  YYSYMBOL_30_ = 30,                       /* '{'  */
  YYSYMBOL_31_ = 31,                       /* '}'  */
  YYSYMBOL_32_ = 32,                       /* ';'  */
  YYSYMBOL_33_ = 33,                       /* ':'  */
  YYSYMBOL_34_ = 34,                       /* ','  */
  YYSYMBOL_35_ = 35,                       /* '('  */
  YYSYMBOL_36_ = 36,                       /* ')'  */
  YYSYMBOL_37_ = 37,                       /* '='  */
  YYSYMBOL_38_ = 38,                       /* '!'  */
  YYSYMBOL_39_ = 39,                       /* '<'  */
  YYSYMBOL_40_ = 40,                       /* '>'  */
  YYSYMBOL_41_ = 41,                       /* '['  */
  YYSYMBOL_42_ = 42,                       /* ']'  */
  YYSYMBOL_43_ = 43,                       /* '&'  */
  YYSYMBOL_44_ = 44,                       /* '*'  */
  YYSYMBOL_45_ = 45,                       /* '+'  */
  YYSYMBOL_YYACCEPT = 46,                  /* $accept  */
  YYSYMBOL_input = 47,                     /* input  */
  YYSYMBOL_element = 48,                   /* element  */
  YYSYMBOL_49_1 = 49,                      /* $@1  */
  YYSYMBOL_50_2 = 50,                      /* $@2  */
  YYSYMBOL_scope = 51,                     /* scope  */
  YYSYMBOL_irclass = 52,                   /* irclass  */
  YYSYMBOL_53_3 = 53,                      /* @3  */
  YYSYMBOL_parentList = 54,                /* parentList  */
  YYSYMBOL_nonEmptyParentList = 55,        /* nonEmptyParentList  */
  YYSYMBOL_kind = 56,                      /* kind  */
  YYSYMBOL_partList = 57,                  /* partList  */
  YYSYMBOL_part = 58,                      /* part  */
  YYSYMBOL_59_4 = 59,                      /* $@4  */
  YYSYMBOL_60_5 = 60,                      /* @5  */
  YYSYMBOL_method = 61,                    /* method  */
  YYSYMBOL_62_6 = 62,                      /* @6  */
  YYSYMBOL_63_7 = 63,                      /* $@7  */
  YYSYMBOL_64_8 = 64,                      /* @8  */
  YYSYMBOL_methodName = 65,                /* methodName  */
  YYSYMBOL_optArgList = 66,                /* optArgList  */
  YYSYMBOL_argList = 67,                   /* argList  */
  YYSYMBOL_optConst = 68,                  /* optConst  */
  YYSYMBOL_optOverride = 69,               /* optOverride  */
  YYSYMBOL_body = 70,                      /* body  */
  YYSYMBOL_irField = 71,                   /* irField  */
  YYSYMBOL_modifier = 72,                  /* modifier  */
  YYSYMBOL_modifiers = 73,                 /* modifiers  */
  YYSYMBOL_fieldName = 74,                 /* fieldName  */
  YYSYMBOL_optInitializer = 75,            /* optInitializer  */
  YYSYMBOL_lookup_scope = 76,              /* lookup_scope  */
  YYSYMBOL_nonRefType = 77,                /* nonRefType  */
  YYSYMBOL_type = 78,                      /* type  */
  YYSYMBOL_type_args = 79,                 /* type_args  */
  YYSYMBOL_type_arg = 80,                  /* type_arg  */
  YYSYMBOL_optTypeList = 81,               /* optTypeList  */
  YYSYMBOL_typeList = 82,                  /* typeList  */
  YYSYMBOL_constFieldInit = 83,            /* constFieldInit  */
  YYSYMBOL_expression = 84,                /* expression  */
  YYSYMBOL_name = 85                       /* name  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;


/* Second part of user prologue.  */
#line 101 "ir-generator.ypp"

static void
symbol_print(FILE* file, int type, YYSTYPE value)
{
    switch (type)
    {
    case EMITBLOCK:
        fprintf(file, "%s%s", value.emit.impl ? "/*impl*/ " : "", value.emit.block.c_str());
        break;
    case BLOCK:
    case COMMENTBLOCK:
    case IDENTIFIER:
    case STRING:
    case NO:
    case INTEGER:
    case ZERO:
        fprintf(file, "%s", value.str.c_str());
        break;
    default:
        break;
    }
}

#define YYPRINT(file, type, value)   symbol_print(file, type, value)

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
#include "ir-generator-lex.c"
#pragma GCC diagnostic pop

static cstring canon_name(cstring name) {
    /* canonical method names for backwards compatibility */
    if (name == "visitchildren") return "visit_children";
    return name;
}

static void pushCurrentComment() {
    if (currCommentBlock) {
        global.push_back(currCommentBlock);
        currCommentBlock = nullptr;
    }
}


#line 276 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"


#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_uint8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if 1

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* 1 */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL \
             && defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
  YYLTYPE yyls_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE) \
             + YYSIZEOF (YYLTYPE)) \
      + 2 * YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  2
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   189

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  46
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  40
/* YYNRULES -- Number of rules.  */
#define YYNRULES  114
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  177

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   284


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    38,     2,     2,     2,     2,    43,     2,
      35,    36,    44,    45,    34,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,    33,    32,
      39,    37,    40,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    41,     2,    42,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    30,     2,    31,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   150,   150,   151,   155,   161,   167,   170,   171,   170,
     176,   180,   181,   182,   187,   186,   193,   194,   198,   199,
     203,   204,   205,   209,   210,   218,   219,   220,   221,   222,
     223,   224,   225,   226,   227,   228,   227,   230,   234,   236,
     239,   245,   238,   250,   249,   269,   270,   271,   272,   273,
     274,   275,   276,   277,   280,   280,   283,   287,   293,   293,
     296,   297,   300,   301,   302,   303,   304,   308,   312,   319,
     320,   321,   322,   323,   326,   326,   328,   328,   331,   332,
     333,   337,   338,   339,   342,   343,   344,   345,   346,   349,
     350,   351,   352,   353,   354,   355,   359,   360,   364,   365,
     369,   370,   374,   375,   378,   384,   384,   384,   384,   385,
     386,   387,   390,   391,   392
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if 1
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "ABSTRACT", "APPLY",
  "CLASS", "CONST", "DBLCOL", "DEFAULT", "DELETE", "INLINE", "INTERFACE",
  "NAMESPACE", "NEW", "NULLOK", "OPERATOR", "OPTIONAL", "PRIVATE",
  "PROTECTED", "PUBLIC", "STATIC", "VIRTUAL", "BLOCK", "COMMENTBLOCK",
  "IDENTIFIER", "INTEGER", "NO", "STRING", "ZERO", "EMITBLOCK", "'{'",
  "'}'", "';'", "':'", "','", "'('", "')'", "'='", "'!'", "'<'", "'>'",
  "'['", "']'", "'&'", "'*'", "'+'", "$accept", "input", "element", "$@1",
  "$@2", "scope", "irclass", "@3", "parentList", "nonEmptyParentList",
  "kind", "partList", "part", "$@4", "@5", "method", "@6", "$@7", "@8",
  "methodName", "optArgList", "argList", "optConst", "optOverride", "body",
  "irField", "modifier", "modifiers", "fieldName", "optInitializer",
  "lookup_scope", "nonRefType", "type", "type_args", "type_arg",
  "optTypeList", "typeList", "constFieldInit", "expression", "name", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-116)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-46)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
    -116,    57,  -116,  -116,  -116,  -116,  -116,  -116,  -116,  -116,
    -116,  -116,    19,   -14,  -116,    -9,  -116,    21,    49,  -116,
      95,    70,  -116,    59,  -116,    31,    47,     7,   -33,     5,
    -116,    53,   129,  -116,    95,  -116,    99,    95,    82,    60,
    -116,  -116,  -116,  -116,  -116,  -116,     5,  -116,    -1,    65,
    -116,    66,  -116,  -116,    92,    95,    95,  -116,  -116,  -116,
    -116,    79,    80,    81,  -116,  -116,  -116,  -116,  -116,  -116,
    -116,   130,  -116,     5,    86,    90,  -116,   101,  -116,  -116,
    -116,    59,  -116,  -116,   137,  -116,  -116,  -116,    56,    39,
    -116,    -3,  -116,    95,    96,    51,    91,    97,    33,    -7,
    -116,   139,  -116,  -116,  -116,    98,   104,   105,     5,  -116,
    -116,   105,  -116,  -116,  -116,  -116,  -116,  -116,    95,   108,
    -116,  -116,  -116,  -116,    42,    11,  -116,   134,   116,  -116,
     117,  -116,   119,     1,    11,  -116,   121,   110,   136,   108,
      95,  -116,   -16,  -116,   112,  -116,   133,    95,   105,  -116,
    -116,  -116,    13,   135,  -116,     0,     3,  -116,  -116,   159,
    -116,  -116,     8,  -116,   105,  -116,   154,   147,   148,   149,
    -116,  -116,     0,  -116,  -116,  -116,  -116
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       2,     0,     1,    21,    22,    20,     7,     5,     6,    10,
       3,     4,    11,     0,    12,     0,     8,    16,     0,    13,
       0,     0,     2,     0,    81,    84,    17,     0,    89,    18,
      14,     0,     0,    82,     0,    86,    85,     0,     0,     0,
      90,    93,    23,     9,    92,    95,    19,    83,    98,     0,
      96,     0,    91,    94,    74,   100,     0,    87,    88,    33,
      34,     0,     0,     0,    37,    26,    25,    15,    24,    31,
      30,     0,    32,   102,     0,   101,    97,     0,    27,    28,
      29,     0,    70,    69,     0,    71,    72,    73,    84,     0,
      75,     0,    99,     0,     0,     0,     0,     0,    50,    52,
      40,     0,    38,    39,    77,    76,     0,    78,   103,    35,
      76,    78,    46,    47,    48,    51,    49,    53,    55,     0,
     112,   107,   106,   108,     0,   105,    43,     0,     0,    23,
       0,    41,    54,     0,   111,   104,     0,     0,     0,     0,
      55,    80,    79,    67,    74,    68,     0,     0,    78,   109,
     110,   113,     0,     0,    36,     0,     0,    56,   114,    58,
      62,    66,     0,    42,    78,    59,    60,     0,     0,     0,
      57,    61,     0,    64,    65,    63,    44
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -116,   160,  -116,  -116,  -116,  -116,  -116,  -116,  -116,  -116,
    -116,    54,  -116,  -116,  -116,  -116,  -116,  -116,  -116,    93,
      45,  -116,  -116,  -116,    14,  -116,  -116,  -116,    94,  -109,
    -116,   -22,   -20,  -116,   131,  -116,  -116,  -116,    61,  -115
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_uint8 yydefgoto[] =
{
       0,     1,    10,    13,    18,    15,    11,    42,    21,    26,
      12,    54,    68,    77,   129,    69,   118,   146,   140,    89,
     131,   132,   166,   172,   163,    70,    90,    71,   107,   128,
      27,    28,    48,    49,    50,    74,    75,    72,   124,   125
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      29,    32,   130,    39,   134,    39,    37,    39,    38,    39,
      16,    39,    84,   104,    46,    17,   167,   168,   138,   136,
     138,   105,   160,    35,   152,   148,    14,   164,    19,   137,
     116,    36,   161,   117,    55,    73,   169,   162,    33,   157,
      40,    41,    40,    41,    40,    41,    40,    41,    40,    41,
     139,    91,   139,   158,    20,   170,     3,     2,     4,    95,
       3,   102,     4,    33,     5,     6,    24,   104,     5,     6,
     114,   103,   115,   108,   135,   110,     7,   136,   -45,    22,
       7,    34,     8,    25,    43,     9,     8,   137,   -45,     9,
      37,   100,    38,   101,    44,    45,    59,    60,   133,    56,
      30,    23,    24,    52,    53,    57,    47,    51,    58,    61,
      62,    63,    78,    79,    80,    64,    59,    60,    65,    25,
     133,    66,    92,    67,    93,    94,   109,   156,   112,    61,
      62,    63,   120,   -45,   113,    64,    81,    24,    65,   126,
      82,    66,   127,   154,    83,    84,    85,   119,   143,   145,
      86,    87,   119,   147,    88,   150,   141,   149,   120,   121,
     151,   122,   123,   120,   121,   165,   122,   123,    37,   155,
      38,   159,    44,    45,    96,    97,    98,    99,   171,   173,
     174,   175,    31,   144,   106,   153,   176,    76,   142,   111
};

static const yytype_uint8 yycheck[] =
{
      20,    23,   111,     6,   119,     6,    39,     6,    41,     6,
      24,     6,    15,    16,    34,    24,     8,     9,     7,    35,
       7,    24,    22,    16,   139,    24,     7,    24,     7,    45,
      37,    24,    32,    40,    35,    55,    28,    37,     7,   148,
      43,    44,    43,    44,    43,    44,    43,    44,    43,    44,
      39,    71,    39,    40,    33,   164,     3,     0,     5,    81,
       3,    22,     5,     7,    11,    12,     7,    16,    11,    12,
      37,    32,    39,    93,    32,    24,    23,    35,    22,    30,
      23,    34,    29,    24,    31,    32,    29,    45,    32,    32,
      39,    35,    41,    37,    43,    44,     4,     5,   118,    34,
      30,     6,     7,    43,    44,    40,     7,    25,    42,    17,
      18,    19,    33,    33,    33,    23,     4,     5,    26,    24,
     140,    29,    36,    31,    34,    24,    30,   147,    37,    17,
      18,    19,    24,    35,    37,    23,     6,     7,    26,    35,
      10,    29,    37,    31,    14,    15,    16,    13,    32,    32,
      20,    21,    13,    34,    24,    45,    22,    36,    24,    25,
      24,    27,    28,    24,    25,     6,    27,    28,    39,    36,
      41,    36,    43,    44,    37,    38,    39,    40,    24,    32,
      32,    32,    22,   129,    91,   140,   172,    56,   127,    95
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    47,     0,     3,     5,    11,    12,    23,    29,    32,
      48,    52,    56,    49,     7,    51,    24,    24,    50,     7,
      33,    54,    30,     6,     7,    24,    55,    76,    77,    78,
      30,    47,    77,     7,    34,    16,    24,    39,    41,     6,
      43,    44,    53,    31,    43,    44,    78,     7,    78,    79,
      80,    25,    43,    44,    57,    35,    34,    40,    42,     4,
       5,    17,    18,    19,    23,    26,    29,    31,    58,    61,
      71,    73,    83,    78,    81,    82,    80,    59,    33,    33,
      33,     6,    10,    14,    15,    16,    20,    21,    24,    65,
      72,    78,    36,    34,    24,    77,    37,    38,    39,    40,
      35,    37,    22,    32,    16,    24,    65,    74,    78,    30,
      24,    74,    37,    37,    37,    39,    37,    40,    62,    13,
      24,    25,    27,    28,    84,    85,    35,    37,    75,    60,
      75,    66,    67,    78,    85,    32,    35,    45,     7,    39,
      64,    22,    84,    32,    57,    32,    63,    34,    24,    36,
      45,    24,    85,    66,    31,    36,    78,    75,    40,    36,
      22,    32,    37,    70,    24,     6,    68,     8,     9,    28,
      75,    24,    69,    32,    32,    32,    70
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    46,    47,    47,    48,    48,    48,    49,    50,    48,
      48,    51,    51,    51,    53,    52,    54,    54,    55,    55,
      56,    56,    56,    57,    57,    58,    58,    58,    58,    58,
      58,    58,    58,    58,    59,    60,    58,    58,    61,    61,
      62,    63,    61,    64,    61,    65,    65,    65,    65,    65,
      65,    65,    65,    65,    66,    66,    67,    67,    68,    68,
      69,    69,    70,    70,    70,    70,    70,    71,    71,    72,
      72,    72,    72,    72,    73,    73,    74,    74,    75,    75,
      75,    76,    76,    76,    77,    77,    77,    77,    77,    78,
      78,    78,    78,    78,    78,    78,    79,    79,    80,    80,
      81,    81,    82,    82,    83,    84,    84,    84,    84,    84,
      84,    84,    85,    85,    85
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     0,     2,     1,     1,     1,     0,     0,     7,
       1,     0,     1,     3,     0,     8,     0,     2,     1,     3,
       1,     1,     1,     0,     2,     1,     1,     2,     2,     2,
       1,     1,     1,     1,     0,     0,     7,     1,     3,     3,
       0,     0,     8,     0,    10,     1,     3,     3,     3,     3,
       2,     3,     2,     3,     1,     0,     3,     5,     0,     1,
       0,     1,     1,     3,     3,     3,     1,     5,     6,     1,
       1,     1,     1,     1,     0,     2,     1,     1,     0,     2,
       2,     1,     2,     3,     1,     2,     2,     4,     4,     1,
       2,     3,     3,     2,     3,     3,     1,     3,     1,     4,
       0,     1,     1,     3,     5,     1,     1,     1,     1,     3,
       3,     2,     1,     3,     4
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF

/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)                                \
    do                                                                  \
      if (N)                                                            \
        {                                                               \
          (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;        \
          (Current).first_column = YYRHSLOC (Rhs, 1).first_column;      \
          (Current).last_line    = YYRHSLOC (Rhs, N).last_line;         \
          (Current).last_column  = YYRHSLOC (Rhs, N).last_column;       \
        }                                                               \
      else                                                              \
        {                                                               \
          (Current).first_line   = (Current).last_line   =              \
            YYRHSLOC (Rhs, 0).last_line;                                \
          (Current).first_column = (Current).last_column =              \
            YYRHSLOC (Rhs, 0).last_column;                              \
        }                                                               \
    while (0)
#endif

#define YYRHSLOC(Rhs, K) ((Rhs)[K])


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)


/* YYLOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

# ifndef YYLOCATION_PRINT

#  if defined YY_LOCATION_PRINT

   /* Temporary convenience wrapper in case some people defined the
      undocumented and private YY_LOCATION_PRINT macros.  */
#   define YYLOCATION_PRINT(File, Loc)  YY_LOCATION_PRINT(File, *(Loc))

#  elif defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL

/* Print *YYLOCP on YYO.  Private, do not rely on its existence. */

YY_ATTRIBUTE_UNUSED
static int
yy_location_print_ (FILE *yyo, YYLTYPE const * const yylocp)
{
  int res = 0;
  int end_col = 0 != yylocp->last_column ? yylocp->last_column - 1 : 0;
  if (0 <= yylocp->first_line)
    {
      res += YYFPRINTF (yyo, "%d", yylocp->first_line);
      if (0 <= yylocp->first_column)
        res += YYFPRINTF (yyo, ".%d", yylocp->first_column);
    }
  if (0 <= yylocp->last_line)
    {
      if (yylocp->first_line < yylocp->last_line)
        {
          res += YYFPRINTF (yyo, "-%d", yylocp->last_line);
          if (0 <= end_col)
            res += YYFPRINTF (yyo, ".%d", end_col);
        }
      else if (0 <= end_col && yylocp->first_column < end_col)
        res += YYFPRINTF (yyo, "-%d", end_col);
    }
  return res;
}

#   define YYLOCATION_PRINT  yy_location_print_

    /* Temporary convenience wrapper in case some people defined the
       undocumented and private YY_LOCATION_PRINT macros.  */
#   define YY_LOCATION_PRINT(File, Loc)  YYLOCATION_PRINT(File, &(Loc))

#  else

#   define YYLOCATION_PRINT(File, Loc) ((void) 0)
    /* Temporary convenience wrapper in case some people defined the
       undocumented and private YY_LOCATION_PRINT macros.  */
#   define YY_LOCATION_PRINT  YYLOCATION_PRINT

#  endif
# endif /* !defined YYLOCATION_PRINT */


# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, Location); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (yylocationp);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  YYLOCATION_PRINT (yyo, yylocationp);
  YYFPRINTF (yyo, ": ");
  yy_symbol_value_print (yyo, yykind, yyvaluep, yylocationp);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp, YYLTYPE *yylsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)],
                       &(yylsp[(yyi + 1) - (yynrhs)]));
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, yylsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif


/* Context of a parse error.  */
typedef struct
{
  yy_state_t *yyssp;
  yysymbol_kind_t yytoken;
  YYLTYPE *yylloc;
} yypcontext_t;

/* Put in YYARG at most YYARGN of the expected tokens given the
   current YYCTX, and return the number of tokens stored in YYARG.  If
   YYARG is null, return the number of expected tokens (guaranteed to
   be less than YYNTOKENS).  Return YYENOMEM on memory exhaustion.
   Return 0 if there are more than YYARGN expected tokens, yet fill
   YYARG up to YYARGN. */
static int
yypcontext_expected_tokens (const yypcontext_t *yyctx,
                            yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  int yyn = yypact[+*yyctx->yyssp];
  if (!yypact_value_is_default (yyn))
    {
      /* Start YYX at -YYN if negative to avoid negative indexes in
         YYCHECK.  In other words, skip the first -YYN actions for
         this state because they are default actions.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;
      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yyx;
      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
        if (yycheck[yyx + yyn] == yyx && yyx != YYSYMBOL_YYerror
            && !yytable_value_is_error (yytable[yyx + yyn]))
          {
            if (!yyarg)
              ++yycount;
            else if (yycount == yyargn)
              return 0;
            else
              yyarg[yycount++] = YY_CAST (yysymbol_kind_t, yyx);
          }
    }
  if (yyarg && yycount == 0 && 0 < yyargn)
    yyarg[0] = YYSYMBOL_YYEMPTY;
  return yycount;
}




#ifndef yystrlen
# if defined __GLIBC__ && defined _STRING_H
#  define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
# else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
# endif
#endif

#ifndef yystpcpy
# if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#  define yystpcpy stpcpy
# else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
# endif
#endif

#ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYPTRDIFF_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYPTRDIFF_T yyn = 0;
      char const *yyp = yystr;
      for (;;)
        switch (*++yyp)
          {
          case '\'':
          case ',':
            goto do_not_strip_quotes;

          case '\\':
            if (*++yyp != '\\')
              goto do_not_strip_quotes;
            else
              goto append;

          append:
          default:
            if (yyres)
              yyres[yyn] = *yyp;
            yyn++;
            break;

          case '"':
            if (yyres)
              yyres[yyn] = '\0';
            return yyn;
          }
    do_not_strip_quotes: ;
    }

  if (yyres)
    return yystpcpy (yyres, yystr) - yyres;
  else
    return yystrlen (yystr);
}
#endif


static int
yy_syntax_error_arguments (const yypcontext_t *yyctx,
                           yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yyctx->yytoken != YYSYMBOL_YYEMPTY)
    {
      int yyn;
      if (yyarg)
        yyarg[yycount] = yyctx->yytoken;
      ++yycount;
      yyn = yypcontext_expected_tokens (yyctx,
                                        yyarg ? yyarg + 1 : yyarg, yyargn - 1);
      if (yyn == YYENOMEM)
        return YYENOMEM;
      else
        yycount += yyn;
    }
  return yycount;
}

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return -1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return YYENOMEM if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                const yypcontext_t *yyctx)
{
  enum { YYARGS_MAX = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  yysymbol_kind_t yyarg[YYARGS_MAX];
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* Actual size of YYARG. */
  int yycount = yy_syntax_error_arguments (yyctx, yyarg, YYARGS_MAX);
  if (yycount == YYENOMEM)
    return YYENOMEM;

  switch (yycount)
    {
#define YYCASE_(N, S)                       \
      case N:                               \
        yyformat = S;                       \
        break
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
#undef YYCASE_
    }

  /* Compute error message size.  Don't count the "%s"s, but reserve
     room for the terminator.  */
  yysize = yystrlen (yyformat) - 2 * yycount + 1;
  {
    int yyi;
    for (yyi = 0; yyi < yycount; ++yyi)
      {
        YYPTRDIFF_T yysize1
          = yysize + yytnamerr (YY_NULLPTR, yytname[yyarg[yyi]]);
        if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
          yysize = yysize1;
        else
          return YYENOMEM;
      }
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return -1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr (yyp, yytname[yyarg[yyi++]]);
          yyformat += 2;
        }
      else
        {
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, YYLTYPE *yylocationp)
{
  YY_USE (yyvaluep);
  YY_USE (yylocationp);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Location data for the lookahead symbol.  */
YYLTYPE yylloc
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
  = { 1, 1, 1, 1 }
# endif
;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

    /* The location stack: array, bottom, top.  */
    YYLTYPE yylsa[YYINITDEPTH];
    YYLTYPE *yyls = yylsa;
    YYLTYPE *yylsp = yyls;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;
  YYLTYPE yyloc;

  /* The locations where the error started and ended.  */
  YYLTYPE yyerror_range[3];

  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N), yylsp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  yylsp[0] = yylloc;
  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;
        YYLTYPE *yyls1 = yyls;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yyls1, yysize * YYSIZEOF (*yylsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
        yyls = yyls1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
        YYSTACK_RELOCATE (yyls_alloc, yyls);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;
      yylsp = yyls + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      yyerror_range[1] = yylloc;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END
  *++yylsp = yylloc;

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];

  /* Default location. */
  YYLLOC_DEFAULT (yyloc, (yylsp - yylen), yylen);
  yyerror_range[1] = yyloc;
  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 4: /* element: irclass  */
#line 155 "ir-generator.ypp"
              {
        if (currCommentBlock) {
            (yyvsp[0].irClass)->comments.push_back(currCommentBlock);
            currCommentBlock = nullptr;
        }
        global.push_back((yyvsp[0].irClass)); }
#line 1749 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 5: /* element: COMMENTBLOCK  */
#line 161 "ir-generator.ypp"
                    {
        if (!currCommentBlock) {
            currCommentBlock = new CommentBlock((yylsp[0]), (yyvsp[0].str));
        } else {
            currCommentBlock->append((yyvsp[0].str));
            currCommentBlock->srcInfo += (yylsp[0]); }}
#line 1760 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 6: /* element: EMITBLOCK  */
#line 167 "ir-generator.ypp"
                {
        pushCurrentComment();
        global.push_back(new EmitBlock((yylsp[0]), (yyvsp[0].emit).impl, (yyvsp[0].emit).block)); }
#line 1768 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 7: /* $@1: %empty  */
#line 170 "ir-generator.ypp"
                { BEGIN(PARSE_BRACKET); }
#line 1774 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 8: /* $@2: %empty  */
#line 171 "ir-generator.ypp"
                 { current_namespace = IrNamespace::get(current_namespace, (yyvsp[0].str)); }
#line 1780 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 9: /* element: NAMESPACE $@1 IDENTIFIER $@2 '{' input '}'  */
#line 172 "ir-generator.ypp"
                    {
        current_namespace = current_namespace->parent;
        pushCurrentComment();
        }
#line 1789 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 10: /* element: ';'  */
#line 176 "ir-generator.ypp"
                       { pushCurrentComment(); }
#line 1795 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 11: /* scope: %empty  */
#line 180 "ir-generator.ypp"
                        { (yyval.irNamespace) = current_namespace; }
#line 1801 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 12: /* scope: DBLCOL  */
#line 181 "ir-generator.ypp"
                        { (yyval.irNamespace) = nullptr; }
#line 1807 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 13: /* scope: scope IDENTIFIER DBLCOL  */
#line 182 "ir-generator.ypp"
                                { (yyval.irNamespace) = IrNamespace::get((yyvsp[-2].irNamespace), (yyvsp[-1].str)); }
#line 1813 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 14: /* @3: %empty  */
#line 187 "ir-generator.ypp"
      { (yyval.irClass) = new IrClass((yylsp[-2]), (yyvsp[-3].irNamespace), (yyvsp[-4].kind), (yyvsp[-2].str), (yyvsp[-1].types)); }
#line 1819 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 15: /* irclass: kind scope IDENTIFIER parentList '{' @3 partList '}'  */
#line 189 "ir-generator.ypp"
      { (yyval.irClass) = (yyvsp[-2].irClass); }
#line 1825 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 16: /* parentList: %empty  */
#line 193 "ir-generator.ypp"
                                { (yyval.types) = nullptr; }
#line 1831 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 17: /* parentList: ':' nonEmptyParentList  */
#line 194 "ir-generator.ypp"
                                { (yyval.types) = (yyvsp[0].types); }
#line 1837 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 18: /* nonEmptyParentList: type  */
#line 198 "ir-generator.ypp"
                        { ((yyval.types) = new std::vector<const Type *>())->push_back((yyvsp[0].type)); }
#line 1843 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 19: /* nonEmptyParentList: nonEmptyParentList ',' type  */
#line 199 "ir-generator.ypp"
                                        { ((yyval.types) = (yyvsp[-2].types))->push_back((yyvsp[0].type)); }
#line 1849 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 20: /* kind: INTERFACE  */
#line 203 "ir-generator.ypp"
                        { (yyval.kind) = NodeKind::Interface; BEGIN(PARSE_BRACKET); }
#line 1855 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 21: /* kind: ABSTRACT  */
#line 204 "ir-generator.ypp"
                        { (yyval.kind) = NodeKind::Abstract; BEGIN(PARSE_BRACKET); }
#line 1861 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 22: /* kind: CLASS  */
#line 205 "ir-generator.ypp"
                        { (yyval.kind) = NodeKind::Concrete; BEGIN(PARSE_BRACKET); }
#line 1867 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 23: /* partList: %empty  */
#line 209 "ir-generator.ypp"
                          { (yyval.irClass) = (yyvsp[0].irClass); }
#line 1873 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 24: /* partList: partList part  */
#line 210 "ir-generator.ypp"
                          { (yyval.irClass) = (yyvsp[-1].irClass);
                            if ((yyvsp[0].irElement)) {
                                (yyvsp[0].irElement)->access = (yyval.irClass)->current_access;
                                (yyvsp[0].irElement)->clss = (yyval.irClass);
                                (yyval.irClass)->elements.push_back((yyvsp[0].irElement)); } }
#line 1883 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 25: /* part: EMITBLOCK  */
#line 218 "ir-generator.ypp"
                      { (yyval.irElement) = new EmitBlock((yylsp[0]), (yyvsp[0].emit).impl, (yyvsp[0].emit).block); }
#line 1889 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 26: /* part: NO  */
#line 219 "ir-generator.ypp"
                      { (yyval.irElement) = new IrNo((yylsp[0]), (yyvsp[0].str)); }
#line 1895 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 27: /* part: PRIVATE ':'  */
#line 220 "ir-generator.ypp"
                      { (yyval.irElement) = nullptr; (yyvsp[-2].irClass)->current_access = IrElement::Private; }
#line 1901 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 28: /* part: PROTECTED ':'  */
#line 221 "ir-generator.ypp"
                      { (yyval.irElement) = nullptr; (yyvsp[-2].irClass)->current_access = IrElement::Protected; }
#line 1907 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 29: /* part: PUBLIC ':'  */
#line 222 "ir-generator.ypp"
                      { (yyval.irElement) = nullptr; (yyvsp[-2].irClass)->current_access = IrElement::Public; }
#line 1913 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 30: /* part: irField  */
#line 223 "ir-generator.ypp"
                      { (yyval.irElement) = (yyvsp[0].irField); }
#line 1919 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 31: /* part: method  */
#line 224 "ir-generator.ypp"
                      { (yyval.irElement) = (yyvsp[0].irMethod); }
#line 1925 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 32: /* part: constFieldInit  */
#line 225 "ir-generator.ypp"
                      { (yyval.irElement) = (yyvsp[0].constFieldInit); }
#line 1931 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 33: /* part: APPLY  */
#line 226 "ir-generator.ypp"
                      { (yyval.irElement) = new IrApply((yylsp[0])); }
#line 1937 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 34: /* $@4: %empty  */
#line 227 "ir-generator.ypp"
                      { BEGIN(PARSE_BRACKET); }
#line 1943 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 35: /* @5: %empty  */
#line 228 "ir-generator.ypp"
                      { (yyval.irClass) = new IrClass((yylsp[-2]), &(yyvsp[-4].irClass)->local, NodeKind::Nested, (yyvsp[-1].str)); }
#line 1949 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 36: /* part: CLASS $@4 IDENTIFIER '{' @5 partList '}'  */
#line 229 "ir-generator.ypp"
                      { (yyval.irElement) = (yyvsp[-2].irClass); }
#line 1955 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 37: /* part: COMMENTBLOCK  */
#line 230 "ir-generator.ypp"
                      { (yyval.irElement) = new CommentBlock((yylsp[0]), (yyvsp[0].str)); }
#line 1961 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 38: /* method: modifiers methodName BLOCK  */
#line 235 "ir-generator.ypp"
          { (yyval.irMethod) = new IrMethod((yylsp[-1]), canon_name((yyvsp[-1].str)), (yyvsp[0].str)); }
#line 1967 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 39: /* method: modifiers methodName ';'  */
#line 237 "ir-generator.ypp"
          { (yyval.irMethod) = new IrMethod((yylsp[-1]), canon_name((yyvsp[-1].str))); }
#line 1973 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 40: /* @6: %empty  */
#line 239 "ir-generator.ypp"
          { if ((yyvsp[-1].str) != (yyvsp[-3].irClass)->name)
                yyerror("constructor name %s doesn't match class name %s", (yyvsp[-1].str), (yyvsp[-3].irClass)->name);
            if ((yyvsp[-2].i) & ~IrField::Inline)
                yyerror("%s invalid on constructor", IrElement::modifier((yyvsp[-2].i)));
            ((yyval.irMethod) = new IrMethod((yylsp[-1]), (yyvsp[-1].str)))->inImpl = !((yyvsp[-2].i) & IrField::Inline);
            (yyval.irMethod)->clss = (yyvsp[-3].irClass); }
#line 1984 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 41: /* $@7: %empty  */
#line 245 "ir-generator.ypp"
                 { BEGIN(PARSE_CTOR_INIT); }
#line 1990 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 42: /* method: modifiers IDENTIFIER '(' @6 optArgList $@7 ')' body  */
#line 246 "ir-generator.ypp"
          { ((yyval.irMethod) = (yyvsp[-4].irMethod))->body = (yyvsp[0].str);
            (yyval.irMethod)->isUser = true;
            BEGIN(NORMAL); }
#line 1998 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 43: /* @8: %empty  */
#line 250 "ir-generator.ypp"
          { ((yyval.irMethod) = new IrMethod((yylsp[-1]), (yyvsp[-1].str)))->rtype = (yyvsp[-2].type);
            (yyval.irMethod)->inImpl = !((yyvsp[-3].i) & IrField::Inline);
            (yyval.irMethod)->isStatic = ((yyvsp[-3].i) & IrField::Static);
            (yyval.irMethod)->isVirtual = ((yyvsp[-3].i) & IrField::Virtual);
            (yyval.irMethod)->clss = (yyvsp[-4].irClass);
            if ((yyvsp[-3].i) & !(IrField::Inline | IrField::Virtual))
                yyerror("%s invalid on method", IrElement::modifier((yyvsp[-3].i))); }
#line 2010 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 44: /* method: modifiers type methodName '(' @8 optArgList ')' optConst optOverride body  */
#line 258 "ir-generator.ypp"
          { ((yyval.irMethod) = (yyvsp[-5].irMethod))->body = (yyvsp[0].str);
            if (!(yyvsp[0].str) || (yyvsp[0].str)[0] == '=') {
                if (!(yyval.irMethod)->inImpl)
                    yyerror("inline method %s with no body", (yyvsp[-7].str));
                (yyval.irMethod)->inImpl = false; }
            (yyval.irMethod)->isUser = true;
            (yyval.irMethod)->isConst = (yyvsp[-2].i);
            (yyval.irMethod)->isOverride = (yyvsp[-1].i); }
#line 2023 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 46: /* methodName: OPERATOR '=' '='  */
#line 270 "ir-generator.ypp"
                                { (yyval.str) = "operator=="; }
#line 2029 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 47: /* methodName: OPERATOR '!' '='  */
#line 271 "ir-generator.ypp"
                                { (yyval.str) = "operator!="; }
#line 2035 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 48: /* methodName: OPERATOR '<' '='  */
#line 272 "ir-generator.ypp"
                                { (yyval.str) = "operator<="; }
#line 2041 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 49: /* methodName: OPERATOR '>' '='  */
#line 273 "ir-generator.ypp"
                                { (yyval.str) = "operator>="; }
#line 2047 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 50: /* methodName: OPERATOR '<'  */
#line 274 "ir-generator.ypp"
                                { (yyval.str) = "operator<"; }
#line 2053 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 51: /* methodName: OPERATOR '<' '<'  */
#line 275 "ir-generator.ypp"
                                { (yyval.str) = "operator<<"; }
#line 2059 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 52: /* methodName: OPERATOR '>'  */
#line 276 "ir-generator.ypp"
                                { (yyval.str) = "operator>"; }
#line 2065 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 53: /* methodName: OPERATOR '>' '>'  */
#line 277 "ir-generator.ypp"
                                { (yyval.str) = "operator>>"; }
#line 2071 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 56: /* argList: type IDENTIFIER optInitializer  */
#line 284 "ir-generator.ypp"
            { auto *field = new IrField((yylsp[-1]), (yyvsp[-2].type), (yyvsp[-1].str), (yyvsp[0].str));
              field->clss = (yyvsp[-3].irMethod)->clss;
              (yyvsp[-3].irMethod)->args.push_back(field); }
#line 2079 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 57: /* argList: argList ',' type IDENTIFIER optInitializer  */
#line 288 "ir-generator.ypp"
            { auto *field = new IrField((yylsp[-1]), (yyvsp[-2].type), (yyvsp[-1].str), (yyvsp[0].str));
              field->clss = (yyvsp[-5].irMethod)->clss;
              (yyvsp[-5].irMethod)->args.push_back(field); }
#line 2087 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 58: /* optConst: %empty  */
#line 293 "ir-generator.ypp"
           { (yyval.i) = false; }
#line 2093 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 59: /* optConst: CONST  */
#line 293 "ir-generator.ypp"
                                   { (yyval.i) = true; }
#line 2099 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 60: /* optOverride: %empty  */
#line 296 "ir-generator.ypp"
      { (yyval.i) = false; }
#line 2105 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 61: /* optOverride: IDENTIFIER  */
#line 297 "ir-generator.ypp"
                      { if (!((yyval.i) = (yyvsp[0].str) == "override"))
                            yyerror("syntax error, expecting override or method body"); }
#line 2112 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 63: /* body: '=' ZERO ';'  */
#line 301 "ir-generator.ypp"
                      { (yyval.str) = "= 0;"; }
#line 2118 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 64: /* body: '=' DEFAULT ';'  */
#line 302 "ir-generator.ypp"
                      { (yyval.str) = "= default;"; }
#line 2124 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 65: /* body: '=' DELETE ';'  */
#line 303 "ir-generator.ypp"
                      { (yyval.str) = "= delete;"; }
#line 2130 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 66: /* body: ';'  */
#line 304 "ir-generator.ypp"
                      { (yyval.str) = nullptr; }
#line 2136 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 67: /* irField: modifiers type fieldName optInitializer ';'  */
#line 309 "ir-generator.ypp"
          { (yyval.irField) = new IrField((yylsp[-2]), (yyvsp[-3].type), (yyvsp[-2].str), (yyvsp[-1].str), (yyvsp[-4].i));
            if ((yyvsp[-4].i) & IrElement::Virtual)
                yyerror("virtual invalid on field %s", (yyvsp[-2].str)); }
#line 2144 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 68: /* irField: modifiers CONST nonRefType fieldName optInitializer ';'  */
#line 313 "ir-generator.ypp"
          { (yyval.irField) = new IrField((yylsp[-2]), (yyvsp[-3].type), (yyvsp[-2].str), (yyvsp[-1].str), (yyvsp[-5].i) | IrElement::Const);
            if ((yyvsp[-5].i) & IrElement::Virtual)
                yyerror("virtual invalid on field %s", (yyvsp[-2].str)); }
#line 2152 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 69: /* modifier: NULLOK  */
#line 319 "ir-generator.ypp"
                { (yyval.i) = IrElement::NullOK; }
#line 2158 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 70: /* modifier: INLINE  */
#line 320 "ir-generator.ypp"
                { (yyval.i) = IrElement::Inline; }
#line 2164 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 71: /* modifier: OPTIONAL  */
#line 321 "ir-generator.ypp"
                { (yyval.i) = IrElement::Optional; }
#line 2170 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 72: /* modifier: STATIC  */
#line 322 "ir-generator.ypp"
                { (yyval.i) = IrElement::Static; }
#line 2176 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 73: /* modifier: VIRTUAL  */
#line 323 "ir-generator.ypp"
                { (yyval.i) = IrElement::Virtual; }
#line 2182 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 74: /* modifiers: %empty  */
#line 326 "ir-generator.ypp"
            { (yyval.i) = 0; }
#line 2188 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 75: /* modifiers: modifiers modifier  */
#line 326 "ir-generator.ypp"
                                             { (yyval.i) = (yyvsp[-1].i) | (yyvsp[0].i); }
#line 2194 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 77: /* fieldName: OPTIONAL  */
#line 328 "ir-generator.ypp"
                                 { (yyval.str) = "optional"; }
#line 2200 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 78: /* optInitializer: %empty  */
#line 331 "ir-generator.ypp"
                        { (yyval.str) = nullptr; }
#line 2206 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 79: /* optInitializer: '=' expression  */
#line 332 "ir-generator.ypp"
                        { (yyval.str) = (yyvsp[0].str); }
#line 2212 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 80: /* optInitializer: '=' BLOCK  */
#line 333 "ir-generator.ypp"
                        { (yyval.str) = (yyvsp[0].str); }
#line 2218 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 81: /* lookup_scope: DBLCOL  */
#line 337 "ir-generator.ypp"
                                        { (yyval.lookup) = new LookupScope(); }
#line 2224 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 82: /* lookup_scope: IDENTIFIER DBLCOL  */
#line 338 "ir-generator.ypp"
                                        { (yyval.lookup) = new LookupScope(0, (yyvsp[-1].str)); }
#line 2230 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 83: /* lookup_scope: lookup_scope IDENTIFIER DBLCOL  */
#line 339 "ir-generator.ypp"
                                        { (yyval.lookup) = new LookupScope((yyvsp[-2].lookup), (yyvsp[-1].str)); }
#line 2236 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 84: /* nonRefType: IDENTIFIER  */
#line 342 "ir-generator.ypp"
                                        { (yyval.type) = new NamedType((yylsp[0]), 0, (yyvsp[0].str)); }
#line 2242 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 85: /* nonRefType: lookup_scope IDENTIFIER  */
#line 343 "ir-generator.ypp"
                                        { (yyval.type) = new NamedType((yylsp[0]), (yyvsp[-1].lookup), (yyvsp[0].str)); }
#line 2248 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 86: /* nonRefType: lookup_scope OPTIONAL  */
#line 344 "ir-generator.ypp"
                                        { (yyval.type) = new NamedType((yylsp[0]), (yyvsp[-1].lookup), "optional"); }
#line 2254 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 87: /* nonRefType: nonRefType '<' type_args '>'  */
#line 345 "ir-generator.ypp"
                                        { (yyval.type) = new TemplateInstantiation((yylsp[-3])+(yylsp[0]), (yyvsp[-3].type), *(yyvsp[-1].types)); }
#line 2260 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 88: /* nonRefType: nonRefType '[' INTEGER ']'  */
#line 346 "ir-generator.ypp"
                                        { (yyval.type) = new ArrayType((yylsp[-3])+(yylsp[0]), (yyvsp[-3].type), atoi((yyvsp[-1].str))); }
#line 2266 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 90: /* type: type '&'  */
#line 350 "ir-generator.ypp"
                                        { (yyval.type) = new ReferenceType((yyvsp[-1].type)); }
#line 2272 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 91: /* type: type CONST '&'  */
#line 351 "ir-generator.ypp"
                                        { (yyval.type) = new ReferenceType((yyvsp[-2].type), true); }
#line 2278 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 92: /* type: CONST nonRefType '&'  */
#line 352 "ir-generator.ypp"
                                        { (yyval.type) = new ReferenceType((yyvsp[-1].type), true); }
#line 2284 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 93: /* type: type '*'  */
#line 353 "ir-generator.ypp"
                                        { (yyval.type) = new PointerType((yyvsp[-1].type)); }
#line 2290 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 94: /* type: type CONST '*'  */
#line 354 "ir-generator.ypp"
                                        { (yyval.type) = new PointerType((yyvsp[-2].type), true); }
#line 2296 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 95: /* type: CONST nonRefType '*'  */
#line 355 "ir-generator.ypp"
                                        { (yyval.type) = new PointerType((yyvsp[-1].type), true); }
#line 2302 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 96: /* type_args: type_arg  */
#line 359 "ir-generator.ypp"
                                        { (yyval.types) = new std::vector<const Type *>{(yyvsp[0].type)}; }
#line 2308 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 97: /* type_args: type_args ',' type_arg  */
#line 360 "ir-generator.ypp"
                                        { ((yyval.types) = (yyvsp[-2].types))->push_back((yyvsp[0].type)); }
#line 2314 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 98: /* type_arg: type  */
#line 364 "ir-generator.ypp"
                                        { (yyval.type) = (yyvsp[0].type); }
#line 2320 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 99: /* type_arg: type '(' optTypeList ')'  */
#line 365 "ir-generator.ypp"
                                        { (yyval.type) = new FunctionType((yyvsp[-3].type), *(yyvsp[-1].types)); }
#line 2326 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 100: /* optTypeList: %empty  */
#line 369 "ir-generator.ypp"
                                        { (yyval.types) = new std::vector<const Type *>(); }
#line 2332 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 101: /* optTypeList: typeList  */
#line 370 "ir-generator.ypp"
                                        { (yyval.types) = (yyvsp[0].types); }
#line 2338 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 102: /* typeList: type  */
#line 374 "ir-generator.ypp"
                                        { (yyval.types) = new std::vector<const Type *>{(yyvsp[0].type)}; }
#line 2344 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 103: /* typeList: typeList ',' type  */
#line 375 "ir-generator.ypp"
                                        { ((yyval.types) = (yyvsp[-2].types))->push_back((yyvsp[0].type)); }
#line 2350 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 104: /* constFieldInit: modifiers IDENTIFIER '=' expression ';'  */
#line 379 "ir-generator.ypp"
          { (yyval.constFieldInit) = new ConstFieldInitializer((yylsp[-3]), (yyvsp[-3].str), (yyvsp[-1].str));
            if ((yyvsp[-4].i)) yyerror("%s invalid on constant", IrElement::modifier((yyvsp[-4].i))); }
#line 2357 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 109: /* expression: expression '(' ')'  */
#line 385 "ir-generator.ypp"
                                        { (yyval.str) = (yyvsp[-2].str) + "()"; }
#line 2363 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 110: /* expression: expression '+' '+'  */
#line 386 "ir-generator.ypp"
                                        { (yyval.str) = (yyvsp[-2].str) + "++"; }
#line 2369 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 111: /* expression: NEW name  */
#line 387 "ir-generator.ypp"
                                        { (yyval.str) = "new " + (yyvsp[0].str); }
#line 2375 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 113: /* name: name DBLCOL IDENTIFIER  */
#line 391 "ir-generator.ypp"
                                { (yyval.str) = (yyvsp[-2].str) + "::" + (yyvsp[0].str); }
#line 2381 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;

  case 114: /* name: name '<' name '>'  */
#line 392 "ir-generator.ypp"
                                { (yyval.str) = (yyvsp[-3].str) + "<" + (yyvsp[-1].str) + ">"; }
#line 2387 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"
    break;


#line 2391 "/mnt/e/p4-verify/P4B-Translator/build-host/tools/ir-generator/ir-generator.cpp"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;
  *++yylsp = yyloc;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      {
        yypcontext_t yyctx
          = {yyssp, yytoken, &yylloc};
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == -1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = YY_CAST (char *,
                             YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
            if (yymsg)
              {
                yysyntax_error_status
                  = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
                yymsgp = yymsg;
              }
            else
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = YYENOMEM;
              }
          }
        yyerror (yymsgp);
        if (yysyntax_error_status == YYENOMEM)
          YYNOMEM;
      }
    }

  yyerror_range[1] = yylloc;
  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, &yylloc);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;

      yyerror_range[1] = *yylsp;
      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, yylsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  yyerror_range[2] = yylloc;
  ++yylsp;
  YYLLOC_DEFAULT (*yylsp, yyerror_range, 2);

  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, &yylloc);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, yylsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
  return yyresult;
}

#line 397 "ir-generator.ypp"

}  // end anonymous namespace

void yyerror(const char *fmt, ...) {
    auto& context = BaseCompileContext::get();
    if (!strcmp(fmt, "syntax error, unexpected IDENTIFIER")) {
        context.errorReporter().parser_error(sources,
                                             "syntax error, unexpected IDENTIFIER \"%s\"",
                                             yylval.str.c_str());
        return;
    }
    va_list args;
    va_start(args, fmt);
    context.errorReporter().parser_error(sources, fmt, args);
    va_end(args);
}

IrDefinitions *parse(char** files, int count) {
    int errors = 0;
    class IrgenCompileContext : public BaseCompileContext { } ctxt;
    AutoCompileContext ctxt_ctl(&ctxt);
#ifdef YYDEBUG
    if (const char *p = getenv("YYDEBUG"))
        yydebug = atoi(p);
#endif
    if (count <= 0) {
        ::error(ErrorType::ERR_EXPECTED, "No input files specified");
        errors = 1; }

    for (int i = 0; i < count; i++) {
        if (FILE *fp = fopen(files[i], "r")) {
            sources->mapLine(files[i], 1);
            yyrestart(fp);
            BEGIN(NORMAL);
            errors |= yyparse();
            fclose(fp);
            if (errors & 2) {
                error(ErrorType::ERR_OVERLIMIT, "out of memory");
                break; }
        } else {
            ::error(ErrorType::ERR_IO, "Cannot open file %s", files[i]);
            perror("");
            errors |= 1; } }

    return errors ? nullptr : new IrDefinitions(global);
}
