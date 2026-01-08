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





#include "p4ltlparser.hpp"


// Unqualified %code blocks.
#line 28 "parsers/p4ltl/p4ltlparser.ypp"

    #include "frontends/parsers/p4ltl/p4ltllexer.hpp"    
    #undef yylex
    #define yylex(x) scanner.lex(x)

#line 52 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"


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

#line 5 "parsers/p4ltl/p4ltlparser.ypp"
namespace P4LTL {
#line 126 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"

  /// Build a parser object.
  P4LTLParser::P4LTLParser (Scanner& scanner_yyarg, AstNode*& root_yyarg)
#if YYDEBUG
    : yydebug_ (false),
      yycdebug_ (&std::cerr),
#else
    :
#endif
      scanner (scanner_yyarg),
      root (root_yyarg)
  {}

  P4LTLParser::~P4LTLParser ()
  {}

  P4LTLParser::syntax_error::~syntax_error () YY_NOEXCEPT YY_NOTHROW
  {}

  /*---------.
  | symbol.  |
  `---------*/

  // basic_symbol.
  template <typename Base>
  P4LTLParser::basic_symbol<Base>::basic_symbol (const basic_symbol& that)
    : Base (that)
    , value ()
  {
    switch (this->kind ())
    {
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        value.copy< AstNode* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_NAME: // NAME
        value.copy< char* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_INT: // INT
        value.copy< unsigned long long int > (YY_MOVE (that.value));
        break;

      default:
        break;
    }

  }




  template <typename Base>
  P4LTLParser::symbol_kind_type
  P4LTLParser::basic_symbol<Base>::type_get () const YY_NOEXCEPT
  {
    return this->kind ();
  }


  template <typename Base>
  bool
  P4LTLParser::basic_symbol<Base>::empty () const YY_NOEXCEPT
  {
    return this->kind () == symbol_kind::S_YYEMPTY;
  }

  template <typename Base>
  void
  P4LTLParser::basic_symbol<Base>::move (basic_symbol& s)
  {
    super_type::move (s);
    switch (this->kind ())
    {
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        value.move< AstNode* > (YY_MOVE (s.value));
        break;

      case symbol_kind::S_NAME: // NAME
        value.move< char* > (YY_MOVE (s.value));
        break;

      case symbol_kind::S_INT: // INT
        value.move< unsigned long long int > (YY_MOVE (s.value));
        break;

      default:
        break;
    }

  }

  // by_kind.
  P4LTLParser::by_kind::by_kind () YY_NOEXCEPT
    : kind_ (symbol_kind::S_YYEMPTY)
  {}

#if 201103L <= YY_CPLUSPLUS
  P4LTLParser::by_kind::by_kind (by_kind&& that) YY_NOEXCEPT
    : kind_ (that.kind_)
  {
    that.clear ();
  }
#endif

  P4LTLParser::by_kind::by_kind (const by_kind& that) YY_NOEXCEPT
    : kind_ (that.kind_)
  {}

  P4LTLParser::by_kind::by_kind (token_kind_type t) YY_NOEXCEPT
    : kind_ (yytranslate_ (t))
  {}



  void
  P4LTLParser::by_kind::clear () YY_NOEXCEPT
  {
    kind_ = symbol_kind::S_YYEMPTY;
  }

  void
  P4LTLParser::by_kind::move (by_kind& that)
  {
    kind_ = that.kind_;
    that.clear ();
  }

  P4LTLParser::symbol_kind_type
  P4LTLParser::by_kind::kind () const YY_NOEXCEPT
  {
    return kind_;
  }


  P4LTLParser::symbol_kind_type
  P4LTLParser::by_kind::type_get () const YY_NOEXCEPT
  {
    return this->kind ();
  }



  // by_state.
  P4LTLParser::by_state::by_state () YY_NOEXCEPT
    : state (empty_state)
  {}

  P4LTLParser::by_state::by_state (const by_state& that) YY_NOEXCEPT
    : state (that.state)
  {}

  void
  P4LTLParser::by_state::clear () YY_NOEXCEPT
  {
    state = empty_state;
  }

  void
  P4LTLParser::by_state::move (by_state& that)
  {
    state = that.state;
    that.clear ();
  }

  P4LTLParser::by_state::by_state (state_type s) YY_NOEXCEPT
    : state (s)
  {}

  P4LTLParser::symbol_kind_type
  P4LTLParser::by_state::kind () const YY_NOEXCEPT
  {
    if (state == empty_state)
      return symbol_kind::S_YYEMPTY;
    else
      return YY_CAST (symbol_kind_type, yystos_[+state]);
  }

  P4LTLParser::stack_symbol_type::stack_symbol_type ()
  {}

  P4LTLParser::stack_symbol_type::stack_symbol_type (YY_RVREF (stack_symbol_type) that)
    : super_type (YY_MOVE (that.state))
  {
    switch (that.kind ())
    {
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        value.YY_MOVE_OR_COPY< AstNode* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_NAME: // NAME
        value.YY_MOVE_OR_COPY< char* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_INT: // INT
        value.YY_MOVE_OR_COPY< unsigned long long int > (YY_MOVE (that.value));
        break;

      default:
        break;
    }

#if 201103L <= YY_CPLUSPLUS
    // that is emptied.
    that.state = empty_state;
#endif
  }

  P4LTLParser::stack_symbol_type::stack_symbol_type (state_type s, YY_MOVE_REF (symbol_type) that)
    : super_type (s)
  {
    switch (that.kind ())
    {
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        value.move< AstNode* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_NAME: // NAME
        value.move< char* > (YY_MOVE (that.value));
        break;

      case symbol_kind::S_INT: // INT
        value.move< unsigned long long int > (YY_MOVE (that.value));
        break;

      default:
        break;
    }

    // that is emptied.
    that.kind_ = symbol_kind::S_YYEMPTY;
  }

#if YY_CPLUSPLUS < 201103L
  P4LTLParser::stack_symbol_type&
  P4LTLParser::stack_symbol_type::operator= (const stack_symbol_type& that)
  {
    state = that.state;
    switch (that.kind ())
    {
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        value.copy< AstNode* > (that.value);
        break;

      case symbol_kind::S_NAME: // NAME
        value.copy< char* > (that.value);
        break;

      case symbol_kind::S_INT: // INT
        value.copy< unsigned long long int > (that.value);
        break;

      default:
        break;
    }

    return *this;
  }

  P4LTLParser::stack_symbol_type&
  P4LTLParser::stack_symbol_type::operator= (stack_symbol_type& that)
  {
    state = that.state;
    switch (that.kind ())
    {
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        value.move< AstNode* > (that.value);
        break;

      case symbol_kind::S_NAME: // NAME
        value.move< char* > (that.value);
        break;

      case symbol_kind::S_INT: // INT
        value.move< unsigned long long int > (that.value);
        break;

      default:
        break;
    }

    // that is emptied.
    that.state = empty_state;
    return *this;
  }
#endif

  template <typename Base>
  void
  P4LTLParser::yy_destroy_ (const char* yymsg, basic_symbol<Base>& yysym) const
  {
    if (yymsg)
      YY_SYMBOL_PRINT (yymsg, yysym);
  }

#if YYDEBUG
  template <typename Base>
  void
  P4LTLParser::yy_print_ (std::ostream& yyo, const basic_symbol<Base>& yysym) const
  {
    std::ostream& yyoutput = yyo;
    YY_USE (yyoutput);
    if (yysym.empty ())
      yyo << "empty symbol";
    else
      {
        symbol_kind_type yykind = yysym.kind ();
        yyo << (yykind < YYNTOKENS ? "token" : "nterm")
            << ' ' << yysym.name () << " (";
        YY_USE (yykind);
        yyo << ')';
      }
  }
#endif

  void
  P4LTLParser::yypush_ (const char* m, YY_MOVE_REF (stack_symbol_type) sym)
  {
    if (m)
      YY_SYMBOL_PRINT (m, sym);
    yystack_.push (YY_MOVE (sym));
  }

  void
  P4LTLParser::yypush_ (const char* m, state_type s, YY_MOVE_REF (symbol_type) sym)
  {
#if 201103L <= YY_CPLUSPLUS
    yypush_ (m, stack_symbol_type (s, std::move (sym)));
#else
    stack_symbol_type ss (s, sym);
    yypush_ (m, ss);
#endif
  }

  void
  P4LTLParser::yypop_ (int n) YY_NOEXCEPT
  {
    yystack_.pop (n);
  }

#if YYDEBUG
  std::ostream&
  P4LTLParser::debug_stream () const
  {
    return *yycdebug_;
  }

  void
  P4LTLParser::set_debug_stream (std::ostream& o)
  {
    yycdebug_ = &o;
  }


  P4LTLParser::debug_level_type
  P4LTLParser::debug_level () const
  {
    return yydebug_;
  }

  void
  P4LTLParser::set_debug_level (debug_level_type l)
  {
    yydebug_ = l;
  }
#endif // YYDEBUG

  P4LTLParser::state_type
  P4LTLParser::yy_lr_goto_state_ (state_type yystate, int yysym)
  {
    int yyr = yypgoto_[yysym - YYNTOKENS] + yystate;
    if (0 <= yyr && yyr <= yylast_ && yycheck_[yyr] == yystate)
      return yytable_[yyr];
    else
      return yydefgoto_[yysym - YYNTOKENS];
  }

  bool
  P4LTLParser::yy_pact_value_is_default_ (int yyvalue) YY_NOEXCEPT
  {
    return yyvalue == yypact_ninf_;
  }

  bool
  P4LTLParser::yy_table_value_is_error_ (int yyvalue) YY_NOEXCEPT
  {
    return yyvalue == yytable_ninf_;
  }

  int
  P4LTLParser::operator() ()
  {
    return parse ();
  }

  int
  P4LTLParser::parse ()
  {
    int yyn;
    /// Length of the RHS of the rule being reduced.
    int yylen = 0;

    // Error handling.
    int yynerrs_ = 0;
    int yyerrstatus_ = 0;

    /// The lookahead symbol.
    symbol_type yyla;

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
            yyla.kind_ = yytranslate_ (yylex (&yyla.value));
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
      case symbol_kind::S_p4ltl: // p4ltl
      case symbol_kind::S_texpr: // texpr
      case symbol_kind::S_predicate: // predicate
      case symbol_kind::S_term: // term
      case symbol_kind::S_identifier: // identifier
        yylhs.value.emplace< AstNode* > ();
        break;

      case symbol_kind::S_NAME: // NAME
        yylhs.value.emplace< char* > ();
        break;

      case symbol_kind::S_INT: // INT
        yylhs.value.emplace< unsigned long long int > ();
        break;

      default:
        break;
    }



      // Perform the reduction.
      YY_REDUCE_PRINT (yyn);
#if YY_EXCEPTIONS
      try
#endif // YY_EXCEPTIONS
        {
          switch (yyn)
            {
  case 2: // p4ltl: texpr
#line 67 "parsers/p4ltl/p4ltlparser.ypp"
    {yylhs.value.as < AstNode* > () = yystack_[0].value.as < AstNode* > (); root = yylhs.value.as < AstNode* > ();
    }
#line 715 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 3: // texpr: texpr AND texpr
#line 72 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::And, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ());}
#line 721 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 4: // texpr: texpr OR texpr
#line 75 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::Or, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 727 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 5: // texpr: texpr IMPLIES texpr
#line 78 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::Implies, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 733 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 6: // texpr: texpr UNTIL texpr
#line 81 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::Until, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 739 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 7: // texpr: texpr WEAKUNTIL texpr
#line 84 "parsers/p4ltl/p4ltlparser.ypp"
        { // a W b == Ga || a U b
        AstNode* globala = new UnaryTemporalOperator(UnaryTemporalOperator::UnaryTemporalOperatorType::Global, yystack_[2].value.as < AstNode* > ());
        AstNode* aUb = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::Until, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ());
        yylhs.value.as < AstNode* > () = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::Or, 
                globala, aUb);
    }
#line 750 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 8: // texpr: texpr RELEASE texpr
#line 92 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTemporalOperator(BinaryTemporalOperator::BinaryTemporalOperatorType::Release, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 756 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 9: // texpr: ALWAYS LPAR texpr RPAR
#line 95 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new UnaryTemporalOperator(UnaryTemporalOperator::UnaryTemporalOperatorType::Global, yystack_[1].value.as < AstNode* > ());}
#line 762 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 10: // texpr: EVENTUALLY LPAR texpr RPAR
#line 98 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new UnaryTemporalOperator(UnaryTemporalOperator::UnaryTemporalOperatorType::Final, yystack_[1].value.as < AstNode* > ()); }
#line 768 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 11: // texpr: NEXT LPAR texpr RPAR
#line 101 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new UnaryTemporalOperator(UnaryTemporalOperator::UnaryTemporalOperatorType::Next, yystack_[1].value.as < AstNode* > ()); }
#line 774 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 12: // texpr: NEG texpr
#line 104 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new UnaryTemporalOperator(UnaryTemporalOperator::UnaryTemporalOperatorType::Not, yystack_[0].value.as < AstNode* > ()); }
#line 780 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 13: // texpr: LPAR texpr RPAR
#line 107 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = yystack_[1].value.as < AstNode* > (); }
#line 786 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 14: // texpr: AP LPAR predicate RPAR
#line 110 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new P4LTLAtomicProposition(yystack_[1].value.as < AstNode* > ()); }
#line 792 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 15: // predicate: DROP
#line 115 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Drop(); }
#line 798 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 16: // predicate: FWD LPAR term RPAR
#line 117 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Forward(yystack_[1].value.as < AstNode* > ()); }
#line 804 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 17: // predicate: APPLY LPAR NAME RPAR
#line 119 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Apply(yystack_[1].value.as < char* > ()); }
#line 810 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 18: // predicate: APPLY LPAR NAME COMMA NAME RPAR
#line 121 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Apply(yystack_[3].value.as < char* > (), yystack_[1].value.as < char* > ()); }
#line 816 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 19: // predicate: VALID LPAR NAME RPAR
#line 123 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Valid(yystack_[1].value.as < char* > ()); }
#line 822 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 20: // predicate: term EQ term
#line 125 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new ExtendedComparativeOperator(ExtendedComparativeOperator::ExtendedComparativeOperatorType::eq, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 828 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 21: // predicate: term GT term
#line 127 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new ExtendedComparativeOperator(ExtendedComparativeOperator::ExtendedComparativeOperatorType::gt, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 834 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 22: // predicate: term GEQ term
#line 129 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new ExtendedComparativeOperator(ExtendedComparativeOperator::ExtendedComparativeOperatorType::geq, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 840 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 23: // predicate: term NEQ term
#line 131 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new ExtendedComparativeOperator(ExtendedComparativeOperator::ExtendedComparativeOperatorType::neq, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 846 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 24: // predicate: term LT term
#line 133 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new ExtendedComparativeOperator(ExtendedComparativeOperator::ExtendedComparativeOperatorType::lt, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 852 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 25: // predicate: term LEQ term
#line 135 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new ExtendedComparativeOperator(ExtendedComparativeOperator::ExtendedComparativeOperatorType::leq, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 858 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 26: // predicate: predicate AND predicate
#line 138 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryPredicateOperator(BinaryPredicateOperator::BinaryPredicateOperatorType::And, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 864 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 27: // predicate: predicate OR predicate
#line 140 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryPredicateOperator(BinaryPredicateOperator::BinaryPredicateOperatorType::Or, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 870 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 28: // predicate: predicate IMPLIES predicate
#line 142 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryPredicateOperator(BinaryPredicateOperator::BinaryPredicateOperatorType::Implies, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 876 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 29: // predicate: LPAR predicate RPAR
#line 144 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = yystack_[1].value.as < AstNode* > (); }
#line 882 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 30: // predicate: NEG predicate
#line 146 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new UnaryPredicateOperator(UnaryPredicateOperator::UnaryPredicateOperatorType::Not, yystack_[0].value.as < AstNode* > ()); }
#line 888 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 31: // term: identifier LBRACKET term RBRACKET
#line 151 "parsers/p4ltl/p4ltlparser.ypp"
        {// currently we don't support multiaccessor
        yylhs.value.as < AstNode* > () = new ArrayAccessExprssion(yystack_[3].value.as < AstNode* > (),yystack_[1].value.as < AstNode* > ()); }
#line 895 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 32: // term: OLD LPAR term RPAR
#line 156 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new OldExpression(yystack_[1].value.as < AstNode* > ()); }
#line 901 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 33: // term: KEY LPAR NAME COMMA NAME RPAR
#line 158 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Key(yystack_[3].value.as < char* > (), yystack_[1].value.as < char* > ()); }
#line 907 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 34: // term: term PLUS term
#line 160 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTermOperator(BinaryTermOperator::BinaryTermOperatorType::Plus, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 913 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 35: // term: term MINUS term
#line 162 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTermOperator(BinaryTermOperator::BinaryTermOperatorType::Minus, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 919 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 36: // term: term MULTIPLY term
#line 164 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BinaryTermOperator(BinaryTermOperator::BinaryTermOperatorType::Multiply, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 925 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 37: // term: term DIVIDE term
#line 166 "parsers/p4ltl/p4ltlparser.ypp"
    {yylhs.value.as < AstNode* > () = new BinaryTermOperator(BinaryTermOperator::BinaryTermOperatorType::Divide, yystack_[2].value.as < AstNode* > (), yystack_[0].value.as < AstNode* > ()); }
#line 931 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 38: // term: LPAR term RPAR
#line 168 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = yystack_[1].value.as < AstNode* > (); }
#line 937 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 39: // term: identifier
#line 170 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = yystack_[0].value.as < AstNode* > (); }
#line 943 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 40: // term: INT
#line 172 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new IntLiteral(yystack_[0].value.as < unsigned long long int > ()); }
#line 949 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 41: // term: TRUE
#line 174 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BooleanLiteral(true); }
#line 955 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 42: // term: FALSE
#line 176 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new BooleanLiteral(false); }
#line 961 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;

  case 43: // identifier: NAME
#line 181 "parsers/p4ltl/p4ltlparser.ypp"
        {yylhs.value.as < AstNode* > () = new Name(yystack_[0].value.as < char* > ()); }
#line 967 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"
    break;


#line 971 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"

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
        error (YY_MOVE (msg));
      }


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

        yy_destroy_ ("Error: popping", yystack_[0]);
        yypop_ ();
        YY_STACK_PRINT ();
      }
    {
      stack_symbol_type error_token;


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
  P4LTLParser::error (const syntax_error& yyexc)
  {
    error (yyexc.what ());
  }

  /* Return YYSTR after stripping away unnecessary quotes and
     backslashes, so that it's suitable for yyerror.  The heuristic is
     that double-quoting is unnecessary unless the string contains an
     apostrophe, a comma, or backslash (other than backslash-backslash).
     YYSTR is taken from yytname.  */
  std::string
  P4LTLParser::yytnamerr_ (const char *yystr)
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
  P4LTLParser::symbol_name (symbol_kind_type yysymbol)
  {
    return yytnamerr_ (yytname_[yysymbol]);
  }



  // P4LTLParser::context.
  P4LTLParser::context::context (const P4LTLParser& yyparser, const symbol_type& yyla)
    : yyparser_ (yyparser)
    , yyla_ (yyla)
  {}

  int
  P4LTLParser::context::expected_tokens (symbol_kind_type yyarg[], int yyargn) const
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
  P4LTLParser::yy_syntax_error_arguments_ (const context& yyctx,
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
  P4LTLParser::yysyntax_error_ (const context& yyctx) const
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


  const signed char P4LTLParser::yypact_ninf_ = -23;

  const signed char P4LTLParser::yytable_ninf_ = -1;

  const short
  P4LTLParser::yypact_[] =
  {
     125,     2,   125,    13,    24,    25,   125,     1,   -11,    65,
      -4,   125,   125,   125,   -23,   -23,   125,   125,   125,   125,
     125,   125,    65,    28,   -23,    55,    61,    65,    64,    97,
     -23,   -23,   -23,   -23,    59,   126,    98,   -23,   151,   159,
     167,   -23,   -23,   -23,    66,    42,   -11,   114,    -3,    36,
      57,    86,   -23,    57,    94,   -23,    65,    65,    65,    57,
      57,    57,    57,    57,    57,    57,    57,    57,    57,    57,
     -23,   -23,   -23,   -23,   -23,   136,    57,    26,   130,    30,
     127,   -23,   113,    90,    69,    69,    76,    76,    69,    69,
      69,    69,   -23,   -23,    78,   102,   -23,    47,   -23,   -23,
     -23,   109,   -23,   135,   139,   -23,   -23
  };

  const signed char
  P4LTLParser::yydefact_[] =
  {
       0,     0,     0,     0,     0,     0,     0,     0,     2,     0,
       0,     0,     0,     0,    12,     1,     0,     0,     0,     0,
       0,     0,     0,     0,    15,     0,     0,     0,     0,     0,
      41,    42,    43,    40,     0,     0,    39,    13,     0,     0,
       0,     6,     7,     8,     3,     4,     5,     0,     0,     0,
       0,     0,    30,     0,     0,    14,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       9,    10,    11,    29,    38,     0,     0,     0,     0,     0,
       0,    26,    27,    28,    20,    23,    34,    35,    21,    22,
      24,    25,    36,    37,     0,     0,    17,     0,    16,    19,
      32,     0,    31,     0,     0,    18,    33
  };

  const signed char
  P4LTLParser::yypgoto_[] =
  {
     -23,   -23,   106,    -8,   -22,   -23
  };

  const signed char
  P4LTLParser::yydefgoto_[] =
  {
       0,     7,     8,    34,    35,    36
  };

  const signed char
  P4LTLParser::yytable_[] =
  {
      48,    15,    37,    74,    16,    17,    18,     9,    19,    20,
      21,    16,    17,    18,    47,    19,    20,    21,    11,    52,
      59,    60,    61,    62,    63,    64,    65,    66,    77,    12,
      13,    79,    98,    49,    67,    68,   100,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    81,    82,
      83,    61,    62,    74,    97,    61,    62,    16,    17,    18,
      50,    19,    76,    67,    68,    55,    51,    67,    68,    53,
      22,    75,    61,    62,    23,    24,    25,    26,    56,    57,
      58,    16,    17,    18,    67,    68,   102,    27,    28,    29,
      30,    31,    32,    33,    61,    62,    28,    29,    30,    31,
      32,    33,    54,    61,    62,    69,    67,    68,    10,    56,
      57,    58,    14,    67,    68,    67,    68,    38,    39,    40,
      73,    78,    41,    42,    43,    44,    45,    46,     1,    80,
       2,   101,    56,    56,    57,    58,    99,   103,     3,     4,
      95,   105,    96,     5,   104,   106,     0,     6,     0,    59,
      60,    61,    62,    63,    64,    65,    66,    70,     0,     0,
       0,     0,     0,    67,    68,    71,    16,    17,    18,     0,
      19,    20,    21,    72,    16,    17,    18,     0,    19,    20,
      21,     0,    16,    17,    18,     0,    19,    20,    21
  };

  const signed char
  P4LTLParser::yycheck_[] =
  {
      22,     0,     6,     6,    15,    16,    17,     5,    19,    20,
      21,    15,    16,    17,    22,    19,    20,    21,     5,    27,
      23,    24,    25,    26,    27,    28,    29,    30,    50,     5,
       5,    53,     6,     5,    37,    38,     6,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    56,    57,
      58,    25,    26,     6,    76,    25,    26,    15,    16,    17,
       5,    19,     5,    37,    38,     6,     5,    37,    38,     5,
       5,    35,    25,    26,     9,    10,    11,    12,    19,    20,
      21,    15,    16,    17,    37,    38,     8,    22,    31,    32,
      33,    34,    35,    36,    25,    26,    31,    32,    33,    34,
      35,    36,     5,    25,    26,     7,    37,    38,     2,    19,
      20,    21,     6,    37,    38,    37,    38,    11,    12,    13,
       6,    35,    16,    17,    18,    19,    20,    21,     3,    35,
       5,     4,    19,    19,    20,    21,     6,    35,    13,    14,
       4,     6,     6,    18,    35,     6,    -1,    22,    -1,    23,
      24,    25,    26,    27,    28,    29,    30,     6,    -1,    -1,
      -1,    -1,    -1,    37,    38,     6,    15,    16,    17,    -1,
      19,    20,    21,     6,    15,    16,    17,    -1,    19,    20,
      21,    -1,    15,    16,    17,    -1,    19,    20,    21
  };

  const signed char
  P4LTLParser::yystos_[] =
  {
       0,     3,     5,    13,    14,    18,    22,    40,    41,     5,
      41,     5,     5,     5,    41,     0,    15,    16,    17,    19,
      20,    21,     5,     9,    10,    11,    12,    22,    31,    32,
      33,    34,    35,    36,    42,    43,    44,     6,    41,    41,
      41,    41,    41,    41,    41,    41,    41,    42,    43,     5,
       5,     5,    42,     5,     5,     6,    19,    20,    21,    23,
      24,    25,    26,    27,    28,    29,    30,    37,    38,     7,
       6,     6,     6,     6,     6,    35,     5,    43,    35,    43,
      35,    42,    42,    42,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,     4,     6,    43,     6,     6,
       6,     4,     8,    35,    35,     6,     6
  };

  const signed char
  P4LTLParser::yyr1_[] =
  {
       0,    39,    40,    41,    41,    41,    41,    41,    41,    41,
      41,    41,    41,    41,    41,    42,    42,    42,    42,    42,
      42,    42,    42,    42,    42,    42,    42,    42,    42,    42,
      42,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    44
  };

  const signed char
  P4LTLParser::yyr2_[] =
  {
       0,     2,     1,     3,     3,     3,     3,     3,     3,     4,
       4,     4,     2,     3,     4,     1,     4,     4,     6,     4,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       2,     4,     4,     6,     3,     3,     3,     3,     3,     1,
       1,     1,     1,     1
  };


#if YYDEBUG || 1
  // YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
  // First, the terminals, then, starting at \a YYNTOKENS, nonterminals.
  const char*
  const P4LTLParser::yytname_[] =
  {
  "\"end of file\"", "error", "\"invalid token\"", "AP", "COMMA", "LPAR",
  "RPAR", "LBRACKET", "RBRACKET", "APPLY", "DROP", "FWD", "VALID",
  "ALWAYS", "EVENTUALLY", "UNTIL", "WEAKUNTIL", "RELEASE", "NEXT", "AND",
  "OR", "IMPLIES", "NEG", "EQ", "NEQ", "PLUS", "MINUS", "GT", "GEQ", "LT",
  "LEQ", "OLD", "KEY", "TRUE", "FALSE", "NAME", "INT", "MULTIPLY",
  "DIVIDE", "$accept", "p4ltl", "texpr", "predicate", "term", "identifier", YY_NULLPTR
  };
#endif


#if YYDEBUG
  const unsigned char
  P4LTLParser::yyrline_[] =
  {
       0,    66,    66,    71,    74,    77,    80,    83,    91,    94,
      97,   100,   103,   106,   109,   114,   116,   118,   120,   122,
     124,   126,   128,   130,   132,   134,   137,   139,   141,   143,
     145,   150,   155,   157,   159,   161,   163,   165,   167,   169,
     171,   173,   175,   180
  };

  void
  P4LTLParser::yy_stack_print_ () const
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
  P4LTLParser::yy_reduce_print_ (int yyrule) const
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

  P4LTLParser::symbol_kind_type
  P4LTLParser::yytranslate_ (int t) YY_NOEXCEPT
  {
    // YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to
    // TOKEN-NUM as returned by yylex.
    static
    const signed char
    translate_table[] =
    {
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
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
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38
    };
    // Last valid token kind.
    const int code_max = 293;

    if (t <= 0)
      return symbol_kind::S_YYEOF;
    else if (t <= code_max)
      return static_cast <symbol_kind_type> (translate_table[t]);
    else
      return symbol_kind::S_YYUNDEF;
  }

#line 5 "parsers/p4ltl/p4ltlparser.ypp"
} // P4LTL
#line 1559 "/mnt/e/p4-verify/P4B-Translator/build-host/frontends/parsers/p4ltl/p4ltlparser.cpp"

#line 183 "parsers/p4ltl/p4ltlparser.ypp"

/* void yyerror (const char *message)
{
	fprintf(stderr, "Error: %s\n", message);
} */

void P4LTL::P4LTLParser::error(const std::string& msg) {
    std::cerr << msg << '\n';
}

/* int main()
{
    yyparse();
    // std::cout << "Parse result: " <<  yyparse() << std::endl;
    if(root != nullptr)
        std::cout << "P4LTL: " + root->toString() << std::endl;
    else
        std::cout << "Root is empty. But Why?" << std::endl;
} */
