// A Bison parser, made by GNU Bison 3.8.2.

// Skeleton implementation for Bison LALR(1) parsers in C++

// Copyright (C) 2002-2015, 2018-2021 Free Software Foundation, Inc.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// As a special exception, you may create a larger work that contains
// part or all of the Bison parser skeleton and distribute that work
// under terms of your choice, so long as that work isn't itself a
// parser generator using the skeleton or a modified version thereof
// as a parser skeleton.  Alternatively, if you modify or redistribute
// the parser skeleton itself, you may (at your option) remove this
// special exception, which will cause the skeleton and the resulting
// Bison output files to be licensed under the GNU General Public
// License without this special exception.

// This special exception was added by the Free Software Foundation in
// version 2.2 of Bison.

// DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
// especially those whose name start with YY_ or yy_.  They are
// private implementation details that can be changed or removed.



// First part of user prologue.
#line 117 "parsers/p4/p4parser.ypp"
 /* -*-C++-*- */
#include "frontends/parsers/parserDriver.h"
#include "frontends/parsers/p4/p4lexer.hpp"
#include "frontends/parsers/p4/p4parser.hpp"

#define YYLLOC_DEFAULT(Cur, Rhs, N)                                             \
    ((Cur) = (N) ? YYRHSLOC(Rhs, 1) + YYRHSLOC(Rhs, N)                          \
                 : Util::SourceInfo(driver.sources, YYRHSLOC(Rhs, 0).getEnd()))

#undef yylex
#define yylex lexer.yylex


#line 55 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"


#include "p4parser.hpp"




#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> // FIXME: INFRINGES ON USER NAME SPACE.
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif


// Whether we are compiled with exception support.
#ifndef YY_EXCEPTIONS
# if defined __GNUC__ && !defined __EXCEPTIONS
#  define YY_EXCEPTIONS 0
# else
#  define YY_EXCEPTIONS 1
# endif
#endif

#define YYRHSLOC(Rhs, K) ((Rhs)[K].location)
/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

# ifndef YYLLOC_DEFAULT
#  define YYLLOC_DEFAULT(Current, Rhs, N)                               \
    do                                                                  \
      if (N)                                                            \
        {                                                               \
          (Current).begin  = YYRHSLOC (Rhs, 1).begin;                   \
          (Current).end    = YYRHSLOC (Rhs, N).end;                     \
        }                                                               \
      else                                                              \
        {                                                               \
          (Current).begin = (Current).end = YYRHSLOC (Rhs, 0).end;      \
        }                                                               \
    while (false)
# endif


// Enable debugging if requested.
#if YYDEBUG

// A pseudo ostream that takes yydebug_ into account.
# define YYCDEBUG if (yydebug_) (*yycdebug_)

# define YY_SYMBOL_PRINT(Title, Symbol)         \
  do {                                          \
    if (yydebug_)                               \
    {                                           \
      *yycdebug_ << Title << ' ';               \
      yy_print_ (*yycdebug_, Symbol);           \
      *yycdebug_ << '\n';                       \
    }                                           \
  } while (false)

# define YY_REDUCE_PRINT(Rule)          \
  do {                                  \
    if (yydebug_)                       \
      yy_reduce_print_ (Rule);          \
  } while (false)

# define YY_STACK_PRINT()               \
  do {                                  \
    if (yydebug_)                       \
      yy_stack_print_ ();                \
  } while (false)

#else // !YYDEBUG

# define YYCDEBUG if (false) std::cerr
# define YY_SYMBOL_PRINT(Title, Symbol)  YY_USE (Symbol)
# define YY_REDUCE_PRINT(Rule)           static_cast<void> (0)
# define YY_STACK_PRINT()                static_cast<void> (0)

#endif // !YYDEBUG

#define yyerrok         (yyerrstatus_ = 0)
#define yyclearin       (yyla.clear ())

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYRECOVERING()  (!!yyerrstatus_)

#line 23 "parsers/p4/p4parser.ypp"
namespace P4 {
#line 153 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"

  /// Build a parser object.
  P4Parser::P4Parser (P4::P4ParserDriver& driver_yyarg, P4::AbstractP4Lexer& lexer_yyarg)
#if YYDEBUG
    : yydebug_ (false),
      yycdebug_ (&std::cerr),
#else
    :
#endif
      driver (driver_yyarg),
      lexer (lexer_yyarg)
  {}

  P4Parser::~P4Parser ()
  {}

  P4Parser::syntax_error::~syntax_error () YY_NOEXCEPT YY_NOTHROW
  {}

  /*---------.
  | symbol.  |
  `---------*/



  // by_state.
  P4Parser::by_state::by_state () YY_NOEXCEPT
    : state (empty_state)
  {}

  P4Parser::by_state::by_state (const by_state& that) YY_NOEXCEPT
    : state (that.state)
  {}

  void
  P4Parser::by_state::clear () YY_NOEXCEPT
  {
    state = empty_state;
  }

  void
  P4Parser::by_state::move (by_state& that)
  {
    state = that.state;
    that.clear ();
  }

  P4Parser::by_state::by_state (state_type s) YY_NOEXCEPT
    : state (s)
  {}

  P4Parser::symbol_kind_type
  P4Parser::by_state::kind () const YY_NOEXCEPT
  {
    if (state == empty_state)
      return symbol_kind::S_YYEMPTY;
    else
      return YY_CAST (symbol_kind_type, yystos_[+state]);
  }

  P4Parser::stack_symbol_type::stack_symbol_type ()
  {}

  P4Parser::stack_symbol_type::stack_symbol_type (YY_RVREF (stack_symbol_type) that)
    : super_type (YY_MOVE (that.state), YY_MOVE (that.location))
  {
    switch (that.kind ())
    {
      case symbol_kind::S_typeRef: // typeRef
      case symbol_kind::S_namedType: // namedType
      case symbol_kind::S_tupleType: // tupleType
      case symbol_kind::S_headerStackType: // headerStackType
      case symbol_kind::S_specializedType: // specializedType
      case symbol_kind::S_baseType: // baseType
      case symbol_kind::S_typeOrVoid: // typeOrVoid
      case symbol_kind::S_typeArg: // typeArg
      case symbol_kind::S_realTypeArg: // realTypeArg
        value.YY_MOVE_OR_COPY< ConstType* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_annotation: // annotation
        value.YY_MOVE_OR_COPY< IR::Annotation* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_optAnnotations: // optAnnotations
        value.YY_MOVE_OR_COPY< IR::Annotations* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_argument: // argument
        value.YY_MOVE_OR_COPY< IR::Argument* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_objInitializer: // objInitializer
      case symbol_kind::S_parserBlockStatement: // parserBlockStatement
      case symbol_kind::S_controlBody: // controlBody
      case symbol_kind::S_blockStatement: // blockStatement
        value.YY_MOVE_OR_COPY< IR::BlockStatement* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_instantiation: // instantiation
      case symbol_kind::S_objDeclaration: // objDeclaration
      case symbol_kind::S_parserLocalElement: // parserLocalElement
      case symbol_kind::S_valueSetDeclaration: // valueSetDeclaration
      case symbol_kind::S_controlLocalDeclaration: // controlLocalDeclaration
      case symbol_kind::S_tableDeclaration: // tableDeclaration
      case symbol_kind::S_actionDeclaration: // actionDeclaration
      case symbol_kind::S_variableDeclaration: // variableDeclaration
      case symbol_kind::S_constantDeclaration: // constantDeclaration
      case symbol_kind::S_functionDeclaration: // functionDeclaration
        value.YY_MOVE_OR_COPY< IR::Declaration* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_direction: // direction
        value.YY_MOVE_OR_COPY< IR::Direction > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_entry: // entry
        value.YY_MOVE_OR_COPY< IR::Entry* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_p4rtControllerType: // p4rtControllerType
      case symbol_kind::S_transitionStatement: // transitionStatement
      case symbol_kind::S_stateExpression: // stateExpression
      case symbol_kind::S_selectExpression: // selectExpression
      case symbol_kind::S_keysetExpression: // keysetExpression
      case symbol_kind::S_reducedSimpleKeysetExpression: // reducedSimpleKeysetExpression
      case symbol_kind::S_simpleKeysetExpression: // simpleKeysetExpression
      case symbol_kind::S_switchLabel: // switchLabel
      case symbol_kind::S_actionRef: // actionRef
      case symbol_kind::S_optInitializer: // optInitializer
      case symbol_kind::S_initializer: // initializer
      case symbol_kind::S_lvalue: // lvalue
      case symbol_kind::S_expression: // expression
      case symbol_kind::S_nonBraceExpression: // nonBraceExpression
      case symbol_kind::S_intOrStr: // intOrStr
        value.YY_MOVE_OR_COPY< IR::Expression* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_nonTypeName: // nonTypeName
      case symbol_kind::S_name: // name
      case symbol_kind::S_nonTableKwName: // nonTableKwName
      case symbol_kind::S_dot_name: // dot_name
        value.YY_MOVE_OR_COPY< IR::ID* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_actionList: // actionList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::ActionListElement>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserLocalElements: // parserLocalElements
      case symbol_kind::S_controlLocalDeclarations: // controlLocalDeclarations
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::Declaration>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_identifierList: // identifierList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::Declaration_ID>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_kvList: // kvList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::NamedExpression>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parameterList: // parameterList
      case symbol_kind::S_nonEmptyParameterList: // nonEmptyParameterList
      case symbol_kind::S_optConstructorParameters: // optConstructorParameters
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::Parameter>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserStates: // parserStates
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::ParserState>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_tablePropertyList: // tablePropertyList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::Property>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_specifiedIdentifierList: // specifiedIdentifierList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::SerEnumMember>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_objDeclarations: // objDeclarations
      case symbol_kind::S_parserStatements: // parserStatements
      case symbol_kind::S_statOrDeclList: // statOrDeclList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::StatOrDecl>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_structFieldList: // structFieldList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::StructField>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_typeParameterList: // typeParameterList
        value.YY_MOVE_OR_COPY< IR::IndexedVector<IR::Type_Var>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_keyElement: // keyElement
        value.YY_MOVE_OR_COPY< IR::KeyElement* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_functionPrototype: // functionPrototype
      case symbol_kind::S_methodPrototype: // methodPrototype
        value.YY_MOVE_OR_COPY< IR::Method* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_kvPair: // kvPair
        value.YY_MOVE_OR_COPY< IR::NamedExpression* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_fragment: // fragment
      case symbol_kind::S_declaration: // declaration
      case symbol_kind::S_externDeclaration: // externDeclaration
      case symbol_kind::S_matchKindDeclaration: // matchKindDeclaration
        value.YY_MOVE_OR_COPY< IR::Node* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parameter: // parameter
        value.YY_MOVE_OR_COPY< IR::Parameter* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserState: // parserState
        value.YY_MOVE_OR_COPY< IR::ParserState* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_prefixedType: // prefixedType
      case symbol_kind::S_prefixedNonTypeName: // prefixedNonTypeName
        value.YY_MOVE_OR_COPY< IR::Path* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_tableProperty: // tableProperty
        value.YY_MOVE_OR_COPY< IR::Property* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_selectCase: // selectCase
        value.YY_MOVE_OR_COPY< IR::SelectCase* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_specifiedIdentifier: // specifiedIdentifier
        value.YY_MOVE_OR_COPY< IR::SerEnumMember* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserStatement: // parserStatement
      case symbol_kind::S_statementOrDeclaration: // statementOrDeclaration
        value.YY_MOVE_OR_COPY< IR::StatOrDecl* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_assignmentOrMethodCallStatement: // assignmentOrMethodCallStatement
      case symbol_kind::S_emptyStatement: // emptyStatement
      case symbol_kind::S_exitStatement: // exitStatement
      case symbol_kind::S_returnStatement: // returnStatement
      case symbol_kind::S_conditionalStatement: // conditionalStatement
      case symbol_kind::S_directApplication: // directApplication
      case symbol_kind::S_statement: // statement
      case symbol_kind::S_switchStatement: // switchStatement
        value.YY_MOVE_OR_COPY< IR::Statement* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_structField: // structField
        value.YY_MOVE_OR_COPY< IR::StructField* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_switchCase: // switchCase
        value.YY_MOVE_OR_COPY< IR::SwitchCase* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_optTypeParameters: // optTypeParameters
      case symbol_kind::S_typeParameters: // typeParameters
        value.YY_MOVE_OR_COPY< IR::TypeParameters* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_controlTypeDeclaration: // controlTypeDeclaration
        value.YY_MOVE_OR_COPY< IR::Type_Control* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_packageTypeDeclaration: // packageTypeDeclaration
      case symbol_kind::S_parserDeclaration: // parserDeclaration
      case symbol_kind::S_controlDeclaration: // controlDeclaration
      case symbol_kind::S_typeDeclaration: // typeDeclaration
      case symbol_kind::S_derivedTypeDeclaration: // derivedTypeDeclaration
      case symbol_kind::S_headerTypeDeclaration: // headerTypeDeclaration
      case symbol_kind::S_structTypeDeclaration: // structTypeDeclaration
      case symbol_kind::S_headerUnionDeclaration: // headerUnionDeclaration
      case symbol_kind::S_enumDeclaration: // enumDeclaration
      case symbol_kind::S_typedefDeclaration: // typedefDeclaration
        value.YY_MOVE_OR_COPY< IR::Type_Declaration* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_errorDeclaration: // errorDeclaration
        value.YY_MOVE_OR_COPY< IR::Type_Error* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_typeName: // typeName
        value.YY_MOVE_OR_COPY< IR::Type_Name* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserTypeDeclaration: // parserTypeDeclaration
        value.YY_MOVE_OR_COPY< IR::Type_Parser* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_annotations: // annotations
        value.YY_MOVE_OR_COPY< IR::Vector<IR::Annotation>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_annotationBody: // annotationBody
        value.YY_MOVE_OR_COPY< IR::Vector<IR::AnnotationToken>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_argumentList: // argumentList
      case symbol_kind::S_nonEmptyArgList: // nonEmptyArgList
        value.YY_MOVE_OR_COPY< IR::Vector<IR::Argument>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_entriesList: // entriesList
        value.YY_MOVE_OR_COPY< IR::Vector<IR::Entry>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_tupleKeysetExpression: // tupleKeysetExpression
      case symbol_kind::S_simpleExpressionList: // simpleExpressionList
      case symbol_kind::S_expressionList: // expressionList
      case symbol_kind::S_intList: // intList
      case symbol_kind::S_intOrStrList: // intOrStrList
      case symbol_kind::S_strList: // strList
        value.YY_MOVE_OR_COPY< IR::Vector<IR::Expression>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_keyElementList: // keyElementList
        value.YY_MOVE_OR_COPY< IR::Vector<IR::KeyElement>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_methodPrototypes: // methodPrototypes
        value.YY_MOVE_OR_COPY< IR::Vector<IR::Method>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_selectCaseList: // selectCaseList
        value.YY_MOVE_OR_COPY< IR::Vector<IR::SelectCase>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_switchCases: // switchCases
        value.YY_MOVE_OR_COPY< IR::Vector<IR::SwitchCase>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_typeArgumentList: // typeArgumentList
      case symbol_kind::S_realTypeArgumentList: // realTypeArgumentList
        value.YY_MOVE_OR_COPY< IR::Vector<IR::Type>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_optCONST: // optCONST
        value.YY_MOVE_OR_COPY< OptionalConst > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_UNEXPECTED_TOKEN: // UNEXPECTED_TOKEN
      case symbol_kind::S_END_PRAGMA: // END_PRAGMA
      case symbol_kind::S_LE: // "<="
      case symbol_kind::S_GE: // ">="
      case symbol_kind::S_SHL: // "<<"
      case symbol_kind::S_AND: // "&&"
      case symbol_kind::S_OR: // "||"
      case symbol_kind::S_NE: // "!="
      case symbol_kind::S_EQ: // "=="
      case symbol_kind::S_PLUS: // "+"
      case symbol_kind::S_MINUS: // "-"
      case symbol_kind::S_PLUS_SAT: // "|+|"
      case symbol_kind::S_MINUS_SAT: // "|-|"
      case symbol_kind::S_MUL: // "*"
      case symbol_kind::S_DIV: // "/"
      case symbol_kind::S_MOD: // "%"
      case symbol_kind::S_BIT_OR: // "|"
      case symbol_kind::S_BIT_AND: // "&"
      case symbol_kind::S_BIT_XOR: // "^"
      case symbol_kind::S_COMPLEMENT: // "~"
      case symbol_kind::S_L_BRACKET: // "["
      case symbol_kind::S_R_BRACKET: // "]"
      case symbol_kind::S_L_BRACE: // "{"
      case symbol_kind::S_R_BRACE: // "}"
      case symbol_kind::S_L_ANGLE: // "<"
      case symbol_kind::S_L_ANGLE_ARGS: // L_ANGLE_ARGS
      case symbol_kind::S_R_ANGLE: // ">"
      case symbol_kind::S_R_ANGLE_SHIFT: // R_ANGLE_SHIFT
      case symbol_kind::S_L_PAREN: // "("
      case symbol_kind::S_R_PAREN: // ")"
      case symbol_kind::S_NOT: // "!"
      case symbol_kind::S_COLON: // ":"
      case symbol_kind::S_COMMA: // ","
      case symbol_kind::S_QUESTION: // "?"
      case symbol_kind::S_DOT: // "."
      case symbol_kind::S_ASSIGN: // "="
      case symbol_kind::S_SEMICOLON: // ";"
      case symbol_kind::S_AT: // "@"
      case symbol_kind::S_PP: // "++"
      case symbol_kind::S_DONTCARE: // "_"
      case symbol_kind::S_MASK: // "&&&"
      case symbol_kind::S_RANGE: // ".."
      case symbol_kind::S_TRUE: // TRUE
      case symbol_kind::S_FALSE: // FALSE
      case symbol_kind::S_THIS: // THIS
      case symbol_kind::S_ABSTRACT: // ABSTRACT
      case symbol_kind::S_ACTION: // ACTION
      case symbol_kind::S_ACTIONS: // ACTIONS
      case symbol_kind::S_APPLY: // APPLY
      case symbol_kind::S_BOOL: // BOOL
      case symbol_kind::S_BIT: // BIT
      case symbol_kind::S_CONST: // CONST
      case symbol_kind::S_CONTROL: // CONTROL
      case symbol_kind::S_DEFAULT: // DEFAULT
      case symbol_kind::S_ELSE: // ELSE
      case symbol_kind::S_ENTRIES: // ENTRIES
      case symbol_kind::S_ENUM: // ENUM
      case symbol_kind::S_ERROR: // ERROR
      case symbol_kind::S_EXIT: // EXIT
      case symbol_kind::S_EXTERN: // EXTERN
      case symbol_kind::S_HEADER: // HEADER
      case symbol_kind::S_HEADER_UNION: // HEADER_UNION
      case symbol_kind::S_IF: // IF
      case symbol_kind::S_IN: // IN
      case symbol_kind::S_INOUT: // INOUT
      case symbol_kind::S_INT: // INT
      case symbol_kind::S_KEY: // KEY
      case symbol_kind::S_SELECT: // SELECT
      case symbol_kind::S_MATCH_KIND: // MATCH_KIND
      case symbol_kind::S_TYPE: // TYPE
      case symbol_kind::S_OUT: // OUT
      case symbol_kind::S_PACKAGE: // PACKAGE
      case symbol_kind::S_PARSER: // PARSER
      case symbol_kind::S_PRAGMA: // PRAGMA
      case symbol_kind::S_RETURN: // RETURN
      case symbol_kind::S_STATE: // STATE
      case symbol_kind::S_STRING: // STRING
      case symbol_kind::S_STRUCT: // STRUCT
      case symbol_kind::S_SWITCH: // SWITCH
      case symbol_kind::S_TABLE: // TABLE
      case symbol_kind::S_TRANSITION: // TRANSITION
      case symbol_kind::S_TUPLE: // TUPLE
      case symbol_kind::S_TYPEDEF: // TYPEDEF
      case symbol_kind::S_VARBIT: // VARBIT
      case symbol_kind::S_VALUESET: // VALUESET
      case symbol_kind::S_VOID: // VOID
      case symbol_kind::S_annotationToken: // annotationToken
        value.YY_MOVE_OR_COPY< Token > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_INTEGER: // INTEGER
        value.YY_MOVE_OR_COPY< UnparsedConstant > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_IDENTIFIER: // IDENTIFIER
      case symbol_kind::S_TYPE_IDENTIFIER: // TYPE_IDENTIFIER
      case symbol_kind::S_STRING_LITERAL: // STRING_LITERAL
        value.YY_MOVE_OR_COPY< cstring > (YY_MOVE (that.value));
        break;

      default:
        break;
    }

#if 201103L <= YY_CPLUSPLUS
    // that is emptied.
    that.state = empty_state;
#endif
  }

  P4Parser::stack_symbol_type::stack_symbol_type (state_type s, YY_MOVE_REF (symbol_type) that)
    : super_type (s, YY_MOVE (that.location))
  {
    switch (that.kind ())
    {
      case symbol_kind::S_typeRef: // typeRef
      case symbol_kind::S_namedType: // namedType
      case symbol_kind::S_tupleType: // tupleType
      case symbol_kind::S_headerStackType: // headerStackType
      case symbol_kind::S_specializedType: // specializedType
      case symbol_kind::S_baseType: // baseType
      case symbol_kind::S_typeOrVoid: // typeOrVoid
      case symbol_kind::S_typeArg: // typeArg
      case symbol_kind::S_realTypeArg: // realTypeArg
        value.move< ConstType* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_annotation: // annotation
        value.move< IR::Annotation* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_optAnnotations: // optAnnotations
        value.move< IR::Annotations* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_argument: // argument
        value.move< IR::Argument* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_objInitializer: // objInitializer
      case symbol_kind::S_parserBlockStatement: // parserBlockStatement
      case symbol_kind::S_controlBody: // controlBody
      case symbol_kind::S_blockStatement: // blockStatement
        value.move< IR::BlockStatement* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_instantiation: // instantiation
      case symbol_kind::S_objDeclaration: // objDeclaration
      case symbol_kind::S_parserLocalElement: // parserLocalElement
      case symbol_kind::S_valueSetDeclaration: // valueSetDeclaration
      case symbol_kind::S_controlLocalDeclaration: // controlLocalDeclaration
      case symbol_kind::S_tableDeclaration: // tableDeclaration
      case symbol_kind::S_actionDeclaration: // actionDeclaration
      case symbol_kind::S_variableDeclaration: // variableDeclaration
      case symbol_kind::S_constantDeclaration: // constantDeclaration
      case symbol_kind::S_functionDeclaration: // functionDeclaration
        value.move< IR::Declaration* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_direction: // direction
        value.move< IR::Direction > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_entry: // entry
        value.move< IR::Entry* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_p4rtControllerType: // p4rtControllerType
      case symbol_kind::S_transitionStatement: // transitionStatement
      case symbol_kind::S_stateExpression: // stateExpression
      case symbol_kind::S_selectExpression: // selectExpression
      case symbol_kind::S_keysetExpression: // keysetExpression
      case symbol_kind::S_reducedSimpleKeysetExpression: // reducedSimpleKeysetExpression
      case symbol_kind::S_simpleKeysetExpression: // simpleKeysetExpression
      case symbol_kind::S_switchLabel: // switchLabel
      case symbol_kind::S_actionRef: // actionRef
      case symbol_kind::S_optInitializer: // optInitializer
      case symbol_kind::S_initializer: // initializer
      case symbol_kind::S_lvalue: // lvalue
      case symbol_kind::S_expression: // expression
      case symbol_kind::S_nonBraceExpression: // nonBraceExpression
      case symbol_kind::S_intOrStr: // intOrStr
        value.move< IR::Expression* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_nonTypeName: // nonTypeName
      case symbol_kind::S_name: // name
      case symbol_kind::S_nonTableKwName: // nonTableKwName
      case symbol_kind::S_dot_name: // dot_name
        value.move< IR::ID* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_actionList: // actionList
        value.move< IR::IndexedVector<IR::ActionListElement>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserLocalElements: // parserLocalElements
      case symbol_kind::S_controlLocalDeclarations: // controlLocalDeclarations
        value.move< IR::IndexedVector<IR::Declaration>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_identifierList: // identifierList
        value.move< IR::IndexedVector<IR::Declaration_ID>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_kvList: // kvList
        value.move< IR::IndexedVector<IR::NamedExpression>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parameterList: // parameterList
      case symbol_kind::S_nonEmptyParameterList: // nonEmptyParameterList
      case symbol_kind::S_optConstructorParameters: // optConstructorParameters
        value.move< IR::IndexedVector<IR::Parameter>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserStates: // parserStates
        value.move< IR::IndexedVector<IR::ParserState>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_tablePropertyList: // tablePropertyList
        value.move< IR::IndexedVector<IR::Property>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_specifiedIdentifierList: // specifiedIdentifierList
        value.move< IR::IndexedVector<IR::SerEnumMember>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_objDeclarations: // objDeclarations
      case symbol_kind::S_parserStatements: // parserStatements
      case symbol_kind::S_statOrDeclList: // statOrDeclList
        value.move< IR::IndexedVector<IR::StatOrDecl>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_structFieldList: // structFieldList
        value.move< IR::IndexedVector<IR::StructField>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_typeParameterList: // typeParameterList
        value.move< IR::IndexedVector<IR::Type_Var>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_keyElement: // keyElement
        value.move< IR::KeyElement* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_functionPrototype: // functionPrototype
      case symbol_kind::S_methodPrototype: // methodPrototype
        value.move< IR::Method* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_kvPair: // kvPair
        value.move< IR::NamedExpression* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_fragment: // fragment
      case symbol_kind::S_declaration: // declaration
      case symbol_kind::S_externDeclaration: // externDeclaration
      case symbol_kind::S_matchKindDeclaration: // matchKindDeclaration
        value.move< IR::Node* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parameter: // parameter
        value.move< IR::Parameter* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserState: // parserState
        value.move< IR::ParserState* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_prefixedType: // prefixedType
      case symbol_kind::S_prefixedNonTypeName: // prefixedNonTypeName
        value.move< IR::Path* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_tableProperty: // tableProperty
        value.move< IR::Property* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_selectCase: // selectCase
        value.move< IR::SelectCase* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_specifiedIdentifier: // specifiedIdentifier
        value.move< IR::SerEnumMember* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserStatement: // parserStatement
      case symbol_kind::S_statementOrDeclaration: // statementOrDeclaration
        value.move< IR::StatOrDecl* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_assignmentOrMethodCallStatement: // assignmentOrMethodCallStatement
      case symbol_kind::S_emptyStatement: // emptyStatement
      case symbol_kind::S_exitStatement: // exitStatement
      case symbol_kind::S_returnStatement: // returnStatement
      case symbol_kind::S_conditionalStatement: // conditionalStatement
      case symbol_kind::S_directApplication: // directApplication
      case symbol_kind::S_statement: // statement
      case symbol_kind::S_switchStatement: // switchStatement
        value.move< IR::Statement* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_structField: // structField
        value.move< IR::StructField* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_switchCase: // switchCase
        value.move< IR::SwitchCase* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_optTypeParameters: // optTypeParameters
      case symbol_kind::S_typeParameters: // typeParameters
        value.move< IR::TypeParameters* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_controlTypeDeclaration: // controlTypeDeclaration
        value.move< IR::Type_Control* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_packageTypeDeclaration: // packageTypeDeclaration
      case symbol_kind::S_parserDeclaration: // parserDeclaration
      case symbol_kind::S_controlDeclaration: // controlDeclaration
      case symbol_kind::S_typeDeclaration: // typeDeclaration
      case symbol_kind::S_derivedTypeDeclaration: // derivedTypeDeclaration
      case symbol_kind::S_headerTypeDeclaration: // headerTypeDeclaration
      case symbol_kind::S_structTypeDeclaration: // structTypeDeclaration
      case symbol_kind::S_headerUnionDeclaration: // headerUnionDeclaration
      case symbol_kind::S_enumDeclaration: // enumDeclaration
      case symbol_kind::S_typedefDeclaration: // typedefDeclaration
        value.move< IR::Type_Declaration* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_errorDeclaration: // errorDeclaration
        value.move< IR::Type_Error* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_typeName: // typeName
        value.move< IR::Type_Name* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_parserTypeDeclaration: // parserTypeDeclaration
        value.move< IR::Type_Parser* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_annotations: // annotations
        value.move< IR::Vector<IR::Annotation>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_annotationBody: // annotationBody
        value.move< IR::Vector<IR::AnnotationToken>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_argumentList: // argumentList
      case symbol_kind::S_nonEmptyArgList: // nonEmptyArgList
        value.move< IR::Vector<IR::Argument>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_entriesList: // entriesList
        value.move< IR::Vector<IR::Entry>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_tupleKeysetExpression: // tupleKeysetExpression
      case symbol_kind::S_simpleExpressionList: // simpleExpressionList
      case symbol_kind::S_expressionList: // expressionList
      case symbol_kind::S_intList: // intList
      case symbol_kind::S_intOrStrList: // intOrStrList
      case symbol_kind::S_strList: // strList
        value.move< IR::Vector<IR::Expression>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_keyElementList: // keyElementList
        value.move< IR::Vector<IR::KeyElement>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_methodPrototypes: // methodPrototypes
        value.move< IR::Vector<IR::Method>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_selectCaseList: // selectCaseList
        value.move< IR::Vector<IR::SelectCase>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_switchCases: // switchCases
        value.move< IR::Vector<IR::SwitchCase>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_typeArgumentList: // typeArgumentList
      case symbol_kind::S_realTypeArgumentList: // realTypeArgumentList
        value.move< IR::Vector<IR::Type>* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_optCONST: // optCONST
        value.move< OptionalConst > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_UNEXPECTED_TOKEN: // UNEXPECTED_TOKEN
      case symbol_kind::S_END_PRAGMA: // END_PRAGMA
      case symbol_kind::S_LE: // "<="
      case symbol_kind::S_GE: // ">="
      case symbol_kind::S_SHL: // "<<"
      case symbol_kind::S_AND: // "&&"
      case symbol_kind::S_OR: // "||"
      case symbol_kind::S_NE: // "!="
      case symbol_kind::S_EQ: // "=="
      case symbol_kind::S_PLUS: // "+"
      case symbol_kind::S_MINUS: // "-"
      case symbol_kind::S_PLUS_SAT: // "|+|"
      case symbol_kind::S_MINUS_SAT: // "|-|"
      case symbol_kind::S_MUL: // "*"
      case symbol_kind::S_DIV: // "/"
      case symbol_kind::S_MOD: // "%"
      case symbol_kind::S_BIT_OR: // "|"
      case symbol_kind::S_BIT_AND: // "&"
      case symbol_kind::S_BIT_XOR: // "^"
      case symbol_kind::S_COMPLEMENT: // "~"
      case symbol_kind::S_L_BRACKET: // "["
      case symbol_kind::S_R_BRACKET: // "]"
      case symbol_kind::S_L_BRACE: // "{"
      case symbol_kind::S_R_BRACE: // "}"
      case symbol_kind::S_L_ANGLE: // "<"
      case symbol_kind::S_L_ANGLE_ARGS: // L_ANGLE_ARGS
      case symbol_kind::S_R_ANGLE: // ">"
      case symbol_kind::S_R_ANGLE_SHIFT: // R_ANGLE_SHIFT
      case symbol_kind::S_L_PAREN: // "("
      case symbol_kind::S_R_PAREN: // ")"
      case symbol_kind::S_NOT: // "!"
      case symbol_kind::S_COLON: // ":"
      case symbol_kind::S_COMMA: // ","
      case symbol_kind::S_QUESTION: // "?"
      case symbol_kind::S_DOT: // "."
      case symbol_kind::S_ASSIGN: // "="
      case symbol_kind::S_SEMICOLON: // ";"
      case symbol_kind::S_AT: // "@"
      case symbol_kind::S_PP: // "++"
      case symbol_kind::S_DONTCARE: // "_"
      case symbol_kind::S_MASK: // "&&&"
      case symbol_kind::S_RANGE: // ".."
      case symbol_kind::S_TRUE: // TRUE
      case symbol_kind::S_FALSE: // FALSE
      case symbol_kind::S_THIS: // THIS
      case symbol_kind::S_ABSTRACT: // ABSTRACT
      case symbol_kind::S_ACTION: // ACTION
      case symbol_kind::S_ACTIONS: // ACTIONS
      case symbol_kind::S_APPLY: // APPLY
      case symbol_kind::S_BOOL: // BOOL
      case symbol_kind::S_BIT: // BIT
      case symbol_kind::S_CONST: // CONST
      case symbol_kind::S_CONTROL: // CONTROL
      case symbol_kind::S_DEFAULT: // DEFAULT
      case symbol_kind::S_ELSE: // ELSE
      case symbol_kind::S_ENTRIES: // ENTRIES
      case symbol_kind::S_ENUM: // ENUM
      case symbol_kind::S_ERROR: // ERROR
      case symbol_kind::S_EXIT: // EXIT
      case symbol_kind::S_EXTERN: // EXTERN
      case symbol_kind::S_HEADER: // HEADER
      case symbol_kind::S_HEADER_UNION: // HEADER_UNION
      case symbol_kind::S_IF: // IF
      case symbol_kind::S_IN: // IN
      case symbol_kind::S_INOUT: // INOUT
      case symbol_kind::S_INT: // INT
      case symbol_kind::S_KEY: // KEY
      case symbol_kind::S_SELECT: // SELECT
      case symbol_kind::S_MATCH_KIND: // MATCH_KIND
      case symbol_kind::S_TYPE: // TYPE
      case symbol_kind::S_OUT: // OUT
      case symbol_kind::S_PACKAGE: // PACKAGE
      case symbol_kind::S_PARSER: // PARSER
      case symbol_kind::S_PRAGMA: // PRAGMA
      case symbol_kind::S_RETURN: // RETURN
      case symbol_kind::S_STATE: // STATE
      case symbol_kind::S_STRING: // STRING
      case symbol_kind::S_STRUCT: // STRUCT
      case symbol_kind::S_SWITCH: // SWITCH
      case symbol_kind::S_TABLE: // TABLE
      case symbol_kind::S_TRANSITION: // TRANSITION
      case symbol_kind::S_TUPLE: // TUPLE
      case symbol_kind::S_TYPEDEF: // TYPEDEF
      case symbol_kind::S_VARBIT: // VARBIT
      case symbol_kind::S_VALUESET: // VALUESET
      case symbol_kind::S_VOID: // VOID
      case symbol_kind::S_annotationToken: // annotationToken
        value.move< Token > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_INTEGER: // INTEGER
        value.move< UnparsedConstant > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_IDENTIFIER: // IDENTIFIER
      case symbol_kind::S_TYPE_IDENTIFIER: // TYPE_IDENTIFIER
      case symbol_kind::S_STRING_LITERAL: // STRING_LITERAL
        value.move< cstring > (YY_MOVE (that.value));
        break;

      default:
        break;
    }

    // that is emptied.
    that.kind_ = symbol_kind::S_YYEMPTY;
  }

#if YY_CPLUSPLUS < 201103L
  P4Parser::stack_symbol_type&
  P4Parser::stack_symbol_type::operator= (const stack_symbol_type& that)
  {
    state = that.state;
    switch (that.kind ())
    {
      case symbol_kind::S_typeRef: // typeRef
      case symbol_kind::S_namedType: // namedType
      case symbol_kind::S_tupleType: // tupleType
      case symbol_kind::S_headerStackType: // headerStackType
      case symbol_kind::S_specializedType: // specializedType
      case symbol_kind::S_baseType: // baseType
      case symbol_kind::S_typeOrVoid: // typeOrVoid
      case symbol_kind::S_typeArg: // typeArg
      case symbol_kind::S_realTypeArg: // realTypeArg
        value.copy< ConstType* > (that.value);
        break;

      case symbol_kind::S_annotation: // annotation
        value.copy< IR::Annotation* > (that.value);
        break;

      case symbol_kind::S_optAnnotations: // optAnnotations
        value.copy< IR::Annotations* > (that.value);
        break;

      case symbol_kind::S_argument: // argument
        value.copy< IR::Argument* > (that.value);
        break;

      case symbol_kind::S_objInitializer: // objInitializer
      case symbol_kind::S_parserBlockStatement: // parserBlockStatement
      case symbol_kind::S_controlBody: // controlBody
      case symbol_kind::S_blockStatement: // blockStatement
        value.copy< IR::BlockStatement* > (that.value);
        break;

      case symbol_kind::S_instantiation: // instantiation
      case symbol_kind::S_objDeclaration: // objDeclaration
      case symbol_kind::S_parserLocalElement: // parserLocalElement
      case symbol_kind::S_valueSetDeclaration: // valueSetDeclaration
      case symbol_kind::S_controlLocalDeclaration: // controlLocalDeclaration
      case symbol_kind::S_tableDeclaration: // tableDeclaration
      case symbol_kind::S_actionDeclaration: // actionDeclaration
      case symbol_kind::S_variableDeclaration: // variableDeclaration
      case symbol_kind::S_constantDeclaration: // constantDeclaration
      case symbol_kind::S_functionDeclaration: // functionDeclaration
        value.copy< IR::Declaration* > (that.value);
        break;

      case symbol_kind::S_direction: // direction
        value.copy< IR::Direction > (that.value);
        break;

      case symbol_kind::S_entry: // entry
        value.copy< IR::Entry* > (that.value);
        break;

      case symbol_kind::S_p4rtControllerType: // p4rtControllerType
      case symbol_kind::S_transitionStatement: // transitionStatement
      case symbol_kind::S_stateExpression: // stateExpression
      case symbol_kind::S_selectExpression: // selectExpression
      case symbol_kind::S_keysetExpression: // keysetExpression
      case symbol_kind::S_reducedSimpleKeysetExpression: // reducedSimpleKeysetExpression
      case symbol_kind::S_simpleKeysetExpression: // simpleKeysetExpression
      case symbol_kind::S_switchLabel: // switchLabel
      case symbol_kind::S_actionRef: // actionRef
      case symbol_kind::S_optInitializer: // optInitializer
      case symbol_kind::S_initializer: // initializer
      case symbol_kind::S_lvalue: // lvalue
      case symbol_kind::S_expression: // expression
      case symbol_kind::S_nonBraceExpression: // nonBraceExpression
      case symbol_kind::S_intOrStr: // intOrStr
        value.copy< IR::Expression* > (that.value);
        break;

      case symbol_kind::S_nonTypeName: // nonTypeName
      case symbol_kind::S_name: // name
      case symbol_kind::S_nonTableKwName: // nonTableKwName
      case symbol_kind::S_dot_name: // dot_name
        value.copy< IR::ID* > (that.value);
        break;

      case symbol_kind::S_actionList: // actionList
        value.copy< IR::IndexedVector<IR::ActionListElement>* > (that.value);
        break;

      case symbol_kind::S_parserLocalElements: // parserLocalElements
      case symbol_kind::S_controlLocalDeclarations: // controlLocalDeclarations
        value.copy< IR::IndexedVector<IR::Declaration>* > (that.value);
        break;

      case symbol_kind::S_identifierList: // identifierList
        value.copy< IR::IndexedVector<IR::Declaration_ID>* > (that.value);
        break;

      case symbol_kind::S_kvList: // kvList
        value.copy< IR::IndexedVector<IR::NamedExpression>* > (that.value);
        break;

      case symbol_kind::S_parameterList: // parameterList
      case symbol_kind::S_nonEmptyParameterList: // nonEmptyParameterList
      case symbol_kind::S_optConstructorParameters: // optConstructorParameters
        value.copy< IR::IndexedVector<IR::Parameter>* > (that.value);
        break;

      case symbol_kind::S_parserStates: // parserStates
        value.copy< IR::IndexedVector<IR::ParserState>* > (that.value);
        break;

      case symbol_kind::S_tablePropertyList: // tablePropertyList
        value.copy< IR::IndexedVector<IR::Property>* > (that.value);
        break;

      case symbol_kind::S_specifiedIdentifierList: // specifiedIdentifierList
        value.copy< IR::IndexedVector<IR::SerEnumMember>* > (that.value);
        break;

      case symbol_kind::S_objDeclarations: // objDeclarations
      case symbol_kind::S_parserStatements: // parserStatements
      case symbol_kind::S_statOrDeclList: // statOrDeclList
        value.copy< IR::IndexedVector<IR::StatOrDecl>* > (that.value);
        break;

      case symbol_kind::S_structFieldList: // structFieldList
        value.copy< IR::IndexedVector<IR::StructField>* > (that.value);
        break;

      case symbol_kind::S_typeParameterList: // typeParameterList
        value.copy< IR::IndexedVector<IR::Type_Var>* > (that.value);
        break;

      case symbol_kind::S_keyElement: // keyElement
        value.copy< IR::KeyElement* > (that.value);
        break;

      case symbol_kind::S_functionPrototype: // functionPrototype
      case symbol_kind::S_methodPrototype: // methodPrototype
        value.copy< IR::Method* > (that.value);
        break;

      case symbol_kind::S_kvPair: // kvPair
        value.copy< IR::NamedExpression* > (that.value);
        break;

      case symbol_kind::S_fragment: // fragment
      case symbol_kind::S_declaration: // declaration
      case symbol_kind::S_externDeclaration: // externDeclaration
      case symbol_kind::S_matchKindDeclaration: // matchKindDeclaration
        value.copy< IR::Node* > (that.value);
        break;

      case symbol_kind::S_parameter: // parameter
        value.copy< IR::Parameter* > (that.value);
        break;

      case symbol_kind::S_parserState: // parserState
        value.copy< IR::ParserState* > (that.value);
        break;

      case symbol_kind::S_prefixedType: // prefixedType
      case symbol_kind::S_prefixedNonTypeName: // prefixedNonTypeName
        value.copy< IR::Path* > (that.value);
        break;

      case symbol_kind::S_tableProperty: // tableProperty
        value.copy< IR::Property* > (that.value);
        break;

      case symbol_kind::S_selectCase: // selectCase
        value.copy< IR::SelectCase* > (that.value);
        break;

      case symbol_kind::S_specifiedIdentifier: // specifiedIdentifier
        value.copy< IR::SerEnumMember* > (that.value);
        break;

      case symbol_kind::S_parserStatement: // parserStatement
      case symbol_kind::S_statementOrDeclaration: // statementOrDeclaration
        value.copy< IR::StatOrDecl* > (that.value);
        break;

      case symbol_kind::S_assignmentOrMethodCallStatement: // assignmentOrMethodCallStatement
      case symbol_kind::S_emptyStatement: // emptyStatement
      case symbol_kind::S_exitStatement: // exitStatement
      case symbol_kind::S_returnStatement: // returnStatement
      case symbol_kind::S_conditionalStatement: // conditionalStatement
      case symbol_kind::S_directApplication: // directApplication
      case symbol_kind::S_statement: // statement
      case symbol_kind::S_switchStatement: // switchStatement
        value.copy< IR::Statement* > (that.value);
        break;

      case symbol_kind::S_structField: // structField
        value.copy< IR::StructField* > (that.value);
        break;

      case symbol_kind::S_switchCase: // switchCase
        value.copy< IR::SwitchCase* > (that.value);
        break;

      case symbol_kind::S_optTypeParameters: // optTypeParameters
      case symbol_kind::S_typeParameters: // typeParameters
        value.copy< IR::TypeParameters* > (that.value);
        break;

      case symbol_kind::S_controlTypeDeclaration: // controlTypeDeclaration
        value.copy< IR::Type_Control* > (that.value);
        break;

      case symbol_kind::S_packageTypeDeclaration: // packageTypeDeclaration
      case symbol_kind::S_parserDeclaration: // parserDeclaration
      case symbol_kind::S_controlDeclaration: // controlDeclaration
      case symbol_kind::S_typeDeclaration: // typeDeclaration
      case symbol_kind::S_derivedTypeDeclaration: // derivedTypeDeclaration
      case symbol_kind::S_headerTypeDeclaration: // headerTypeDeclaration
      case symbol_kind::S_structTypeDeclaration: // structTypeDeclaration
      case symbol_kind::S_headerUnionDeclaration: // headerUnionDeclaration
      case symbol_kind::S_enumDeclaration: // enumDeclaration
      case symbol_kind::S_typedefDeclaration: // typedefDeclaration
        value.copy< IR::Type_Declaration* > (that.value);
        break;

      case symbol_kind::S_errorDeclaration: // errorDeclaration
        value.copy< IR::Type_Error* > (that.value);
        break;

      case symbol_kind::S_typeName: // typeName
        value.copy< IR::Type_Name* > (that.value);
        break;

      case symbol_kind::S_parserTypeDeclaration: // parserTypeDeclaration
        value.copy< IR::Type_Parser* > (that.value);
        break;

      case symbol_kind::S_annotations: // annotations
        value.copy< IR::Vector<IR::Annotation>* > (that.value);
        break;

      case symbol_kind::S_annotationBody: // annotationBody
        value.copy< IR::Vector<IR::AnnotationToken>* > (that.value);
        break;

      case symbol_kind::S_argumentList: // argumentList
      case symbol_kind::S_nonEmptyArgList: // nonEmptyArgList
        value.copy< IR::Vector<IR::Argument>* > (that.value);
        break;

      case symbol_kind::S_entriesList: // entriesList
        value.copy< IR::Vector<IR::Entry>* > (that.value);
        break;

      case symbol_kind::S_tupleKeysetExpression: // tupleKeysetExpression
      case symbol_kind::S_simpleExpressionList: // simpleExpressionList
      case symbol_kind::S_expressionList: // expressionList
      case symbol_kind::S_intList: // intList
      case symbol_kind::S_intOrStrList: // intOrStrList
      case symbol_kind::S_strList: // strList
        value.copy< IR::Vector<IR::Expression>* > (that.value);
        break;

      case symbol_kind::S_keyElementList: // keyElementList
        value.copy< IR::Vector<IR::KeyElement>* > (that.value);
        break;

      case symbol_kind::S_methodPrototypes: // methodPrototypes
        value.copy< IR::Vector<IR::Method>* > (that.value);
        break;

      case symbol_kind::S_selectCaseList: // selectCaseList
        value.copy< IR::Vector<IR::SelectCase>* > (that.value);
        break;

      case symbol_kind::S_switchCases: // switchCases
        value.copy< IR::Vector<IR::SwitchCase>* > (that.value);
        break;

      case symbol_kind::S_typeArgumentList: // typeArgumentList
      case symbol_kind::S_realTypeArgumentList: // realTypeArgumentList
        value.copy< IR::Vector<IR::Type>* > (that.value);
        break;

      case symbol_kind::S_optCONST: // optCONST
        value.copy< OptionalConst > (that.value);
        break;

      case symbol_kind::S_UNEXPECTED_TOKEN: // UNEXPECTED_TOKEN
      case symbol_kind::S_END_PRAGMA: // END_PRAGMA
      case symbol_kind::S_LE: // "<="
      case symbol_kind::S_GE: // ">="
      case symbol_kind::S_SHL: // "<<"
      case symbol_kind::S_AND: // "&&"
      case symbol_kind::S_OR: // "||"
      case symbol_kind::S_NE: // "!="
      case symbol_kind::S_EQ: // "=="
      case symbol_kind::S_PLUS: // "+"
      case symbol_kind::S_MINUS: // "-"
      case symbol_kind::S_PLUS_SAT: // "|+|"
      case symbol_kind::S_MINUS_SAT: // "|-|"
      case symbol_kind::S_MUL: // "*"
      case symbol_kind::S_DIV: // "/"
      case symbol_kind::S_MOD: // "%"
      case symbol_kind::S_BIT_OR: // "|"
      case symbol_kind::S_BIT_AND: // "&"
      case symbol_kind::S_BIT_XOR: // "^"
      case symbol_kind::S_COMPLEMENT: // "~"
      case symbol_kind::S_L_BRACKET: // "["
      case symbol_kind::S_R_BRACKET: // "]"
      case symbol_kind::S_L_BRACE: // "{"
      case symbol_kind::S_R_BRACE: // "}"
      case symbol_kind::S_L_ANGLE: // "<"
      case symbol_kind::S_L_ANGLE_ARGS: // L_ANGLE_ARGS
      case symbol_kind::S_R_ANGLE: // ">"
      case symbol_kind::S_R_ANGLE_SHIFT: // R_ANGLE_SHIFT
      case symbol_kind::S_L_PAREN: // "("
      case symbol_kind::S_R_PAREN: // ")"
      case symbol_kind::S_NOT: // "!"
      case symbol_kind::S_COLON: // ":"
      case symbol_kind::S_COMMA: // ","
      case symbol_kind::S_QUESTION: // "?"
      case symbol_kind::S_DOT: // "."
      case symbol_kind::S_ASSIGN: // "="
      case symbol_kind::S_SEMICOLON: // ";"
      case symbol_kind::S_AT: // "@"
      case symbol_kind::S_PP: // "++"
      case symbol_kind::S_DONTCARE: // "_"
      case symbol_kind::S_MASK: // "&&&"
      case symbol_kind::S_RANGE: // ".."
      case symbol_kind::S_TRUE: // TRUE
      case symbol_kind::S_FALSE: // FALSE
      case symbol_kind::S_THIS: // THIS
      case symbol_kind::S_ABSTRACT: // ABSTRACT
      case symbol_kind::S_ACTION: // ACTION
      case symbol_kind::S_ACTIONS: // ACTIONS
      case symbol_kind::S_APPLY: // APPLY
      case symbol_kind::S_BOOL: // BOOL
      case symbol_kind::S_BIT: // BIT
      case symbol_kind::S_CONST: // CONST
      case symbol_kind::S_CONTROL: // CONTROL
      case symbol_kind::S_DEFAULT: // DEFAULT
      case symbol_kind::S_ELSE: // ELSE
      case symbol_kind::S_ENTRIES: // ENTRIES
      case symbol_kind::S_ENUM: // ENUM
      case symbol_kind::S_ERROR: // ERROR
      case symbol_kind::S_EXIT: // EXIT
      case symbol_kind::S_EXTERN: // EXTERN
      case symbol_kind::S_HEADER: // HEADER
      case symbol_kind::S_HEADER_UNION: // HEADER_UNION
      case symbol_kind::S_IF: // IF
      case symbol_kind::S_IN: // IN
      case symbol_kind::S_INOUT: // INOUT
      case symbol_kind::S_INT: // INT
      case symbol_kind::S_KEY: // KEY
      case symbol_kind::S_SELECT: // SELECT
      case symbol_kind::S_MATCH_KIND: // MATCH_KIND
      case symbol_kind::S_TYPE: // TYPE
      case symbol_kind::S_OUT: // OUT
      case symbol_kind::S_PACKAGE: // PACKAGE
      case symbol_kind::S_PARSER: // PARSER
      case symbol_kind::S_PRAGMA: // PRAGMA
      case symbol_kind::S_RETURN: // RETURN
      case symbol_kind::S_STATE: // STATE
      case symbol_kind::S_STRING: // STRING
      case symbol_kind::S_STRUCT: // STRUCT
      case symbol_kind::S_SWITCH: // SWITCH
      case symbol_kind::S_TABLE: // TABLE
      case symbol_kind::S_TRANSITION: // TRANSITION
      case symbol_kind::S_TUPLE: // TUPLE
      case symbol_kind::S_TYPEDEF: // TYPEDEF
      case symbol_kind::S_VARBIT: // VARBIT
      case symbol_kind::S_VALUESET: // VALUESET
      case symbol_kind::S_VOID: // VOID
      case symbol_kind::S_annotationToken: // annotationToken
        value.copy< Token > (that.value);
        break;

      case symbol_kind::S_INTEGER: // INTEGER
        value.copy< UnparsedConstant > (that.value);
        break;

      case symbol_kind::S_IDENTIFIER: // IDENTIFIER
      case symbol_kind::S_TYPE_IDENTIFIER: // TYPE_IDENTIFIER
      case symbol_kind::S_STRING_LITERAL: // STRING_LITERAL
        value.copy< cstring > (that.value);
        break;

      default:
        break;
    }

    location = that.location;
    return *this;
  }

  P4Parser::stack_symbol_type&
  P4Parser::stack_symbol_type::operator= (stack_symbol_type& that)
  {
    state = that.state;
    switch (that.kind ())
    {
      case symbol_kind::S_typeRef: // typeRef
      case symbol_kind::S_namedType: // namedType
      case symbol_kind::S_tupleType: // tupleType
      case symbol_kind::S_headerStackType: // headerStackType
      case symbol_kind::S_specializedType: // specializedType
      case symbol_kind::S_baseType: // baseType
      case symbol_kind::S_typeOrVoid: // typeOrVoid
      case symbol_kind::S_typeArg: // typeArg
      case symbol_kind::S_realTypeArg: // realTypeArg
        value.move< ConstType* > (that.value);
        break;

      case symbol_kind::S_annotation: // annotation
        value.move< IR::Annotation* > (that.value);
        break;

      case symbol_kind::S_optAnnotations: // optAnnotations
        value.move< IR::Annotations* > (that.value);
        break;

      case symbol_kind::S_argument: // argument
        value.move< IR::Argument* > (that.value);
        break;

      case symbol_kind::S_objInitializer: // objInitializer
      case symbol_kind::S_parserBlockStatement: // parserBlockStatement
      case symbol_kind::S_controlBody: // controlBody
      case symbol_kind::S_blockStatement: // blockStatement
        value.move< IR::BlockStatement* > (that.value);
        break;

      case symbol_kind::S_instantiation: // instantiation
      case symbol_kind::S_objDeclaration: // objDeclaration
      case symbol_kind::S_parserLocalElement: // parserLocalElement
      case symbol_kind::S_valueSetDeclaration: // valueSetDeclaration
      case symbol_kind::S_controlLocalDeclaration: // controlLocalDeclaration
      case symbol_kind::S_tableDeclaration: // tableDeclaration
      case symbol_kind::S_actionDeclaration: // actionDeclaration
      case symbol_kind::S_variableDeclaration: // variableDeclaration
      case symbol_kind::S_constantDeclaration: // constantDeclaration
      case symbol_kind::S_functionDeclaration: // functionDeclaration
        value.move< IR::Declaration* > (that.value);
        break;

      case symbol_kind::S_direction: // direction
        value.move< IR::Direction > (that.value);
        break;

      case symbol_kind::S_entry: // entry
        value.move< IR::Entry* > (that.value);
        break;

      case symbol_kind::S_p4rtControllerType: // p4rtControllerType
      case symbol_kind::S_transitionStatement: // transitionStatement
      case symbol_kind::S_stateExpression: // stateExpression
      case symbol_kind::S_selectExpression: // selectExpression
      case symbol_kind::S_keysetExpression: // keysetExpression
      case symbol_kind::S_reducedSimpleKeysetExpression: // reducedSimpleKeysetExpression
      case symbol_kind::S_simpleKeysetExpression: // simpleKeysetExpression
      case symbol_kind::S_switchLabel: // switchLabel
      case symbol_kind::S_actionRef: // actionRef
      case symbol_kind::S_optInitializer: // optInitializer
      case symbol_kind::S_initializer: // initializer
      case symbol_kind::S_lvalue: // lvalue
      case symbol_kind::S_expression: // expression
      case symbol_kind::S_nonBraceExpression: // nonBraceExpression
      case symbol_kind::S_intOrStr: // intOrStr
        value.move< IR::Expression* > (that.value);
        break;

      case symbol_kind::S_nonTypeName: // nonTypeName
      case symbol_kind::S_name: // name
      case symbol_kind::S_nonTableKwName: // nonTableKwName
      case symbol_kind::S_dot_name: // dot_name
        value.move< IR::ID* > (that.value);
        break;

      case symbol_kind::S_actionList: // actionList
        value.move< IR::IndexedVector<IR::ActionListElement>* > (that.value);
        break;

      case symbol_kind::S_parserLocalElements: // parserLocalElements
      case symbol_kind::S_controlLocalDeclarations: // controlLocalDeclarations
        value.move< IR::IndexedVector<IR::Declaration>* > (that.value);
        break;

      case symbol_kind::S_identifierList: // identifierList
        value.move< IR::IndexedVector<IR::Declaration_ID>* > (that.value);
        break;

      case symbol_kind::S_kvList: // kvList
        value.move< IR::IndexedVector<IR::NamedExpression>* > (that.value);
        break;

      case symbol_kind::S_parameterList: // parameterList
      case symbol_kind::S_nonEmptyParameterList: // nonEmptyParameterList
      case symbol_kind::S_optConstructorParameters: // optConstructorParameters
        value.move< IR::IndexedVector<IR::Parameter>* > (that.value);
        break;

      case symbol_kind::S_parserStates: // parserStates
        value.move< IR::IndexedVector<IR::ParserState>* > (that.value);
        break;

      case symbol_kind::S_tablePropertyList: // tablePropertyList
        value.move< IR::IndexedVector<IR::Property>* > (that.value);
        break;

      case symbol_kind::S_specifiedIdentifierList: // specifiedIdentifierList
        value.move< IR::IndexedVector<IR::SerEnumMember>* > (that.value);
        break;

      case symbol_kind::S_objDeclarations: // objDeclarations
      case symbol_kind::S_parserStatements: // parserStatements
      case symbol_kind::S_statOrDeclList: // statOrDeclList
        value.move< IR::IndexedVector<IR::StatOrDecl>* > (that.value);
        break;

      case symbol_kind::S_structFieldList: // structFieldList
        value.move< IR::IndexedVector<IR::StructField>* > (that.value);
        break;

      case symbol_kind::S_typeParameterList: // typeParameterList
        value.move< IR::IndexedVector<IR::Type_Var>* > (that.value);
        break;

      case symbol_kind::S_keyElement: // keyElement
        value.move< IR::KeyElement* > (that.value);
        break;

      case symbol_kind::S_functionPrototype: // functionPrototype
      case symbol_kind::S_methodPrototype: // methodPrototype
        value.move< IR::Method* > (that.value);
        break;

      case symbol_kind::S_kvPair: // kvPair
        value.move< IR::NamedExpression* > (that.value);
        break;

      case symbol_kind::S_fragment: // fragment
      case symbol_kind::S_declaration: // declaration
      case symbol_kind::S_externDeclaration: // externDeclaration
      case symbol_kind::S_matchKindDeclaration: // matchKindDeclaration
        value.move< IR::Node* > (that.value);
        break;

      case symbol_kind::S_parameter: // parameter
        value.move< IR::Parameter* > (that.value);
        break;

      case symbol_kind::S_parserState: // parserState
        value.move< IR::ParserState* > (that.value);
        break;

      case symbol_kind::S_prefixedType: // prefixedType
      case symbol_kind::S_prefixedNonTypeName: // prefixedNonTypeName
        value.move< IR::Path* > (that.value);
        break;

      case symbol_kind::S_tableProperty: // tableProperty
        value.move< IR::Property* > (that.value);
        break;

      case symbol_kind::S_selectCase: // selectCase
        value.move< IR::SelectCase* > (that.value);
        break;

      case symbol_kind::S_specifiedIdentifier: // specifiedIdentifier
        value.move< IR::SerEnumMember* > (that.value);
        break;

      case symbol_kind::S_parserStatement: // parserStatement
      case symbol_kind::S_statementOrDeclaration: // statementOrDeclaration
        value.move< IR::StatOrDecl* > (that.value);
        break;

      case symbol_kind::S_assignmentOrMethodCallStatement: // assignmentOrMethodCallStatement
      case symbol_kind::S_emptyStatement: // emptyStatement
      case symbol_kind::S_exitStatement: // exitStatement
      case symbol_kind::S_returnStatement: // returnStatement
      case symbol_kind::S_conditionalStatement: // conditionalStatement
      case symbol_kind::S_directApplication: // directApplication
      case symbol_kind::S_statement: // statement
      case symbol_kind::S_switchStatement: // switchStatement
        value.move< IR::Statement* > (that.value);
        break;

      case symbol_kind::S_structField: // structField
        value.move< IR::StructField* > (that.value);
        break;

      case symbol_kind::S_switchCase: // switchCase
        value.move< IR::SwitchCase* > (that.value);
        break;

      case symbol_kind::S_optTypeParameters: // optTypeParameters
      case symbol_kind::S_typeParameters: // typeParameters
        value.move< IR::TypeParameters* > (that.value);
        break;

      case symbol_kind::S_controlTypeDeclaration: // controlTypeDeclaration
        value.move< IR::Type_Control* > (that.value);
        break;

      case symbol_kind::S_packageTypeDeclaration: // packageTypeDeclaration
      case symbol_kind::S_parserDeclaration: // parserDeclaration
      case symbol_kind::S_controlDeclaration: // controlDeclaration
      case symbol_kind::S_typeDeclaration: // typeDeclaration
      case symbol_kind::S_derivedTypeDeclaration: // derivedTypeDeclaration
      case symbol_kind::S_headerTypeDeclaration: // headerTypeDeclaration
      case symbol_kind::S_structTypeDeclaration: // structTypeDeclaration
      case symbol_kind::S_headerUnionDeclaration: // headerUnionDeclaration
      case symbol_kind::S_enumDeclaration: // enumDeclaration
      case symbol_kind::S_typedefDeclaration: // typedefDeclaration
        value.move< IR::Type_Declaration* > (that.value);
        break;

      case symbol_kind::S_errorDeclaration: // errorDeclaration
        value.move< IR::Type_Error* > (that.value);
        break;

      case symbol_kind::S_typeName: // typeName
        value.move< IR::Type_Name* > (that.value);
        break;

      case symbol_kind::S_parserTypeDeclaration: // parserTypeDeclaration
        value.move< IR::Type_Parser* > (that.value);
        break;

      case symbol_kind::S_annotations: // annotations
        value.move< IR::Vector<IR::Annotation>* > (that.value);
        break;

      case symbol_kind::S_annotationBody: // annotationBody
        value.move< IR::Vector<IR::AnnotationToken>* > (that.value);
        break;

      case symbol_kind::S_argumentList: // argumentList
      case symbol_kind::S_nonEmptyArgList: // nonEmptyArgList
        value.move< IR::Vector<IR::Argument>* > (that.value);
        break;

      case symbol_kind::S_entriesList: // entriesList
        value.move< IR::Vector<IR::Entry>* > (that.value);
        break;

      case symbol_kind::S_tupleKeysetExpression: // tupleKeysetExpression
      case symbol_kind::S_simpleExpressionList: // simpleExpressionList
      case symbol_kind::S_expressionList: // expressionList
      case symbol_kind::S_intList: // intList
      case symbol_kind::S_intOrStrList: // intOrStrList
      case symbol_kind::S_strList: // strList
        value.move< IR::Vector<IR::Expression>* > (that.value);
        break;

      case symbol_kind::S_keyElementList: // keyElementList
        value.move< IR::Vector<IR::KeyElement>* > (that.value);
        break;

      case symbol_kind::S_methodPrototypes: // methodPrototypes
        value.move< IR::Vector<IR::Method>* > (that.value);
        break;

      case symbol_kind::S_selectCaseList: // selectCaseList
        value.move< IR::Vector<IR::SelectCase>* > (that.value);
        break;

      case symbol_kind::S_switchCases: // switchCases
        value.move< IR::Vector<IR::SwitchCase>* > (that.value);
        break;

      case symbol_kind::S_typeArgumentList: // typeArgumentList
      case symbol_kind::S_realTypeArgumentList: // realTypeArgumentList
        value.move< IR::Vector<IR::Type>* > (that.value);
        break;

      case symbol_kind::S_optCONST: // optCONST
        value.move< OptionalConst > (that.value);
        break;

      case symbol_kind::S_UNEXPECTED_TOKEN: // UNEXPECTED_TOKEN
      case symbol_kind::S_END_PRAGMA: // END_PRAGMA
      case symbol_kind::S_LE: // "<="
      case symbol_kind::S_GE: // ">="
      case symbol_kind::S_SHL: // "<<"
      case symbol_kind::S_AND: // "&&"
      case symbol_kind::S_OR: // "||"
      case symbol_kind::S_NE: // "!="
      case symbol_kind::S_EQ: // "=="
      case symbol_kind::S_PLUS: // "+"
      case symbol_kind::S_MINUS: // "-"
      case symbol_kind::S_PLUS_SAT: // "|+|"
      case symbol_kind::S_MINUS_SAT: // "|-|"
      case symbol_kind::S_MUL: // "*"
      case symbol_kind::S_DIV: // "/"
      case symbol_kind::S_MOD: // "%"
      case symbol_kind::S_BIT_OR: // "|"
      case symbol_kind::S_BIT_AND: // "&"
      case symbol_kind::S_BIT_XOR: // "^"
      case symbol_kind::S_COMPLEMENT: // "~"
      case symbol_kind::S_L_BRACKET: // "["
      case symbol_kind::S_R_BRACKET: // "]"
      case symbol_kind::S_L_BRACE: // "{"
      case symbol_kind::S_R_BRACE: // "}"
      case symbol_kind::S_L_ANGLE: // "<"
      case symbol_kind::S_L_ANGLE_ARGS: // L_ANGLE_ARGS
      case symbol_kind::S_R_ANGLE: // ">"
      case symbol_kind::S_R_ANGLE_SHIFT: // R_ANGLE_SHIFT
      case symbol_kind::S_L_PAREN: // "("
      case symbol_kind::S_R_PAREN: // ")"
      case symbol_kind::S_NOT: // "!"
      case symbol_kind::S_COLON: // ":"
      case symbol_kind::S_COMMA: // ","
      case symbol_kind::S_QUESTION: // "?"
      case symbol_kind::S_DOT: // "."
      case symbol_kind::S_ASSIGN: // "="
      case symbol_kind::S_SEMICOLON: // ";"
      case symbol_kind::S_AT: // "@"
      case symbol_kind::S_PP: // "++"
      case symbol_kind::S_DONTCARE: // "_"
      case symbol_kind::S_MASK: // "&&&"
      case symbol_kind::S_RANGE: // ".."
      case symbol_kind::S_TRUE: // TRUE
      case symbol_kind::S_FALSE: // FALSE
      case symbol_kind::S_THIS: // THIS
      case symbol_kind::S_ABSTRACT: // ABSTRACT
      case symbol_kind::S_ACTION: // ACTION
      case symbol_kind::S_ACTIONS: // ACTIONS
      case symbol_kind::S_APPLY: // APPLY
      case symbol_kind::S_BOOL: // BOOL
      case symbol_kind::S_BIT: // BIT
      case symbol_kind::S_CONST: // CONST
      case symbol_kind::S_CONTROL: // CONTROL
      case symbol_kind::S_DEFAULT: // DEFAULT
      case symbol_kind::S_ELSE: // ELSE
      case symbol_kind::S_ENTRIES: // ENTRIES
      case symbol_kind::S_ENUM: // ENUM
      case symbol_kind::S_ERROR: // ERROR
      case symbol_kind::S_EXIT: // EXIT
      case symbol_kind::S_EXTERN: // EXTERN
      case symbol_kind::S_HEADER: // HEADER
      case symbol_kind::S_HEADER_UNION: // HEADER_UNION
      case symbol_kind::S_IF: // IF
      case symbol_kind::S_IN: // IN
      case symbol_kind::S_INOUT: // INOUT
      case symbol_kind::S_INT: // INT
      case symbol_kind::S_KEY: // KEY
      case symbol_kind::S_SELECT: // SELECT
      case symbol_kind::S_MATCH_KIND: // MATCH_KIND
      case symbol_kind::S_TYPE: // TYPE
      case symbol_kind::S_OUT: // OUT
      case symbol_kind::S_PACKAGE: // PACKAGE
      case symbol_kind::S_PARSER: // PARSER
      case symbol_kind::S_PRAGMA: // PRAGMA
      case symbol_kind::S_RETURN: // RETURN
      case symbol_kind::S_STATE: // STATE
      case symbol_kind::S_STRING: // STRING
      case symbol_kind::S_STRUCT: // STRUCT
      case symbol_kind::S_SWITCH: // SWITCH
      case symbol_kind::S_TABLE: // TABLE
      case symbol_kind::S_TRANSITION: // TRANSITION
      case symbol_kind::S_TUPLE: // TUPLE
      case symbol_kind::S_TYPEDEF: // TYPEDEF
      case symbol_kind::S_VARBIT: // VARBIT
      case symbol_kind::S_VALUESET: // VALUESET
      case symbol_kind::S_VOID: // VOID
      case symbol_kind::S_annotationToken: // annotationToken
        value.move< Token > (that.value);
        break;

      case symbol_kind::S_INTEGER: // INTEGER
        value.move< UnparsedConstant > (that.value);
        break;

      case symbol_kind::S_IDENTIFIER: // IDENTIFIER
      case symbol_kind::S_TYPE_IDENTIFIER: // TYPE_IDENTIFIER
      case symbol_kind::S_STRING_LITERAL: // STRING_LITERAL
        value.move< cstring > (that.value);
        break;

      default:
        break;
    }

    location = that.location;
    // that is emptied.
    that.state = empty_state;
    return *this;
  }
#endif

  template <typename Base>
  void
  P4Parser::yy_destroy_ (const char* yymsg, basic_symbol<Base>& yysym) const
  {
    if (yymsg)
      YY_SYMBOL_PRINT (yymsg, yysym);
  }

#if YYDEBUG
  template <typename Base>
  void
  P4Parser::yy_print_ (std::ostream& yyo, const basic_symbol<Base>& yysym) const
  {
    std::ostream& yyoutput = yyo;
    YY_USE (yyoutput);
    if (yysym.empty ())
      yyo << "empty symbol";
    else
      {
        symbol_kind_type yykind = yysym.kind ();
        yyo << (yykind < YYNTOKENS ? "token" : "nterm")
            << ' ' << yysym.name () << " ("
            << yysym.location << ": ";
        switch (yykind)
    {
      case symbol_kind::S_UNEXPECTED_TOKEN: // UNEXPECTED_TOKEN
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1825 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_END_PRAGMA: // END_PRAGMA
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1831 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_LE: // "<="
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1837 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_GE: // ">="
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1843 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_SHL: // "<<"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1849 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_AND: // "&&"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1855 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_OR: // "||"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1861 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_NE: // "!="
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1867 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_EQ: // "=="
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1873 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_PLUS: // "+"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1879 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_MINUS: // "-"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1885 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_PLUS_SAT: // "|+|"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1891 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_MINUS_SAT: // "|-|"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1897 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_MUL: // "*"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1903 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_DIV: // "/"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1909 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_MOD: // "%"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1915 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_BIT_OR: // "|"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1921 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_BIT_AND: // "&"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1927 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_BIT_XOR: // "^"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1933 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_COMPLEMENT: // "~"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1939 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_L_BRACKET: // "["
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1945 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_R_BRACKET: // "]"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1951 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_L_BRACE: // "{"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1957 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_R_BRACE: // "}"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1963 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_L_ANGLE: // "<"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1969 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_L_ANGLE_ARGS: // L_ANGLE_ARGS
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1975 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_R_ANGLE: // ">"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1981 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_R_ANGLE_SHIFT: // R_ANGLE_SHIFT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1987 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_L_PAREN: // "("
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1993 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_R_PAREN: // ")"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 1999 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_NOT: // "!"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2005 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_COLON: // ":"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2011 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_COMMA: // ","
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2017 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_QUESTION: // "?"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2023 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_DOT: // "."
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2029 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ASSIGN: // "="
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2035 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_SEMICOLON: // ";"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2041 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_AT: // "@"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2047 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_PP: // "++"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2053 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_DONTCARE: // "_"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2059 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_MASK: // "&&&"
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2065 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_RANGE: // ".."
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2071 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TRUE: // TRUE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2077 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_FALSE: // FALSE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2083 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_THIS: // THIS
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2089 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ABSTRACT: // ABSTRACT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2095 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ACTION: // ACTION
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2101 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ACTIONS: // ACTIONS
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2107 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_APPLY: // APPLY
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2113 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_BOOL: // BOOL
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2119 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_BIT: // BIT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2125 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_CONST: // CONST
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2131 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_CONTROL: // CONTROL
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2137 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_DEFAULT: // DEFAULT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2143 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ELSE: // ELSE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2149 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ENTRIES: // ENTRIES
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2155 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ENUM: // ENUM
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2161 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_ERROR: // ERROR
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2167 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_EXIT: // EXIT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2173 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_EXTERN: // EXTERN
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2179 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_HEADER: // HEADER
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2185 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_HEADER_UNION: // HEADER_UNION
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2191 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_IF: // IF
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2197 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_IN: // IN
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2203 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_INOUT: // INOUT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2209 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_INT: // INT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2215 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_KEY: // KEY
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2221 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_SELECT: // SELECT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2227 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_MATCH_KIND: // MATCH_KIND
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2233 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TYPE: // TYPE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2239 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_OUT: // OUT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2245 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_PACKAGE: // PACKAGE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2251 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_PARSER: // PARSER
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2257 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_PRAGMA: // PRAGMA
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2263 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_RETURN: // RETURN
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2269 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_STATE: // STATE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2275 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_STRING: // STRING
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2281 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_STRUCT: // STRUCT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2287 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_SWITCH: // SWITCH
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2293 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TABLE: // TABLE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2299 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TRANSITION: // TRANSITION
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2305 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TUPLE: // TUPLE
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2311 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TYPEDEF: // TYPEDEF
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2317 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_VARBIT: // VARBIT
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2323 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_VALUESET: // VALUESET
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2329 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_VOID: // VOID
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2335 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_IDENTIFIER: // IDENTIFIER
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < cstring > (); }
#line 2341 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_TYPE_IDENTIFIER: // TYPE_IDENTIFIER
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < cstring > (); }
#line 2347 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_STRING_LITERAL: // STRING_LITERAL
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < cstring > (); }
#line 2353 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_INTEGER: // INTEGER
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < UnparsedConstant > (); }
#line 2359 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_fragment: // fragment
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Node* > (); }
#line 2365 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_p4rtControllerType: // p4rtControllerType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2371 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_declaration: // declaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Node* > (); }
#line 2377 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_nonTypeName: // nonTypeName
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::ID* > (); }
#line 2383 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_name: // name
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::ID* > (); }
#line 2389 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_nonTableKwName: // nonTableKwName
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::ID* > (); }
#line 2395 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_optCONST: // optCONST
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < OptionalConst > (); }
#line 2401 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_optAnnotations: // optAnnotations
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Annotations* > (); }
#line 2407 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_annotations: // annotations
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Annotation>* > (); }
#line 2413 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_annotation: // annotation
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Annotation* > (); }
#line 2419 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_annotationBody: // annotationBody
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::AnnotationToken>* > (); }
#line 2425 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_annotationToken: // annotationToken
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < Token > (); }
#line 2431 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_kvList: // kvList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::NamedExpression>* > (); }
#line 2437 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_kvPair: // kvPair
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::NamedExpression* > (); }
#line 2443 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parameterList: // parameterList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Parameter>* > (); }
#line 2449 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_nonEmptyParameterList: // nonEmptyParameterList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Parameter>* > (); }
#line 2455 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parameter: // parameter
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Parameter* > (); }
#line 2461 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_direction: // direction
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Direction > (); }
#line 2467 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_packageTypeDeclaration: // packageTypeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2473 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_instantiation: // instantiation
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 2479 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_objInitializer: // objInitializer
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::BlockStatement* > (); }
#line 2485 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_objDeclarations: // objDeclarations
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::StatOrDecl>* > (); }
#line 2491 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_objDeclaration: // objDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 2497 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_optConstructorParameters: // optConstructorParameters
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Parameter>* > (); }
#line 2503 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserDeclaration: // parserDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2509 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserLocalElements: // parserLocalElements
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Declaration>* > (); }
#line 2515 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserLocalElement: // parserLocalElement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 2521 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserTypeDeclaration: // parserTypeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Parser* > (); }
#line 2527 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserStates: // parserStates
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::ParserState>* > (); }
#line 2533 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserState: // parserState
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::ParserState* > (); }
#line 2539 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserStatements: // parserStatements
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::StatOrDecl>* > (); }
#line 2545 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserStatement: // parserStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::StatOrDecl* > (); }
#line 2551 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_parserBlockStatement: // parserBlockStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::BlockStatement* > (); }
#line 2557 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_transitionStatement: // transitionStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2563 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_stateExpression: // stateExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2569 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_selectExpression: // selectExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2575 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_selectCaseList: // selectCaseList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::SelectCase>* > (); }
#line 2581 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_selectCase: // selectCase
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::SelectCase* > (); }
#line 2587 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_keysetExpression: // keysetExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2593 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_tupleKeysetExpression: // tupleKeysetExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Expression>* > (); }
#line 2599 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_simpleExpressionList: // simpleExpressionList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Expression>* > (); }
#line 2605 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_reducedSimpleKeysetExpression: // reducedSimpleKeysetExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2611 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_simpleKeysetExpression: // simpleKeysetExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2617 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_valueSetDeclaration: // valueSetDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 2623 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_controlDeclaration: // controlDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2629 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_controlTypeDeclaration: // controlTypeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Control* > (); }
#line 2635 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_controlLocalDeclarations: // controlLocalDeclarations
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Declaration>* > (); }
#line 2641 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_controlLocalDeclaration: // controlLocalDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 2647 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_controlBody: // controlBody
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::BlockStatement* > (); }
#line 2653 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_externDeclaration: // externDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Node* > (); }
#line 2659 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_methodPrototypes: // methodPrototypes
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Method>* > (); }
#line 2665 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_functionPrototype: // functionPrototype
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Method* > (); }
#line 2671 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_methodPrototype: // methodPrototype
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Method* > (); }
#line 2677 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeRef: // typeRef
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2683 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_namedType: // namedType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2689 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_prefixedType: // prefixedType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Path* > (); }
#line 2695 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeName: // typeName
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Name* > (); }
#line 2701 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_tupleType: // tupleType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2707 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_headerStackType: // headerStackType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2713 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_specializedType: // specializedType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2719 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_baseType: // baseType
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2725 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeOrVoid: // typeOrVoid
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2731 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_optTypeParameters: // optTypeParameters
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::TypeParameters* > (); }
#line 2737 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeParameters: // typeParameters
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::TypeParameters* > (); }
#line 2743 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeParameterList: // typeParameterList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Type_Var>* > (); }
#line 2749 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeArg: // typeArg
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2755 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeArgumentList: // typeArgumentList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Type>* > (); }
#line 2761 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_realTypeArg: // realTypeArg
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < ConstType* > (); }
#line 2767 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_realTypeArgumentList: // realTypeArgumentList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Type>* > (); }
#line 2773 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typeDeclaration: // typeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2779 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_derivedTypeDeclaration: // derivedTypeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2785 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_headerTypeDeclaration: // headerTypeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2791 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_structTypeDeclaration: // structTypeDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2797 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_headerUnionDeclaration: // headerUnionDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2803 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_structFieldList: // structFieldList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::StructField>* > (); }
#line 2809 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_structField: // structField
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::StructField* > (); }
#line 2815 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_enumDeclaration: // enumDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2821 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_specifiedIdentifierList: // specifiedIdentifierList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::SerEnumMember>* > (); }
#line 2827 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_specifiedIdentifier: // specifiedIdentifier
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::SerEnumMember* > (); }
#line 2833 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_errorDeclaration: // errorDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Error* > (); }
#line 2839 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_matchKindDeclaration: // matchKindDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Node* > (); }
#line 2845 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_identifierList: // identifierList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Declaration_ID>* > (); }
#line 2851 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_typedefDeclaration: // typedefDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Type_Declaration* > (); }
#line 2857 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_assignmentOrMethodCallStatement: // assignmentOrMethodCallStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2863 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_emptyStatement: // emptyStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2869 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_exitStatement: // exitStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2875 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_returnStatement: // returnStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2881 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_conditionalStatement: // conditionalStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2887 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_directApplication: // directApplication
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2893 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_statement: // statement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2899 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_blockStatement: // blockStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::BlockStatement* > (); }
#line 2905 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_statOrDeclList: // statOrDeclList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::StatOrDecl>* > (); }
#line 2911 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_switchStatement: // switchStatement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Statement* > (); }
#line 2917 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_switchCases: // switchCases
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::SwitchCase>* > (); }
#line 2923 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_switchCase: // switchCase
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::SwitchCase* > (); }
#line 2929 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_switchLabel: // switchLabel
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2935 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_statementOrDeclaration: // statementOrDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::StatOrDecl* > (); }
#line 2941 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_tableDeclaration: // tableDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 2947 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_tablePropertyList: // tablePropertyList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::Property>* > (); }
#line 2953 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_tableProperty: // tableProperty
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Property* > (); }
#line 2959 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_keyElementList: // keyElementList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::KeyElement>* > (); }
#line 2965 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_keyElement: // keyElement
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::KeyElement* > (); }
#line 2971 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_actionList: // actionList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::IndexedVector<IR::ActionListElement>* > (); }
#line 2977 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_actionRef: // actionRef
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 2983 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_entry: // entry
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Entry* > (); }
#line 2989 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_entriesList: // entriesList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Entry>* > (); }
#line 2995 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_actionDeclaration: // actionDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 3001 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_variableDeclaration: // variableDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 3007 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_constantDeclaration: // constantDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 3013 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_optInitializer: // optInitializer
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 3019 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_initializer: // initializer
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 3025 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_functionDeclaration: // functionDeclaration
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Declaration* > (); }
#line 3031 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_argumentList: // argumentList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Argument>* > (); }
#line 3037 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_nonEmptyArgList: // nonEmptyArgList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Argument>* > (); }
#line 3043 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_argument: // argument
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Argument* > (); }
#line 3049 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_expressionList: // expressionList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Expression>* > (); }
#line 3055 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_prefixedNonTypeName: // prefixedNonTypeName
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Path* > (); }
#line 3061 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_dot_name: // dot_name
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::ID* > (); }
#line 3067 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_lvalue: // lvalue
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 3073 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_expression: // expression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 3079 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_nonBraceExpression: // nonBraceExpression
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 3085 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_intOrStr: // intOrStr
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Expression* > (); }
#line 3091 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_intList: // intList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Expression>* > (); }
#line 3097 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_intOrStrList: // intOrStrList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Expression>* > (); }
#line 3103 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      case symbol_kind::S_strList: // strList
#line 132 "parsers/p4/p4parser.ypp"
                 { yyoutput << yysym.value.template as < IR::Vector<IR::Expression>* > (); }
#line 3109 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
        break;

      default:
        break;
    }
        yyo << ')';
      }
  }
#endif

  void
  P4Parser::yypush_ (const char* m, YY_MOVE_REF (stack_symbol_type) sym)
  {
    if (m)
      YY_SYMBOL_PRINT (m, sym);
    yystack_.push (YY_MOVE (sym));
  }

  void
  P4Parser::yypush_ (const char* m, state_type s, YY_MOVE_REF (symbol_type) sym)
  {
#if 201103L <= YY_CPLUSPLUS
    yypush_ (m, stack_symbol_type (s, std::move (sym)));
#else
    stack_symbol_type ss (s, sym);
    yypush_ (m, ss);
#endif
  }

  void
  P4Parser::yypop_ (int n) YY_NOEXCEPT
  {
    yystack_.pop (n);
  }

#if YYDEBUG
  std::ostream&
  P4Parser::debug_stream () const
  {
    return *yycdebug_;
  }

  void
  P4Parser::set_debug_stream (std::ostream& o)
  {
    yycdebug_ = &o;
  }


  P4Parser::debug_level_type
  P4Parser::debug_level () const
  {
    return yydebug_;
  }

  void
  P4Parser::set_debug_level (debug_level_type l)
  {
    yydebug_ = l;
  }
#endif // YYDEBUG

  P4Parser::state_type
  P4Parser::yy_lr_goto_state_ (state_type yystate, int yysym)
  {
    int yyr = yypgoto_[yysym - YYNTOKENS] + yystate;
    if (0 <= yyr && yyr <= yylast_ && yycheck_[yyr] == yystate)
      return yytable_[yyr];
    else
      return yydefgoto_[yysym - YYNTOKENS];
  }

  bool
  P4Parser::yy_pact_value_is_default_ (int yyvalue) YY_NOEXCEPT
  {
    return yyvalue == yypact_ninf_;
  }

  bool
  P4Parser::yy_table_value_is_error_ (int yyvalue) YY_NOEXCEPT
  {
    return yyvalue == yytable_ninf_;
  }

  int
  P4Parser::operator() ()
  {
    return parse ();
  }

  int
  P4Parser::parse ()
  {
    int yyn;
    /// Length of the RHS of the rule being reduced.
    int yylen = 0;

    // Error handling.
    int yynerrs_ = 0;
    int yyerrstatus_ = 0;

    /// The lookahead symbol.
    symbol_type yyla;

    /// The locations where the error started and ended.
    stack_symbol_type yyerror_range[3];

    /// The return value of parse ().
    int yyresult;

#if YY_EXCEPTIONS
    try
#endif // YY_EXCEPTIONS
      {
    YYCDEBUG << "Starting parse\n";


    /* Initialize the stack.  The initial state will be set in
       yynewstate, since the latter expects the semantical and the
       location values to have been already stored, initialize these
       stacks with a primary value.  */
    yystack_.clear ();
    yypush_ (YY_NULLPTR, 0, YY_MOVE (yyla));

  /*-----------------------------------------------.
  | yynewstate -- push a new symbol on the stack.  |
  `-----------------------------------------------*/
  yynewstate:
    YYCDEBUG << "Entering state " << int (yystack_[0].state) << '\n';
    YY_STACK_PRINT ();

    // Accept?
    if (yystack_[0].state == yyfinal_)
      YYACCEPT;

    goto yybackup;


  /*-----------.
  | yybackup.  |
  `-----------*/
  yybackup:
    // Try to take a decision without lookahead.
    yyn = yypact_[+yystack_[0].state];
    if (yy_pact_value_is_default_ (yyn))
      goto yydefault;

    // Read a lookahead token.
    if (yyla.empty ())
      {
        YYCDEBUG << "Reading a token\n";
#if YY_EXCEPTIONS
        try
#endif // YY_EXCEPTIONS
          {
            symbol_type yylookahead (yylex (driver));
            yyla.move (yylookahead);
          }
#if YY_EXCEPTIONS
        catch (const syntax_error& yyexc)
          {
            YYCDEBUG << "Caught exception: " << yyexc.what() << '\n';
            error (yyexc);
            goto yyerrlab1;
          }
#endif // YY_EXCEPTIONS
      }
    YY_SYMBOL_PRINT ("Next token is", yyla);

    if (yyla.kind () == symbol_kind::S_YYerror)
    {
      // The scanner already issued an error message, process directly
      // to error recovery.  But do not keep the error token as
      // lookahead, it is too special and may lead us to an endless
      // loop in error recovery. */
      yyla.kind_ = symbol_kind::S_YYUNDEF;
      goto yyerrlab1;
    }

    /* If the proper action on seeing token YYLA.TYPE is to reduce or
       to detect an error, take that action.  */
    yyn += yyla.kind ();
    if (yyn < 0 || yylast_ < yyn || yycheck_[yyn] != yyla.kind ())
      {
        goto yydefault;
      }

    // Reduce or error.
    yyn = yytable_[yyn];
    if (yyn <= 0)
      {
        if (yy_table_value_is_error_ (yyn))
          goto yyerrlab;
        yyn = -yyn;
        goto yyreduce;
      }

    // Count tokens shifted since error; after three, turn off error status.
    if (yyerrstatus_)
      --yyerrstatus_;

    // Shift the lookahead token.
    yypush_ ("Shifting", state_type (yyn), YY_MOVE (yyla));
    goto yynewstate;


  /*-----------------------------------------------------------.
  | yydefault -- do the default action for the current state.  |
  `-----------------------------------------------------------*/
  yydefault:
    yyn = yydefact_[+yystack_[0].state];
    if (yyn == 0)
      goto yyerrlab;
    goto yyreduce;


  /*-----------------------------.
  | yyreduce -- do a reduction.  |
  `-----------------------------*/
  yyreduce:
    yylen = yyr2_[yyn];
    {
      stack_symbol_type yylhs;
      yylhs.state = yy_lr_goto_state_ (yystack_[yylen].state, yyr1_[yyn]);
      /* Variants are always initialized to an empty instance of the
         correct type. The default '$$ = $1' action is NOT applied
         when using variants.  */
      switch (yyr1_[yyn])
    {
      case symbol_kind::S_typeRef: // typeRef
      case symbol_kind::S_namedType: // namedType
      case symbol_kind::S_tupleType: // tupleType
      case symbol_kind::S_headerStackType: // headerStackType
      case symbol_kind::S_specializedType: // specializedType
      case symbol_kind::S_baseType: // baseType
      case symbol_kind::S_typeOrVoid: // typeOrVoid
      case symbol_kind::S_typeArg: // typeArg
      case symbol_kind::S_realTypeArg: // realTypeArg
        yylhs.value.emplace< ConstType* > ();
        break;

      case symbol_kind::S_annotation: // annotation
        yylhs.value.emplace< IR::Annotation* > ();
        break;

      case symbol_kind::S_optAnnotations: // optAnnotations
        yylhs.value.emplace< IR::Annotations* > ();
        break;

      case symbol_kind::S_argument: // argument
        yylhs.value.emplace< IR::Argument* > ();
        break;

      case symbol_kind::S_objInitializer: // objInitializer
      case symbol_kind::S_parserBlockStatement: // parserBlockStatement
      case symbol_kind::S_controlBody: // controlBody
      case symbol_kind::S_blockStatement: // blockStatement
        yylhs.value.emplace< IR::BlockStatement* > ();
        break;

      case symbol_kind::S_instantiation: // instantiation
      case symbol_kind::S_objDeclaration: // objDeclaration
      case symbol_kind::S_parserLocalElement: // parserLocalElement
      case symbol_kind::S_valueSetDeclaration: // valueSetDeclaration
      case symbol_kind::S_controlLocalDeclaration: // controlLocalDeclaration
      case symbol_kind::S_tableDeclaration: // tableDeclaration
      case symbol_kind::S_actionDeclaration: // actionDeclaration
      case symbol_kind::S_variableDeclaration: // variableDeclaration
      case symbol_kind::S_constantDeclaration: // constantDeclaration
      case symbol_kind::S_functionDeclaration: // functionDeclaration
        yylhs.value.emplace< IR::Declaration* > ();
        break;

      case symbol_kind::S_direction: // direction
        yylhs.value.emplace< IR::Direction > ();
        break;

      case symbol_kind::S_entry: // entry
        yylhs.value.emplace< IR::Entry* > ();
        break;

      case symbol_kind::S_p4rtControllerType: // p4rtControllerType
      case symbol_kind::S_transitionStatement: // transitionStatement
      case symbol_kind::S_stateExpression: // stateExpression
      case symbol_kind::S_selectExpression: // selectExpression
      case symbol_kind::S_keysetExpression: // keysetExpression
      case symbol_kind::S_reducedSimpleKeysetExpression: // reducedSimpleKeysetExpression
      case symbol_kind::S_simpleKeysetExpression: // simpleKeysetExpression
      case symbol_kind::S_switchLabel: // switchLabel
      case symbol_kind::S_actionRef: // actionRef
      case symbol_kind::S_optInitializer: // optInitializer
      case symbol_kind::S_initializer: // initializer
      case symbol_kind::S_lvalue: // lvalue
      case symbol_kind::S_expression: // expression
      case symbol_kind::S_nonBraceExpression: // nonBraceExpression
      case symbol_kind::S_intOrStr: // intOrStr
        yylhs.value.emplace< IR::Expression* > ();
        break;

      case symbol_kind::S_nonTypeName: // nonTypeName
      case symbol_kind::S_name: // name
      case symbol_kind::S_nonTableKwName: // nonTableKwName
      case symbol_kind::S_dot_name: // dot_name
        yylhs.value.emplace< IR::ID* > ();
        break;

      case symbol_kind::S_actionList: // actionList
        yylhs.value.emplace< IR::IndexedVector<IR::ActionListElement>* > ();
        break;

      case symbol_kind::S_parserLocalElements: // parserLocalElements
      case symbol_kind::S_controlLocalDeclarations: // controlLocalDeclarations
        yylhs.value.emplace< IR::IndexedVector<IR::Declaration>* > ();
        break;

      case symbol_kind::S_identifierList: // identifierList
        yylhs.value.emplace< IR::IndexedVector<IR::Declaration_ID>* > ();
        break;

      case symbol_kind::S_kvList: // kvList
        yylhs.value.emplace< IR::IndexedVector<IR::NamedExpression>* > ();
        break;

      case symbol_kind::S_parameterList: // parameterList
      case symbol_kind::S_nonEmptyParameterList: // nonEmptyParameterList
      case symbol_kind::S_optConstructorParameters: // optConstructorParameters
        yylhs.value.emplace< IR::IndexedVector<IR::Parameter>* > ();
        break;

      case symbol_kind::S_parserStates: // parserStates
        yylhs.value.emplace< IR::IndexedVector<IR::ParserState>* > ();
        break;

      case symbol_kind::S_tablePropertyList: // tablePropertyList
        yylhs.value.emplace< IR::IndexedVector<IR::Property>* > ();
        break;

      case symbol_kind::S_specifiedIdentifierList: // specifiedIdentifierList
        yylhs.value.emplace< IR::IndexedVector<IR::SerEnumMember>* > ();
        break;

      case symbol_kind::S_objDeclarations: // objDeclarations
      case symbol_kind::S_parserStatements: // parserStatements
      case symbol_kind::S_statOrDeclList: // statOrDeclList
        yylhs.value.emplace< IR::IndexedVector<IR::StatOrDecl>* > ();
        break;

      case symbol_kind::S_structFieldList: // structFieldList
        yylhs.value.emplace< IR::IndexedVector<IR::StructField>* > ();
        break;

      case symbol_kind::S_typeParameterList: // typeParameterList
        yylhs.value.emplace< IR::IndexedVector<IR::Type_Var>* > ();
        break;

      case symbol_kind::S_keyElement: // keyElement
        yylhs.value.emplace< IR::KeyElement* > ();
        break;

      case symbol_kind::S_functionPrototype: // functionPrototype
      case symbol_kind::S_methodPrototype: // methodPrototype
        yylhs.value.emplace< IR::Method* > ();
        break;

      case symbol_kind::S_kvPair: // kvPair
        yylhs.value.emplace< IR::NamedExpression* > ();
        break;

      case symbol_kind::S_fragment: // fragment
      case symbol_kind::S_declaration: // declaration
      case symbol_kind::S_externDeclaration: // externDeclaration
      case symbol_kind::S_matchKindDeclaration: // matchKindDeclaration
        yylhs.value.emplace< IR::Node* > ();
        break;

      case symbol_kind::S_parameter: // parameter
        yylhs.value.emplace< IR::Parameter* > ();
        break;

      case symbol_kind::S_parserState: // parserState
        yylhs.value.emplace< IR::ParserState* > ();
        break;

      case symbol_kind::S_prefixedType: // prefixedType
      case symbol_kind::S_prefixedNonTypeName: // prefixedNonTypeName
        yylhs.value.emplace< IR::Path* > ();
        break;

      case symbol_kind::S_tableProperty: // tableProperty
        yylhs.value.emplace< IR::Property* > ();
        break;

      case symbol_kind::S_selectCase: // selectCase
        yylhs.value.emplace< IR::SelectCase* > ();
        break;

      case symbol_kind::S_specifiedIdentifier: // specifiedIdentifier
        yylhs.value.emplace< IR::SerEnumMember* > ();
        break;

      case symbol_kind::S_parserStatement: // parserStatement
      case symbol_kind::S_statementOrDeclaration: // statementOrDeclaration
        yylhs.value.emplace< IR::StatOrDecl* > ();
        break;

      case symbol_kind::S_assignmentOrMethodCallStatement: // assignmentOrMethodCallStatement
      case symbol_kind::S_emptyStatement: // emptyStatement
      case symbol_kind::S_exitStatement: // exitStatement
      case symbol_kind::S_returnStatement: // returnStatement
      case symbol_kind::S_conditionalStatement: // conditionalStatement
      case symbol_kind::S_directApplication: // directApplication
      case symbol_kind::S_statement: // statement
      case symbol_kind::S_switchStatement: // switchStatement
        yylhs.value.emplace< IR::Statement* > ();
        break;

      case symbol_kind::S_structField: // structField
        yylhs.value.emplace< IR::StructField* > ();
        break;

      case symbol_kind::S_switchCase: // switchCase
        yylhs.value.emplace< IR::SwitchCase* > ();
        break;

      case symbol_kind::S_optTypeParameters: // optTypeParameters
      case symbol_kind::S_typeParameters: // typeParameters
        yylhs.value.emplace< IR::TypeParameters* > ();
        break;

      case symbol_kind::S_controlTypeDeclaration: // controlTypeDeclaration
        yylhs.value.emplace< IR::Type_Control* > ();
        break;

      case symbol_kind::S_packageTypeDeclaration: // packageTypeDeclaration
      case symbol_kind::S_parserDeclaration: // parserDeclaration
      case symbol_kind::S_controlDeclaration: // controlDeclaration
      case symbol_kind::S_typeDeclaration: // typeDeclaration
      case symbol_kind::S_derivedTypeDeclaration: // derivedTypeDeclaration
      case symbol_kind::S_headerTypeDeclaration: // headerTypeDeclaration
      case symbol_kind::S_structTypeDeclaration: // structTypeDeclaration
      case symbol_kind::S_headerUnionDeclaration: // headerUnionDeclaration
      case symbol_kind::S_enumDeclaration: // enumDeclaration
      case symbol_kind::S_typedefDeclaration: // typedefDeclaration
        yylhs.value.emplace< IR::Type_Declaration* > ();
        break;

      case symbol_kind::S_errorDeclaration: // errorDeclaration
        yylhs.value.emplace< IR::Type_Error* > ();
        break;

      case symbol_kind::S_typeName: // typeName
        yylhs.value.emplace< IR::Type_Name* > ();
        break;

      case symbol_kind::S_parserTypeDeclaration: // parserTypeDeclaration
        yylhs.value.emplace< IR::Type_Parser* > ();
        break;

      case symbol_kind::S_annotations: // annotations
        yylhs.value.emplace< IR::Vector<IR::Annotation>* > ();
        break;

      case symbol_kind::S_annotationBody: // annotationBody
        yylhs.value.emplace< IR::Vector<IR::AnnotationToken>* > ();
        break;

      case symbol_kind::S_argumentList: // argumentList
      case symbol_kind::S_nonEmptyArgList: // nonEmptyArgList
        yylhs.value.emplace< IR::Vector<IR::Argument>* > ();
        break;

      case symbol_kind::S_entriesList: // entriesList
        yylhs.value.emplace< IR::Vector<IR::Entry>* > ();
        break;

      case symbol_kind::S_tupleKeysetExpression: // tupleKeysetExpression
      case symbol_kind::S_simpleExpressionList: // simpleExpressionList
      case symbol_kind::S_expressionList: // expressionList
      case symbol_kind::S_intList: // intList
      case symbol_kind::S_intOrStrList: // intOrStrList
      case symbol_kind::S_strList: // strList
        yylhs.value.emplace< IR::Vector<IR::Expression>* > ();
        break;

      case symbol_kind::S_keyElementList: // keyElementList
        yylhs.value.emplace< IR::Vector<IR::KeyElement>* > ();
        break;

      case symbol_kind::S_methodPrototypes: // methodPrototypes
        yylhs.value.emplace< IR::Vector<IR::Method>* > ();
        break;

      case symbol_kind::S_selectCaseList: // selectCaseList
        yylhs.value.emplace< IR::Vector<IR::SelectCase>* > ();
        break;

      case symbol_kind::S_switchCases: // switchCases
        yylhs.value.emplace< IR::Vector<IR::SwitchCase>* > ();
        break;

      case symbol_kind::S_typeArgumentList: // typeArgumentList
      case symbol_kind::S_realTypeArgumentList: // realTypeArgumentList
        yylhs.value.emplace< IR::Vector<IR::Type>* > ();
        break;

      case symbol_kind::S_optCONST: // optCONST
        yylhs.value.emplace< OptionalConst > ();
        break;

      case symbol_kind::S_UNEXPECTED_TOKEN: // UNEXPECTED_TOKEN
      case symbol_kind::S_END_PRAGMA: // END_PRAGMA
      case symbol_kind::S_LE: // "<="
      case symbol_kind::S_GE: // ">="
      case symbol_kind::S_SHL: // "<<"
      case symbol_kind::S_AND: // "&&"
      case symbol_kind::S_OR: // "||"
      case symbol_kind::S_NE: // "!="
      case symbol_kind::S_EQ: // "=="
      case symbol_kind::S_PLUS: // "+"
      case symbol_kind::S_MINUS: // "-"
      case symbol_kind::S_PLUS_SAT: // "|+|"
      case symbol_kind::S_MINUS_SAT: // "|-|"
      case symbol_kind::S_MUL: // "*"
      case symbol_kind::S_DIV: // "/"
      case symbol_kind::S_MOD: // "%"
      case symbol_kind::S_BIT_OR: // "|"
      case symbol_kind::S_BIT_AND: // "&"
      case symbol_kind::S_BIT_XOR: // "^"
      case symbol_kind::S_COMPLEMENT: // "~"
      case symbol_kind::S_L_BRACKET: // "["
      case symbol_kind::S_R_BRACKET: // "]"
      case symbol_kind::S_L_BRACE: // "{"
      case symbol_kind::S_R_BRACE: // "}"
      case symbol_kind::S_L_ANGLE: // "<"
      case symbol_kind::S_L_ANGLE_ARGS: // L_ANGLE_ARGS
      case symbol_kind::S_R_ANGLE: // ">"
      case symbol_kind::S_R_ANGLE_SHIFT: // R_ANGLE_SHIFT
      case symbol_kind::S_L_PAREN: // "("
      case symbol_kind::S_R_PAREN: // ")"
      case symbol_kind::S_NOT: // "!"
      case symbol_kind::S_COLON: // ":"
      case symbol_kind::S_COMMA: // ","
      case symbol_kind::S_QUESTION: // "?"
      case symbol_kind::S_DOT: // "."
      case symbol_kind::S_ASSIGN: // "="
      case symbol_kind::S_SEMICOLON: // ";"
      case symbol_kind::S_AT: // "@"
      case symbol_kind::S_PP: // "++"
      case symbol_kind::S_DONTCARE: // "_"
      case symbol_kind::S_MASK: // "&&&"
      case symbol_kind::S_RANGE: // ".."
      case symbol_kind::S_TRUE: // TRUE
      case symbol_kind::S_FALSE: // FALSE
      case symbol_kind::S_THIS: // THIS
      case symbol_kind::S_ABSTRACT: // ABSTRACT
      case symbol_kind::S_ACTION: // ACTION
      case symbol_kind::S_ACTIONS: // ACTIONS
      case symbol_kind::S_APPLY: // APPLY
      case symbol_kind::S_BOOL: // BOOL
      case symbol_kind::S_BIT: // BIT
      case symbol_kind::S_CONST: // CONST
      case symbol_kind::S_CONTROL: // CONTROL
      case symbol_kind::S_DEFAULT: // DEFAULT
      case symbol_kind::S_ELSE: // ELSE
      case symbol_kind::S_ENTRIES: // ENTRIES
      case symbol_kind::S_ENUM: // ENUM
      case symbol_kind::S_ERROR: // ERROR
      case symbol_kind::S_EXIT: // EXIT
      case symbol_kind::S_EXTERN: // EXTERN
      case symbol_kind::S_HEADER: // HEADER
      case symbol_kind::S_HEADER_UNION: // HEADER_UNION
      case symbol_kind::S_IF: // IF
      case symbol_kind::S_IN: // IN
      case symbol_kind::S_INOUT: // INOUT
      case symbol_kind::S_INT: // INT
      case symbol_kind::S_KEY: // KEY
      case symbol_kind::S_SELECT: // SELECT
      case symbol_kind::S_MATCH_KIND: // MATCH_KIND
      case symbol_kind::S_TYPE: // TYPE
      case symbol_kind::S_OUT: // OUT
      case symbol_kind::S_PACKAGE: // PACKAGE
      case symbol_kind::S_PARSER: // PARSER
      case symbol_kind::S_PRAGMA: // PRAGMA
      case symbol_kind::S_RETURN: // RETURN
      case symbol_kind::S_STATE: // STATE
      case symbol_kind::S_STRING: // STRING
      case symbol_kind::S_STRUCT: // STRUCT
      case symbol_kind::S_SWITCH: // SWITCH
      case symbol_kind::S_TABLE: // TABLE
      case symbol_kind::S_TRANSITION: // TRANSITION
      case symbol_kind::S_TUPLE: // TUPLE
      case symbol_kind::S_TYPEDEF: // TYPEDEF
      case symbol_kind::S_VARBIT: // VARBIT
      case symbol_kind::S_VALUESET: // VALUESET
      case symbol_kind::S_VOID: // VOID
      case symbol_kind::S_annotationToken: // annotationToken
        yylhs.value.emplace< Token > ();
        break;

      case symbol_kind::S_INTEGER: // INTEGER
        yylhs.value.emplace< UnparsedConstant > ();
        break;

      case symbol_kind::S_IDENTIFIER: // IDENTIFIER
      case symbol_kind::S_TYPE_IDENTIFIER: // TYPE_IDENTIFIER
      case symbol_kind::S_STRING_LITERAL: // STRING_LITERAL
        yylhs.value.emplace< cstring > ();
        break;

      default:
        break;
    }


      // Default location.
      {
        stack_type::slice range (yystack_, yylen);
        YYLLOC_DEFAULT (yylhs.location, range, yylen);
        yyerror_range[1].location = yylhs.location;
      }

      // Perform the reduction.
      YY_REDUCE_PRINT (yyn);
#if YY_EXCEPTIONS
      try
#endif // YY_EXCEPTIONS
        {
          switch (yyn)
            {
  case 2: // start: fragment END_ANNOTATION
#line 348 "parsers/p4/p4parser.ypp"
                              { driver.nodes->push_back(yystack_[1].value.as < IR::Node* > ()->getNode()); YYACCEPT; }
#line 3742 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 4: // fragment: START_EXPRESSION_LIST expressionList
#line 354 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Vector<IR::Expression>* > (); }
#line 3748 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 5: // fragment: START_KV_LIST kvList
#line 355 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::IndexedVector<IR::NamedExpression>* > (); }
#line 3754 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 6: // fragment: START_INTEGER_LIST intList
#line 356 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Vector<IR::Expression>* > (); }
#line 3760 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 7: // fragment: START_INTEGER_OR_STRING_LITERAL_LIST intOrStrList
#line 357 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Vector<IR::Expression>* > (); }
#line 3766 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 8: // fragment: START_STRING_LITERAL_LIST strList
#line 358 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Vector<IR::Expression>* > (); }
#line 3772 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 9: // fragment: START_EXPRESSION expression
#line 361 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 3778 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 10: // fragment: START_INTEGER INTEGER
#line 362 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0); }
#line 3784 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 11: // fragment: START_INTEGER_OR_STRING_LITERAL intOrStr
#line 363 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 3790 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 12: // fragment: START_STRING_LITERAL STRING_LITERAL
#line 364 "parsers/p4/p4parser.ypp"
                                                        { yylhs.value.as < IR::Node* > () = new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 3796 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 13: // fragment: START_EXPRESSION_PAIR expression "," expression
#line 368 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(yystack_[2].value.as < IR::Expression* > ());
          result->push_back(yystack_[0].value.as < IR::Expression* > ());
          yylhs.value.as < IR::Node* > () = result; }
#line 3805 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 14: // fragment: START_INTEGER_PAIR INTEGER "," INTEGER
#line 373 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(parseConstant(yystack_[2].location, yystack_[2].value.as < UnparsedConstant > (), 0));
          result->push_back(parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0));
          yylhs.value.as < IR::Node* > () = result; }
#line 3814 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 15: // fragment: START_STRING_LITERAL_PAIR STRING_LITERAL "," STRING_LITERAL
#line 378 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(new IR::StringLiteral(yystack_[2].location, yystack_[2].value.as < cstring > ()));
          result->push_back(new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ()));
          yylhs.value.as < IR::Node* > () = result; }
#line 3823 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 16: // fragment: START_EXPRESSION_TRIPLE expression "," expression "," expression
#line 385 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(yystack_[4].value.as < IR::Expression* > ());
          result->push_back(yystack_[2].value.as < IR::Expression* > ());
          result->push_back(yystack_[0].value.as < IR::Expression* > ());
          yylhs.value.as < IR::Node* > () = result; }
#line 3833 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 17: // fragment: START_INTEGER_TRIPLE INTEGER "," INTEGER "," INTEGER
#line 391 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(parseConstant(yystack_[4].location, yystack_[4].value.as < UnparsedConstant > (), 0));
          result->push_back(parseConstant(yystack_[2].location, yystack_[2].value.as < UnparsedConstant > (), 0));
          result->push_back(parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0));
          yylhs.value.as < IR::Node* > () = result; }
#line 3843 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 18: // fragment: START_STRING_LITERAL_TRIPLE STRING_LITERAL "," STRING_LITERAL "," STRING_LITERAL
#line 398 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(new IR::StringLiteral(yystack_[4].location, yystack_[4].value.as < cstring > ()));
          result->push_back(new IR::StringLiteral(yystack_[2].location, yystack_[2].value.as < cstring > ()));
          result->push_back(new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ()));
          yylhs.value.as < IR::Node* > () = result; }
#line 3853 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 19: // fragment: START_P4RT_TRANSLATION_ANNOTATION STRING_LITERAL "," p4rtControllerType
#line 406 "parsers/p4/p4parser.ypp"
        { auto* result = new IR::Vector<IR::Expression>();
          result->push_back(new IR::StringLiteral(yystack_[2].location, yystack_[2].value.as < cstring > ()));
          result->push_back(yystack_[0].value.as < IR::Expression* > ());
          yylhs.value.as < IR::Node* > () = result; }
#line 3862 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 20: // p4rtControllerType: STRING
#line 418 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::StringLiteral(yystack_[0].location, ""); }
#line 3868 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 21: // p4rtControllerType: BIT l_angle INTEGER r_angle
#line 420 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::Constant(parseConstantChecked(yystack_[1].location, yystack_[1].value.as < UnparsedConstant > ())); }
#line 3874 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 22: // p4rtControllerType: INTEGER
#line 423 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::Constant(parseConstantChecked(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > ())); }
#line 3880 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 23: // program: input END
#line 426 "parsers/p4/p4parser.ypp"
                    { YYACCEPT; }
#line 3886 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 25: // input: input declaration
#line 430 "parsers/p4/p4parser.ypp"
                         { if (yystack_[0].value.as < IR::Node* > ()) driver.nodes->push_back(yystack_[0].value.as < IR::Node* > ()->getNode()); }
#line 3892 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 26: // input: input ";"
#line 431 "parsers/p4/p4parser.ypp"
                         {}
#line 3898 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 27: // declaration: constantDeclaration
#line 435 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 3904 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 28: // declaration: externDeclaration
#line 436 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Node* > (); }
#line 3910 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 29: // declaration: actionDeclaration
#line 437 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 3916 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 30: // declaration: parserDeclaration
#line 438 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 3922 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 31: // declaration: typeDeclaration
#line 439 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 3928 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 32: // declaration: controlDeclaration
#line 440 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 3934 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 33: // declaration: instantiation
#line 441 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 3940 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 34: // declaration: errorDeclaration
#line 442 "parsers/p4/p4parser.ypp"
                              { driver.onReadErrorDeclaration(yystack_[0].value.as < IR::Type_Error* > ()); yylhs.value.as < IR::Node* > () = nullptr; }
#line 3946 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 35: // declaration: matchKindDeclaration
#line 443 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Node* > (); }
#line 3952 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 36: // declaration: functionDeclaration
#line 444 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Node* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 3958 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 37: // nonTypeName: IDENTIFIER
#line 448 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 3964 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 38: // nonTypeName: APPLY
#line 449 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "apply"); }
#line 3970 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 39: // nonTypeName: KEY
#line 450 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "key"); }
#line 3976 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 40: // nonTypeName: ACTIONS
#line 451 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "actions"); }
#line 3982 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 41: // nonTypeName: STATE
#line 452 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "state"); }
#line 3988 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 42: // nonTypeName: ENTRIES
#line 453 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "entries"); }
#line 3994 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 43: // nonTypeName: TYPE
#line 454 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "type"); }
#line 4000 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 44: // name: nonTypeName
#line 458 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::ID* > () = yystack_[0].value.as < IR::ID* > (); }
#line 4006 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 45: // name: TYPE_IDENTIFIER
#line 459 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 4012 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 46: // nonTableKwName: IDENTIFIER
#line 463 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 4018 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 47: // nonTableKwName: TYPE_IDENTIFIER
#line 464 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 4024 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 48: // nonTableKwName: APPLY
#line 465 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "apply"); }
#line 4030 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 49: // nonTableKwName: STATE
#line 466 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "state"); }
#line 4036 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 50: // nonTableKwName: TYPE
#line 467 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::ID* > () = new IR::ID(yystack_[0].location, "type"); }
#line 4042 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 51: // optCONST: %empty
#line 471 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < OptionalConst > () = OptionalConst{false}; }
#line 4048 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 52: // optCONST: CONST
#line 472 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < OptionalConst > () = OptionalConst{true}; }
#line 4054 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 53: // optAnnotations: %empty
#line 476 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::Annotations* > () = IR::Annotations::empty; }
#line 4060 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 54: // optAnnotations: annotations
#line 477 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < IR::Annotations* > () = new IR::Annotations(yystack_[0].location, *yystack_[0].value.as < IR::Vector<IR::Annotation>* > ()); }
#line 4066 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 55: // annotations: annotation
#line 481 "parsers/p4/p4parser.ypp"
                  {
       yylhs.value.as < IR::Vector<IR::Annotation>* > () = new IR::Vector<IR::Annotation>();
       if (! P4CContext::get().options().isAnnotationDisabled(yystack_[0].value.as < IR::Annotation* > ()))
         yylhs.value.as < IR::Vector<IR::Annotation>* > ()->push_back(yystack_[0].value.as < IR::Annotation* > ()); }
#line 4075 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 56: // annotations: annotations annotation
#line 485 "parsers/p4/p4parser.ypp"
                             {
       yylhs.value.as < IR::Vector<IR::Annotation>* > () = yystack_[1].value.as < IR::Vector<IR::Annotation>* > ();
       if (! P4CContext::get().options().isAnnotationDisabled(yystack_[0].value.as < IR::Annotation* > ()))
          yylhs.value.as < IR::Vector<IR::Annotation>* > ()->push_back(yystack_[0].value.as < IR::Annotation* > ()); }
#line 4084 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 57: // annotation: "@" name
#line 493 "parsers/p4/p4parser.ypp"
        { // Initialize with an empty sequence of annotation tokens so that the
          // annotation node is marked as unparsed.
          IR::Vector<IR::AnnotationToken> body;
          yylhs.value.as < IR::Annotation* > () = new IR::Annotation(yystack_[1].location, *yystack_[0].value.as < IR::ID* > (), body); }
#line 4093 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 58: // annotation: "@" name "(" annotationBody ")"
#line 498 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Annotation* > () = new IR::Annotation(yystack_[4].location, *yystack_[3].value.as < IR::ID* > (), *yystack_[1].value.as < IR::Vector<IR::AnnotationToken>* > ()); }
#line 4099 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 59: // annotation: "@" name "[" expressionList "]"
#line 500 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Annotation* > () = new IR::Annotation(yystack_[4].location, *yystack_[3].value.as < IR::ID* > (), *yystack_[1].value.as < IR::Vector<IR::Expression>* > (), true); }
#line 4105 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 60: // annotation: "@" name "[" kvList "]"
#line 502 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Annotation* > () = new IR::Annotation(yystack_[4].location, *yystack_[3].value.as < IR::ID* > (), *yystack_[1].value.as < IR::IndexedVector<IR::NamedExpression>* > (), true); }
#line 4111 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 61: // annotation: PRAGMA name annotationBody END_PRAGMA
#line 506 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Annotation* > () = new IR::Annotation(yystack_[3].location, *yystack_[2].value.as < IR::ID* > (), *yystack_[1].value.as < IR::Vector<IR::AnnotationToken>* > (), false); }
#line 4117 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 62: // annotationBody: %empty
#line 510 "parsers/p4/p4parser.ypp"
              { yylhs.value.as < IR::Vector<IR::AnnotationToken>* > () = new IR::Vector<IR::AnnotationToken>; }
#line 4123 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 63: // annotationBody: annotationBody "(" annotationBody ")"
#line 512 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Vector<IR::AnnotationToken>* > () = yystack_[3].value.as < IR::Vector<IR::AnnotationToken>* > ();
          yylhs.value.as < IR::Vector<IR::AnnotationToken>* > ()->push_back(new IR::AnnotationToken(yystack_[2].location, yystack_[2].value.as < Token > ().type, yystack_[2].value.as < Token > ().text));
          yylhs.value.as < IR::Vector<IR::AnnotationToken>* > ()->append(*yystack_[1].value.as < IR::Vector<IR::AnnotationToken>* > ());
          yylhs.value.as < IR::Vector<IR::AnnotationToken>* > ()->push_back(new IR::AnnotationToken(yystack_[0].location, yystack_[0].value.as < Token > ().type, yystack_[0].value.as < Token > ().text)); }
#line 4132 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 64: // annotationBody: annotationBody annotationToken
#line 517 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Vector<IR::AnnotationToken>* > () = yystack_[1].value.as < IR::Vector<IR::AnnotationToken>* > ();
          yylhs.value.as < IR::Vector<IR::AnnotationToken>* > ()->push_back(new IR::AnnotationToken(yystack_[0].location, yystack_[0].value.as < Token > ().type, yystack_[0].value.as < Token > ().text, yystack_[0].value.as < Token > ().unparsedConstant)); }
#line 4139 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 65: // annotationToken: UNEXPECTED_TOKEN
#line 522 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4145 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 66: // annotationToken: ABSTRACT
#line 523 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4151 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 67: // annotationToken: ACTION
#line 524 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4157 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 68: // annotationToken: ACTIONS
#line 525 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4163 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 69: // annotationToken: APPLY
#line 526 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4169 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 70: // annotationToken: BOOL
#line 527 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4175 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 71: // annotationToken: BIT
#line 528 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4181 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 72: // annotationToken: CONST
#line 529 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4187 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 73: // annotationToken: CONTROL
#line 530 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4193 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 74: // annotationToken: DEFAULT
#line 531 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4199 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 75: // annotationToken: ELSE
#line 532 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4205 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 76: // annotationToken: ENTRIES
#line 533 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4211 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 77: // annotationToken: ENUM
#line 534 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4217 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 78: // annotationToken: ERROR
#line 535 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4223 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 79: // annotationToken: EXIT
#line 536 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4229 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 80: // annotationToken: EXTERN
#line 537 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4235 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 81: // annotationToken: FALSE
#line 538 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4241 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 82: // annotationToken: HEADER
#line 539 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4247 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 83: // annotationToken: HEADER_UNION
#line 540 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4253 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 84: // annotationToken: IF
#line 541 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4259 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 85: // annotationToken: IN
#line 542 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4265 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 86: // annotationToken: INOUT
#line 543 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4271 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 87: // annotationToken: INT
#line 544 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4277 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 88: // annotationToken: KEY
#line 545 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4283 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 89: // annotationToken: MATCH_KIND
#line 546 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4289 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 90: // annotationToken: TYPE
#line 547 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4295 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 91: // annotationToken: OUT
#line 548 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4301 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 92: // annotationToken: PARSER
#line 549 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4307 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 93: // annotationToken: PACKAGE
#line 550 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4313 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 94: // annotationToken: PRAGMA
#line 551 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4319 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 95: // annotationToken: RETURN
#line 552 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4325 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 96: // annotationToken: SELECT
#line 553 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4331 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 97: // annotationToken: STATE
#line 554 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4337 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 98: // annotationToken: STRING
#line 555 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4343 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 99: // annotationToken: STRUCT
#line 556 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4349 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 100: // annotationToken: SWITCH
#line 557 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4355 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 101: // annotationToken: TABLE
#line 558 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4361 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 102: // annotationToken: THIS
#line 559 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4367 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 103: // annotationToken: TRANSITION
#line 560 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4373 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 104: // annotationToken: TRUE
#line 561 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4379 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 105: // annotationToken: TUPLE
#line 562 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4385 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 106: // annotationToken: TYPEDEF
#line 563 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4391 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 107: // annotationToken: VARBIT
#line 564 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4397 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 108: // annotationToken: VALUESET
#line 565 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4403 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 109: // annotationToken: VOID
#line 566 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4409 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 110: // annotationToken: "_"
#line 567 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4415 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 111: // annotationToken: IDENTIFIER
#line 569 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = Token(token::TOK_IDENTIFIER, yystack_[0].value.as < cstring > ()); }
#line 4421 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 112: // annotationToken: TYPE_IDENTIFIER
#line 570 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = Token(token::TOK_TYPE_IDENTIFIER, yystack_[0].value.as < cstring > ()); }
#line 4427 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 113: // annotationToken: STRING_LITERAL
#line 571 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = Token(token::TOK_STRING_LITERAL, yystack_[0].value.as < cstring > ()); }
#line 4433 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 114: // annotationToken: INTEGER
#line 572 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = Token(token::TOK_INTEGER, yystack_[0].value.as < UnparsedConstant > ()); }
#line 4439 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 115: // annotationToken: "&&&"
#line 574 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4445 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 116: // annotationToken: ".."
#line 575 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4451 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 117: // annotationToken: "<<"
#line 576 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4457 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 118: // annotationToken: "&&"
#line 577 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4463 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 119: // annotationToken: "||"
#line 578 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4469 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 120: // annotationToken: "=="
#line 579 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4475 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 121: // annotationToken: "!="
#line 580 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4481 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 122: // annotationToken: ">="
#line 581 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4487 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 123: // annotationToken: "<="
#line 582 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4493 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 124: // annotationToken: "++"
#line 583 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4499 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 125: // annotationToken: "+"
#line 585 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4505 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 126: // annotationToken: "|+|"
#line 586 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4511 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 127: // annotationToken: "-"
#line 587 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4517 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 128: // annotationToken: "|-|"
#line 588 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4523 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 129: // annotationToken: "*"
#line 589 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4529 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 130: // annotationToken: "/"
#line 590 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4535 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 131: // annotationToken: "%"
#line 591 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4541 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 132: // annotationToken: "|"
#line 593 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4547 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 133: // annotationToken: "&"
#line 594 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4553 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 134: // annotationToken: "^"
#line 595 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4559 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 135: // annotationToken: "~"
#line 596 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4565 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 136: // annotationToken: "["
#line 603 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4571 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 137: // annotationToken: "]"
#line 604 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4577 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 138: // annotationToken: "{"
#line 605 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4583 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 139: // annotationToken: "}"
#line 606 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4589 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 140: // annotationToken: "<"
#line 607 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4595 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 141: // annotationToken: L_ANGLE_ARGS
#line 608 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4601 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 142: // annotationToken: ">"
#line 609 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4607 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 143: // annotationToken: R_ANGLE_SHIFT
#line 610 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4613 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 144: // annotationToken: "!"
#line 612 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4619 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 145: // annotationToken: ":"
#line 613 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4625 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 146: // annotationToken: ","
#line 614 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4631 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 147: // annotationToken: "?"
#line 615 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4637 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 148: // annotationToken: "."
#line 616 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4643 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 149: // annotationToken: "="
#line 617 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4649 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 150: // annotationToken: ";"
#line 618 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4655 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 151: // annotationToken: "@"
#line 619 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < Token > () = yystack_[0].value.as < Token > (); }
#line 4661 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 152: // kvList: kvPair
#line 623 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::IndexedVector<IR::NamedExpression>* > () = new IR::IndexedVector<IR::NamedExpression>; yylhs.value.as < IR::IndexedVector<IR::NamedExpression>* > ()->push_back(yystack_[0].value.as < IR::NamedExpression* > ()); }
#line 4667 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 153: // kvList: kvList "," kvPair
#line 624 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::IndexedVector<IR::NamedExpression>* > () = yystack_[2].value.as < IR::IndexedVector<IR::NamedExpression>* > (); yylhs.value.as < IR::IndexedVector<IR::NamedExpression>* > ()->push_back(yystack_[0].value.as < IR::NamedExpression* > ()); }
#line 4673 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 154: // kvPair: name "=" expression
#line 628 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::NamedExpression* > () = new IR::NamedExpression(yystack_[2].location, *yystack_[2].value.as < IR::ID* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 4679 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 155: // parameterList: %empty
#line 632 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::IndexedVector<IR::Parameter>* > () = new IR::IndexedVector<IR::Parameter>(); }
#line 4685 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 156: // parameterList: nonEmptyParameterList
#line 633 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::IndexedVector<IR::Parameter>* > () = yystack_[0].value.as < IR::IndexedVector<IR::Parameter>* > (); }
#line 4691 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 157: // nonEmptyParameterList: parameter
#line 637 "parsers/p4/p4parser.ypp"
                                          { yylhs.value.as < IR::IndexedVector<IR::Parameter>* > () = new IR::IndexedVector<IR::Parameter>();
                                            yylhs.value.as < IR::IndexedVector<IR::Parameter>* > ()->push_back(yystack_[0].value.as < IR::Parameter* > ()); }
#line 4698 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 158: // nonEmptyParameterList: nonEmptyParameterList "," parameter
#line 639 "parsers/p4/p4parser.ypp"
                                          { yylhs.value.as < IR::IndexedVector<IR::Parameter>* > () = yystack_[2].value.as < IR::IndexedVector<IR::Parameter>* > (); yylhs.value.as < IR::IndexedVector<IR::Parameter>* > ()->push_back(yystack_[0].value.as < IR::Parameter* > ()); }
#line 4704 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 159: // parameter: optAnnotations direction typeRef name
#line 643 "parsers/p4/p4parser.ypp"
                                            { yylhs.value.as < IR::Parameter* > () = new IR::Parameter(yystack_[0].location, *yystack_[0].value.as < IR::ID* > (), yystack_[3].value.as < IR::Annotations* > (), yystack_[2].value.as < IR::Direction > (), yystack_[1].value.as < ConstType* > (), nullptr); }
#line 4710 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 160: // parameter: optAnnotations direction typeRef name "=" expression
#line 644 "parsers/p4/p4parser.ypp"
                                                           { yylhs.value.as < IR::Parameter* > () = new IR::Parameter(yystack_[2].location, *yystack_[2].value.as < IR::ID* > (), yystack_[5].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::Direction > (), yystack_[3].value.as < ConstType* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 4716 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 161: // direction: IN
#line 648 "parsers/p4/p4parser.ypp"
                   { yylhs.value.as < IR::Direction > () = IR::Direction::In; }
#line 4722 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 162: // direction: OUT
#line 649 "parsers/p4/p4parser.ypp"
                   { yylhs.value.as < IR::Direction > () = IR::Direction::Out; }
#line 4728 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 163: // direction: INOUT
#line 650 "parsers/p4/p4parser.ypp"
                   { yylhs.value.as < IR::Direction > () = IR::Direction::InOut; }
#line 4734 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 164: // direction: %empty
#line 651 "parsers/p4/p4parser.ypp"
                   { yylhs.value.as < IR::Direction > () = IR::Direction::None; }
#line 4740 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 165: // $@1: %empty
#line 655 "parsers/p4/p4parser.ypp"
                                  { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), false); }
#line 4746 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 166: // $@2: %empty
#line 656 "parsers/p4/p4parser.ypp"
                        {
          if (!yystack_[0].value.as < IR::TypeParameters* > ()->empty()) driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
          driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 4754 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 167: // packageTypeDeclaration: optAnnotations PACKAGE name $@1 optTypeParameters $@2 "(" parameterList ")"
#line 659 "parsers/p4/p4parser.ypp"
                                   {
          driver.structure->declareParameters(yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
          auto pl = new IR::ParameterList(yystack_[1].location, *yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
          yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Package(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[8].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::TypeParameters* > (), pl); }
#line 4763 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 168: // instantiation: annotations typeRef "(" argumentList ")" name ";"
#line 667 "parsers/p4/p4parser.ypp"
                     { yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Instance(yystack_[1].location, *yystack_[1].value.as < IR::ID* > (), new IR::Annotations(*yystack_[6].value.as < IR::Vector<IR::Annotation>* > ()),
                                                         yystack_[5].value.as < ConstType* > (), yystack_[3].value.as < IR::Vector<IR::Argument>* > ());
                       driver.structure->declareObject(*yystack_[1].value.as < IR::ID* > (), yystack_[5].value.as < ConstType* > ()->toString()); }
#line 4771 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 169: // instantiation: typeRef "(" argumentList ")" name ";"
#line 671 "parsers/p4/p4parser.ypp"
                     { yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Instance(yystack_[1].location, *yystack_[1].value.as < IR::ID* > (), yystack_[5].value.as < ConstType* > (), yystack_[3].value.as < IR::Vector<IR::Argument>* > ());
                       driver.structure->declareObject(*yystack_[1].value.as < IR::ID* > (), yystack_[5].value.as < ConstType* > ()->toString()); }
#line 4778 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 170: // instantiation: annotations typeRef "(" argumentList ")" name "=" objInitializer ";"
#line 675 "parsers/p4/p4parser.ypp"
                     { yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Instance(yystack_[3].location, *yystack_[3].value.as < IR::ID* > (), new IR::Annotations(*yystack_[8].value.as < IR::Vector<IR::Annotation>* > ()),
                                                         yystack_[7].value.as < ConstType* > (), yystack_[5].value.as < IR::Vector<IR::Argument>* > (), yystack_[1].value.as < IR::BlockStatement* > ());
                       driver.structure->declareObject(*yystack_[3].value.as < IR::ID* > (), yystack_[7].value.as < ConstType* > ()->toString()); }
#line 4786 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 171: // instantiation: typeRef "(" argumentList ")" name "=" objInitializer ";"
#line 680 "parsers/p4/p4parser.ypp"
                     { yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Instance(yystack_[3].location, *yystack_[3].value.as < IR::ID* > (), yystack_[7].value.as < ConstType* > (), yystack_[5].value.as < IR::Vector<IR::Argument>* > (), yystack_[1].value.as < IR::BlockStatement* > ());
                       driver.structure->declareObject(*yystack_[3].value.as < IR::ID* > (), yystack_[7].value.as < ConstType* > ()->toString()); }
#line 4793 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 172: // $@3: %empty
#line 686 "parsers/p4/p4parser.ypp"
          { driver.structure->pushNamespace(yystack_[0].location, false); }
#line 4799 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 173: // objInitializer: "{" $@3 objDeclarations "}"
#line 687 "parsers/p4/p4parser.ypp"
                               { driver.structure->pop();
                                 yylhs.value.as < IR::BlockStatement* > () = new IR::BlockStatement(yystack_[3].location+yystack_[0].location, *yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > ()); }
#line 4806 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 174: // objDeclarations: %empty
#line 692 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > () = new IR::IndexedVector<IR::StatOrDecl>(); }
#line 4812 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 175: // objDeclarations: objDeclarations objDeclaration
#line 693 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > () = yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > (); yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > ()->push_back(yystack_[0].value.as < IR::Declaration* > ()); }
#line 4818 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 176: // objDeclaration: functionDeclaration
#line 697 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4824 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 177: // objDeclaration: instantiation
#line 698 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4830 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 178: // optConstructorParameters: %empty
#line 702 "parsers/p4/p4parser.ypp"
                             { yylhs.value.as < IR::IndexedVector<IR::Parameter>* > () = new IR::IndexedVector<IR::Parameter>(); }
#line 4836 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 179: // optConstructorParameters: "(" parameterList ")"
#line 703 "parsers/p4/p4parser.ypp"
                             { yylhs.value.as < IR::IndexedVector<IR::Parameter>* > () = yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > (); }
#line 4842 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 180: // dotPrefix: "."
#line 707 "parsers/p4/p4parser.ypp"
                               { driver.structure->startAbsolutePath(); }
#line 4848 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 181: // parserDeclaration: parserTypeDeclaration optConstructorParameters "{" parserLocalElements parserStates "}"
#line 715 "parsers/p4/p4parser.ypp"
                             { driver.structure->pop();
                               auto pl = new IR::ParameterList(yystack_[4].location, *yystack_[4].value.as < IR::IndexedVector<IR::Parameter>* > ());
                               yylhs.value.as < IR::Type_Declaration* > () = new IR::P4Parser(yystack_[5].value.as < IR::Type_Parser* > ()->name.srcInfo, yystack_[5].value.as < IR::Type_Parser* > ()->name,
                                                     yystack_[5].value.as < IR::Type_Parser* > (), pl, *yystack_[2].value.as < IR::IndexedVector<IR::Declaration>* > (), *yystack_[1].value.as < IR::IndexedVector<IR::ParserState>* > ());}
#line 4857 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 182: // parserLocalElements: %empty
#line 722 "parsers/p4/p4parser.ypp"
                                             { yylhs.value.as < IR::IndexedVector<IR::Declaration>* > () = new IR::IndexedVector<IR::Declaration>(); }
#line 4863 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 183: // parserLocalElements: parserLocalElements parserLocalElement
#line 723 "parsers/p4/p4parser.ypp"
                                             { yylhs.value.as < IR::IndexedVector<IR::Declaration>* > () = yystack_[1].value.as < IR::IndexedVector<IR::Declaration>* > (); yylhs.value.as < IR::IndexedVector<IR::Declaration>* > ()->push_back(yystack_[0].value.as < IR::Declaration* > ()); }
#line 4869 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 184: // parserLocalElement: constantDeclaration
#line 727 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4875 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 185: // parserLocalElement: instantiation
#line 728 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4881 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 186: // parserLocalElement: variableDeclaration
#line 729 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4887 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 187: // parserLocalElement: valueSetDeclaration
#line 730 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4893 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 188: // $@4: %empty
#line 735 "parsers/p4/p4parser.ypp"
                          { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), true); }
#line 4899 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 189: // $@5: %empty
#line 736 "parsers/p4/p4parser.ypp"
                          { if (!yystack_[0].value.as < IR::TypeParameters* > ()->empty()) driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
                            driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 4906 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 190: // parserTypeDeclaration: optAnnotations PARSER name $@4 optTypeParameters $@5 "(" parameterList ")"
#line 738 "parsers/p4/p4parser.ypp"
                              { driver.structure->declareParameters(yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                auto pl = new IR::ParameterList(yystack_[1].location, *yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                yylhs.value.as < IR::Type_Parser* > () = new IR::Type_Parser(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[8].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::TypeParameters* > (), pl); }
#line 4914 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 191: // parserStates: parserState
#line 744 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::IndexedVector<IR::ParserState>* > () = new IR::IndexedVector<IR::ParserState>();
                                        yylhs.value.as < IR::IndexedVector<IR::ParserState>* > ()->push_back(yystack_[0].value.as < IR::ParserState* > ()); }
#line 4921 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 192: // parserStates: parserStates parserState
#line 746 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::IndexedVector<IR::ParserState>* > () = yystack_[1].value.as < IR::IndexedVector<IR::ParserState>* > (); yylhs.value.as < IR::IndexedVector<IR::ParserState>* > ()->push_back(yystack_[0].value.as < IR::ParserState* > ()); }
#line 4927 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 193: // $@6: %empty
#line 750 "parsers/p4/p4parser.ypp"
                                { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), false); }
#line 4933 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 194: // parserState: optAnnotations STATE name $@6 "{" parserStatements transitionStatement "}"
#line 752 "parsers/p4/p4parser.ypp"
                                      { driver.structure->pop();
                                        yylhs.value.as < IR::ParserState* > () = new IR::ParserState(yystack_[5].location, *yystack_[5].value.as < IR::ID* > (), yystack_[7].value.as < IR::Annotations* > (), *yystack_[2].value.as < IR::IndexedVector<IR::StatOrDecl>* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 4940 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 195: // parserStatements: %empty
#line 757 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > () = new IR::IndexedVector<IR::StatOrDecl>(); }
#line 4946 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 196: // parserStatements: parserStatements parserStatement
#line 758 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > () = yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > (); yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > ()->push_back(yystack_[0].value.as < IR::StatOrDecl* > ()); }
#line 4952 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 197: // parserStatement: assignmentOrMethodCallStatement
#line 762 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 4958 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 198: // parserStatement: directApplication
#line 763 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 4964 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 199: // parserStatement: emptyStatement
#line 764 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 4970 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 200: // parserStatement: variableDeclaration
#line 765 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4976 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 201: // parserStatement: constantDeclaration
#line 766 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 4982 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 202: // parserStatement: parserBlockStatement
#line 767 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::BlockStatement* > (); }
#line 4988 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 203: // parserStatement: conditionalStatement
#line 768 "parsers/p4/p4parser.ypp"
                                      { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 4994 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 204: // $@7: %empty
#line 772 "parsers/p4/p4parser.ypp"
                         { driver.structure->pushNamespace(yystack_[0].location, false); }
#line 5000 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 205: // parserBlockStatement: optAnnotations "{" $@7 parserStatements "}"
#line 773 "parsers/p4/p4parser.ypp"
                           { driver.structure->pop(); yylhs.value.as < IR::BlockStatement* > () = new IR::BlockStatement(yystack_[4].location+yystack_[0].location, yystack_[4].value.as < IR::Annotations* > (), *yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > ()); }
#line 5006 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 206: // transitionStatement: %empty
#line 777 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = nullptr; }
#line 5012 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 207: // transitionStatement: TRANSITION stateExpression
#line 778 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 5018 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 208: // stateExpression: name ";"
#line 782 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(*yystack_[1].value.as < IR::ID* > ()); }
#line 5024 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 209: // stateExpression: selectExpression
#line 783 "parsers/p4/p4parser.ypp"
                       { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 5030 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 210: // selectExpression: SELECT "(" expressionList ")" "{" selectCaseList "}"
#line 788 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Expression* > () = new IR::SelectExpression(yystack_[6].location + yystack_[0].location,
                                     new IR::ListExpression(yystack_[4].location, *yystack_[4].value.as < IR::Vector<IR::Expression>* > ()), std::move(*yystack_[1].value.as < IR::Vector<IR::SelectCase>* > ())); }
#line 5037 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 211: // selectCaseList: %empty
#line 793 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::SelectCase>* > () = new IR::Vector<IR::SelectCase>(); }
#line 5043 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 212: // selectCaseList: selectCaseList selectCase
#line 794 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::SelectCase>* > () = yystack_[1].value.as < IR::Vector<IR::SelectCase>* > (); yylhs.value.as < IR::Vector<IR::SelectCase>* > ()->push_back(yystack_[0].value.as < IR::SelectCase* > ()); }
#line 5049 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 213: // selectCase: keysetExpression ":" name ";"
#line 799 "parsers/p4/p4parser.ypp"
      { auto expr = new IR::PathExpression(*yystack_[1].value.as < IR::ID* > ());
        yylhs.value.as < IR::SelectCase* > () = new IR::SelectCase(yystack_[3].location + yystack_[1].location, yystack_[3].value.as < IR::Expression* > (), expr); }
#line 5056 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 214: // keysetExpression: tupleKeysetExpression
#line 804 "parsers/p4/p4parser.ypp"
                                { yylhs.value.as < IR::Expression* > () = new IR::ListExpression(yystack_[0].location, *yystack_[0].value.as < IR::Vector<IR::Expression>* > ()); }
#line 5062 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 215: // keysetExpression: simpleKeysetExpression
#line 805 "parsers/p4/p4parser.ypp"
                                { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 5068 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 216: // tupleKeysetExpression: "(" simpleKeysetExpression "," simpleExpressionList ")"
#line 810 "parsers/p4/p4parser.ypp"
                                { yylhs.value.as < IR::Vector<IR::Expression>* > () = yystack_[1].value.as < IR::Vector<IR::Expression>* > (); yystack_[1].value.as < IR::Vector<IR::Expression>* > ()->insert(yystack_[1].value.as < IR::Vector<IR::Expression>* > ()->begin(), yystack_[3].value.as < IR::Expression* > ()); }
#line 5074 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 217: // tupleKeysetExpression: "(" reducedSimpleKeysetExpression ")"
#line 811 "parsers/p4/p4parser.ypp"
                                            { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>(); yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[1].value.as < IR::Expression* > ()); }
#line 5080 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 218: // simpleExpressionList: simpleKeysetExpression
#line 815 "parsers/p4/p4parser.ypp"
                             { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>(); yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[0].value.as < IR::Expression* > ()); }
#line 5086 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 219: // simpleExpressionList: simpleExpressionList "," simpleKeysetExpression
#line 816 "parsers/p4/p4parser.ypp"
                                                      { yylhs.value.as < IR::Vector<IR::Expression>* > () = yystack_[2].value.as < IR::Vector<IR::Expression>* > (); yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[0].value.as < IR::Expression* > ()); }
#line 5092 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 220: // reducedSimpleKeysetExpression: expression "&&&" expression
#line 821 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::Mask(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 5098 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 221: // reducedSimpleKeysetExpression: expression ".." expression
#line 822 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::Range(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 5104 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 222: // reducedSimpleKeysetExpression: DEFAULT
#line 823 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::DefaultExpression(yystack_[0].location); }
#line 5110 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 223: // reducedSimpleKeysetExpression: "_"
#line 824 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::DefaultExpression(yystack_[0].location); }
#line 5116 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 224: // simpleKeysetExpression: expression
#line 828 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 5122 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 225: // simpleKeysetExpression: expression "&&&" expression
#line 829 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::Mask(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 5128 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 226: // simpleKeysetExpression: expression ".." expression
#line 830 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::Range(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 5134 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 227: // simpleKeysetExpression: DEFAULT
#line 831 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::DefaultExpression(yystack_[0].location); }
#line 5140 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 228: // simpleKeysetExpression: "_"
#line 832 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < IR::Expression* > () = new IR::DefaultExpression(yystack_[0].location); }
#line 5146 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 229: // valueSetDeclaration: optAnnotations VALUESET l_angle baseType r_angle "(" expression ")" name ";"
#line 838 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Declaration* > () = new IR::P4ValueSet(yystack_[1].location, *yystack_[1].value.as < IR::ID* > (), yystack_[9].value.as < IR::Annotations* > (), yystack_[6].value.as < ConstType* > (), yystack_[3].value.as < IR::Expression* > ()); }
#line 5152 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 230: // valueSetDeclaration: optAnnotations VALUESET l_angle tupleType r_angle "(" expression ")" name ";"
#line 841 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Declaration* > () = new IR::P4ValueSet(yystack_[1].location, *yystack_[1].value.as < IR::ID* > (), yystack_[9].value.as < IR::Annotations* > (), yystack_[6].value.as < ConstType* > (), yystack_[3].value.as < IR::Expression* > ()); }
#line 5158 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 231: // valueSetDeclaration: optAnnotations VALUESET l_angle typeName r_angle "(" expression ")" name ";"
#line 844 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Declaration* > () = new IR::P4ValueSet(yystack_[1].location, *yystack_[1].value.as < IR::ID* > (), yystack_[9].value.as < IR::Annotations* > (), yystack_[6].value.as < IR::Type_Name* > (), yystack_[3].value.as < IR::Expression* > ()); }
#line 5164 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 232: // controlDeclaration: controlTypeDeclaration optConstructorParameters "{" controlLocalDeclarations APPLY controlBody "}"
#line 852 "parsers/p4/p4parser.ypp"
        { driver.structure->pop();
          auto pl = new IR::ParameterList(yystack_[5].location, *yystack_[5].value.as < IR::IndexedVector<IR::Parameter>* > ());
          yylhs.value.as < IR::Type_Declaration* > () = new IR::P4Control(yystack_[6].value.as < IR::Type_Control* > ()->name.srcInfo, yystack_[6].value.as < IR::Type_Control* > ()->name, yystack_[6].value.as < IR::Type_Control* > (), pl, *yystack_[3].value.as < IR::IndexedVector<IR::Declaration>* > (), yystack_[1].value.as < IR::BlockStatement* > ()); }
#line 5172 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 233: // $@8: %empty
#line 859 "parsers/p4/p4parser.ypp"
                     { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), true); }
#line 5178 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 234: // $@9: %empty
#line 860 "parsers/p4/p4parser.ypp"
                          { if (!yystack_[0].value.as < IR::TypeParameters* > ()->empty()) driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
                            driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 5185 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 235: // controlTypeDeclaration: optAnnotations CONTROL name $@8 optTypeParameters $@9 "(" parameterList ")"
#line 862 "parsers/p4/p4parser.ypp"
                              { driver.structure->declareParameters(yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                auto pl = new IR::ParameterList(yystack_[1].location, *yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                yylhs.value.as < IR::Type_Control* > () = new IR::Type_Control(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[8].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::TypeParameters* > (), pl); }
#line 5193 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 236: // controlLocalDeclarations: %empty
#line 868 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < IR::IndexedVector<IR::Declaration>* > () = new IR::IndexedVector<IR::Declaration>(); }
#line 5199 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 237: // controlLocalDeclarations: controlLocalDeclarations controlLocalDeclaration
#line 869 "parsers/p4/p4parser.ypp"
                                                       { yylhs.value.as < IR::IndexedVector<IR::Declaration>* > () = yystack_[1].value.as < IR::IndexedVector<IR::Declaration>* > (); yylhs.value.as < IR::IndexedVector<IR::Declaration>* > ()->push_back(yystack_[0].value.as < IR::Declaration* > ()); }
#line 5205 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 238: // controlLocalDeclaration: constantDeclaration
#line 873 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 5211 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 239: // controlLocalDeclaration: actionDeclaration
#line 874 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 5217 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 240: // controlLocalDeclaration: tableDeclaration
#line 875 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 5223 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 241: // controlLocalDeclaration: instantiation
#line 876 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 5229 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 242: // controlLocalDeclaration: variableDeclaration
#line 877 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Declaration* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 5235 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 243: // controlBody: blockStatement
#line 881 "parsers/p4/p4parser.ypp"
                     { yylhs.value.as < IR::BlockStatement* > () = yystack_[0].value.as < IR::BlockStatement* > (); }
#line 5241 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 244: // $@10: %empty
#line 888 "parsers/p4/p4parser.ypp"
                           { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), true); }
#line 5247 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 245: // $@11: %empty
#line 889 "parsers/p4/p4parser.ypp"
                          { if (!yystack_[0].value.as < IR::TypeParameters* > ()->empty()) driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
                            driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 5254 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 246: // externDeclaration: optAnnotations EXTERN nonTypeName $@10 optTypeParameters $@11 "{" methodPrototypes "}"
#line 891 "parsers/p4/p4parser.ypp"
                                 { driver.structure->pop();
                                   yylhs.value.as < IR::Node* > () = new IR::Type_Extern(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[4].value.as < IR::TypeParameters* > (), *yystack_[1].value.as < IR::Vector<IR::Method>* > (), yystack_[8].value.as < IR::Annotations* > ()); }
#line 5261 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 247: // externDeclaration: optAnnotations EXTERN functionPrototype ";"
#line 893 "parsers/p4/p4parser.ypp"
                                                  {
            driver.structure->pop();
            yylhs.value.as < IR::Node* > () = yystack_[1].value.as < IR::Method* > ();
            yystack_[1].value.as < IR::Method* > ()->annotations = yystack_[3].value.as < IR::Annotations* > (); }
#line 5270 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 248: // externDeclaration: optAnnotations EXTERN name ";"
#line 897 "parsers/p4/p4parser.ypp"
                                     {
            // forward declaration;
            driver.structure->pushContainerType(*yystack_[1].value.as < IR::ID* > (), true);
            driver.structure->pop();
            yylhs.value.as < IR::Node* > () = nullptr; }
#line 5280 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 249: // methodPrototypes: %empty
#line 905 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Vector<IR::Method>* > () = new IR::Vector<IR::Method>(); }
#line 5286 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 250: // methodPrototypes: methodPrototypes methodPrototype
#line 906 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Vector<IR::Method>* > () = yystack_[1].value.as < IR::Vector<IR::Method>* > (); yystack_[1].value.as < IR::Vector<IR::Method>* > ()->push_back(yystack_[0].value.as < IR::Method* > ()); }
#line 5292 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 251: // $@12: %empty
#line 911 "parsers/p4/p4parser.ypp"
                               {
            driver.structure->declareObject(*yystack_[1].value.as < IR::ID* > (), yystack_[2].value.as < ConstType* > ()->toString());
            if (!yystack_[0].value.as < IR::TypeParameters* > ()->empty()) driver.structure->markAsTemplate(*yystack_[1].value.as < IR::ID* > ());
            driver.structure->pushNamespace(yystack_[1].location, false);
            driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 5302 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 252: // functionPrototype: typeOrVoid name optTypeParameters $@12 "(" parameterList ")"
#line 916 "parsers/p4/p4parser.ypp"
                              { driver.structure->declareParameters(yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                auto params = new IR::ParameterList(yystack_[1].location, *yystack_[1].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                auto mt = new IR::Type_Method(yystack_[5].location, yystack_[4].value.as < IR::TypeParameters* > (), yystack_[6].value.as < ConstType* > (), params, *yystack_[5].value.as < IR::ID* > ());
                                yylhs.value.as < IR::Method* > () = new IR::Method(yystack_[5].location, *yystack_[5].value.as < IR::ID* > (), mt); }
#line 5311 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 253: // methodPrototype: optAnnotations functionPrototype ";"
#line 923 "parsers/p4/p4parser.ypp"
                                           {
            driver.structure->pop();
            yylhs.value.as < IR::Method* > () = yystack_[1].value.as < IR::Method* > (); yystack_[1].value.as < IR::Method* > ()->annotations = yystack_[2].value.as < IR::Annotations* > (); }
#line 5319 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 254: // methodPrototype: optAnnotations ABSTRACT functionPrototype ";"
#line 926 "parsers/p4/p4parser.ypp"
                                                    {
            driver.structure->pop();
            yylhs.value.as < IR::Method* > () = yystack_[1].value.as < IR::Method* > (); yylhs.value.as < IR::Method* > ()->setAbstract();
            yystack_[1].value.as < IR::Method* > ()->annotations = yystack_[3].value.as < IR::Annotations* > (); }
#line 5328 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 255: // methodPrototype: optAnnotations TYPE_IDENTIFIER "(" parameterList ")" ";"
#line 931 "parsers/p4/p4parser.ypp"
                                        { auto par = new IR::ParameterList(yystack_[2].location, *yystack_[2].value.as < IR::IndexedVector<IR::Parameter>* > ());
                                          auto mt = new IR::Type_Method(yystack_[4].location, par, yystack_[4].value.as < cstring > ());
                                          yylhs.value.as < IR::Method* > () = new IR::Method(yystack_[4].location, IR::ID(yystack_[4].location, yystack_[4].value.as < cstring > ()), mt, yystack_[5].value.as < IR::Annotations* > ()); }
#line 5336 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 256: // typeRef: baseType
#line 939 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5342 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 257: // typeRef: typeName
#line 940 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < IR::Type_Name* > (); }
#line 5348 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 258: // typeRef: specializedType
#line 941 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5354 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 259: // typeRef: headerStackType
#line 942 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5360 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 260: // typeRef: tupleType
#line 943 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5366 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 261: // namedType: typeName
#line 947 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < IR::Type_Name* > (); }
#line 5372 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 262: // namedType: specializedType
#line 948 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5378 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 263: // prefixedType: TYPE_IDENTIFIER
#line 952 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Path* > () = new IR::Path(IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ())); }
#line 5384 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 264: // prefixedType: dotPrefix TYPE_IDENTIFIER
#line 953 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Path* > () = new IR::Path(IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ()), true);
                                         driver.structure->clearPath(); }
#line 5391 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 265: // typeName: prefixedType
#line 958 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Type_Name* > () = new IR::Type_Name(yystack_[0].location, yystack_[0].value.as < IR::Path* > ()); }
#line 5397 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 266: // tupleType: TUPLE l_angle typeArgumentList r_angle
#line 962 "parsers/p4/p4parser.ypp"
                                                { yylhs.value.as < ConstType* > () = new IR::Type_Tuple(yystack_[3].location+yystack_[0].location, *yystack_[1].value.as < IR::Vector<IR::Type>* > ()); }
#line 5403 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 267: // headerStackType: typeName "[" expression "]"
#line 966 "parsers/p4/p4parser.ypp"
                                          { yylhs.value.as < ConstType* > () = new IR::Type_Stack(yystack_[3].location+yystack_[0].location, yystack_[3].value.as < IR::Type_Name* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 5409 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 268: // headerStackType: specializedType "[" expression "]"
#line 967 "parsers/p4/p4parser.ypp"
                                          { yylhs.value.as < ConstType* > () = new IR::Type_Stack(yystack_[3].location+yystack_[0].location, yystack_[3].value.as < ConstType* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 5415 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 269: // specializedType: typeName l_angle typeArgumentList r_angle
#line 971 "parsers/p4/p4parser.ypp"
                                                { yylhs.value.as < ConstType* > () = new IR::Type_Specialized(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Type_Name* > (), yystack_[1].value.as < IR::Vector<IR::Type>* > ()); }
#line 5421 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 270: // baseType: BOOL
#line 975 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < ConstType* > () = IR::Type_Boolean::get(); }
#line 5427 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 271: // baseType: ERROR
#line 976 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < ConstType* > () = new IR::Type_Name(yystack_[0].location, new IR::Path(IR::ID(yystack_[0].location, "error"))); }
#line 5433 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 272: // baseType: BIT
#line 977 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < ConstType* > () = IR::Type::Bits::get(yystack_[0].location, 1); }
#line 5439 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 273: // baseType: STRING
#line 978 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < ConstType* > () = IR::Type::String::get(); }
#line 5445 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 274: // baseType: INT
#line 979 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < ConstType* > () = new IR::Type_InfInt(); }
#line 5451 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 275: // baseType: BIT l_angle INTEGER r_angle
#line 981 "parsers/p4/p4parser.ypp"
      { yylhs.value.as < ConstType* > () = IR::Type::Bits::get(yystack_[3].location+yystack_[0].location, parseConstantChecked(yystack_[1].location, yystack_[1].value.as < UnparsedConstant > ()), false); }
#line 5457 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 276: // baseType: INT l_angle INTEGER r_angle
#line 983 "parsers/p4/p4parser.ypp"
      { yylhs.value.as < ConstType* > () = IR::Type::Bits::get(yystack_[3].location+yystack_[0].location, parseConstantChecked(yystack_[1].location, yystack_[1].value.as < UnparsedConstant > ()), true); }
#line 5463 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 277: // baseType: VARBIT l_angle INTEGER r_angle
#line 985 "parsers/p4/p4parser.ypp"
      { yylhs.value.as < ConstType* > () = IR::Type::Varbits::get(yystack_[3].location+yystack_[0].location, parseConstantChecked(yystack_[1].location, yystack_[1].value.as < UnparsedConstant > ())); }
#line 5469 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 278: // baseType: BIT l_angle "(" expression ")" r_angle
#line 988 "parsers/p4/p4parser.ypp"
      { yylhs.value.as < ConstType* > () = new IR::Type_Bits(yystack_[5].location+yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), false); }
#line 5475 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 279: // baseType: INT l_angle "(" expression ")" r_angle
#line 990 "parsers/p4/p4parser.ypp"
      { yylhs.value.as < ConstType* > () = new IR::Type_Bits(yystack_[5].location+yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), true); }
#line 5481 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 280: // baseType: VARBIT l_angle "(" expression ")" r_angle
#line 992 "parsers/p4/p4parser.ypp"
      { yylhs.value.as < ConstType* > () = new IR::Type_Varbits(yystack_[5].location+yystack_[0].location, yystack_[2].value.as < IR::Expression* > ()); }
#line 5487 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 281: // typeOrVoid: typeRef
#line 996 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5493 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 282: // typeOrVoid: VOID
#line 997 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < ConstType* > () = IR::Type_Void::get(); }
#line 5499 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 283: // typeOrVoid: IDENTIFIER
#line 998 "parsers/p4/p4parser.ypp"
                  { yylhs.value.as < ConstType* > () = new IR::Type_Name(yystack_[0].location, new IR::Path(*(new IR::ID(yystack_[0].location, yystack_[0].value.as < cstring > ())))); }
#line 5505 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 284: // optTypeParameters: %empty
#line 1003 "parsers/p4/p4parser.ypp"
                                { yylhs.value.as < IR::TypeParameters* > () = new IR::TypeParameters(); }
#line 5511 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 285: // optTypeParameters: typeParameters
#line 1004 "parsers/p4/p4parser.ypp"
                                { yylhs.value.as < IR::TypeParameters* > () = yystack_[0].value.as < IR::TypeParameters* > (); }
#line 5517 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 286: // typeParameters: l_angle typeParameterList r_angle
#line 1008 "parsers/p4/p4parser.ypp"
                                        { yylhs.value.as < IR::TypeParameters* > () = new IR::TypeParameters(yystack_[2].location+yystack_[0].location, *yystack_[1].value.as < IR::IndexedVector<IR::Type_Var>* > ()); }
#line 5523 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 287: // typeParameterList: name
#line 1012 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::IndexedVector<IR::Type_Var>* > () = new IR::IndexedVector<IR::Type_Var>();
                                       yylhs.value.as < IR::IndexedVector<IR::Type_Var>* > ()->push_back(new IR::Type_Var(yystack_[0].location, *yystack_[0].value.as < IR::ID* > ())); }
#line 5530 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 288: // typeParameterList: typeParameterList "," name
#line 1014 "parsers/p4/p4parser.ypp"
                                     { (yylhs.value.as < IR::IndexedVector<IR::Type_Var>* > ()=yystack_[2].value.as < IR::IndexedVector<IR::Type_Var>* > ())->push_back(new IR::Type_Var(yystack_[0].location, *yystack_[0].value.as < IR::ID* > ())); }
#line 5536 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 289: // typeArg: typeRef
#line 1018 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5542 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 290: // typeArg: nonTypeName
#line 1019 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = new IR::Type_Name(yystack_[0].location, new IR::Path(*yystack_[0].value.as < IR::ID* > ())); }
#line 5548 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 291: // typeArg: VOID
#line 1021 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = IR::Type_Void::get(); }
#line 5554 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 292: // typeArg: "_"
#line 1022 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = new IR::Type_Dontcare(yystack_[0].location); }
#line 5560 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 293: // typeArgumentList: %empty
#line 1026 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Vector<IR::Type>* > () = new IR::Vector<IR::Type>(); }
#line 5566 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 294: // typeArgumentList: typeArg
#line 1027 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Vector<IR::Type>* > () = new IR::Vector<IR::Type>(); yylhs.value.as < IR::Vector<IR::Type>* > ()->push_back(yystack_[0].value.as < ConstType* > ()); }
#line 5572 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 295: // typeArgumentList: typeArgumentList "," typeArg
#line 1028 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Vector<IR::Type>* > () = yystack_[2].value.as < IR::Vector<IR::Type>* > (); yylhs.value.as < IR::Vector<IR::Type>* > ()->push_back(yystack_[0].value.as < ConstType* > ()); }
#line 5578 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 296: // realTypeArg: typeRef
#line 1032 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = yystack_[0].value.as < ConstType* > (); }
#line 5584 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 297: // realTypeArg: VOID
#line 1033 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = IR::Type_Void::get(); }
#line 5590 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 298: // realTypeArg: "_"
#line 1034 "parsers/p4/p4parser.ypp"
                                  { yylhs.value.as < ConstType* > () = new IR::Type_Dontcare(yystack_[0].location); }
#line 5596 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 299: // realTypeArgumentList: realTypeArg
#line 1040 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Type>* > () = new IR::Vector<IR::Type>(); yylhs.value.as < IR::Vector<IR::Type>* > ()->push_back(yystack_[0].value.as < ConstType* > ()); }
#line 5602 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 300: // realTypeArgumentList: realTypeArgumentList "," typeArg
#line 1041 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Type>* > () = yystack_[2].value.as < IR::Vector<IR::Type>* > (); yylhs.value.as < IR::Vector<IR::Type>* > ()->push_back(yystack_[0].value.as < ConstType* > ()); }
#line 5608 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 301: // typeDeclaration: derivedTypeDeclaration
#line 1045 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Type_Declaration* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 5614 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 302: // typeDeclaration: typedefDeclaration ";"
#line 1046 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Type_Declaration* > () = yystack_[1].value.as < IR::Type_Declaration* > (); }
#line 5620 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 303: // typeDeclaration: parserTypeDeclaration ";"
#line 1047 "parsers/p4/p4parser.ypp"
                                 { driver.structure->pop(); yylhs.value.as < IR::Type_Declaration* > () = yystack_[1].value.as < IR::Type_Parser* > (); }
#line 5626 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 304: // typeDeclaration: controlTypeDeclaration ";"
#line 1048 "parsers/p4/p4parser.ypp"
                                 { driver.structure->pop(); yylhs.value.as < IR::Type_Declaration* > () = yystack_[1].value.as < IR::Type_Control* > (); }
#line 5632 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 305: // typeDeclaration: packageTypeDeclaration ";"
#line 1049 "parsers/p4/p4parser.ypp"
                                 { driver.structure->pop(); yylhs.value.as < IR::Type_Declaration* > () = yystack_[1].value.as < IR::Type_Declaration* > (); }
#line 5638 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 306: // derivedTypeDeclaration: headerTypeDeclaration
#line 1053 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Type_Declaration* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 5644 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 307: // derivedTypeDeclaration: headerUnionDeclaration
#line 1054 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Type_Declaration* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 5650 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 308: // derivedTypeDeclaration: structTypeDeclaration
#line 1055 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Type_Declaration* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 5656 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 309: // derivedTypeDeclaration: enumDeclaration
#line 1056 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Type_Declaration* > () = yystack_[0].value.as < IR::Type_Declaration* > (); }
#line 5662 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 310: // $@13: %empty
#line 1060 "parsers/p4/p4parser.ypp"
                                 { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), true); }
#line 5668 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 311: // $@14: %empty
#line 1060 "parsers/p4/p4parser.ypp"
                                                                                                       {
        // type parameters are experimental
        driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
        driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 5677 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 312: // headerTypeDeclaration: optAnnotations HEADER name $@13 optTypeParameters $@14 "{" structFieldList "}"
#line 1064 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Header(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[8].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::TypeParameters* > (), *yystack_[1].value.as < IR::IndexedVector<IR::StructField>* > ());
                                driver.structure->pop(); }
#line 5684 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 313: // $@15: %empty
#line 1069 "parsers/p4/p4parser.ypp"
                                  { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), true); }
#line 5690 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 314: // $@16: %empty
#line 1069 "parsers/p4/p4parser.ypp"
                                                                                                        {
        // type parameters are experimental
        driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
        driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 5699 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 315: // structTypeDeclaration: optAnnotations STRUCT name $@15 optTypeParameters $@16 "{" structFieldList "}"
#line 1073 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Struct(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[8].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::TypeParameters* > (), *yystack_[1].value.as < IR::IndexedVector<IR::StructField>* > ());
                                driver.structure->pop(); }
#line 5706 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 316: // $@17: %empty
#line 1078 "parsers/p4/p4parser.ypp"
                                       { driver.structure->pushContainerType(*yystack_[0].value.as < IR::ID* > (), true); }
#line 5712 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 317: // $@18: %empty
#line 1078 "parsers/p4/p4parser.ypp"
                                                                                                             {
        // type parameters are experimental
        driver.structure->markAsTemplate(*yystack_[2].value.as < IR::ID* > ());
        driver.structure->declareTypes(&yystack_[0].value.as < IR::TypeParameters* > ()->parameters); }
#line 5721 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 318: // headerUnionDeclaration: optAnnotations HEADER_UNION name $@17 optTypeParameters $@18 "{" structFieldList "}"
#line 1082 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_HeaderUnion(yystack_[6].location, *yystack_[6].value.as < IR::ID* > (), yystack_[8].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::TypeParameters* > (), *yystack_[1].value.as < IR::IndexedVector<IR::StructField>* > ());
                                driver.structure->pop(); }
#line 5728 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 319: // structFieldList: %empty
#line 1087 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::IndexedVector<IR::StructField>* > () = new IR::IndexedVector<IR::StructField>(); }
#line 5734 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 320: // structFieldList: structFieldList structField
#line 1088 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::IndexedVector<IR::StructField>* > () = yystack_[1].value.as < IR::IndexedVector<IR::StructField>* > (); yystack_[1].value.as < IR::IndexedVector<IR::StructField>* > ()->push_back(yystack_[0].value.as < IR::StructField* > ()); }
#line 5740 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 321: // structField: optAnnotations typeRef name ";"
#line 1092 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::StructField* > () = new IR::StructField(yystack_[1].location, *yystack_[1].value.as < IR::ID* > (), yystack_[3].value.as < IR::Annotations* > (), yystack_[2].value.as < ConstType* > ()); }
#line 5746 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 322: // $@19: %empty
#line 1097 "parsers/p4/p4parser.ypp"
                  { driver.structure->declareType(*yystack_[0].value.as < IR::ID* > ()); }
#line 5752 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 323: // enumDeclaration: optAnnotations ENUM name $@19 "{" identifierList "}"
#line 1098 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Enum(yystack_[4].location, *yystack_[4].value.as < IR::ID* > (), *yystack_[1].value.as < IR::IndexedVector<IR::Declaration_ID>* > ()); }
#line 5758 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 324: // $@20: %empty
#line 1099 "parsers/p4/p4parser.ypp"
                                       { driver.structure->declareType(*yystack_[0].value.as < IR::ID* > ()); }
#line 5764 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 325: // enumDeclaration: optAnnotations ENUM typeRef name $@20 "{" specifiedIdentifierList "}"
#line 1100 "parsers/p4/p4parser.ypp"
                                         {
              auto type = yystack_[5].value.as < ConstType* > ();
              yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_SerEnum(yystack_[4].location, *yystack_[4].value.as < IR::ID* > (), type, *yystack_[1].value.as < IR::IndexedVector<IR::SerEnumMember>* > ());
	  }
#line 5773 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 326: // specifiedIdentifierList: specifiedIdentifier
#line 1107 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::IndexedVector<IR::SerEnumMember>* > () = new IR::IndexedVector<IR::SerEnumMember>(); yylhs.value.as < IR::IndexedVector<IR::SerEnumMember>* > ()->push_back(yystack_[0].value.as < IR::SerEnumMember* > ()); }
#line 5779 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 327: // specifiedIdentifierList: specifiedIdentifierList "," specifiedIdentifier
#line 1108 "parsers/p4/p4parser.ypp"
                                                      { yylhs.value.as < IR::IndexedVector<IR::SerEnumMember>* > () = yystack_[2].value.as < IR::IndexedVector<IR::SerEnumMember>* > (); yystack_[2].value.as < IR::IndexedVector<IR::SerEnumMember>* > ()->push_back(yystack_[0].value.as < IR::SerEnumMember* > ()); }
#line 5785 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 328: // specifiedIdentifier: name "=" initializer
#line 1112 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::SerEnumMember* > () = new IR::SerEnumMember(yystack_[2].location+yystack_[0].location, *yystack_[2].value.as < IR::ID* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 5791 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 329: // errorDeclaration: ERROR "{" identifierList "}"
#line 1117 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Type_Error* > () = new IR::Type_Error(yystack_[3].location + yystack_[0].location, IR::ID(yystack_[3].location, "error"), *yystack_[1].value.as < IR::IndexedVector<IR::Declaration_ID>* > ()); }
#line 5797 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 330: // matchKindDeclaration: MATCH_KIND "{" identifierList "}"
#line 1122 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Node* > () = new IR::Declaration_MatchKind(yystack_[3].location + yystack_[0].location, *yystack_[1].value.as < IR::IndexedVector<IR::Declaration_ID>* > ()); }
#line 5803 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 331: // identifierList: name
#line 1126 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::IndexedVector<IR::Declaration_ID>* > () = new IR::IndexedVector<IR::Declaration_ID>();
                                yylhs.value.as < IR::IndexedVector<IR::Declaration_ID>* > ()->push_back(new IR::Declaration_ID(yystack_[0].location, *yystack_[0].value.as < IR::ID* > ()));}
#line 5810 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 332: // identifierList: identifierList "," name
#line 1128 "parsers/p4/p4parser.ypp"
                              { yylhs.value.as < IR::IndexedVector<IR::Declaration_ID>* > () = yystack_[2].value.as < IR::IndexedVector<IR::Declaration_ID>* > (); yylhs.value.as < IR::IndexedVector<IR::Declaration_ID>* > ()->push_back(new IR::Declaration_ID(yystack_[0].location, *yystack_[0].value.as < IR::ID* > ())); }
#line 5816 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 333: // typedefDeclaration: optAnnotations TYPEDEF typeRef name
#line 1132 "parsers/p4/p4parser.ypp"
                                            { driver.structure->declareType(*yystack_[0].value.as < IR::ID* > ());
          yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Typedef(yystack_[0].location, *yystack_[0].value.as < IR::ID* > (), new IR::Annotations(*yystack_[3].value.as < IR::Annotations* > ()), yystack_[1].value.as < ConstType* > ()); }
#line 5823 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 334: // typedefDeclaration: optAnnotations TYPEDEF derivedTypeDeclaration name
#line 1134 "parsers/p4/p4parser.ypp"
                                                           { driver.structure->declareType(*yystack_[0].value.as < IR::ID* > ());
                        yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Typedef(yystack_[0].location, *yystack_[0].value.as < IR::ID* > (), new IR::Annotations(*yystack_[3].value.as < IR::Annotations* > ()), yystack_[1].value.as < IR::Type_Declaration* > ()); }
#line 5830 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 335: // typedefDeclaration: optAnnotations TYPE typeRef name
#line 1136 "parsers/p4/p4parser.ypp"
                                         { driver.structure->declareType(*yystack_[0].value.as < IR::ID* > ());
          yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Newtype(yystack_[0].location, *yystack_[0].value.as < IR::ID* > (), new IR::Annotations(*yystack_[3].value.as < IR::Annotations* > ()), yystack_[1].value.as < ConstType* > ()); }
#line 5837 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 336: // typedefDeclaration: optAnnotations TYPE derivedTypeDeclaration name
#line 1138 "parsers/p4/p4parser.ypp"
                                                        { driver.structure->declareType(*yystack_[0].value.as < IR::ID* > ());
                        yylhs.value.as < IR::Type_Declaration* > () = new IR::Type_Newtype(yystack_[0].location, *yystack_[0].value.as < IR::ID* > (), new IR::Annotations(*yystack_[3].value.as < IR::Annotations* > ()), yystack_[1].value.as < IR::Type_Declaration* > ()); }
#line 5844 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 337: // assignmentOrMethodCallStatement: lvalue "(" argumentList ")" ";"
#line 1147 "parsers/p4/p4parser.ypp"
        { auto mc = new IR::MethodCallExpression(yystack_[4].location + yystack_[1].location, yystack_[4].value.as < IR::Expression* > (),
                                                 new IR::Vector<IR::Type>(), yystack_[2].value.as < IR::Vector<IR::Argument>* > ());
          yylhs.value.as < IR::Statement* > () = new IR::MethodCallStatement(yystack_[4].location + yystack_[1].location, mc); }
#line 5852 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 338: // assignmentOrMethodCallStatement: lvalue l_angle typeArgumentList r_angle "(" argumentList ")" ";"
#line 1152 "parsers/p4/p4parser.ypp"
        { auto mc = new IR::MethodCallExpression(yystack_[7].location + yystack_[1].location,
                                                 yystack_[7].value.as < IR::Expression* > (), yystack_[5].value.as < IR::Vector<IR::Type>* > (), yystack_[2].value.as < IR::Vector<IR::Argument>* > ());
          yylhs.value.as < IR::Statement* > () = new IR::MethodCallStatement(yystack_[7].location + yystack_[1].location, mc); }
#line 5860 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 339: // assignmentOrMethodCallStatement: lvalue "=" expression ";"
#line 1157 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Statement* > () = new IR::AssignmentStatement(yystack_[2].location, yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 5866 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 340: // emptyStatement: ";"
#line 1162 "parsers/p4/p4parser.ypp"
               { yylhs.value.as < IR::Statement* > () = new IR::EmptyStatement(yystack_[0].location); }
#line 5872 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 341: // exitStatement: EXIT ";"
#line 1166 "parsers/p4/p4parser.ypp"
               { yylhs.value.as < IR::Statement* > () = new IR::ExitStatement(yystack_[1].location); }
#line 5878 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 342: // returnStatement: RETURN ";"
#line 1170 "parsers/p4/p4parser.ypp"
                            { yylhs.value.as < IR::Statement* > () = new IR::ReturnStatement(yystack_[1].location, nullptr); }
#line 5884 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 343: // returnStatement: RETURN expression ";"
#line 1171 "parsers/p4/p4parser.ypp"
                            { yylhs.value.as < IR::Statement* > () = new IR::ReturnStatement(yystack_[2].location, yystack_[1].value.as < IR::Expression* > ()); }
#line 5890 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 344: // conditionalStatement: IF "(" expression ")" statement
#line 1176 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Statement* > () = new IR::IfStatement(yystack_[4].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Statement* > (), nullptr); }
#line 5896 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 345: // conditionalStatement: IF "(" expression ")" statement ELSE statement
#line 1178 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Statement* > () = new IR::IfStatement(yystack_[6].location, yystack_[4].value.as < IR::Expression* > (), yystack_[2].value.as < IR::Statement* > (), yystack_[0].value.as < IR::Statement* > ()); }
#line 5902 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 346: // directApplication: typeName "." APPLY "(" argumentList ")" ";"
#line 1183 "parsers/p4/p4parser.ypp"
                                                  {
                                  auto method = new IR::Member(
                                      yystack_[6].location + yystack_[4].location, new IR::TypeNameExpression(yystack_[6].value.as < IR::Type_Name* > ()), IR::ID(yystack_[4].location, "apply"));
                                  auto mce = new IR::MethodCallExpression(yystack_[6].location + yystack_[1].location, method, yystack_[2].value.as < IR::Vector<IR::Argument>* > ());
                                  yylhs.value.as < IR::Statement* > () = new IR::MethodCallStatement(yystack_[6].location + yystack_[1].location, mce); }
#line 5912 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 347: // statement: assignmentOrMethodCallStatement
#line 1191 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5918 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 348: // statement: directApplication
#line 1192 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5924 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 349: // statement: conditionalStatement
#line 1193 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5930 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 350: // statement: emptyStatement
#line 1194 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5936 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 351: // statement: blockStatement
#line 1195 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::BlockStatement* > (); }
#line 5942 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 352: // statement: returnStatement
#line 1196 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5948 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 353: // statement: exitStatement
#line 1197 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5954 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 354: // statement: switchStatement
#line 1198 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Statement* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 5960 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 355: // $@21: %empty
#line 1202 "parsers/p4/p4parser.ypp"
                         { driver.structure->pushNamespace(yystack_[0].location, false); }
#line 5966 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 356: // blockStatement: optAnnotations "{" $@21 statOrDeclList "}"
#line 1203 "parsers/p4/p4parser.ypp"
                         { driver.structure->pop();
                           yylhs.value.as < IR::BlockStatement* > () = new IR::BlockStatement(yystack_[4].location + yystack_[0].location, yystack_[4].value.as < IR::Annotations* > (), *yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > ()); }
#line 5973 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 357: // statOrDeclList: %empty
#line 1208 "parsers/p4/p4parser.ypp"
                                            { yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > () = new IR::IndexedVector<IR::StatOrDecl>(); }
#line 5979 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 358: // statOrDeclList: statOrDeclList statementOrDeclaration
#line 1209 "parsers/p4/p4parser.ypp"
                                            { yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > () = yystack_[1].value.as < IR::IndexedVector<IR::StatOrDecl>* > (); yylhs.value.as < IR::IndexedVector<IR::StatOrDecl>* > ()->push_back(yystack_[0].value.as < IR::StatOrDecl* > ()); }
#line 5985 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 359: // switchStatement: SWITCH "(" expression ")" "{" switchCases "}"
#line 1213 "parsers/p4/p4parser.ypp"
                                                    {
            yylhs.value.as < IR::Statement* > () = new IR::SwitchStatement(yystack_[6].location, yystack_[4].value.as < IR::Expression* > (), std::move(*yystack_[1].value.as < IR::Vector<IR::SwitchCase>* > ())); }
#line 5992 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 360: // switchCases: %empty
#line 1218 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Vector<IR::SwitchCase>* > () = new IR::Vector<IR::SwitchCase>(); }
#line 5998 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 361: // switchCases: switchCases switchCase
#line 1219 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Vector<IR::SwitchCase>* > () = yystack_[1].value.as < IR::Vector<IR::SwitchCase>* > (); yylhs.value.as < IR::Vector<IR::SwitchCase>* > ()->push_back(yystack_[0].value.as < IR::SwitchCase* > ()); }
#line 6004 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 362: // switchCase: switchLabel ":" blockStatement
#line 1223 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::SwitchCase* > () = new IR::SwitchCase(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::BlockStatement* > ()); }
#line 6010 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 363: // switchCase: switchLabel ":"
#line 1224 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::SwitchCase* > () = new IR::SwitchCase(yystack_[1].location, yystack_[1].value.as < IR::Expression* > (), nullptr); }
#line 6016 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 364: // switchLabel: DEFAULT
#line 1228 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Expression* > () = new IR::DefaultExpression(yystack_[0].location); }
#line 6022 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 365: // switchLabel: nonBraceExpression
#line 1229 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 6028 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 366: // statementOrDeclaration: variableDeclaration
#line 1233 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 6034 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 367: // statementOrDeclaration: constantDeclaration
#line 1234 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 6040 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 368: // statementOrDeclaration: statement
#line 1235 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Statement* > (); }
#line 6046 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 369: // statementOrDeclaration: instantiation
#line 1236 "parsers/p4/p4parser.ypp"
                               { yylhs.value.as < IR::StatOrDecl* > () = yystack_[0].value.as < IR::Declaration* > (); }
#line 6052 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 370: // tableDeclaration: optAnnotations TABLE name "{" tablePropertyList "}"
#line 1244 "parsers/p4/p4parser.ypp"
          { yylhs.value.as < IR::Declaration* > () = new IR::P4Table(yystack_[3].location, *yystack_[3].value.as < IR::ID* > (), yystack_[5].value.as < IR::Annotations* > (), new IR::TableProperties(yystack_[1].location, *yystack_[1].value.as < IR::IndexedVector<IR::Property>* > ())); }
#line 6058 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 371: // tablePropertyList: tableProperty
#line 1248 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::IndexedVector<IR::Property>* > () = new IR::IndexedVector<IR::Property>();
                                           yylhs.value.as < IR::IndexedVector<IR::Property>* > ()->push_back(yystack_[0].value.as < IR::Property* > ()); }
#line 6065 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 372: // tablePropertyList: tablePropertyList tableProperty
#line 1250 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::IndexedVector<IR::Property>* > () = yystack_[1].value.as < IR::IndexedVector<IR::Property>* > (); yylhs.value.as < IR::IndexedVector<IR::Property>* > ()->push_back(yystack_[0].value.as < IR::Property* > ()); }
#line 6071 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 373: // tableProperty: KEY "=" "{" keyElementList "}"
#line 1255 "parsers/p4/p4parser.ypp"
        { auto v = new IR::Key(yystack_[1].location, *yystack_[1].value.as < IR::Vector<IR::KeyElement>* > ());
          auto id = IR::ID(yystack_[4].location, "key");
          yylhs.value.as < IR::Property* > () = new IR::Property( yystack_[4].location + yystack_[0].location, id, v, false); }
#line 6079 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 374: // tableProperty: ACTIONS "=" "{" actionList "}"
#line 1259 "parsers/p4/p4parser.ypp"
        { auto v = new IR::ActionList(yystack_[1].location, *yystack_[1].value.as < IR::IndexedVector<IR::ActionListElement>* > ());
          auto id = IR::ID(yystack_[4].location, "actions");
          yylhs.value.as < IR::Property* > () = new IR::Property(yystack_[4].location + yystack_[0].location, id, v, false); }
#line 6087 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 375: // tableProperty: optAnnotations optCONST ENTRIES "=" "{" entriesList "}"
#line 1263 "parsers/p4/p4parser.ypp"
        { auto l = new IR::EntriesList(yystack_[4].location, *yystack_[1].value.as < IR::Vector<IR::Entry>* > ());
          auto id = IR::ID(yystack_[4].location+yystack_[0].location, "entries");
          yylhs.value.as < IR::Property* > () = new IR::Property(yystack_[4].location, id, yystack_[6].value.as < IR::Annotations* > (), l, yystack_[5].value.as < OptionalConst > ().isConst); }
#line 6095 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 376: // tableProperty: optAnnotations optCONST nonTableKwName "=" initializer ";"
#line 1267 "parsers/p4/p4parser.ypp"
        { auto v = new IR::ExpressionValue(yystack_[1].location, yystack_[1].value.as < IR::Expression* > ());
          auto id = *yystack_[3].value.as < IR::ID* > ();
          yylhs.value.as < IR::Property* > () = new IR::Property(yystack_[3].value.as < IR::ID* > ()->srcInfo, id, yystack_[5].value.as < IR::Annotations* > (), v, yystack_[4].value.as < OptionalConst > ().isConst); }
#line 6103 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 377: // keyElementList: %empty
#line 1273 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::KeyElement>* > () = new IR::Vector<IR::KeyElement>(); }
#line 6109 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 378: // keyElementList: keyElementList keyElement
#line 1274 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::KeyElement>* > () = yystack_[1].value.as < IR::Vector<IR::KeyElement>* > (); yylhs.value.as < IR::Vector<IR::KeyElement>* > ()->push_back(yystack_[0].value.as < IR::KeyElement* > ()); }
#line 6115 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 379: // keyElement: expression ":" name optAnnotations ";"
#line 1279 "parsers/p4/p4parser.ypp"
                                         { auto expr = new IR::PathExpression(*yystack_[2].value.as < IR::ID* > ());
                                           yylhs.value.as < IR::KeyElement* > () = new IR::KeyElement(yystack_[4].location, yystack_[1].value.as < IR::Annotations* > (), yystack_[4].value.as < IR::Expression* > (), expr); }
#line 6122 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 380: // actionList: %empty
#line 1284 "parsers/p4/p4parser.ypp"
             { yylhs.value.as < IR::IndexedVector<IR::ActionListElement>* > () = new IR::IndexedVector<IR::ActionListElement>(); }
#line 6128 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 381: // actionList: actionList optAnnotations actionRef ";"
#line 1286 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::IndexedVector<IR::ActionListElement>* > () = yystack_[3].value.as < IR::IndexedVector<IR::ActionListElement>* > (); yylhs.value.as < IR::IndexedVector<IR::ActionListElement>* > ()->push_back(new IR::ActionListElement(yystack_[1].location, yystack_[2].value.as < IR::Annotations* > (), yystack_[1].value.as < IR::Expression* > ())); }
#line 6134 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 382: // actionRef: prefixedNonTypeName
#line 1291 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(yystack_[0].value.as < IR::Path* > ()); }
#line 6140 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 383: // actionRef: prefixedNonTypeName "(" argumentList ")"
#line 1293 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::MethodCallExpression(yystack_[3].location+yystack_[1].location, new IR::PathExpression(yystack_[3].value.as < IR::Path* > ()), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6146 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 384: // entry: keysetExpression ":" actionRef optAnnotations ";"
#line 1298 "parsers/p4/p4parser.ypp"
        { if (auto l = yystack_[4].value.as < IR::Expression* > ()->to<IR::ListExpression>())
            yylhs.value.as < IR::Entry* > () = new IR::Entry(yystack_[4].location+yystack_[1].location, yystack_[1].value.as < IR::Annotations* > (), l, yystack_[2].value.as < IR::Expression* > ());
          else {  // if not a tuple, make it a list of 1
            IR::Vector<IR::Expression> le(yystack_[4].value.as < IR::Expression* > ());
            yylhs.value.as < IR::Entry* > () = new IR::Entry(yystack_[4].location+yystack_[1].location, yystack_[1].value.as < IR::Annotations* > (),
                   new IR::ListExpression(yystack_[4].location, le),
                   yystack_[2].value.as < IR::Expression* > ());
          }
        }
#line 6160 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 385: // entriesList: entry
#line 1310 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Vector<IR::Entry>* > () = new IR::Vector<IR::Entry>(); yylhs.value.as < IR::Vector<IR::Entry>* > ()->push_back(yystack_[0].value.as < IR::Entry* > ()); }
#line 6166 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 386: // entriesList: entriesList entry
#line 1311 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Vector<IR::Entry>* > () = yystack_[1].value.as < IR::Vector<IR::Entry>* > (); yylhs.value.as < IR::Vector<IR::Entry>* > ()->push_back(yystack_[0].value.as < IR::Entry* > ()); }
#line 6172 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 387: // actionDeclaration: optAnnotations ACTION name "(" parameterList ")" blockStatement
#line 1318 "parsers/p4/p4parser.ypp"
        { auto pl = new IR::ParameterList(yystack_[2].location, *yystack_[2].value.as < IR::IndexedVector<IR::Parameter>* > ());
          yylhs.value.as < IR::Declaration* > () = new IR::P4Action(yystack_[4].location, *yystack_[4].value.as < IR::ID* > (), yystack_[6].value.as < IR::Annotations* > (), pl, yystack_[0].value.as < IR::BlockStatement* > ()); }
#line 6179 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 388: // variableDeclaration: annotations typeRef name optInitializer ";"
#line 1326 "parsers/p4/p4parser.ypp"
                                     { auto ann = new IR::Annotations(yystack_[4].location, *yystack_[4].value.as < IR::Vector<IR::Annotation>* > ());
                                       yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Variable(yystack_[4].location+yystack_[1].location, *yystack_[2].value.as < IR::ID* > (), ann, yystack_[3].value.as < ConstType* > (), yystack_[1].value.as < IR::Expression* > ());
                                       driver.structure->declareObject(*yystack_[2].value.as < IR::ID* > (), yystack_[3].value.as < ConstType* > ()->toString()); }
#line 6187 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 389: // variableDeclaration: typeRef name optInitializer ";"
#line 1330 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Variable(yystack_[3].location+yystack_[0].location, *yystack_[2].value.as < IR::ID* > (), yystack_[3].value.as < ConstType* > (), yystack_[1].value.as < IR::Expression* > ());
                                       driver.structure->declareObject(*yystack_[2].value.as < IR::ID* > (), yystack_[3].value.as < ConstType* > ()->toString()); }
#line 6194 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 390: // constantDeclaration: optAnnotations CONST typeRef name "=" initializer ";"
#line 1336 "parsers/p4/p4parser.ypp"
                                     { yylhs.value.as < IR::Declaration* > () = new IR::Declaration_Constant(yystack_[3].location, *yystack_[3].value.as < IR::ID* > (), yystack_[6].value.as < IR::Annotations* > (), yystack_[4].value.as < ConstType* > (), yystack_[1].value.as < IR::Expression* > ());
                                       driver.structure->declareObject(*yystack_[3].value.as < IR::ID* > (), yystack_[4].value.as < ConstType* > ()->toString()); }
#line 6201 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 391: // optInitializer: %empty
#line 1341 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Expression* > () = nullptr; }
#line 6207 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 392: // optInitializer: "=" initializer
#line 1342 "parsers/p4/p4parser.ypp"
                                       { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 6213 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 393: // initializer: expression
#line 1346 "parsers/p4/p4parser.ypp"
                                          { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 6219 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 394: // functionDeclaration: functionPrototype blockStatement
#line 1352 "parsers/p4/p4parser.ypp"
                                         {
            driver.structure->pop();
            yylhs.value.as < IR::Declaration* > () = new IR::Function(yystack_[1].value.as < IR::Method* > ()->srcInfo, yystack_[1].value.as < IR::Method* > ()->name, yystack_[1].value.as < IR::Method* > ()->type, yystack_[0].value.as < IR::BlockStatement* > ()); }
#line 6227 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 395: // argumentList: %empty
#line 1358 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Argument>* > () = new IR::Vector<IR::Argument>(); }
#line 6233 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 396: // argumentList: nonEmptyArgList
#line 1359 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Argument>* > () = yystack_[0].value.as < IR::Vector<IR::Argument>* > (); }
#line 6239 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 397: // nonEmptyArgList: argument
#line 1363 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Argument>* > () = new IR::Vector<IR::Argument>();
                                           yylhs.value.as < IR::Vector<IR::Argument>* > ()->push_back(yystack_[0].value.as < IR::Argument* > ()); }
#line 6246 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 398: // nonEmptyArgList: nonEmptyArgList "," argument
#line 1365 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Argument>* > () = yystack_[2].value.as < IR::Vector<IR::Argument>* > (); yylhs.value.as < IR::Vector<IR::Argument>* > ()->push_back(yystack_[0].value.as < IR::Argument* > ()); }
#line 6252 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 399: // argument: expression
#line 1369 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Argument* > () = new IR::Argument(yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6258 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 400: // argument: name "=" expression
#line 1370 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Argument* > () = new IR::Argument(yystack_[2].location, *yystack_[2].value.as < IR::ID* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6264 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 401: // argument: "_"
#line 1371 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Argument* > () = new IR::Argument(yystack_[0].location, new IR::DefaultExpression(yystack_[0].location)); }
#line 6270 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 402: // expressionList: %empty
#line 1375 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>(); }
#line 6276 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 403: // expressionList: expression
#line 1376 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>();
                                           yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[0].value.as < IR::Expression* > ()); }
#line 6283 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 404: // expressionList: expressionList "," expression
#line 1378 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Vector<IR::Expression>* > () = yystack_[2].value.as < IR::Vector<IR::Expression>* > (); yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[0].value.as < IR::Expression* > ()); }
#line 6289 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 405: // prefixedNonTypeName: nonTypeName
#line 1382 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Path* > () = new IR::Path(*yystack_[0].value.as < IR::ID* > ()); }
#line 6295 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 406: // prefixedNonTypeName: dotPrefix nonTypeName
#line 1383 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Path* > () = new IR::Path(*yystack_[0].value.as < IR::ID* > (), true);
                                           driver.structure->clearPath(); }
#line 6302 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 407: // $@22: %empty
#line 1388 "parsers/p4/p4parser.ypp"
        { driver.structure->relativePathFromLastSymbol(); }
#line 6308 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 408: // dot_name: "." $@22 name
#line 1388 "parsers/p4/p4parser.ypp"
                                                                 {
          driver.structure->clearPath(); yylhs.value.as < IR::ID* > () = yystack_[0].value.as < IR::ID* > (); }
#line 6315 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 409: // lvalue: prefixedNonTypeName
#line 1392 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(yystack_[0].value.as < IR::Path* > ()); }
#line 6321 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 410: // lvalue: THIS
#line 1393 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::This(yystack_[0].location); }
#line 6327 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 411: // lvalue: lvalue dot_name
#line 1394 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[1].location + yystack_[0].location, yystack_[1].value.as < IR::Expression* > (), *yystack_[0].value.as < IR::ID* > ()); }
#line 6333 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 412: // lvalue: lvalue "[" expression "]"
#line 1395 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::ArrayIndex(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 6339 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 413: // lvalue: lvalue "[" expression ":" expression "]"
#line 1396 "parsers/p4/p4parser.ypp"
                                               { yylhs.value.as < IR::Expression* > () = new IR::Slice(yystack_[5].location + yystack_[0].location, yystack_[5].value.as < IR::Expression* > (), yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 6345 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 414: // expression: INTEGER
#line 1400 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0); }
#line 6351 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 415: // expression: STRING_LITERAL
#line 1401 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 6357 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 416: // expression: TRUE
#line 1402 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BoolLiteral(yystack_[0].location, true); }
#line 6363 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 417: // expression: FALSE
#line 1403 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BoolLiteral(yystack_[0].location, false); }
#line 6369 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 418: // expression: THIS
#line 1404 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::This(yystack_[0].location); }
#line 6375 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 419: // expression: nonTypeName
#line 1405 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(*yystack_[0].value.as < IR::ID* > ()); }
#line 6381 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 420: // expression: dotPrefix nonTypeName
#line 1406 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(new IR::Path(*yystack_[0].value.as < IR::ID* > (), true)); driver.structure->clearPath(); }
#line 6387 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 421: // expression: expression "[" expression "]"
#line 1407 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::ArrayIndex(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 6393 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 422: // expression: expression "[" expression ":" expression "]"
#line 1408 "parsers/p4/p4parser.ypp"
                                                   { yylhs.value.as < IR::Expression* > () = new IR::Slice(yystack_[5].location + yystack_[0].location, yystack_[5].value.as < IR::Expression* > (), yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 6399 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 423: // expression: "{" expressionList "}"
#line 1409 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::ListExpression(yystack_[2].location + yystack_[0].location, *yystack_[1].value.as < IR::Vector<IR::Expression>* > ()); }
#line 6405 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 424: // expression: "{" kvList "}"
#line 1410 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::StructExpression(
                                                  yystack_[2].location + yystack_[0].location, IR::Type::Unknown::get(), (IR::Type_Name*)nullptr, *yystack_[1].value.as < IR::IndexedVector<IR::NamedExpression>* > ()); }
#line 6412 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 425: // expression: "(" expression ")"
#line 1412 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = yystack_[1].value.as < IR::Expression* > (); }
#line 6418 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 426: // expression: "!" expression
#line 1413 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::LNot(yystack_[1].location + yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6424 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 427: // expression: "~" expression
#line 1414 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Cmpl(yystack_[1].location + yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6430 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 428: // expression: "-" expression
#line 1415 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Neg(yystack_[1].location + yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6436 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 429: // expression: "+" expression
#line 1416 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 6442 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 430: // expression: typeName dot_name
#line 1418 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[1].location + yystack_[0].location, new IR::TypeNameExpression(yystack_[1].location, yystack_[1].value.as < IR::Type_Name* > ()), *yystack_[0].value.as < IR::ID* > ()); }
#line 6448 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 431: // expression: ERROR "." name
#line 1420 "parsers/p4/p4parser.ypp"
        { auto typeName = new IR::Type_Name(yystack_[2].location, new IR::Path(IR::ID(yystack_[2].location, "error")));
          yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[2].location+yystack_[0].location, new IR::TypeNameExpression(yystack_[2].location+yystack_[0].location, typeName), *yystack_[0].value.as < IR::ID* > ()); }
#line 6455 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 432: // expression: expression dot_name
#line 1422 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[1].location + yystack_[0].location, yystack_[1].value.as < IR::Expression* > (), *yystack_[0].value.as < IR::ID* > ()); }
#line 6461 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 433: // expression: expression "*" expression
#line 1423 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Mul(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6467 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 434: // expression: expression "/" expression
#line 1424 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Div(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6473 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 435: // expression: expression "%" expression
#line 1425 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Mod(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6479 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 436: // expression: expression "+" expression
#line 1426 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Add(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6485 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 437: // expression: expression "-" expression
#line 1427 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Sub(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6491 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 438: // expression: expression "|+|" expression
#line 1428 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::AddSat(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6497 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 439: // expression: expression "|-|" expression
#line 1429 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::SubSat(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6503 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 440: // expression: expression "<<" expression
#line 1430 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Shl(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6509 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 441: // expression: expression R_ANGLE_SHIFT ">" expression
#line 1432 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::Shr(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6515 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 442: // expression: expression "<=" expression
#line 1433 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Leq(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6521 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 443: // expression: expression ">=" expression
#line 1434 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Geq(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6527 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 444: // expression: expression l_angle expression
#line 1436 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Lss(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6533 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 445: // expression: expression ">" expression
#line 1437 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Grt(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6539 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 446: // expression: expression "!=" expression
#line 1438 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Neq(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6545 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 447: // expression: expression "==" expression
#line 1439 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Equ(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6551 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 448: // expression: expression "&" expression
#line 1440 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BAnd(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6557 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 449: // expression: expression "^" expression
#line 1441 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BXor(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6563 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 450: // expression: expression "|" expression
#line 1442 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BOr(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6569 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 451: // expression: expression "++" expression
#line 1443 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Concat(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6575 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 452: // expression: expression "&&" expression
#line 1444 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::LAnd(yystack_[2].location + yystack_[1].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6581 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 453: // expression: expression "||" expression
#line 1445 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::LOr(yystack_[2].location + yystack_[1].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6587 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 454: // expression: expression "?" expression ":" expression
#line 1446 "parsers/p4/p4parser.ypp"
                                               { yylhs.value.as < IR::Expression* > () = new IR::Mux(yystack_[4].location + yystack_[0].location, yystack_[4].value.as < IR::Expression* > (), yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6593 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 455: // expression: expression l_angle realTypeArgumentList r_angle "(" argumentList ")"
#line 1448 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::MethodCallExpression(yystack_[6].location + yystack_[3].location, yystack_[6].value.as < IR::Expression* > (), yystack_[4].value.as < IR::Vector<IR::Type>* > (), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6599 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 456: // expression: expression "(" argumentList ")"
#line 1450 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::MethodCallExpression(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6605 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 457: // expression: namedType "(" argumentList ")"
#line 1452 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::ConstructorCallExpression(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < ConstType* > (), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6611 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 458: // expression: "(" typeRef ")" expression
#line 1453 "parsers/p4/p4parser.ypp"
                                              { yylhs.value.as < IR::Expression* > () = new IR::Cast(yystack_[3].location + yystack_[0].location, yystack_[2].value.as < ConstType* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6617 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 459: // nonBraceExpression: INTEGER
#line 1457 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0); }
#line 6623 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 460: // nonBraceExpression: STRING_LITERAL
#line 1458 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 6629 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 461: // nonBraceExpression: TRUE
#line 1459 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BoolLiteral(yystack_[0].location, true); }
#line 6635 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 462: // nonBraceExpression: FALSE
#line 1460 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::BoolLiteral(yystack_[0].location, false); }
#line 6641 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 463: // nonBraceExpression: THIS
#line 1461 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::This(yystack_[0].location); }
#line 6647 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 464: // nonBraceExpression: nonTypeName
#line 1462 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(*yystack_[0].value.as < IR::ID* > ()); }
#line 6653 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 465: // nonBraceExpression: dotPrefix nonTypeName
#line 1463 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::PathExpression(new IR::Path(*yystack_[0].value.as < IR::ID* > (), true)); driver.structure->clearPath(); }
#line 6659 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 466: // nonBraceExpression: nonBraceExpression "[" expression "]"
#line 1464 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::ArrayIndex(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 6665 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 467: // nonBraceExpression: nonBraceExpression "[" expression ":" expression "]"
#line 1465 "parsers/p4/p4parser.ypp"
                                                           { yylhs.value.as < IR::Expression* > () = new IR::Slice(yystack_[5].location + yystack_[0].location, yystack_[5].value.as < IR::Expression* > (), yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Expression* > ()); }
#line 6671 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 468: // nonBraceExpression: "(" expression ")"
#line 1466 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = yystack_[1].value.as < IR::Expression* > (); }
#line 6677 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 469: // nonBraceExpression: "!" expression
#line 1467 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::LNot(yystack_[1].location + yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6683 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 470: // nonBraceExpression: "~" expression
#line 1468 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Cmpl(yystack_[1].location + yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6689 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 471: // nonBraceExpression: "-" expression
#line 1469 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Neg(yystack_[1].location + yystack_[0].location, yystack_[0].value.as < IR::Expression* > ()); }
#line 6695 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 472: // nonBraceExpression: "+" expression
#line 1470 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = yystack_[0].value.as < IR::Expression* > (); }
#line 6701 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 473: // nonBraceExpression: typeName dot_name
#line 1472 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[1].location + yystack_[0].location, new IR::TypeNameExpression(yystack_[1].location, yystack_[1].value.as < IR::Type_Name* > ()), *yystack_[0].value.as < IR::ID* > ()); }
#line 6707 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 474: // nonBraceExpression: ERROR "." name
#line 1474 "parsers/p4/p4parser.ypp"
        { auto typeName = new IR::Type_Name(yystack_[2].location, new IR::Path(IR::ID(yystack_[2].location, "error")));
          yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[2].location+yystack_[0].location, new IR::TypeNameExpression(yystack_[2].location+yystack_[0].location, typeName), *yystack_[0].value.as < IR::ID* > ()); }
#line 6714 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 475: // nonBraceExpression: nonBraceExpression dot_name
#line 1476 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Member(yystack_[1].location + yystack_[0].location, yystack_[1].value.as < IR::Expression* > (), *yystack_[0].value.as < IR::ID* > ()); }
#line 6720 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 476: // nonBraceExpression: nonBraceExpression "*" expression
#line 1477 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Mul(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6726 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 477: // nonBraceExpression: nonBraceExpression "/" expression
#line 1478 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Div(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6732 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 478: // nonBraceExpression: nonBraceExpression "%" expression
#line 1479 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Mod(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6738 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 479: // nonBraceExpression: nonBraceExpression "+" expression
#line 1480 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Add(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6744 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 480: // nonBraceExpression: nonBraceExpression "-" expression
#line 1481 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Sub(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6750 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 481: // nonBraceExpression: nonBraceExpression "|+|" expression
#line 1482 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::AddSat(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6756 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 482: // nonBraceExpression: nonBraceExpression "|-|" expression
#line 1483 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::SubSat(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6762 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 483: // nonBraceExpression: nonBraceExpression "<<" expression
#line 1484 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Shl(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6768 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 484: // nonBraceExpression: nonBraceExpression R_ANGLE_SHIFT ">" expression
#line 1486 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::Shr(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6774 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 485: // nonBraceExpression: nonBraceExpression "<=" expression
#line 1487 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Leq(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6780 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 486: // nonBraceExpression: nonBraceExpression ">=" expression
#line 1488 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Geq(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6786 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 487: // nonBraceExpression: nonBraceExpression l_angle expression
#line 1490 "parsers/p4/p4parser.ypp"
                                         { yylhs.value.as < IR::Expression* > () = new IR::Lss(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6792 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 488: // nonBraceExpression: nonBraceExpression ">" expression
#line 1491 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Grt(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6798 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 489: // nonBraceExpression: nonBraceExpression "!=" expression
#line 1492 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Neq(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6804 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 490: // nonBraceExpression: nonBraceExpression "==" expression
#line 1493 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Equ(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6810 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 491: // nonBraceExpression: nonBraceExpression "&" expression
#line 1494 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::BAnd(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6816 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 492: // nonBraceExpression: nonBraceExpression "^" expression
#line 1495 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::BXor(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6822 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 493: // nonBraceExpression: nonBraceExpression "|" expression
#line 1496 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::BOr(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6828 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 494: // nonBraceExpression: nonBraceExpression "++" expression
#line 1497 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::Concat(yystack_[2].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6834 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 495: // nonBraceExpression: nonBraceExpression "&&" expression
#line 1498 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::LAnd(yystack_[2].location + yystack_[1].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6840 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 496: // nonBraceExpression: nonBraceExpression "||" expression
#line 1499 "parsers/p4/p4parser.ypp"
                                                 { yylhs.value.as < IR::Expression* > () = new IR::LOr(yystack_[2].location + yystack_[1].location + yystack_[0].location, yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6846 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 497: // nonBraceExpression: nonBraceExpression "?" expression ":" expression
#line 1500 "parsers/p4/p4parser.ypp"
                                                       { yylhs.value.as < IR::Expression* > () = new IR::Mux(yystack_[4].location + yystack_[0].location, yystack_[4].value.as < IR::Expression* > (), yystack_[2].value.as < IR::Expression* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6852 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 498: // nonBraceExpression: nonBraceExpression l_angle realTypeArgumentList r_angle "(" argumentList ")"
#line 1502 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::MethodCallExpression(yystack_[6].location + yystack_[3].location, yystack_[6].value.as < IR::Expression* > (), yystack_[4].value.as < IR::Vector<IR::Type>* > (), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6858 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 499: // nonBraceExpression: nonBraceExpression "(" argumentList ")"
#line 1504 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::MethodCallExpression(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < IR::Expression* > (), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6864 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 500: // nonBraceExpression: namedType "(" argumentList ")"
#line 1506 "parsers/p4/p4parser.ypp"
        { yylhs.value.as < IR::Expression* > () = new IR::ConstructorCallExpression(yystack_[3].location + yystack_[0].location, yystack_[3].value.as < ConstType* > (), yystack_[1].value.as < IR::Vector<IR::Argument>* > ()); }
#line 6870 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 501: // nonBraceExpression: "(" typeRef ")" expression
#line 1507 "parsers/p4/p4parser.ypp"
                                              { yylhs.value.as < IR::Expression* > () = new IR::Cast(yystack_[3].location + yystack_[0].location, yystack_[2].value.as < ConstType* > (), yystack_[0].value.as < IR::Expression* > ()); }
#line 6876 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 502: // intOrStr: INTEGER
#line 1511 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Expression* > () = parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0); }
#line 6882 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 503: // intOrStr: STRING_LITERAL
#line 1512 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Expression* > () = new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ()); }
#line 6888 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 504: // intList: INTEGER
#line 1516 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>();
                                   yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0)); }
#line 6895 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 505: // intList: intList "," INTEGER
#line 1518 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::Expression>* > () = yystack_[2].value.as < IR::Vector<IR::Expression>* > ();
                                   yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(parseConstant(yystack_[0].location, yystack_[0].value.as < UnparsedConstant > (), 0)); }
#line 6902 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 506: // intOrStrList: intOrStr
#line 1523 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>();
                                   yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[0].value.as < IR::Expression* > ()); }
#line 6909 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 507: // intOrStrList: intOrStrList "," intOrStr
#line 1525 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::Expression>* > () = yystack_[2].value.as < IR::Vector<IR::Expression>* > ();
                                   yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(yystack_[0].value.as < IR::Expression* > ()); }
#line 6916 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 508: // strList: STRING_LITERAL
#line 1530 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::Expression>* > () = new IR::Vector<IR::Expression>();
                                   yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ())); }
#line 6923 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;

  case 509: // strList: strList "," STRING_LITERAL
#line 1532 "parsers/p4/p4parser.ypp"
                                 { yylhs.value.as < IR::Vector<IR::Expression>* > () = yystack_[2].value.as < IR::Vector<IR::Expression>* > ();
                                   yylhs.value.as < IR::Vector<IR::Expression>* > ()->push_back(new IR::StringLiteral(yystack_[0].location, yystack_[0].value.as < cstring > ())); }
#line 6930 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"
    break;


#line 6934 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"

            default:
              break;
            }
        }
#if YY_EXCEPTIONS
      catch (const syntax_error& yyexc)
        {
          YYCDEBUG << "Caught exception: " << yyexc.what() << '\n';
          error (yyexc);
          YYERROR;
        }
#endif // YY_EXCEPTIONS
      YY_SYMBOL_PRINT ("-> $$ =", yylhs);
      yypop_ (yylen);
      yylen = 0;

      // Shift the result of the reduction.
      yypush_ (YY_NULLPTR, YY_MOVE (yylhs));
    }
    goto yynewstate;


  /*--------------------------------------.
  | yyerrlab -- here on detecting error.  |
  `--------------------------------------*/
  yyerrlab:
    // If not already recovering from an error, report this error.
    if (!yyerrstatus_)
      {
        ++yynerrs_;
        context yyctx (*this, yyla);
        std::string msg = yysyntax_error_ (yyctx);
        error (yyla.location, YY_MOVE (msg));
      }


    yyerror_range[1].location = yyla.location;
    if (yyerrstatus_ == 3)
      {
        /* If just tried and failed to reuse lookahead token after an
           error, discard it.  */

        // Return failure if at end of input.
        if (yyla.kind () == symbol_kind::S_YYEOF)
          YYABORT;
        else if (!yyla.empty ())
          {
            yy_destroy_ ("Error: discarding", yyla);
            yyla.clear ();
          }
      }

    // Else will try to reuse lookahead token after shifting the error token.
    goto yyerrlab1;


  /*---------------------------------------------------.
  | yyerrorlab -- error raised explicitly by YYERROR.  |
  `---------------------------------------------------*/
  yyerrorlab:
    /* Pacify compilers when the user code never invokes YYERROR and
       the label yyerrorlab therefore never appears in user code.  */
    if (false)
      YYERROR;

    /* Do not reclaim the symbols of the rule whose action triggered
       this YYERROR.  */
    yypop_ (yylen);
    yylen = 0;
    YY_STACK_PRINT ();
    goto yyerrlab1;


  /*-------------------------------------------------------------.
  | yyerrlab1 -- common code for both syntax error and YYERROR.  |
  `-------------------------------------------------------------*/
  yyerrlab1:
    yyerrstatus_ = 3;   // Each real token shifted decrements this.
    // Pop stack until we find a state that shifts the error token.
    for (;;)
      {
        yyn = yypact_[+yystack_[0].state];
        if (!yy_pact_value_is_default_ (yyn))
          {
            yyn += symbol_kind::S_YYerror;
            if (0 <= yyn && yyn <= yylast_
                && yycheck_[yyn] == symbol_kind::S_YYerror)
              {
                yyn = yytable_[yyn];
                if (0 < yyn)
                  break;
              }
          }

        // Pop the current state because it cannot handle the error token.
        if (yystack_.size () == 1)
          YYABORT;

        yyerror_range[1].location = yystack_[0].location;
        yy_destroy_ ("Error: popping", yystack_[0]);
        yypop_ ();
        YY_STACK_PRINT ();
      }
    {
      stack_symbol_type error_token;

      yyerror_range[2].location = yyla.location;
      YYLLOC_DEFAULT (error_token.location, yyerror_range, 2);

      // Shift the error token.
      error_token.state = state_type (yyn);
      yypush_ ("Shifting", YY_MOVE (error_token));
    }
    goto yynewstate;


  /*-------------------------------------.
  | yyacceptlab -- YYACCEPT comes here.  |
  `-------------------------------------*/
  yyacceptlab:
    yyresult = 0;
    goto yyreturn;


  /*-----------------------------------.
  | yyabortlab -- YYABORT comes here.  |
  `-----------------------------------*/
  yyabortlab:
    yyresult = 1;
    goto yyreturn;


  /*-----------------------------------------------------.
  | yyreturn -- parsing is finished, return the result.  |
  `-----------------------------------------------------*/
  yyreturn:
    if (!yyla.empty ())
      yy_destroy_ ("Cleanup: discarding lookahead", yyla);

    /* Do not reclaim the symbols of the rule whose action triggered
       this YYABORT or YYACCEPT.  */
    yypop_ (yylen);
    YY_STACK_PRINT ();
    while (1 < yystack_.size ())
      {
        yy_destroy_ ("Cleanup: popping", yystack_[0]);
        yypop_ ();
      }

    return yyresult;
  }
#if YY_EXCEPTIONS
    catch (...)
      {
        YYCDEBUG << "Exception caught: cleaning lookahead and stack\n";
        // Do not try to display the values of the reclaimed symbols,
        // as their printers might throw an exception.
        if (!yyla.empty ())
          yy_destroy_ (YY_NULLPTR, yyla);

        while (1 < yystack_.size ())
          {
            yy_destroy_ (YY_NULLPTR, yystack_[0]);
            yypop_ ();
          }
        throw;
      }
#endif // YY_EXCEPTIONS
  }

  void
  P4Parser::error (const syntax_error& yyexc)
  {
    error (yyexc.location, yyexc.what ());
  }

  /* Return YYSTR after stripping away unnecessary quotes and
     backslashes, so that it's suitable for yyerror.  The heuristic is
     that double-quoting is unnecessary unless the string contains an
     apostrophe, a comma, or backslash (other than backslash-backslash).
     YYSTR is taken from yytname.  */
  std::string
  P4Parser::yytnamerr_ (const char *yystr)
  {
    if (*yystr == '"')
      {
        std::string yyr;
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
              yyr += *yyp;
              break;

            case '"':
              return yyr;
            }
      do_not_strip_quotes: ;
      }

    return yystr;
  }

  std::string
  P4Parser::symbol_name (symbol_kind_type yysymbol)
  {
    return yytnamerr_ (yytname_[yysymbol]);
  }



  // P4Parser::context.
  P4Parser::context::context (const P4Parser& yyparser, const symbol_type& yyla)
    : yyparser_ (yyparser)
    , yyla_ (yyla)
  {}

  int
  P4Parser::context::expected_tokens (symbol_kind_type yyarg[], int yyargn) const
  {
    // Actual number of expected tokens
    int yycount = 0;

    const int yyn = yypact_[+yyparser_.yystack_[0].state];
    if (!yy_pact_value_is_default_ (yyn))
      {
        /* Start YYX at -YYN if negative to avoid negative indexes in
           YYCHECK.  In other words, skip the first -YYN actions for
           this state because they are default actions.  */
        const int yyxbegin = yyn < 0 ? -yyn : 0;
        // Stay within bounds of both yycheck and yytname.
        const int yychecklim = yylast_ - yyn + 1;
        const int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
        for (int yyx = yyxbegin; yyx < yyxend; ++yyx)
          if (yycheck_[yyx + yyn] == yyx && yyx != symbol_kind::S_YYerror
              && !yy_table_value_is_error_ (yytable_[yyx + yyn]))
            {
              if (!yyarg)
                ++yycount;
              else if (yycount == yyargn)
                return 0;
              else
                yyarg[yycount++] = YY_CAST (symbol_kind_type, yyx);
            }
      }

    if (yyarg && yycount == 0 && 0 < yyargn)
      yyarg[0] = symbol_kind::S_YYEMPTY;
    return yycount;
  }






  int
  P4Parser::yy_syntax_error_arguments_ (const context& yyctx,
                                                 symbol_kind_type yyarg[], int yyargn) const
  {
    /* There are many possibilities here to consider:
       - If this state is a consistent state with a default action, then
         the only way this function was invoked is if the default action
         is an error action.  In that case, don't check for expected
         tokens because there are none.
       - The only way there can be no lookahead present (in yyla) is
         if this state is a consistent state with a default action.
         Thus, detecting the absence of a lookahead is sufficient to
         determine that there is no unexpected or expected token to
         report.  In that case, just report a simple "syntax error".
       - Don't assume there isn't a lookahead just because this state is
         a consistent state with a default action.  There might have
         been a previous inconsistent state, consistent state with a
         non-default action, or user semantic action that manipulated
         yyla.  (However, yyla is currently not documented for users.)
       - Of course, the expected token list depends on states to have
         correct lookahead information, and it depends on the parser not
         to perform extra reductions after fetching a lookahead from the
         scanner and before detecting a syntax error.  Thus, state merging
         (from LALR or IELR) and default reductions corrupt the expected
         token list.  However, the list is correct for canonical LR with
         one exception: it will still contain any token that will not be
         accepted due to an error action in a later state.
    */

    if (!yyctx.lookahead ().empty ())
      {
        if (yyarg)
          yyarg[0] = yyctx.token ();
        int yyn = yyctx.expected_tokens (yyarg ? yyarg + 1 : yyarg, yyargn - 1);
        return yyn + 1;
      }
    return 0;
  }

  // Generate an error message.
  std::string
  P4Parser::yysyntax_error_ (const context& yyctx) const
  {
    // Its maximum.
    enum { YYARGS_MAX = 5 };
    // Arguments of yyformat.
    symbol_kind_type yyarg[YYARGS_MAX];
    int yycount = yy_syntax_error_arguments_ (yyctx, yyarg, YYARGS_MAX);

    char const* yyformat = YY_NULLPTR;
    switch (yycount)
      {
#define YYCASE_(N, S)                         \
        case N:                               \
          yyformat = S;                       \
        break
      default: // Avoid compiler warnings.
        YYCASE_ (0, YY_("syntax error"));
        YYCASE_ (1, YY_("syntax error, unexpected %s"));
        YYCASE_ (2, YY_("syntax error, unexpected %s, expecting %s"));
        YYCASE_ (3, YY_("syntax error, unexpected %s, expecting %s or %s"));
        YYCASE_ (4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
        YYCASE_ (5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
#undef YYCASE_
      }

    std::string yyres;
    // Argument number.
    std::ptrdiff_t yyi = 0;
    for (char const* yyp = yyformat; *yyp; ++yyp)
      if (yyp[0] == '%' && yyp[1] == 's' && yyi < yycount)
        {
          yyres += symbol_name (yyarg[yyi++]);
          ++yyp;
        }
      else
        yyres += *yyp;
    return yyres;
  }


  const short P4Parser::yypact_ninf_ = -846;

  const short P4Parser::yytable_ninf_ = -263;

  const short
  P4Parser::yypact_[] =
  {
    4152,  -846,  2308,   378,   -83,   209,   -61,  2308,   -31,   209,
      22,  2308,    72,    75,  2308,    88,    99,   120,   117,   229,
    -846,   329,  2308,  2308,  2308,  2357,  1016,  2308,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,   184,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,   458,   202,  -846,   219,  -846,   218,
    3736,  -846,  -846,   211,   224,  -846,  -846,   233,  -846,  -846,
    -846,   237,  -846,   245,  3736,  -846,  -846,  -846,  2811,   260,
     267,  2848,   270,   275,   279,  -846,  -846,  -846,  -846,   378,
    -846,   107,   292,   107,   294,   378,  -846,   107,   107,  -846,
    -846,  -846,  3897,  1236,  -846,   285,  -846,   252,  -846,     6,
    -846,   129,  -846,   -34,   304,   320,  -846,  -846,   326,  -846,
     378,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,   315,
    -846,  -846,  -846,   168,   168,   168,    93,   319,   -14,    47,
     184,   321,   214,   139,  2885,   168,   378,  -846,  -846,  2112,
    -846,  -846,  -846,  -846,  2495,  2308,  2308,  2308,  2308,  2308,
    2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,
    2308,  2308,  2308,  2308,  2308,   330,  2112,  2308,  2308,  -846,
    1415,  2308,   378,   268,   209,   274,  2308,   269,   280,  2308,
     278,   281,    44,   204,   -26,   378,   -21,   378,  -846,  2495,
     -20,   378,   176,   378,  1088,   908,   378,   378,  1236,   378,
     378,   378,  1236,  -846,  -846,   336,  -846,    24,  -846,   348,
    -846,   350,   351,   -34,  -846,  2112,  2308,  2308,   107,  -846,
    -846,  -846,  2308,  -846,  -846,  -846,   340,   352,   345,  -846,
    3736,   378,  -846,  -846,  -846,  -846,  -846,   157,  3736,  3971,
    3971,  4094,  3880,  3847,  3913,  3913,   166,   166,   166,   166,
     168,   168,   168,  4002,  4064,  4033,  2700,  3971,  2308,   359,
    2922,   166,  -846,  -846,  -846,  -846,   296,  3971,  3736,  -846,
    -846,  -846,  -846,  3736,  -846,  -846,  2959,   357,   358,   107,
    -846,  -846,  -846,  2357,  -846,  2308,   298,  -846,    68,  2308,
     298,   113,  1572,   157,  2308,   298,   365,   378,  -846,  -846,
     378,   173,   362,   363,   364,  -846,  -846,  -846,    62,   378,
     378,  -846,  -846,  -846,   378,   378,  2112,    43,   366,   369,
    -846,  -846,  -846,  -846,   374,  2996,  3033,  -846,  -846,   378,
     168,  2308,  -846,  2112,  -846,  -846,  -846,  2495,  -846,  -846,
    2308,  4094,  -846,  2308,  2495,   376,  2308,   317,   323,   324,
      -6,   105,  1662,  3070,  -846,  -846,   378,  3107,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -846,  3144,  -846,    24,   373,   107,   395,  -846,   107,  -846,
    -846,   107,   107,  -846,  -846,   107,   107,   107,  -846,  -846,
     389,  -846,  -846,  -846,   176,  -846,   -34,  1236,  1178,  -846,
     378,  -846,  -846,   391,  -846,   311,  3736,  -846,  -846,  3181,
    3810,  -846,  2112,  3736,  -846,  -846,   298,  -846,  -846,  -846,
     298,  -846,   298,  1752,   298,   392,  2308,  -846,   378,   398,
    -846,  -846,  -846,  -846,  -846,  -846,   378,   378,  -846,    74,
    1236,  -846,  -846,     9,  -846,  -846,   207,  -846,  -846,   -34,
     -30,  -846,  -846,  -846,  -846,  -846,  -846,  1474,   306,    24,
     378,  -846,  -846,   393,  -846,  -846,  -846,  -846,  -846,   -34,
     387,  3736,   396,   150,   378,   406,   408,   409,   418,   420,
     412,   312,   416,   378,   107,   305,  -846,   377,  -846,   419,
     433,  -846,   378,  -846,  -846,  -846,   422,   431,  2161,   432,
    -846,     8,  -846,   458,   276,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,   246,   439,
    -846,   434,  -846,  -846,  -846,  -846,    24,  -846,   435,   213,
    -846,  -846,  -846,  -846,    24,    24,  -846,   439,  -846,  2308,
    -846,   176,   419,  2308,   436,  -846,   451,  -846,  2308,  -846,
    3218,  2308,  -846,   426,  2308,  2112,  2308,  -846,  2495,  -846,
     440,  -846,   446,  2308,  -846,   378,    10,    13,    14,   449,
     450,    20,   444,  3736,   460,   298,   298,   298,   457,  -846,
    -846,    61,  3255,  -846,  3292,   468,  2737,   456,  3329,   157,
    -846,  -846,  -846,  -846,  -846,  -846,  1321,  -846,  -846,   176,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,   469,   480,   481,
    -846,   476,   479,   465,    15,  -846,   515,   495,  2112,  -846,
    2308,   489,  -846,   498,    -9,  2534,   502,   496,   378,  2404,
    2308,  2308,  2308,   509,   512,  -846,   192,  -846,  -846,   501,
     487,  -846,   513,  3366,  -846,  2112,  -846,  1236,  -846,  -846,
    -846,   507,    24,  -846,   514,   402,    70,  1236,  -846,  -846,
     525,   378,  -846,  -846,  -846,  -846,  -846,  -846,  3403,  3440,
    3477,  -846,  -846,  -846,   519,  -846,  -846,  -846,  -846,   520,
     515,  2210,   517,  -846,   528,  -846,   535,  -846,   537,   530,
    -846,  -846,  -846,   378,  -846,   378,   378,   378,    67,  2259,
     546,  2308,  -846,  2308,  2308,  2308,  -846,  1016,  2308,  -846,
    -846,  -846,  -846,   538,  -846,  -846,  -846,   458,   541,   219,
    -846,   540,  3773,  -846,   539,   542,  2308,  -846,  -846,   543,
     550,   555,  -846,    69,  -846,  -846,  3514,  2010,   559,   168,
     168,   168,   547,  3551,   168,   378,  -846,  2112,  -846,     7,
    2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,
    2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,  2308,   556,
    2112,  2308,  2308,  -846,  1415,  -846,  -846,    80,  2452,  -846,
    -846,  -846,   240,   560,   570,   378,  1833,  -846,  -846,   568,
    -846,  -846,  -846,  1908,  2660,  -846,  2308,  -846,  -846,   576,
    -846,  3971,  3971,  4094,  3880,  3847,  3913,  3913,   166,   166,
     166,   166,   168,   168,   168,  4002,  4064,  4033,  2774,  3971,
    2308,   577,  3588,   166,   296,  3971,   589,  -846,  -846,  2112,
     -34,   580,   582,   586,   585,  2620,    69,  -846,  -846,  2308,
    2308,   168,  -846,  -846,  2308,  4094,  -846,  2308,   590,  -846,
     592,   583,  -846,  2061,  2308,  2308,   -34,  3736,  3736,  3625,
    3810,  2112,  1959,  -846,  -846,   172,  -846,  3662,  3699,   587,
    -846,   593,  -846,  -846,   594,  -846,  2061,  -846,  -846,   378,
    -846,   588,  -846
  };

  const short
  P4Parser::yydefact_[] =
  {
       0,    24,   402,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       3,    53,     0,     0,     0,   402,     0,     0,   180,   416,
     417,   418,    40,    38,    42,     0,    39,    43,    41,    37,
     263,   415,   414,   419,     0,     0,   265,   261,   262,     4,
     403,    45,    44,     0,     5,   152,   504,     6,   503,   502,
     506,     7,   508,     8,     9,    10,    11,    12,     0,     0,
       0,     0,     0,     0,     0,     1,     2,    23,    26,     0,
     270,   272,   271,   274,     0,     0,   273,     0,     0,   282,
     283,    25,     0,    54,    55,     0,    33,     0,    30,   178,
      32,   178,    28,    53,   281,   257,   260,   259,   258,   256,
       0,    31,   301,   306,   308,   307,   309,    34,    35,     0,
      29,    27,    36,   429,   428,   427,   263,   419,     0,     0,
     271,     0,   257,   258,     0,   426,     0,   264,   420,   395,
     510,   511,   407,   430,   293,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   395,     0,     0,   432,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    57,     0,     0,     0,     0,    62,   293,
       0,     0,     0,     0,     0,     0,     0,     0,    53,     0,
       0,     0,    53,   271,    56,     0,   305,    53,   303,     0,
     304,     0,     0,    54,   394,   395,     0,     0,   284,   302,
     424,   423,     0,   425,   431,   401,     0,     0,   396,   397,
     399,     0,   292,   291,   290,   289,   294,     0,   404,   442,
     443,   440,   452,   453,   446,   447,   436,   437,   438,   439,
     433,   434,   435,   450,   448,   449,     0,   445,     0,     0,
       0,   451,   298,   297,   296,   299,     0,   444,   154,   153,
     505,   507,   509,    13,    14,    15,     0,     0,     0,     0,
      20,    22,    19,   402,    62,     0,     0,   331,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   233,   322,
       0,   283,   244,     0,     0,   281,   310,   316,     0,     0,
       0,   165,   188,   313,     0,     0,   395,   164,     0,   156,
     157,   182,   236,   355,     0,     0,     0,   251,   285,     0,
     458,     0,   457,     0,   408,   512,   513,     0,   269,   421,
       0,   441,   456,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   275,   329,     0,     0,   276,   330,
      65,    61,   123,   122,   117,   118,   119,   121,   120,   125,
     127,   126,   128,   129,   130,   131,   132,   133,   134,   135,
     136,   137,   138,   139,   140,   141,   142,   143,    62,   144,
     145,   146,   147,   148,   149,   150,   151,   124,   110,   115,
     116,   104,    81,   102,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    82,
      83,    84,    85,    86,    87,    88,    96,    89,    90,    91,
      93,    92,    94,    95,    97,    98,    99,   100,   101,   103,
     105,   106,   107,   108,   109,   111,   112,   113,   114,    64,
     266,     0,   277,    53,     0,   284,     0,   324,   284,   248,
     247,   284,   284,   335,   336,   284,   284,   284,   333,   334,
       0,   161,   163,   162,     0,   179,    53,    53,    53,   357,
       0,   267,   268,     0,   287,     0,   400,   398,   295,     0,
     454,   300,   395,    16,    17,    18,     0,    60,    59,    58,
       0,   332,     0,     0,     0,     0,     0,   234,     0,     0,
     245,   311,   317,   166,   189,   314,     0,     0,   158,     0,
      54,   185,   183,    53,   191,   187,     0,   186,   184,    53,
       0,   241,   237,   240,   239,   242,   238,    53,     0,    53,
       0,   286,   422,     0,    21,   278,   279,    63,   280,    53,
       0,   393,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   159,     0,     0,     0,   181,     0,   192,   391,
       0,   243,     0,   356,   340,   410,     0,     0,     0,     0,
     405,     0,   369,     0,   257,   347,   350,   353,   352,   349,
     348,   368,   351,   354,   358,   366,   367,   409,     0,     0,
     169,     0,   288,   455,   387,   390,    53,   323,     0,     0,
     326,   249,   319,   319,    53,    53,   319,     0,   168,     0,
     193,     0,   391,     0,     0,   232,     0,   341,     0,   342,
       0,     0,   406,     0,     0,   395,     0,   411,   293,   172,
       0,   252,     0,     0,   325,     0,    53,    53,    53,     0,
       0,    53,     0,   160,     0,     0,     0,     0,     0,   392,
     389,    53,     0,   343,     0,     0,     0,     0,     0,     0,
     174,   171,   235,   328,   327,   246,     0,   250,   312,     0,
     320,   318,   167,   190,   315,   170,   195,     0,     0,     0,
     388,     0,     0,    51,    53,   371,    53,     0,   395,   412,
       0,     0,   339,     0,     0,     0,   263,     0,     0,    53,
       0,     0,     0,     0,     0,    52,     0,   370,   372,     0,
     344,   360,     0,     0,   337,   395,   173,     0,   177,   175,
     176,     0,    53,   253,     0,     0,     0,    54,   196,   202,
       0,     0,   197,   199,   203,   198,   200,   201,     0,     0,
       0,   380,   377,    48,     0,    50,    49,    46,    47,     0,
      53,     0,     0,   413,     0,   254,     0,   321,     0,     0,
     207,   209,   204,     0,   194,     0,     0,     0,    53,     0,
       0,     0,   345,     0,     0,     0,   359,     0,     0,   461,
     462,   463,   364,     0,   460,   459,   464,     0,     0,   261,
     361,     0,   365,   346,     0,     0,   402,   208,   195,     0,
       0,     0,   374,     0,   373,   378,     0,     0,     0,   472,
     471,   470,     0,     0,   469,     0,   465,   395,   473,   363,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     395,     0,     0,   475,     0,   338,   255,     0,    53,   231,
     230,   229,     0,     0,   382,     0,     0,   228,   227,     0,
     214,   215,   385,     0,   224,   376,     0,   468,   474,     0,
     362,   485,   486,   483,   495,   496,   489,   490,   479,   480,
     481,   482,   476,   477,   478,   493,   491,   492,     0,   488,
       0,     0,     0,   494,     0,   487,     0,   205,   381,   395,
      53,   223,   222,     0,     0,   224,     0,   375,   386,     0,
       0,   501,   500,   466,     0,   484,   499,     0,     0,   211,
       0,     0,   217,     0,     0,     0,    53,   225,   226,     0,
     497,   395,     0,   383,   379,     0,   218,   220,   221,     0,
     467,     0,   210,   212,     0,   216,     0,   384,   498,     0,
     219,     0,   213
  };

  const short
  P4Parser::yypgoto_[] =
  {
    -846,  -846,  -846,  -846,  -846,  -846,  -846,    -3,    42,  -846,
    -846,   179,   -13,   -89,  -270,  -846,   -12,   477,  -442,  -846,
     178,  -846,  -846,  -846,  -846,  -460,    35,  -846,  -846,  -846,
     554,   265,  -846,  -846,  -846,  -846,  -846,  -846,  -846,   136,
    -846,  -148,  -846,  -846,  -846,  -846,  -846,  -846,  -846,  -846,
    -281,  -846,  -846,  -846,  -845,  -846,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -188,  -846,  -846,
     727,   -99,  -846,   314,    63,  -846,   557,    71,  -846,   164,
    -846,  -846,  -291,  -187,  -846,  -171,  -846,    23,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,  -846,  -846,  -308,  -846,  -846,
    -846,  -846,  -846,    45,  -846,  -846,  -181,  -846,  -693,  -690,
    -846,  -846,  -683,  -682,  -673,  -100,  -846,  -846,  -846,  -846,
    -846,  -846,  -846,  -846,  -846,     4,  -846,  -846,  -846,  -217,
    -173,  -846,   225,  -444,   -16,    82,  -611,     3,  -109,  -846,
     379,   -24,  -793,   -37,  -846,  -846,   518,  -846,     0,  -846,
    -846,  -846,   748,  -251
  };

  const short
  P4Parser::yydefgoto_[] =
  {
       0,    18,    19,   282,    20,    21,    91,    43,   226,   759,
     716,   317,   213,    94,   292,   449,    54,    55,   318,   319,
     320,   474,    95,   465,   558,    96,   640,   670,   704,   729,
     209,    44,    98,   477,   522,    99,   466,   559,   523,   524,
     654,   709,   738,   739,   808,   740,   770,   771,   942,   953,
     869,   870,   945,   913,   871,   525,   100,   101,   455,   552,
     478,   532,   570,   102,   458,   555,   646,   103,   483,   677,
     235,    45,    46,    47,   106,   107,    48,   109,   110,   327,
     328,   485,   236,   237,   265,   266,   111,   112,   113,   461,
     556,   114,   467,   560,   115,   462,   557,   647,   680,   116,
     456,   509,   609,   610,   117,   118,   288,   119,   585,   586,
     587,   588,   589,   590,   591,   592,   479,   537,   593,   761,
     800,   801,   594,   533,   694,   695,   779,   815,   778,   863,
     872,   873,   120,   746,   747,   624,   550,   122,   227,   228,
     229,    49,   597,   169,   231,   598,   230,   802,    60,    57,
      61,    63,   170,   338
  };

  const short
  P4Parser::yytable_[] =
  {
      52,   129,   293,   214,   204,   121,   291,   304,    93,    66,
     143,   505,   659,   128,   352,   345,   742,   521,   531,   743,
     864,   914,   127,   720,   285,    79,   744,   745,    56,   289,
     294,   220,   673,   527,   535,   354,   726,   497,   191,   358,
     172,   138,   450,   192,   452,    53,   488,    28,   172,    62,
      79,   -53,   323,   491,   566,   675,   207,   259,   678,   681,
     717,    85,    80,    81,   208,   684,    79,    53,    79,    79,
     203,   572,    79,    79,    79,  -155,    52,   582,    83,    79,
      65,   192,    52,    79,   691,   286,    85,   782,   946,    86,
     290,   295,   221,   595,    87,   143,    88,   601,    89,    90,
      40,   145,    85,   692,    85,    85,   324,    52,    85,    85,
      85,   960,   812,   355,   772,    85,   279,    75,   503,    85,
      79,   183,   356,   864,   204,    28,    79,   188,   471,   472,
     691,   906,    67,    52,   145,   473,   127,   -45,    32,    33,
     194,   234,   280,   192,   196,   197,    34,   192,   498,   692,
     -45,   -45,   218,   140,   141,   281,    85,    36,   359,   145,
      37,   201,    85,   127,   642,   742,    38,   356,   743,    52,
     818,   563,   649,   650,   271,   744,   745,    39,   224,   207,
     564,   217,    52,    69,    52,    70,   234,   210,    52,  -262,
      52,    52,   302,    52,    52,   607,    52,    52,    52,    72,
      92,   157,   158,   159,   356,   335,   336,   470,   163,    73,
     163,   337,   127,   141,    53,   141,   166,   -37,   166,   -37,
     -37,   310,   142,   955,   142,   315,   956,   287,    52,   287,
      74,   -37,    28,   296,   541,   298,   299,   303,   306,   307,
     136,   311,   312,   313,   728,   544,   283,    80,    81,   545,
      76,   546,   139,   548,   284,   203,   216,   215,   644,   351,
     140,   141,   753,    83,  -261,   140,   141,   645,   171,   754,
     142,   350,   145,   334,    86,   142,    32,    33,   172,    87,
     127,    88,   212,   755,    34,    40,    97,   173,   634,   756,
     766,   174,   140,   141,    52,    36,   635,    52,    37,   175,
     757,   758,   142,   636,    38,   648,    52,    52,   651,    32,
      33,    52,    52,   127,   177,    39,    51,    34,   216,    58,
      59,   178,   140,   141,   180,    53,    52,   553,    36,   181,
     127,    37,   633,   182,   234,   105,   185,    38,   187,   454,
     132,   234,   457,   206,   335,   336,   335,   336,    39,    77,
     344,   463,   464,    52,   215,   316,   468,   469,    97,   335,
     336,   137,   216,   599,   600,   540,   140,   141,   217,   617,
     618,   484,   222,   219,    32,    33,   -44,   308,   258,   270,
     274,   308,    34,   543,   272,    28,   316,    78,    79,   277,
     275,   278,   321,    36,   322,   323,    37,   331,   501,   333,
      80,    81,    38,   332,   687,   688,   689,   105,    82,    97,
     342,   347,   348,    39,    51,   453,    83,   475,   703,    84,
     -44,   459,   460,   476,    85,   480,   492,    86,   494,   571,
     506,   204,    87,   495,    88,   496,    89,    90,    40,   508,
     516,   539,   554,   549,   603,   605,   606,    32,    33,   604,
     611,   669,   612,   613,    97,    34,   616,    97,   105,    97,
      97,   528,   536,    97,   520,   520,    36,    97,   614,    37,
     615,    32,    33,   619,   563,    38,   623,    52,   625,    34,
     627,   628,   631,   639,   132,   641,    39,    51,   707,   127,
      36,   768,   643,    37,   660,   661,   665,   672,   671,    38,
     682,   683,   685,   105,   686,    52,   105,   701,   105,   105,
      39,    51,   105,    52,    52,   690,   105,   731,   698,   710,
      50,   596,   538,    52,   520,    64,   667,    32,    33,    68,
     711,   712,    71,   713,   580,    34,   714,    52,   715,   721,
     123,   124,   125,    50,   134,   135,    36,   724,   725,    37,
     287,    52,   732,   751,   733,    38,   752,   633,   561,   562,
      52,   637,    52,   760,   762,   765,    39,   137,   569,    52,
     774,    28,   767,   574,    79,   803,   780,   781,   108,   804,
     632,   575,   602,   133,    32,    33,   805,   806,   807,   722,
     817,   827,    34,   829,   825,   576,   608,   855,   876,   577,
     856,   859,    97,    36,   900,   620,    37,   622,   860,    97,
      85,   578,    38,   861,   626,   579,   764,   875,   908,   507,
     909,   916,   510,    39,    40,   511,   512,   922,   926,   513,
     514,   515,   127,   929,  -228,   234,  -227,   932,   204,   933,
     941,   944,    52,   943,   958,   957,   962,   959,   204,   269,
     108,   105,   652,   928,   518,   211,   519,   530,   105,   568,
     858,   954,   798,   238,   239,   240,   241,   242,   243,   244,
     245,   246,   247,   248,   249,   250,   251,   252,   253,   254,
     255,   256,   257,   904,   656,   260,   261,   608,   267,   268,
     674,   727,   657,   580,   273,   127,   737,   276,   718,   936,
     918,   108,   567,   534,   658,    52,   580,   730,   212,     0,
       0,     0,   487,     0,     0,     0,   581,     0,   879,     0,
       0,     0,   127,     0,     0,     0,     0,   133,   212,   880,
       0,     0,    52,     0,   325,   326,     0,     0,    52,    97,
     330,   901,    97,    97,     0,     0,   108,     0,   104,   108,
     734,   108,   108,   131,     0,   108,     0,   580,   796,   108,
       0,     0,   828,     0,     0,   853,     0,     0,     0,     0,
      52,     0,    52,    52,    52,     0,   341,   769,     0,     0,
       0,     0,   857,   569,     0,    97,     0,     0,   105,     0,
       0,   105,   105,     0,   826,   144,     0,     0,     0,     0,
     930,    50,   583,   353,     0,     0,     0,   357,     0,     0,
     580,     0,   451,     0,     0,   622,     0,   809,   810,   811,
     205,     0,    52,     0,   127,   676,   679,   679,     0,   184,
     679,   186,   951,     0,   105,   189,   190,     0,     0,     0,
     693,     0,     0,     0,     0,   737,     0,   127,     0,   486,
       0,   584,     0,   144,     0,   580,     0,     0,   489,   632,
       0,   490,    52,     0,   493,     0,     0,   878,     0,     0,
       0,     0,     0,   693,     0,   212,     0,     0,     0,     0,
     144,     0,     0,     0,     0,     0,    97,     0,   736,     0,
       0,     0,     0,     0,   108,     0,     0,   264,     0,     0,
       0,   108,     0,    97,     0,     0,   127,   910,     0,     0,
       0,     0,     0,   580,     0,     0,     0,     0,     0,   297,
       0,   300,   305,     0,     0,   309,     0,     0,     0,   314,
       0,     0,     0,     0,     0,   655,     0,     0,   127,   212,
       0,    97,     0,     0,    97,     0,     0,     0,     0,     0,
       0,     0,   105,     0,     0,     0,    52,   813,     0,     0,
       0,   583,     0,     0,    28,     0,   329,     0,     0,    97,
      97,     0,     0,     0,   583,     0,     0,    32,    33,    80,
      81,     0,     0,     0,     0,    34,     0,   203,     0,     0,
     105,     0,    97,   105,     0,    83,    36,     0,     0,    37,
       0,   961,    97,     0,     0,    38,    86,     0,   212,     0,
     719,    87,     0,    88,     0,    89,   301,   126,   105,   105,
       0,     0,     0,   584,   551,   583,   797,   349,     0,     0,
       0,   108,     0,     0,   108,   108,     0,   736,     0,     0,
       0,   105,     0,     0,     0,     0,     0,    22,    23,     0,
       0,   105,     0,     0,     0,     0,     0,    24,     0,     0,
      25,     0,     0,     0,     0,     0,    26,     0,    27,     0,
       0,     0,    28,     0,   719,   799,     0,   108,   862,     0,
      29,    30,    31,     0,     0,    32,    33,    80,    81,   931,
       0,     0,     0,    34,   108,   130,   630,     0,     0,     0,
       0,   132,     0,    83,    36,     0,     0,    37,     0,     0,
       0,     0,     0,    38,    86,   949,     0,     0,     0,    87,
       0,    88,     0,   583,    39,    40,    41,    42,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   653,     0,     0,
       0,   551,     0,     0,    28,     0,   662,     0,     0,   664,
       0,     0,   666,     0,   668,     0,     0,    32,    33,    80,
      81,   551,     0,     0,     0,    34,     0,   203,   132,     0,
       0,     0,   584,     0,     0,    83,    36,     0,     0,    37,
     132,   862,     0,     0,     0,    38,    86,     0,     0,     0,
       0,    87,     0,    88,     0,   108,    39,   126,     0,     0,
       0,   517,     0,   329,   526,   526,   329,     0,     0,   329,
     329,     0,     0,   329,   329,   329,     0,     0,   723,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   748,   749,
     750,     0,     0,   108,    28,     0,   108,    79,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   565,   529,    80,
      81,     0,     0,     0,     0,     0,     0,   203,     0,     0,
       0,   108,   108,     0,   526,    83,   108,     0,     0,     0,
       0,     0,     0,    85,     0,     0,    86,     0,     0,     0,
       0,    87,     0,    88,   108,     0,     0,    40,     0,     0,
       0,     0,    28,     0,   108,    79,     0,   816,     0,   551,
       0,   819,   820,   821,     0,   823,   824,    80,    81,     0,
       0,     0,   621,     0,     0,   203,     0,     0,     0,     0,
       0,     0,     0,    83,    50,     0,     0,     0,     0,     0,
       0,    85,   144,     0,    86,   874,     0,     0,     0,    87,
       0,    88,     0,     0,   133,    40,   638,     0,   881,   882,
     883,   884,   885,   886,   887,   888,   889,   890,   891,   892,
     893,   894,   895,   896,   897,   898,   899,     0,     0,   902,
     903,     0,   905,     0,     0,     0,     0,    28,     0,     0,
       0,     0,     0,     0,   915,     0,     0,     0,   705,     0,
       0,   874,    80,    81,   921,     0,     0,     0,     0,     0,
     203,     0,     0,   305,     0,     0,   708,     0,    83,     0,
       0,   133,     0,     0,     0,   108,     0,     0,   925,    86,
       0,     0,     0,   133,    87,     0,    88,     0,    89,    90,
     706,   104,   305,     0,     0,     0,   741,   937,   938,     0,
       0,     0,   939,     0,     0,   940,    22,    23,     0,     0,
       0,   874,   947,   948,   205,     0,    24,     0,     0,    25,
     874,     0,     0,     0,   773,    26,     0,    27,     0,     0,
       0,    28,     0,     0,   874,     0,   262,     0,     0,    29,
      30,    31,     0,     0,    32,    33,    80,    81,     0,     0,
       0,     0,    34,     0,   130,     0,     0,     0,     0,     0,
       0,     0,    83,    36,     0,     0,    37,     0,     0,     0,
       0,     0,    38,    86,   822,     0,     0,     0,    87,   573,
      88,     0,   263,    39,    40,    41,    42,     0,     0,     0,
      28,     0,   574,    79,     0,     0,     0,     0,     0,     0,
     575,     0,     0,    32,    33,    80,    81,   144,     0,     0,
     854,    34,     0,   203,   576,     0,     0,     0,   577,     0,
       0,    83,    36,     0,     0,    37,     0,     0,     0,    85,
     578,    38,    86,     0,   579,     0,     0,    87,     0,    88,
       0,   264,    39,    40,     0,   741,     0,     0,     0,     0,
       0,     0,     0,   131,   360,   361,   362,   363,   364,   365,
     366,   367,   368,   369,   370,   371,   372,   373,   374,   375,
     376,   377,   378,   379,   380,   381,   382,   383,   384,   385,
     386,   387,   388,     0,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429,   430,   431,   432,   433,   434,
     435,   436,   437,   438,   439,   440,   441,   442,   443,   444,
     445,   446,   447,   448,   360,     0,   362,   363,   364,   365,
     366,   367,   368,   369,   370,   371,   372,   373,   374,   375,
     376,   377,   378,   379,   380,   381,   382,   383,   384,   385,
     386,   387,   388,   499,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429,   430,   431,   432,   433,   434,
     435,   436,   437,   438,   439,   440,   441,   442,   443,   444,
     445,   446,   447,   448,   360,     0,   362,   363,   364,   365,
     366,   367,   368,   369,   370,   371,   372,   373,   374,   375,
     376,   377,   378,   379,   380,   381,   382,   383,   384,   385,
     386,   387,   388,   547,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429,   430,   431,   432,   433,   434,
     435,   436,   437,   438,   439,   440,   441,   442,   443,   444,
     445,   446,   447,   448,    22,    23,     0,     0,     0,     0,
       0,     0,     0,     0,    24,     0,     0,    25,     0,     0,
       0,     0,     0,    26,     0,    27,     0,     0,     0,    28,
       0,     0,     0,     0,   911,     0,     0,    29,    30,    31,
       0,     0,    32,    33,    80,    81,     0,     0,   912,     0,
      34,     0,   130,     0,     0,     0,     0,     0,     0,     0,
      83,    36,     0,     0,    37,     0,     0,     0,     0,     0,
      38,    86,     0,     0,     0,     0,    87,     0,    88,    22,
      23,    39,    40,    41,    42,     0,     0,     0,     0,    24,
       0,     0,    25,   917,     0,     0,     0,     0,   866,     0,
      27,     0,     0,     0,    28,     0,     0,     0,     0,   867,
       0,     0,    29,    30,    31,     0,     0,    32,    33,     0,
       0,     0,     0,   868,     0,    34,     0,    35,     0,     0,
      22,    23,     0,     0,     0,     0,    36,     0,     0,    37,
      24,     0,     0,    25,   952,    38,     0,     0,     0,   866,
       0,    27,     0,     0,     0,    28,    39,    40,    41,    42,
     867,     0,     0,    29,    30,    31,     0,     0,    32,    33,
       0,     0,     0,     0,   868,     0,    34,     0,    35,     0,
       0,    22,    23,     0,     0,     0,     0,    36,     0,     0,
      37,    24,     0,     0,    25,     0,    38,     0,     0,     0,
     866,     0,    27,     0,     0,     0,    28,    39,    40,    41,
      42,   867,     0,     0,    29,    30,    31,     0,     0,    32,
      33,     0,     0,     0,     0,   868,     0,    34,     0,    35,
       0,     0,    22,    23,     0,     0,     0,     0,    36,     0,
       0,    37,    24,     0,     0,    25,     0,    38,     0,     0,
       0,    26,     0,    27,     0,     0,     0,    28,    39,    40,
      41,    42,   867,     0,     0,    29,    30,    31,     0,     0,
      32,    33,     0,     0,     0,     0,   868,     0,    34,     0,
      35,     0,     0,    22,    23,     0,     0,     0,     0,    36,
       0,     0,    37,    24,     0,     0,    25,     0,    38,     0,
       0,     0,    26,     0,    27,     0,     0,     0,    28,    39,
      40,    41,    42,   225,     0,     0,    29,    30,    31,     0,
       0,    32,    33,     0,     0,     0,     0,     0,     0,    34,
       0,    35,    22,    23,     0,     0,     0,     0,     0,     0,
      36,     0,    24,    37,     0,    25,     0,     0,     0,    38,
       0,    26,     0,    27,     0,     0,     0,    28,     0,   629,
      39,   126,    41,    42,     0,    29,    30,    31,     0,     0,
      32,    33,     0,     0,     0,     0,     0,     0,    34,     0,
      35,   783,   784,     0,     0,     0,     0,     0,     0,    36,
       0,   785,    37,     0,     0,   786,     0,     0,    38,     0,
     787,     0,   788,     0,     0,     0,    28,     0,     0,    39,
      40,    41,    42,     0,   789,   790,   791,     0,     0,    32,
      33,     0,     0,     0,     0,   792,     0,    34,     0,   793,
      22,    23,     0,     0,     0,     0,     0,     0,    36,     0,
      24,    37,     0,    25,   814,     0,     0,    38,     0,    26,
       0,    27,     0,     0,     0,    28,     0,     0,    39,    40,
     794,   795,     0,    29,    30,    31,     0,     0,    32,    33,
       0,     0,     0,     0,     0,     0,    34,     0,    35,    22,
      23,     0,     0,     0,     0,     0,     0,    36,     0,    24,
      37,     0,    25,     0,     0,     0,    38,     0,    26,     0,
      27,     0,     0,     0,    28,     0,     0,    39,    40,    41,
      42,     0,    29,    30,    31,     0,     0,    32,    33,     0,
       0,     0,     0,     0,     0,    34,     0,    35,    22,    23,
       0,     0,     0,     0,     0,     0,    36,     0,    24,    37,
       0,    25,     0,     0,     0,    38,     0,    26,     0,    27,
       0,     0,     0,    28,     0,     0,    39,    40,    41,    42,
       0,    29,    30,    31,     0,     0,    32,    33,     0,     0,
       0,     0,     0,     0,    34,     0,    35,     0,     0,     0,
       0,     0,     0,     0,     0,    36,     0,     0,    37,  -206,
       0,     0,     0,     0,    38,     0,     0,     0,     0,     0,
      28,     0,   574,    79,     0,    39,   126,    41,    42,     0,
     575,     0,     0,    32,    33,    80,    81,     0,     0,     0,
       0,    34,     0,   203,     0,     0,     0,     0,   577,     0,
       0,    83,    36,     0,     0,    37,     0,   907,     0,    85,
       0,    38,    86,     0,     0,     0,   735,    87,    28,    88,
     574,    79,    39,    40,     0,     0,     0,     0,   575,     0,
       0,    32,    33,    80,    81,     0,     0,     0,     0,    34,
       0,   203,     0,     0,     0,     0,   577,     0,     0,    83,
      36,     0,     0,    37,     0,     0,     0,    85,     0,    38,
      86,    28,     0,     0,     0,    87,   232,    88,     0,     0,
      39,    40,     0,     0,    32,    33,    80,    81,     0,     0,
       0,     0,    34,     0,   203,     0,     0,     0,     0,     0,
       0,     0,    83,    36,     0,     0,    37,     0,     0,     0,
      28,     0,    38,    86,     0,     0,     0,     0,    87,     0,
      88,     0,   233,    39,    40,    80,    81,     0,     0,     0,
       0,     0,     0,   203,     0,     0,     0,     0,     0,     0,
       0,    83,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    86,     0,     0,     0,     0,    87,     0,    88,
       0,    89,    90,    40,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,     0,     0,     0,   140,   141,   164,   165,
     166,   223,     0,     0,     0,   167,   142,     0,     0,     0,
     168,     0,   934,   935,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,     0,     0,     0,   140,   141,   164,   165,
     166,     0,     0,     0,     0,   167,   142,     0,     0,     0,
     168,     0,   919,   920,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,   339,     0,     0,   140,   141,   164,   165,
     166,     0,     0,   340,     0,   167,   142,     0,     0,     0,
     168,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,     0,   163,
     699,     0,     0,   140,   141,   164,   165,   166,     0,     0,
     700,     0,   167,   142,     0,     0,     0,   168,   146,   147,
     148,   149,   150,   151,   152,   153,   154,   155,   156,   157,
     158,   159,   160,   161,   162,     0,   163,   923,     0,     0,
     140,   141,   164,   165,   166,     0,     0,   924,     0,   167,
     142,     0,     0,     0,   168,   146,   147,   148,   149,   150,
     151,   152,   153,   154,   155,   156,   157,   158,   159,   160,
     161,   162,     0,   163,     0,     0,     0,   140,   141,   164,
     165,   166,     0,     0,     0,   176,   167,   142,     0,     0,
       0,   168,   146,   147,   148,   149,   150,   151,   152,   153,
     154,   155,   156,   157,   158,   159,   160,   161,   162,     0,
     163,     0,     0,     0,   140,   141,   164,   165,   166,     0,
       0,     0,   179,   167,   142,     0,     0,     0,   168,   146,
     147,   148,   149,   150,   151,   152,   153,   154,   155,   156,
     157,   158,   159,   160,   161,   162,     0,   163,     0,     0,
       0,   140,   141,   164,   165,   166,   223,     0,     0,     0,
     167,   142,     0,     0,     0,   168,   146,   147,   148,   149,
     150,   151,   152,   153,   154,   155,   156,   157,   158,   159,
     160,   161,   162,     0,   163,     0,     0,     0,   140,   141,
     164,   165,   166,     0,     0,   343,     0,   167,   142,     0,
       0,     0,   168,   146,   147,   148,   149,   150,   151,   152,
     153,   154,   155,   156,   157,   158,   159,   160,   161,   162,
       0,   163,     0,     0,     0,   140,   141,   164,   165,   166,
       0,     0,     0,   346,   167,   142,     0,     0,     0,   168,
     146,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156,   157,   158,   159,   160,   161,   162,     0,   163,   481,
       0,     0,   140,   141,   164,   165,   166,     0,     0,     0,
       0,   167,   142,     0,     0,     0,   168,   146,   147,   148,
     149,   150,   151,   152,   153,   154,   155,   156,   157,   158,
     159,   160,   161,   162,     0,   163,   482,     0,     0,   140,
     141,   164,   165,   166,     0,     0,     0,     0,   167,   142,
       0,     0,     0,   168,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,     0,     0,     0,   140,   141,   164,   165,
     166,   500,     0,     0,     0,   167,   142,     0,     0,     0,
     168,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,     0,   163,
       0,     0,     0,   140,   141,   164,   165,   166,   502,     0,
       0,     0,   167,   142,     0,     0,     0,   168,   146,   147,
     148,   149,   150,   151,   152,   153,   154,   155,   156,   157,
     158,   159,   160,   161,   162,     0,   163,     0,     0,     0,
     140,   141,   164,   165,   166,   504,     0,     0,     0,   167,
     142,     0,     0,     0,   168,   146,   147,   148,   149,   150,
     151,   152,   153,   154,   155,   156,   157,   158,   159,   160,
     161,   162,     0,   163,   542,     0,     0,   140,   141,   164,
     165,   166,     0,     0,     0,     0,   167,   142,     0,     0,
       0,   168,   146,   147,   148,   149,   150,   151,   152,   153,
     154,   155,   156,   157,   158,   159,   160,   161,   162,     0,
     163,     0,     0,     0,   140,   141,   164,   165,   166,     0,
       0,     0,     0,   167,   142,     0,   663,     0,   168,   146,
     147,   148,   149,   150,   151,   152,   153,   154,   155,   156,
     157,   158,   159,   160,   161,   162,     0,   163,     0,     0,
       0,   140,   141,   164,   165,   166,   696,     0,     0,     0,
     167,   142,     0,     0,     0,   168,   146,   147,   148,   149,
     150,   151,   152,   153,   154,   155,   156,   157,   158,   159,
     160,   161,   162,     0,   163,     0,     0,     0,   140,   141,
     164,   165,   166,   697,     0,     0,     0,   167,   142,     0,
       0,     0,   168,   146,   147,   148,   149,   150,   151,   152,
     153,   154,   155,   156,   157,   158,   159,   160,   161,   162,
       0,   163,     0,     0,     0,   140,   141,   164,   165,   166,
       0,     0,     0,     0,   167,   142,     0,   702,     0,   168,
     146,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156,   157,   158,   159,   160,   161,   162,     0,   163,   763,
       0,     0,   140,   141,   164,   165,   166,     0,     0,     0,
       0,   167,   142,     0,     0,     0,   168,   146,   147,   148,
     149,   150,   151,   152,   153,   154,   155,   156,   157,   158,
     159,   160,   161,   162,     0,   163,     0,     0,     0,   140,
     141,   164,   165,   166,   775,     0,     0,     0,   167,   142,
       0,     0,     0,   168,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,     0,     0,     0,   140,   141,   164,   165,
     166,   776,     0,     0,     0,   167,   142,     0,     0,     0,
     168,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,     0,   163,
       0,     0,     0,   140,   141,   164,   165,   166,   777,     0,
       0,     0,   167,   142,     0,     0,     0,   168,   146,   147,
     148,   149,   150,   151,   152,   153,   154,   155,   156,   157,
     158,   159,   160,   161,   162,     0,   163,     0,     0,     0,
     140,   141,   164,   165,   166,     0,     0,   865,     0,   167,
     142,     0,     0,     0,   168,   146,   147,   148,   149,   150,
     151,   152,   153,   154,   155,   156,   157,   158,   159,   160,
     161,   162,     0,   163,     0,     0,     0,   140,   141,   164,
     165,   166,   877,     0,     0,     0,   167,   142,     0,     0,
       0,   168,   146,   147,   148,   149,   150,   151,   152,   153,
     154,   155,   156,   157,   158,   159,   160,   161,   162,     0,
     163,     0,     0,     0,   140,   141,   164,   165,   166,     0,
       0,   927,     0,   167,   142,     0,     0,     0,   168,   146,
     147,   148,   149,   150,   151,   152,   153,   154,   155,   156,
     157,   158,   159,   160,   161,   162,     0,   163,   950,     0,
       0,   140,   141,   164,   165,   166,     0,     0,     0,     0,
     167,   142,     0,     0,     0,   168,   146,   147,   148,   149,
     150,   151,   152,   153,   154,   155,   156,   157,   158,   159,
     160,   161,   162,     0,   163,     0,     0,     0,   140,   141,
     164,   165,   166,     0,     0,     0,  -225,   167,   142,     0,
       0,     0,   168,   146,   147,   148,   149,   150,   151,   152,
     153,   154,   155,   156,   157,   158,   159,   160,   161,   162,
       0,   163,     0,     0,     0,   140,   141,   164,   165,   166,
       0,     0,     0,  -226,   167,   142,     0,     0,     0,   168,
     146,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156,   157,   158,   159,   160,   161,   162,     0,   163,     0,
       0,     0,   140,   141,   164,   165,   166,     0,     0,     0,
       0,   167,   142,     0,     0,     0,   168,   830,   831,   832,
     833,   834,   835,   836,   837,   838,   839,   840,   841,   842,
     843,   844,   845,   846,     0,   847,     0,     0,     0,   140,
     141,   848,   849,   850,     0,     0,     0,     0,   851,   142,
       0,     0,     0,   852,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,     0,     0,     0,   140,   141,   164,   165,
     166,     0,     0,     0,     0,     0,   142,     0,     0,     0,
     168,   146,   147,   148,   149,     0,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,     0,   163,
       0,     0,     0,   140,   141,   164,   165,   166,     0,     0,
       0,     0,     0,   142,   146,   147,   148,   168,     0,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,     0,   163,     0,     0,     0,   140,   141,   164,   165,
     166,     0,     0,     0,     0,     0,   142,   146,   147,   148,
     168,     0,     0,     0,   153,   154,   155,   156,   157,   158,
     159,   160,   161,   162,     0,   163,     0,     0,     0,   140,
     141,   164,   165,   166,     0,   191,     0,     0,     0,   142,
     192,   193,     0,   168,     0,   194,     0,     0,   195,   196,
     197,     0,     0,     0,     0,     0,     0,     0,   198,     0,
     199,   200,     0,     0,     0,     0,   201,   148,     0,     0,
       0,   202,   153,   154,   155,   156,   157,   158,   159,   160,
     161,   162,     0,   163,     0,     0,     0,     0,   141,     0,
     165,   166,     0,     0,     0,     0,     0,   142,   148,     0,
       0,   168,     0,   153,   154,   155,   156,   157,   158,   159,
       0,   161,   162,     0,   163,     0,     0,     0,     0,   141,
       0,   165,   166,     0,     0,     0,     0,     0,   142,   148,
       0,     0,   168,     0,   153,   154,   155,   156,   157,   158,
     159,     0,   161,     0,     0,   163,     0,     0,     0,     0,
     141,     0,   165,   166,     0,     0,     0,     0,     0,   142,
     148,     0,     0,   168,     0,   153,   154,   155,   156,   157,
     158,   159,     0,     0,     0,     0,   163,     0,     0,     0,
       0,   141,     0,   165,   166,     0,     0,     0,     0,     0,
     142,     0,     0,     0,   168,   153,   154,   155,   156,   157,
     158,   159,     0,     0,     0,     0,   163,     0,     0,     0,
       0,   141,     0,     0,   166,     0,     0,     0,     0,     0,
     142,     0,     0,     0,   168,     1,     2,     3,     4,     5,
       6,     7,     8,     9,    10,    11,    12,    13,    14,    15,
      16,    17
  };

  const short
  P4Parser::yycheck_[] =
  {
       3,    25,   189,   103,    93,    21,   187,   195,    21,     9,
      47,   453,   623,    25,   284,   266,   709,   477,   478,   709,
     813,   866,    25,   696,    50,    59,   709,   709,   111,    50,
      50,    45,   643,   477,   478,   286,    45,    43,    68,   290,
      54,    44,   293,    73,   295,     3,   337,    56,    54,   110,
      59,    44,    44,   344,    45,    45,    50,   166,    45,    45,
      45,    95,    71,    72,    58,    45,    59,    25,    59,    59,
      79,   101,    59,    59,    59,    51,    79,   537,    87,    59,
     111,    73,    85,    59,    69,   111,    95,   760,   933,    98,
     111,   111,    45,   537,   103,   132,   105,   539,   107,   108,
     109,    54,    95,    88,    95,    95,   215,   110,    95,    95,
      95,   956,    45,    45,    44,    95,    72,     0,   388,    95,
      59,    79,    54,   916,   213,    56,    59,    85,    85,    86,
      69,    51,   110,   136,    54,    92,   139,    44,    69,    70,
      78,   144,    98,    73,    82,    83,    77,    73,    43,    88,
      57,    58,   110,    46,    47,   111,    95,    88,    45,    54,
      91,    99,    95,   166,   606,   858,    97,    54,   858,   172,
     781,    97,   614,   615,   174,   858,   858,   108,   136,    50,
     106,    42,   185,   111,   187,   110,   189,    58,   191,    50,
     193,   194,   195,   196,   197,    45,   199,   200,   201,   111,
      21,    35,    36,    37,    54,    48,    49,   316,    42,   110,
      42,    54,   215,    47,   172,    47,    50,    44,    50,    46,
      47,   198,    56,    51,    56,   202,    54,   185,   231,   187,
     110,    58,    56,   191,   485,   193,   194,   195,   196,   197,
      56,   199,   200,   201,   704,   496,    42,    71,    72,   500,
      21,   502,    50,   504,    50,    79,    42,    50,    45,   283,
      46,    47,    70,    87,    50,    46,    47,    54,    57,    77,
      56,   283,    54,   231,    98,    56,    69,    70,    54,   103,
     283,   105,   103,    91,    77,   109,    21,    54,    42,    97,
     732,    54,    46,    47,   297,    88,    50,   300,    91,    54,
     108,   109,    56,    57,    97,   613,   309,   310,   616,    69,
      70,   314,   315,   316,    54,   108,   109,    77,    42,   110,
     111,    54,    46,    47,    54,   283,   329,   508,    88,    54,
     333,    91,    56,    54,   337,    21,    44,    97,    44,   297,
      26,   344,   300,    58,    48,    49,    48,    49,   108,    20,
      54,   309,   310,   356,    50,    50,   314,   315,    93,    48,
      49,   109,    42,    57,    58,    54,    46,    47,    42,    57,
      58,   329,    51,    58,    69,    70,    57,   198,    48,   111,
     111,   202,    77,   492,   110,    56,    50,    58,    59,   111,
     110,   110,    44,    88,    44,    44,    91,    57,   356,    54,
      71,    72,    97,    51,   655,   656,   657,    93,    79,   144,
      51,    54,    54,   108,   109,    50,    87,    51,   669,    90,
      58,    58,    58,    54,    95,    51,    50,    98,   111,   529,
      57,   520,   103,   110,   105,   111,   107,   108,   109,    44,
      51,    50,    44,    51,    51,    58,    50,    69,    70,   549,
      44,   638,    44,    44,   189,    77,    44,   192,   144,   194,
     195,   477,   478,   198,   477,   478,    88,   202,    50,    91,
      50,    69,    70,    57,    97,    97,    57,   480,    45,    77,
      58,    50,    50,    44,   170,    51,   108,   109,   676,   492,
      88,    89,    57,    91,    58,    44,    70,    51,    58,    97,
      51,    51,    58,   189,    44,   508,   192,    51,   194,   195,
     108,   109,   198,   516,   517,    58,   202,   705,    50,    50,
       2,   537,   480,   526,   537,     7,   635,    69,    70,    11,
      50,    50,    14,    57,   537,    77,    57,   540,    73,    44,
      22,    23,    24,    25,    26,    27,    88,    58,    50,    91,
     508,   554,    50,    44,    58,    97,    44,    56,   516,   517,
     563,   598,   565,    76,    51,    58,   108,   109,   526,   572,
      45,    56,    58,    58,    59,    58,    57,    57,    21,    51,
     583,    66,   540,    26,    69,    70,    51,    50,    58,   698,
      44,    50,    77,    53,    56,    80,   554,    58,    51,    84,
      58,    58,   337,    88,    48,   563,    91,   565,    58,   344,
      95,    96,    97,    58,   572,   100,   725,    58,    58,   455,
      50,    53,   458,   108,   109,   461,   462,    51,    51,   465,
     466,   467,   635,    44,    54,   638,    54,    51,   727,    54,
      50,    58,   645,    51,    51,    58,    58,    53,   737,   172,
      93,   337,   617,   904,   476,   101,   477,   478,   344,   523,
     808,   942,   761,   145,   146,   147,   148,   149,   150,   151,
     152,   153,   154,   155,   156,   157,   158,   159,   160,   161,
     162,   163,   164,   854,   621,   167,   168,   645,   170,   171,
     645,   704,   621,   696,   176,   698,   709,   179,   694,   916,
     873,   144,   523,   478,   622,   708,   709,   704,   529,    -1,
      -1,    -1,   333,    -1,    -1,    -1,   537,    -1,   827,    -1,
      -1,    -1,   725,    -1,    -1,    -1,    -1,   170,   549,   829,
      -1,    -1,   735,    -1,   216,   217,    -1,    -1,   741,   474,
     222,   850,   477,   478,    -1,    -1,   189,    -1,    21,   192,
     708,   194,   195,    26,    -1,   198,    -1,   760,   761,   202,
      -1,    -1,   799,    -1,    -1,   802,    -1,    -1,    -1,    -1,
     773,    -1,   775,   776,   777,    -1,   258,   735,    -1,    -1,
      -1,    -1,   806,   741,    -1,   520,    -1,    -1,   474,    -1,
      -1,   477,   478,    -1,   797,    47,    -1,    -1,    -1,    -1,
     909,   283,   537,   285,    -1,    -1,    -1,   289,    -1,    -1,
     813,    -1,   294,    -1,    -1,   773,    -1,   775,   776,   777,
      93,    -1,   825,    -1,   827,   646,   647,   648,    -1,    81,
     651,    83,   941,    -1,   520,    87,    88,    -1,    -1,    -1,
     661,    -1,    -1,    -1,    -1,   858,    -1,   850,    -1,   331,
      -1,   537,    -1,   105,    -1,   858,    -1,    -1,   340,   862,
      -1,   343,   865,    -1,   346,    -1,    -1,   825,    -1,    -1,
      -1,    -1,    -1,   694,    -1,   696,    -1,    -1,    -1,    -1,
     132,    -1,    -1,    -1,    -1,    -1,   621,    -1,   709,    -1,
      -1,    -1,    -1,    -1,   337,    -1,    -1,   170,    -1,    -1,
      -1,   344,    -1,   638,    -1,    -1,   909,   865,    -1,    -1,
      -1,    -1,    -1,   916,    -1,    -1,    -1,    -1,    -1,   192,
      -1,   194,   195,    -1,    -1,   198,    -1,    -1,    -1,   202,
      -1,    -1,    -1,    -1,    -1,   621,    -1,    -1,   941,   760,
      -1,   676,    -1,    -1,   679,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   638,    -1,    -1,    -1,   959,   778,    -1,    -1,
      -1,   696,    -1,    -1,    56,    -1,   218,    -1,    -1,   704,
     705,    -1,    -1,    -1,   709,    -1,    -1,    69,    70,    71,
      72,    -1,    -1,    -1,    -1,    77,    -1,    79,    -1,    -1,
     676,    -1,   727,   679,    -1,    87,    88,    -1,    -1,    91,
      -1,   959,   737,    -1,    -1,    97,    98,    -1,   829,    -1,
     696,   103,    -1,   105,    -1,   107,   108,   109,   704,   705,
      -1,    -1,    -1,   709,   506,   760,   761,   279,    -1,    -1,
      -1,   474,    -1,    -1,   477,   478,    -1,   858,    -1,    -1,
      -1,   727,    -1,    -1,    -1,    -1,    -1,    31,    32,    -1,
      -1,   737,    -1,    -1,    -1,    -1,    -1,    41,    -1,    -1,
      44,    -1,    -1,    -1,    -1,    -1,    50,    -1,    52,    -1,
      -1,    -1,    56,    -1,   760,   761,    -1,   520,   813,    -1,
      64,    65,    66,    -1,    -1,    69,    70,    71,    72,   910,
      -1,    -1,    -1,    77,   537,    79,   578,    -1,    -1,    -1,
      -1,   787,    -1,    87,    88,    -1,    -1,    91,    -1,    -1,
      -1,    -1,    -1,    97,    98,   936,    -1,    -1,    -1,   103,
      -1,   105,    -1,   858,   108,   109,   110,   111,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   619,    -1,    -1,
      -1,   623,    -1,    -1,    56,    -1,   628,    -1,    -1,   631,
      -1,    -1,   634,    -1,   636,    -1,    -1,    69,    70,    71,
      72,   643,    -1,    -1,    -1,    77,    -1,    79,   854,    -1,
      -1,    -1,   858,    -1,    -1,    87,    88,    -1,    -1,    91,
     866,   916,    -1,    -1,    -1,    97,    98,    -1,    -1,    -1,
      -1,   103,    -1,   105,    -1,   638,   108,   109,    -1,    -1,
      -1,   474,    -1,   455,   477,   478,   458,    -1,    -1,   461,
     462,    -1,    -1,   465,   466,   467,    -1,    -1,   700,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   710,   711,
     712,    -1,    -1,   676,    56,    -1,   679,    59,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   520,    70,    71,
      72,    -1,    -1,    -1,    -1,    -1,    -1,    79,    -1,    -1,
      -1,   704,   705,    -1,   537,    87,   709,    -1,    -1,    -1,
      -1,    -1,    -1,    95,    -1,    -1,    98,    -1,    -1,    -1,
      -1,   103,    -1,   105,   727,    -1,    -1,   109,    -1,    -1,
      -1,    -1,    56,    -1,   737,    59,    -1,   779,    -1,   781,
      -1,   783,   784,   785,    -1,   787,   788,    71,    72,    -1,
      -1,    -1,   564,    -1,    -1,    79,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    87,   806,    -1,    -1,    -1,    -1,    -1,
      -1,    95,   584,    -1,    98,   817,    -1,    -1,    -1,   103,
      -1,   105,    -1,    -1,   787,   109,   598,    -1,   830,   831,
     832,   833,   834,   835,   836,   837,   838,   839,   840,   841,
     842,   843,   844,   845,   846,   847,   848,    -1,    -1,   851,
     852,    -1,   854,    -1,    -1,    -1,    -1,    56,    -1,    -1,
      -1,    -1,    -1,    -1,   866,    -1,    -1,    -1,    67,    -1,
      -1,   873,    71,    72,   876,    -1,    -1,    -1,    -1,    -1,
      79,    -1,    -1,   676,    -1,    -1,   679,    -1,    87,    -1,
      -1,   854,    -1,    -1,    -1,   858,    -1,    -1,   900,    98,
      -1,    -1,    -1,   866,   103,    -1,   105,    -1,   107,   108,
     109,   704,   705,    -1,    -1,    -1,   709,   919,   920,    -1,
      -1,    -1,   924,    -1,    -1,   927,    31,    32,    -1,    -1,
      -1,   933,   934,   935,   727,    -1,    41,    -1,    -1,    44,
     942,    -1,    -1,    -1,   737,    50,    -1,    52,    -1,    -1,
      -1,    56,    -1,    -1,   956,    -1,    61,    -1,    -1,    64,
      65,    66,    -1,    -1,    69,    70,    71,    72,    -1,    -1,
      -1,    -1,    77,    -1,    79,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    87,    88,    -1,    -1,    91,    -1,    -1,    -1,
      -1,    -1,    97,    98,   787,    -1,    -1,    -1,   103,    45,
     105,    -1,   107,   108,   109,   110,   111,    -1,    -1,    -1,
      56,    -1,    58,    59,    -1,    -1,    -1,    -1,    -1,    -1,
      66,    -1,    -1,    69,    70,    71,    72,   799,    -1,    -1,
     802,    77,    -1,    79,    80,    -1,    -1,    -1,    84,    -1,
      -1,    87,    88,    -1,    -1,    91,    -1,    -1,    -1,    95,
      96,    97,    98,    -1,   100,    -1,    -1,   103,    -1,   105,
      -1,   854,   108,   109,    -1,   858,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   866,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    -1,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,    22,    -1,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,    22,    -1,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,    31,    32,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    41,    -1,    -1,    44,    -1,    -1,
      -1,    -1,    -1,    50,    -1,    52,    -1,    -1,    -1,    56,
      -1,    -1,    -1,    -1,    61,    -1,    -1,    64,    65,    66,
      -1,    -1,    69,    70,    71,    72,    -1,    -1,    75,    -1,
      77,    -1,    79,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      87,    88,    -1,    -1,    91,    -1,    -1,    -1,    -1,    -1,
      97,    98,    -1,    -1,    -1,    -1,   103,    -1,   105,    31,
      32,   108,   109,   110,   111,    -1,    -1,    -1,    -1,    41,
      -1,    -1,    44,    45,    -1,    -1,    -1,    -1,    50,    -1,
      52,    -1,    -1,    -1,    56,    -1,    -1,    -1,    -1,    61,
      -1,    -1,    64,    65,    66,    -1,    -1,    69,    70,    -1,
      -1,    -1,    -1,    75,    -1,    77,    -1,    79,    -1,    -1,
      31,    32,    -1,    -1,    -1,    -1,    88,    -1,    -1,    91,
      41,    -1,    -1,    44,    45,    97,    -1,    -1,    -1,    50,
      -1,    52,    -1,    -1,    -1,    56,   108,   109,   110,   111,
      61,    -1,    -1,    64,    65,    66,    -1,    -1,    69,    70,
      -1,    -1,    -1,    -1,    75,    -1,    77,    -1,    79,    -1,
      -1,    31,    32,    -1,    -1,    -1,    -1,    88,    -1,    -1,
      91,    41,    -1,    -1,    44,    -1,    97,    -1,    -1,    -1,
      50,    -1,    52,    -1,    -1,    -1,    56,   108,   109,   110,
     111,    61,    -1,    -1,    64,    65,    66,    -1,    -1,    69,
      70,    -1,    -1,    -1,    -1,    75,    -1,    77,    -1,    79,
      -1,    -1,    31,    32,    -1,    -1,    -1,    -1,    88,    -1,
      -1,    91,    41,    -1,    -1,    44,    -1,    97,    -1,    -1,
      -1,    50,    -1,    52,    -1,    -1,    -1,    56,   108,   109,
     110,   111,    61,    -1,    -1,    64,    65,    66,    -1,    -1,
      69,    70,    -1,    -1,    -1,    -1,    75,    -1,    77,    -1,
      79,    -1,    -1,    31,    32,    -1,    -1,    -1,    -1,    88,
      -1,    -1,    91,    41,    -1,    -1,    44,    -1,    97,    -1,
      -1,    -1,    50,    -1,    52,    -1,    -1,    -1,    56,   108,
     109,   110,   111,    61,    -1,    -1,    64,    65,    66,    -1,
      -1,    69,    70,    -1,    -1,    -1,    -1,    -1,    -1,    77,
      -1,    79,    31,    32,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    -1,    41,    91,    -1,    44,    -1,    -1,    -1,    97,
      -1,    50,    -1,    52,    -1,    -1,    -1,    56,    -1,    58,
     108,   109,   110,   111,    -1,    64,    65,    66,    -1,    -1,
      69,    70,    -1,    -1,    -1,    -1,    -1,    -1,    77,    -1,
      79,    31,    32,    -1,    -1,    -1,    -1,    -1,    -1,    88,
      -1,    41,    91,    -1,    -1,    45,    -1,    -1,    97,    -1,
      50,    -1,    52,    -1,    -1,    -1,    56,    -1,    -1,   108,
     109,   110,   111,    -1,    64,    65,    66,    -1,    -1,    69,
      70,    -1,    -1,    -1,    -1,    75,    -1,    77,    -1,    79,
      31,    32,    -1,    -1,    -1,    -1,    -1,    -1,    88,    -1,
      41,    91,    -1,    44,    45,    -1,    -1,    97,    -1,    50,
      -1,    52,    -1,    -1,    -1,    56,    -1,    -1,   108,   109,
     110,   111,    -1,    64,    65,    66,    -1,    -1,    69,    70,
      -1,    -1,    -1,    -1,    -1,    -1,    77,    -1,    79,    31,
      32,    -1,    -1,    -1,    -1,    -1,    -1,    88,    -1,    41,
      91,    -1,    44,    -1,    -1,    -1,    97,    -1,    50,    -1,
      52,    -1,    -1,    -1,    56,    -1,    -1,   108,   109,   110,
     111,    -1,    64,    65,    66,    -1,    -1,    69,    70,    -1,
      -1,    -1,    -1,    -1,    -1,    77,    -1,    79,    31,    32,
      -1,    -1,    -1,    -1,    -1,    -1,    88,    -1,    41,    91,
      -1,    44,    -1,    -1,    -1,    97,    -1,    50,    -1,    52,
      -1,    -1,    -1,    56,    -1,    -1,   108,   109,   110,   111,
      -1,    64,    65,    66,    -1,    -1,    69,    70,    -1,    -1,
      -1,    -1,    -1,    -1,    77,    -1,    79,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    -1,    -1,    91,    45,
      -1,    -1,    -1,    -1,    97,    -1,    -1,    -1,    -1,    -1,
      56,    -1,    58,    59,    -1,   108,   109,   110,   111,    -1,
      66,    -1,    -1,    69,    70,    71,    72,    -1,    -1,    -1,
      -1,    77,    -1,    79,    -1,    -1,    -1,    -1,    84,    -1,
      -1,    87,    88,    -1,    -1,    91,    -1,    45,    -1,    95,
      -1,    97,    98,    -1,    -1,    -1,   102,   103,    56,   105,
      58,    59,   108,   109,    -1,    -1,    -1,    -1,    66,    -1,
      -1,    69,    70,    71,    72,    -1,    -1,    -1,    -1,    77,
      -1,    79,    -1,    -1,    -1,    -1,    84,    -1,    -1,    87,
      88,    -1,    -1,    91,    -1,    -1,    -1,    95,    -1,    97,
      98,    56,    -1,    -1,    -1,   103,    61,   105,    -1,    -1,
     108,   109,    -1,    -1,    69,    70,    71,    72,    -1,    -1,
      -1,    -1,    77,    -1,    79,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    87,    88,    -1,    -1,    91,    -1,    -1,    -1,
      56,    -1,    97,    98,    -1,    -1,    -1,    -1,   103,    -1,
     105,    -1,   107,   108,   109,    71,    72,    -1,    -1,    -1,
      -1,    -1,    -1,    79,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    87,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    98,    -1,    -1,    -1,    -1,   103,    -1,   105,
      -1,   107,   108,   109,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,
      50,    51,    -1,    -1,    -1,    55,    56,    -1,    -1,    -1,
      60,    -1,    62,    63,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,
      50,    -1,    -1,    -1,    -1,    55,    56,    -1,    -1,    -1,
      60,    -1,    62,    63,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    43,    -1,    -1,    46,    47,    48,    49,
      50,    -1,    -1,    53,    -1,    55,    56,    -1,    -1,    -1,
      60,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    -1,    42,
      43,    -1,    -1,    46,    47,    48,    49,    50,    -1,    -1,
      53,    -1,    55,    56,    -1,    -1,    -1,    60,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    -1,    42,    43,    -1,    -1,
      46,    47,    48,    49,    50,    -1,    -1,    53,    -1,    55,
      56,    -1,    -1,    -1,    60,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,
      49,    50,    -1,    -1,    -1,    54,    55,    56,    -1,    -1,
      -1,    60,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    -1,
      42,    -1,    -1,    -1,    46,    47,    48,    49,    50,    -1,
      -1,    -1,    54,    55,    56,    -1,    -1,    -1,    60,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    -1,    42,    -1,    -1,
      -1,    46,    47,    48,    49,    50,    51,    -1,    -1,    -1,
      55,    56,    -1,    -1,    -1,    60,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    -1,    42,    -1,    -1,    -1,    46,    47,
      48,    49,    50,    -1,    -1,    53,    -1,    55,    56,    -1,
      -1,    -1,    60,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,    50,
      -1,    -1,    -1,    54,    55,    56,    -1,    -1,    -1,    60,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    -1,    42,    43,
      -1,    -1,    46,    47,    48,    49,    50,    -1,    -1,    -1,
      -1,    55,    56,    -1,    -1,    -1,    60,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    -1,    42,    43,    -1,    -1,    46,
      47,    48,    49,    50,    -1,    -1,    -1,    -1,    55,    56,
      -1,    -1,    -1,    60,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,
      50,    51,    -1,    -1,    -1,    55,    56,    -1,    -1,    -1,
      60,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    -1,    42,
      -1,    -1,    -1,    46,    47,    48,    49,    50,    51,    -1,
      -1,    -1,    55,    56,    -1,    -1,    -1,    60,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    -1,    42,    -1,    -1,    -1,
      46,    47,    48,    49,    50,    51,    -1,    -1,    -1,    55,
      56,    -1,    -1,    -1,    60,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    -1,    42,    43,    -1,    -1,    46,    47,    48,
      49,    50,    -1,    -1,    -1,    -1,    55,    56,    -1,    -1,
      -1,    60,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    -1,
      42,    -1,    -1,    -1,    46,    47,    48,    49,    50,    -1,
      -1,    -1,    -1,    55,    56,    -1,    58,    -1,    60,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    -1,    42,    -1,    -1,
      -1,    46,    47,    48,    49,    50,    51,    -1,    -1,    -1,
      55,    56,    -1,    -1,    -1,    60,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    -1,    42,    -1,    -1,    -1,    46,    47,
      48,    49,    50,    51,    -1,    -1,    -1,    55,    56,    -1,
      -1,    -1,    60,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,    50,
      -1,    -1,    -1,    -1,    55,    56,    -1,    58,    -1,    60,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    -1,    42,    43,
      -1,    -1,    46,    47,    48,    49,    50,    -1,    -1,    -1,
      -1,    55,    56,    -1,    -1,    -1,    60,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    -1,    42,    -1,    -1,    -1,    46,
      47,    48,    49,    50,    51,    -1,    -1,    -1,    55,    56,
      -1,    -1,    -1,    60,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,
      50,    51,    -1,    -1,    -1,    55,    56,    -1,    -1,    -1,
      60,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    -1,    42,
      -1,    -1,    -1,    46,    47,    48,    49,    50,    51,    -1,
      -1,    -1,    55,    56,    -1,    -1,    -1,    60,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    -1,    42,    -1,    -1,    -1,
      46,    47,    48,    49,    50,    -1,    -1,    53,    -1,    55,
      56,    -1,    -1,    -1,    60,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,
      49,    50,    51,    -1,    -1,    -1,    55,    56,    -1,    -1,
      -1,    60,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    -1,
      42,    -1,    -1,    -1,    46,    47,    48,    49,    50,    -1,
      -1,    53,    -1,    55,    56,    -1,    -1,    -1,    60,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    -1,    42,    43,    -1,
      -1,    46,    47,    48,    49,    50,    -1,    -1,    -1,    -1,
      55,    56,    -1,    -1,    -1,    60,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    -1,    42,    -1,    -1,    -1,    46,    47,
      48,    49,    50,    -1,    -1,    -1,    54,    55,    56,    -1,
      -1,    -1,    60,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,    50,
      -1,    -1,    -1,    54,    55,    56,    -1,    -1,    -1,    60,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    -1,    42,    -1,
      -1,    -1,    46,    47,    48,    49,    50,    -1,    -1,    -1,
      -1,    55,    56,    -1,    -1,    -1,    60,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    -1,    42,    -1,    -1,    -1,    46,
      47,    48,    49,    50,    -1,    -1,    -1,    -1,    55,    56,
      -1,    -1,    -1,    60,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,
      50,    -1,    -1,    -1,    -1,    -1,    56,    -1,    -1,    -1,
      60,    24,    25,    26,    27,    -1,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    -1,    42,
      -1,    -1,    -1,    46,    47,    48,    49,    50,    -1,    -1,
      -1,    -1,    -1,    56,    24,    25,    26,    60,    -1,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    -1,    42,    -1,    -1,    -1,    46,    47,    48,    49,
      50,    -1,    -1,    -1,    -1,    -1,    56,    24,    25,    26,
      60,    -1,    -1,    -1,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    -1,    42,    -1,    -1,    -1,    46,
      47,    48,    49,    50,    -1,    68,    -1,    -1,    -1,    56,
      73,    74,    -1,    60,    -1,    78,    -1,    -1,    81,    82,
      83,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    91,    -1,
      93,    94,    -1,    -1,    -1,    -1,    99,    26,    -1,    -1,
      -1,   104,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    -1,    42,    -1,    -1,    -1,    -1,    47,    -1,
      49,    50,    -1,    -1,    -1,    -1,    -1,    56,    26,    -1,
      -1,    60,    -1,    31,    32,    33,    34,    35,    36,    37,
      -1,    39,    40,    -1,    42,    -1,    -1,    -1,    -1,    47,
      -1,    49,    50,    -1,    -1,    -1,    -1,    -1,    56,    26,
      -1,    -1,    60,    -1,    31,    32,    33,    34,    35,    36,
      37,    -1,    39,    -1,    -1,    42,    -1,    -1,    -1,    -1,
      47,    -1,    49,    50,    -1,    -1,    -1,    -1,    -1,    56,
      26,    -1,    -1,    60,    -1,    31,    32,    33,    34,    35,
      36,    37,    -1,    -1,    -1,    -1,    42,    -1,    -1,    -1,
      -1,    47,    -1,    49,    50,    -1,    -1,    -1,    -1,    -1,
      56,    -1,    -1,    -1,    60,    31,    32,    33,    34,    35,
      36,    37,    -1,    -1,    -1,    -1,    42,    -1,    -1,    -1,
      -1,    47,    -1,    -1,    50,    -1,    -1,    -1,    -1,    -1,
      56,    -1,    -1,    -1,    60,     3,     4,     5,     6,     7,
       8,     9,    10,    11,    12,    13,    14,    15,    16,    17,
      18,    19
  };

  const short
  P4Parser::yystos_[] =
  {
       0,     3,     4,     5,     6,     7,     8,     9,    10,    11,
      12,    13,    14,    15,    16,    17,    18,    19,   115,   116,
     118,   119,    31,    32,    41,    44,    50,    52,    56,    64,
      65,    66,    69,    70,    77,    79,    88,    91,    97,   108,
     109,   110,   111,   121,   145,   185,   186,   187,   190,   255,
     260,   109,   121,   122,   130,   131,   111,   263,   110,   111,
     262,   264,   110,   265,   260,   111,   262,   110,   260,   111,
     110,   260,   111,   110,   110,     0,    21,    20,    58,    59,
      71,    72,    79,    87,    90,    95,    98,   103,   105,   107,
     108,   120,   125,   126,   127,   136,   139,   145,   146,   149,
     170,   171,   177,   181,   184,   187,   188,   189,   190,   191,
     192,   200,   201,   202,   205,   208,   213,   218,   219,   221,
     246,   248,   251,   260,   260,   260,   109,   121,   130,   255,
      79,   184,   187,   190,   260,   260,    56,   109,   121,    50,
      46,    47,    56,   257,   266,    54,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    42,    48,    49,    50,    55,    60,   257,
     266,    57,    54,    54,    54,    54,    54,    54,    54,    54,
      54,    54,    54,   122,   266,    44,   266,    44,   122,   266,
     266,    68,    73,    74,    78,    81,    82,    83,    91,    93,
      94,    99,   104,    79,   127,   184,    58,    50,    58,   144,
      58,   144,   125,   126,   229,    50,    42,    42,   122,    58,
      45,    45,    51,    51,   122,    61,   122,   252,   253,   254,
     260,   258,    61,   107,   121,   184,   196,   197,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,    48,   252,
     260,   260,    61,   107,   184,   198,   199,   260,   260,   131,
     111,   262,   110,   260,   111,   110,   260,   111,   110,    72,
      98,   111,   117,    42,    50,    50,   111,   122,   220,    50,
     111,   220,   128,   197,    50,   111,   122,   184,   122,   122,
     184,   108,   121,   122,   181,   184,   122,   122,   125,   184,
     201,   122,   122,   122,   184,   201,    50,   125,   132,   133,
     134,    44,    44,    44,   252,   260,   260,   193,   194,   266,
     260,    57,    51,    54,   122,    48,    49,    54,   267,    43,
      53,   260,    51,    53,    54,   267,    54,    54,    54,   266,
     130,   255,   128,   260,   267,    45,    54,   260,   267,    45,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    62,
      63,    64,    65,    66,    67,    68,    69,    70,    71,    72,
      73,    74,    75,    76,    77,    78,    79,    80,    81,    82,
      83,    84,    85,    86,    87,    88,    89,    90,    91,    92,
      93,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   129,
     267,   260,   267,    50,   122,   172,   214,   122,   178,    58,
      58,   203,   209,   122,   122,   137,   150,   206,   122,   122,
     252,    85,    86,    92,   135,    51,    54,   147,   174,   230,
      51,    43,    43,   182,   122,   195,   260,   254,   196,   260,
     260,   196,    50,   260,   111,   110,   111,    43,    43,    51,
      51,   122,    51,   128,    51,   132,    57,   193,    44,   215,
     193,   193,   193,   193,   193,   193,    51,   184,   134,   125,
     126,   139,   148,   152,   153,   169,   184,   247,   248,    70,
     125,   139,   175,   237,   246,   247,   248,   231,   122,    50,
      54,   267,    43,   252,   267,   267,   267,    51,   267,    51,
     250,   260,   173,   220,    44,   179,   204,   210,   138,   151,
     207,   122,   122,    97,   106,   184,    45,   125,   153,   122,
     176,   229,   101,    45,    58,    66,    80,    84,    96,   100,
     121,   125,   139,   145,   187,   222,   223,   224,   225,   226,
     227,   228,   229,   232,   236,   247,   248,   256,   259,    57,
      58,   132,   122,    51,   229,    58,    50,    45,   122,   216,
     217,    44,    44,    44,    50,    50,    44,    57,    58,    57,
     122,   266,   122,    57,   249,    45,   122,    58,    50,    58,
     260,    50,   121,    56,    42,    50,    57,   257,   266,    44,
     140,    51,   132,    57,    45,    54,   180,   211,   211,   132,
     132,   211,   140,   260,   154,   187,   188,   191,   249,   250,
      58,    44,   260,    58,   260,    70,   260,   252,   260,   197,
     141,    58,    51,   250,   217,    45,   125,   183,    45,   125,
     212,    45,    51,    51,    45,    58,    44,   267,   267,   267,
      58,    69,    88,   125,   238,   239,    51,    51,    50,    43,
      53,    51,    58,   267,   142,    67,   109,   181,   184,   155,
      50,    50,    50,    57,    57,    73,   124,    45,   239,   187,
     228,    44,   252,   260,    58,    50,    45,   126,   139,   143,
     251,   181,    50,    58,   122,   102,   125,   126,   156,   157,
     159,   184,   222,   223,   226,   227,   247,   248,   260,   260,
     260,    44,    44,    70,    77,    91,    97,   108,   109,   123,
      76,   233,    51,    43,   252,    58,   132,    58,    89,   122,
     160,   161,    44,   184,    45,    51,    51,    51,   242,   240,
      57,    57,   228,    31,    32,    41,    45,    50,    52,    64,
      65,    66,    75,    79,   110,   111,   121,   145,   185,   187,
     234,   235,   261,    58,    51,    51,    50,    58,   158,   122,
     122,   122,    45,   125,    45,   241,   260,    44,   250,   260,
     260,   260,   184,   260,   260,    56,   121,    50,   257,    53,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    42,    48,    49,
      50,    55,    60,   257,   266,    58,    58,   255,   155,    58,
      58,    58,   145,   243,   256,    53,    50,    61,    75,   164,
     165,   168,   244,   245,   260,    58,    51,    51,   122,   252,
     229,   260,   260,   260,   260,   260,   260,   260,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,   260,   260,
      48,   252,   260,   260,   199,   260,    51,    45,    58,    50,
     122,    61,    75,   167,   168,   260,    53,    45,   244,    62,
      63,   260,    51,    43,    53,   260,    51,    53,   267,    44,
     252,   125,    51,    54,    62,    63,   243,   260,   260,   260,
     260,    50,   162,    51,    58,   166,   168,   260,   260,   125,
      43,   252,    45,   163,   164,    51,    54,    58,    51,    53,
     168,   122,    58
  };

  const short
  P4Parser::yyr1_[] =
  {
       0,   114,   115,   115,   116,   116,   116,   116,   116,   116,
     116,   116,   116,   116,   116,   116,   116,   116,   116,   116,
     117,   117,   117,   118,   119,   119,   119,   120,   120,   120,
     120,   120,   120,   120,   120,   120,   120,   121,   121,   121,
     121,   121,   121,   121,   122,   122,   123,   123,   123,   123,
     123,   124,   124,   125,   125,   126,   126,   127,   127,   127,
     127,   127,   128,   128,   128,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   130,   130,   131,   132,   132,   133,   133,   134,
     134,   135,   135,   135,   135,   137,   138,   136,   139,   139,
     139,   139,   141,   140,   142,   142,   143,   143,   144,   144,
     145,   146,   147,   147,   148,   148,   148,   148,   150,   151,
     149,   152,   152,   154,   153,   155,   155,   156,   156,   156,
     156,   156,   156,   156,   158,   157,   159,   159,   160,   160,
     161,   162,   162,   163,   164,   164,   165,   165,   166,   166,
     167,   167,   167,   167,   168,   168,   168,   168,   168,   169,
     169,   169,   170,   172,   173,   171,   174,   174,   175,   175,
     175,   175,   175,   176,   178,   179,   177,   177,   177,   180,
     180,   182,   181,   183,   183,   183,   184,   184,   184,   184,
     184,   185,   185,   186,   186,   187,   188,   189,   189,   190,
     191,   191,   191,   191,   191,   191,   191,   191,   191,   191,
     191,   192,   192,   192,   193,   193,   194,   195,   195,   196,
     196,   196,   196,   197,   197,   197,   198,   198,   198,   199,
     199,   200,   200,   200,   200,   200,   201,   201,   201,   201,
     203,   204,   202,   206,   207,   205,   209,   210,   208,   211,
     211,   212,   214,   213,   215,   213,   216,   216,   217,   218,
     219,   220,   220,   221,   221,   221,   221,   222,   222,   222,
     223,   224,   225,   225,   226,   226,   227,   228,   228,   228,
     228,   228,   228,   228,   228,   230,   229,   231,   231,   232,
     233,   233,   234,   234,   235,   235,   236,   236,   236,   236,
     237,   238,   238,   239,   239,   239,   239,   240,   240,   241,
     242,   242,   243,   243,   244,   245,   245,   246,   247,   247,
     248,   249,   249,   250,   251,   252,   252,   253,   253,   254,
     254,   254,   255,   255,   255,   256,   256,   258,   257,   259,
     259,   259,   259,   259,   260,   260,   260,   260,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,   260,   260,
     260,   260,   260,   260,   260,   260,   260,   260,   260,   261,
     261,   261,   261,   261,   261,   261,   261,   261,   261,   261,
     261,   261,   261,   261,   261,   261,   261,   261,   261,   261,
     261,   261,   261,   261,   261,   261,   261,   261,   261,   261,
     261,   261,   261,   261,   261,   261,   261,   261,   261,   261,
     261,   261,   262,   262,   263,   263,   264,   264,   265,   265,
     266,   266,   267,   267
  };

  const signed char
  P4Parser::yyr2_[] =
  {
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     4,     4,     4,     6,     6,     6,     4,
       1,     4,     1,     2,     0,     2,     2,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     0,     1,     0,     1,     1,     2,     2,     5,     5,
       5,     4,     0,     4,     2,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     3,     3,     0,     1,     1,     3,     4,
       6,     1,     1,     1,     0,     0,     0,     9,     7,     6,
       9,     8,     0,     4,     0,     2,     1,     1,     0,     3,
       1,     6,     0,     2,     1,     1,     1,     1,     0,     0,
       9,     1,     2,     0,     8,     0,     2,     1,     1,     1,
       1,     1,     1,     1,     0,     5,     0,     2,     2,     1,
       7,     0,     2,     4,     1,     1,     5,     3,     1,     3,
       3,     3,     1,     1,     1,     3,     3,     1,     1,    10,
      10,    10,     7,     0,     0,     9,     0,     2,     1,     1,
       1,     1,     1,     1,     0,     0,     9,     4,     4,     0,
       2,     0,     7,     3,     4,     6,     1,     1,     1,     1,
       1,     1,     1,     1,     2,     1,     4,     4,     4,     4,
       1,     1,     1,     1,     1,     4,     4,     4,     6,     6,
       6,     1,     1,     1,     0,     1,     3,     1,     3,     1,
       1,     1,     1,     0,     1,     3,     1,     1,     1,     1,
       3,     1,     2,     2,     2,     2,     1,     1,     1,     1,
       0,     0,     9,     0,     0,     9,     0,     0,     9,     0,
       2,     4,     0,     7,     0,     8,     1,     3,     3,     4,
       4,     1,     3,     4,     4,     4,     4,     5,     8,     4,
       1,     2,     2,     3,     5,     7,     7,     1,     1,     1,
       1,     1,     1,     1,     1,     0,     5,     0,     2,     7,
       0,     2,     3,     2,     1,     1,     1,     1,     1,     1,
       6,     1,     2,     5,     5,     7,     6,     0,     2,     5,
       0,     4,     1,     4,     5,     1,     2,     7,     5,     4,
       7,     0,     2,     1,     2,     0,     1,     1,     3,     1,
       3,     1,     0,     1,     3,     1,     2,     0,     3,     1,
       1,     2,     4,     6,     1,     1,     1,     1,     1,     1,
       2,     4,     6,     3,     3,     3,     2,     2,     2,     2,
       2,     3,     2,     3,     3,     3,     3,     3,     3,     3,
       3,     4,     3,     3,     3,     3,     3,     3,     3,     3,
       3,     3,     3,     3,     5,     7,     4,     4,     4,     1,
       1,     1,     1,     1,     1,     2,     4,     6,     3,     2,
       2,     2,     2,     2,     3,     2,     3,     3,     3,     3,
       3,     3,     3,     3,     4,     3,     3,     3,     3,     3,
       3,     3,     3,     3,     3,     3,     3,     5,     7,     4,
       4,     4,     1,     1,     1,     3,     1,     3,     1,     3,
       1,     1,     1,     1
  };


#if YYDEBUG || 1
  // YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
  // First, the terminals, then, starting at \a YYNTOKENS, nonterminals.
  const char*
  const P4Parser::yytname_[] =
  {
  "\"end of file\"", "error", "\"invalid token\"", "START_PROGRAM",
  "START_EXPRESSION_LIST", "START_KV_LIST", "START_INTEGER_LIST",
  "START_INTEGER_OR_STRING_LITERAL_LIST", "START_STRING_LITERAL_LIST",
  "START_EXPRESSION", "START_INTEGER", "START_INTEGER_OR_STRING_LITERAL",
  "START_STRING_LITERAL", "START_EXPRESSION_PAIR", "START_INTEGER_PAIR",
  "START_STRING_LITERAL_PAIR", "START_EXPRESSION_TRIPLE",
  "START_INTEGER_TRIPLE", "START_STRING_LITERAL_TRIPLE",
  "START_P4RT_TRANSLATION_ANNOTATION", "END", "END_ANNOTATION",
  "UNEXPECTED_TOKEN", "END_PRAGMA", "\"<=\"", "\">=\"", "\"<<\"", "\"&&\"",
  "\"||\"", "\"!=\"", "\"==\"", "\"+\"", "\"-\"", "\"|+|\"", "\"|-|\"",
  "\"*\"", "\"/\"", "\"%\"", "\"|\"", "\"&\"", "\"^\"", "\"~\"", "\"[\"",
  "\"]\"", "\"{\"", "\"}\"", "\"<\"", "L_ANGLE_ARGS", "\">\"",
  "R_ANGLE_SHIFT", "\"(\"", "\")\"", "\"!\"", "\":\"", "\",\"", "\"?\"",
  "\".\"", "\"=\"", "\";\"", "\"@\"", "\"++\"", "\"_\"", "\"&&&\"",
  "\"..\"", "TRUE", "FALSE", "THIS", "ABSTRACT", "ACTION", "ACTIONS",
  "APPLY", "BOOL", "BIT", "CONST", "CONTROL", "DEFAULT", "ELSE", "ENTRIES",
  "ENUM", "ERROR", "EXIT", "EXTERN", "HEADER", "HEADER_UNION", "IF", "IN",
  "INOUT", "INT", "KEY", "SELECT", "MATCH_KIND", "TYPE", "OUT", "PACKAGE",
  "PARSER", "PRAGMA", "RETURN", "STATE", "STRING", "STRUCT", "SWITCH",
  "TABLE", "TRANSITION", "TUPLE", "TYPEDEF", "VARBIT", "VALUESET", "VOID",
  "IDENTIFIER", "TYPE_IDENTIFIER", "STRING_LITERAL", "INTEGER", "PREFIX",
  "THEN", "$accept", "start", "fragment", "p4rtControllerType", "program",
  "input", "declaration", "nonTypeName", "name", "nonTableKwName",
  "optCONST", "optAnnotations", "annotations", "annotation",
  "annotationBody", "annotationToken", "kvList", "kvPair", "parameterList",
  "nonEmptyParameterList", "parameter", "direction",
  "packageTypeDeclaration", "$@1", "$@2", "instantiation",
  "objInitializer", "$@3", "objDeclarations", "objDeclaration",
  "optConstructorParameters", "dotPrefix", "parserDeclaration",
  "parserLocalElements", "parserLocalElement", "parserTypeDeclaration",
  "$@4", "$@5", "parserStates", "parserState", "$@6", "parserStatements",
  "parserStatement", "parserBlockStatement", "$@7", "transitionStatement",
  "stateExpression", "selectExpression", "selectCaseList", "selectCase",
  "keysetExpression", "tupleKeysetExpression", "simpleExpressionList",
  "reducedSimpleKeysetExpression", "simpleKeysetExpression",
  "valueSetDeclaration", "controlDeclaration", "controlTypeDeclaration",
  "$@8", "$@9", "controlLocalDeclarations", "controlLocalDeclaration",
  "controlBody", "externDeclaration", "$@10", "$@11", "methodPrototypes",
  "functionPrototype", "$@12", "methodPrototype", "typeRef", "namedType",
  "prefixedType", "typeName", "tupleType", "headerStackType",
  "specializedType", "baseType", "typeOrVoid", "optTypeParameters",
  "typeParameters", "typeParameterList", "typeArg", "typeArgumentList",
  "realTypeArg", "realTypeArgumentList", "typeDeclaration",
  "derivedTypeDeclaration", "headerTypeDeclaration", "$@13", "$@14",
  "structTypeDeclaration", "$@15", "$@16", "headerUnionDeclaration",
  "$@17", "$@18", "structFieldList", "structField", "enumDeclaration",
  "$@19", "$@20", "specifiedIdentifierList", "specifiedIdentifier",
  "errorDeclaration", "matchKindDeclaration", "identifierList",
  "typedefDeclaration", "assignmentOrMethodCallStatement",
  "emptyStatement", "exitStatement", "returnStatement",
  "conditionalStatement", "directApplication", "statement",
  "blockStatement", "$@21", "statOrDeclList", "switchStatement",
  "switchCases", "switchCase", "switchLabel", "statementOrDeclaration",
  "tableDeclaration", "tablePropertyList", "tableProperty",
  "keyElementList", "keyElement", "actionList", "actionRef", "entry",
  "entriesList", "actionDeclaration", "variableDeclaration",
  "constantDeclaration", "optInitializer", "initializer",
  "functionDeclaration", "argumentList", "nonEmptyArgList", "argument",
  "expressionList", "prefixedNonTypeName", "dot_name", "$@22", "lvalue",
  "expression", "nonBraceExpression", "intOrStr", "intList",
  "intOrStrList", "strList", "l_angle", "r_angle", YY_NULLPTR
  };
#endif


#if YYDEBUG
  const short
  P4Parser::yyrline_[] =
  {
       0,   348,   348,   349,   354,   355,   356,   357,   358,   361,
     362,   363,   364,   367,   372,   377,   384,   390,   396,   405,
     417,   419,   422,   426,   429,   430,   431,   435,   436,   437,
     438,   439,   440,   441,   442,   443,   444,   448,   449,   450,
     451,   452,   453,   454,   458,   459,   463,   464,   465,   466,
     467,   471,   472,   476,   477,   481,   485,   492,   497,   499,
     501,   505,   510,   511,   516,   522,   523,   524,   525,   526,
     527,   528,   529,   530,   531,   532,   533,   534,   535,   536,
     537,   538,   539,   540,   541,   542,   543,   544,   545,   546,
     547,   548,   549,   550,   551,   552,   553,   554,   555,   556,
     557,   558,   559,   560,   561,   562,   563,   564,   565,   566,
     567,   569,   570,   571,   572,   574,   575,   576,   577,   578,
     579,   580,   581,   582,   583,   585,   586,   587,   588,   589,
     590,   591,   593,   594,   595,   596,   603,   604,   605,   606,
     607,   608,   609,   610,   612,   613,   614,   615,   616,   617,
     618,   619,   623,   624,   628,   632,   633,   637,   639,   643,
     644,   648,   649,   650,   651,   655,   656,   655,   666,   670,
     674,   679,   686,   686,   692,   693,   697,   698,   702,   703,
     707,   713,   722,   723,   727,   728,   729,   730,   735,   736,
     734,   744,   746,   750,   750,   757,   758,   762,   763,   764,
     765,   766,   767,   768,   772,   772,   777,   778,   782,   783,
     787,   793,   794,   798,   804,   805,   809,   811,   815,   816,
     821,   822,   823,   824,   828,   829,   830,   831,   832,   836,
     839,   842,   850,   859,   860,   858,   868,   869,   873,   874,
     875,   876,   877,   881,   888,   889,   887,   893,   897,   905,
     906,   911,   910,   923,   926,   930,   939,   940,   941,   942,
     943,   947,   948,   952,   953,   958,   962,   966,   967,   971,
     975,   976,   977,   978,   979,   980,   982,   984,   987,   989,
     991,   996,   997,   998,  1003,  1004,  1008,  1012,  1014,  1018,
    1019,  1021,  1022,  1026,  1027,  1028,  1032,  1033,  1034,  1040,
    1041,  1045,  1046,  1047,  1048,  1049,  1053,  1054,  1055,  1056,
    1060,  1060,  1060,  1069,  1069,  1069,  1078,  1078,  1078,  1087,
    1088,  1092,  1097,  1096,  1099,  1099,  1107,  1108,  1112,  1116,
    1121,  1126,  1128,  1132,  1134,  1136,  1138,  1146,  1151,  1156,
    1162,  1166,  1170,  1171,  1175,  1177,  1183,  1191,  1192,  1193,
    1194,  1195,  1196,  1197,  1198,  1202,  1202,  1208,  1209,  1213,
    1218,  1219,  1223,  1224,  1228,  1229,  1233,  1234,  1235,  1236,
    1242,  1248,  1250,  1254,  1258,  1262,  1266,  1273,  1274,  1278,
    1284,  1285,  1290,  1292,  1297,  1310,  1311,  1317,  1325,  1329,
    1335,  1341,  1342,  1346,  1352,  1358,  1359,  1363,  1365,  1369,
    1370,  1371,  1375,  1376,  1378,  1382,  1383,  1388,  1388,  1392,
    1393,  1394,  1395,  1396,  1400,  1401,  1402,  1403,  1404,  1405,
    1406,  1407,  1408,  1409,  1410,  1412,  1413,  1414,  1415,  1416,
    1417,  1419,  1422,  1423,  1424,  1425,  1426,  1427,  1428,  1429,
    1430,  1431,  1433,  1434,  1435,  1437,  1438,  1439,  1440,  1441,
    1442,  1443,  1444,  1445,  1446,  1447,  1449,  1451,  1453,  1457,
    1458,  1459,  1460,  1461,  1462,  1463,  1464,  1465,  1466,  1467,
    1468,  1469,  1470,  1471,  1473,  1476,  1477,  1478,  1479,  1480,
    1481,  1482,  1483,  1484,  1485,  1487,  1488,  1489,  1491,  1492,
    1493,  1494,  1495,  1496,  1497,  1498,  1499,  1500,  1501,  1503,
    1505,  1507,  1511,  1512,  1516,  1518,  1523,  1525,  1530,  1532,
    1536,  1536,  1537,  1537
  };

  void
  P4Parser::yy_stack_print_ () const
  {
    *yycdebug_ << "Stack now";
    for (stack_type::const_iterator
           i = yystack_.begin (),
           i_end = yystack_.end ();
         i != i_end; ++i)
      *yycdebug_ << ' ' << int (i->state);
    *yycdebug_ << '\n';
  }

  void
  P4Parser::yy_reduce_print_ (int yyrule) const
  {
    int yylno = yyrline_[yyrule];
    int yynrhs = yyr2_[yyrule];
    // Print the symbols being reduced, and their result.
    *yycdebug_ << "Reducing stack by rule " << yyrule - 1
               << " (line " << yylno << "):\n";
    // The symbols being reduced.
    for (int yyi = 0; yyi < yynrhs; yyi++)
      YY_SYMBOL_PRINT ("   $" << yyi + 1 << " =",
                       yystack_[(yynrhs) - (yyi + 1)]);
  }
#endif // YYDEBUG


#line 23 "parsers/p4/p4parser.ypp"
} // P4
#line 8758 "/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/frontends/parsers/p4/p4parser.cpp"

#line 1541 "parsers/p4/p4parser.ypp"


void P4::P4Parser::error(const Util::SourceInfo& location,
                         const std::string& message) {
    driver.onParseError(location, message);
}
