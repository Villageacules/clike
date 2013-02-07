{
{-# LANGUAGE BangPatterns #-}
{-# OPTIONS -Wwarn -w #-}
{-# OPTIONS_GHC -funbox-strict-fields #-}

------------------------------------------------------------------------------------------------
module Language.CLike.Lexer
  ( scanner
  , Token(..)
  
  , ScannerOpt(..)
  
  , ScannerConfig(..), initScannerConfig
  , scannerConfigC, scannerConfigCXX
  , scfgAddOpts
  ) where
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
import Data.Bits
-- import Data.Word
-- import Control.Monad.Trans.State.Strict
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

}

%wrapper "monadUserState"

$alpha = [a-zA-Z] -- alphabetic characters

$whitechar   = [$white \xa0] -- \xa0 is Unicode no-break space
$white_no_nl = $whitechar # \n
$printable_no_nl = $printable # \n

$ascdigit  = 0-9
-- $unidigit  = \x01 -- Trick Alex into handling Unicode. See alexGetChar.
$digit     = [$ascdigit] -- $unidigit]
$octit     = 0-7
$hexit     = [$digit A-F a-f]

-- $unilarge  = \x03 -- Trick Alex into handling Unicode. See alexGetChar.
$asclarge  = [A-Z \xc0-\xd6 \xd8-\xde]
$large     = [$asclarge] -- $unilarge]

-- $unismall  = \x04 -- Trick Alex into handling Unicode. See alexGetChar.
$ascsmall  = [a-z \xdf-\xf6 \xf8-\xff]
$small     = [$ascsmall \_] -- $unismall]

$namebegin = [$large $small \. \$ \@]
$namechar  = [$namebegin $digit]

-- header char
$h_char     = $printable_no_nl # [$whitechar >]
$q_char     = $printable_no_nl # [$whitechar "]

-- number literal
$octal_digit			= $octit
@octal_literal			= 0 $octal_digit+
$decimal_digit			= $ascdigit
@decimal_literal		= $decimal_digit+
$hexadecimal_digit		= $hexit
@hexadecimal_literal 	= (0x | 0X) $hexadecimal_digit+
$unsigned_suffix		= [uU]
$long_suffix			= [lL]
@long_long_suffix		= ll | LL
@integer_suffix			= $unsigned_suffix $long_suffix? | $unsigned_suffix @long_long_suffix? | $long_suffix $unsigned_suffix? | @long_long_suffix $unsigned_suffix?
@integer_literal		= (@octal_literal | @decimal_literal | @hexadecimal_literal) @integer_suffix?

@decimal     = $digit+
@octal       = $octit+
@hexadecimal = $hexit+
@exponent    = [eE] [\-\+]? @decimal

@floating_point = @decimal \. @decimal @exponent? | @decimal @exponent

@escape      = \\ ([abfnrt\\\'\"\?] | x $hexit{1,2} | $octit{1,3})
@strchar     = ($printable # [\"\\]) | @escape

-- header name
@header_name    = \< $h_char+ \> | \" $q_char+ \"

clike :-

-- comment
"//" [$printable_no_nl]* \n / {ifScannerOpt ScOpt_CommentAs1Token} {tkStr C_Comment}
"//" [$printable_no_nl]* \n ;

-- preprocessor
<0> {
	^ \#     	{cxPush cx_hash `andAction` tk C_hash}
}

<cx_hash> {
    define      {tk C_hash_define}
    elif        {tk C_hash_elif}
    else        {tk C_hash_else}
    endif       {tk C_hash_endif}
    error       {tk C_hash_error}
    if          {tk C_hash_if}
    ifdef       {tk C_hash_ifdef}
    ifndef      {tk C_hash_ifndef}
    include     {cxSet cx_hash_include `andAction` tk C_hash_include}
    pragma      {tk C_hash_pragma}
    undef       {tk C_hash_undef}
}

<cx_hash_include> {
    @header_name    {tkStr C_String}
}

<cx_hash,cx_hash_include> {
    \\ $        ;
    \n          {cxPop `andAction` tk C_hash_EOL}
}

-- literals
@integer_literal	{tkStr C_Int}

-- keywords
<0> {
    alignas             / {ifLangs langsCXX}        {tk C_alignas }
    alignof             / {ifLangs langsCXX}        {tk C_alignof }
    and                 / {ifLangs langsCXX}        {tk C_and}
    and_eq              / {ifLangs langsCXX}        {tk C_and_eq}
    asm                 / {ifLangs langsCXX}        {tk C_asm}
    auto                                            {tk C_auto}
    bitand              / {ifLangs langsCXX}        {tk C_bitand}
    bitor               / {ifLangs langsCXX}        {tk C_bitor}
    bool                / {ifLangs langsCXX}        {tk C_bool}
    break                                           {tk C_break}
    case                                            {tk C_case}
    catch               / {ifLangs langsCXX}        {tk C_catch}
    char                                            {tk C_char}
    char16_t            / {ifLangs langsCXX}        {tk C_char16_t}
    char32_t            / {ifLangs langsCXX}        {tk C_char32_t}
    class               / {ifLangs langsCXX}        {tk C_class}
    compl               / {ifLangs langsCXX}        {tk C_compl}
    const                                           {tk C_const}
    const_cast          / {ifLangs langsCXX}        {tk C_const_cast}
    constexpr           / {ifLangs langsCXX}        {tk C_constexpr}
    continue                                        {tk C_continue}
    decltype            / {ifLangs langsCXX}        {tk C_decltype}
    default                                         {tk C_default}
    delete              / {ifLangs langsCXX}        {tk C_delete}
    do                                              {tk C_do}
    double                                          {tk C_double}
    dynamic_cast        / {ifLangs langsCXX}        {tk C_dynamic_cast}
    else                                            {tk C_else}
    enum                                            {tk C_enum}
    explicit            / {ifLangs langsCXX}        {tk C_explicit}
    export              / {ifLangs langsCXX}        {tk C_export}
    extern                                          {tk C_extern}
    false               / {ifLangs langsCXX}        {tk C_false}
    float                                           {tk C_float}
    for                                             {tk C_for}
    friend              / {ifLangs langsCXX}        {tk C_friend}
    goto                                            {tk C_goto}
    if                                              {tk C_if}
    inline                                          {tk C_inline}
    int                                             {tk C_int}
    long                                            {tk C_long}
    mutable             / {ifLangs langsCXX}        {tk C_mutable}
    namespace           / {ifLangs langsCXX}        {tk C_namespace}
    new                 / {ifLangs langsCXX}        {tk C_new}
    noexcept            / {ifLangs langsCXX}        {tk C_noexcept}
    not                 / {ifLangs langsCXX}        {tk C_not}
    not_eq              / {ifLangs langsCXX}        {tk C_not_eq}
    nullptr             / {ifLangs langsCXX}        {tk C_nullptr }
    operator            / {ifLangs langsCXX}        {tk C_operator}
    or                  / {ifLangs langsCXX}        {tk C_or}
    or_eq               / {ifLangs langsCXX}        {tk C_or_eq}
    private             / {ifLangs langsCXX}        {tk C_private}
    protected           / {ifLangs langsCXX}        {tk C_protected}
    public              / {ifLangs langsCXX}        {tk C_public}
    register                                        {tk C_register}
    reinterpret_cast    / {ifLangs langsCXX}        {tk C_reinterpret_cast}
    restrict                                        {tk C_restrict}
    return                                          {tk C_return}
    short                                           {tk C_short}
    signed                                          {tk C_signed}
    sizeof                                          {tk C_sizeof}
    static                                          {tk C_static}
    static_assert       / {ifLangs langsCXX}        {tk C_static_assert}
    static_cast         / {ifLangs langsCXX}        {tk C_static_cast}
    struct                                          {tk C_struct}
    switch                                          {tk C_switch}
    template            / {ifLangs langsCXX}        {tk C_template}
    this                / {ifLangs langsCXX}        {tk C_this}
    thread_local        / {ifLangs langsCXX}        {tk C_thread_local}
    throw               / {ifLangs langsCXX}        {tk C_throw}
    true                / {ifLangs langsCXX}        {tk C_true}
    try                 / {ifLangs langsCXX}        {tk C_try}
    typedef                                         {tk C_typedef}
    typeid              / {ifLangs langsCXX}        {tk C_typeid}
    typename            / {ifLangs langsCXX}        {tk C_typename}
    union                                           {tk C_union}
    unsigned                                        {tk C_unsigned}
    using               / {ifLangs langsCXX}        {tk C_using}
    virtual             / {ifLangs langsCXX}        {tk C_virtual}
    void                                            {tk C_void}
    volatile                                        {tk C_volatile}
    wchar_t             / {ifLangs langsCXX}        {tk C_wchar_t}
    while                                           {tk C_while}
    xor                 / {ifLangs langsCXX}        {tk C_xor}
    xor_eq              / {ifLangs langsCXX}        {tk C_xor_eq}
}

$white_no_nl+ ;

-- $digit+ { tkStr (Int . read) }
[\=\+\-\*\/\(\)] { tkStr (Sym . head) }
$alpha [$alpha $digit \_ \']* { tkStr C_Name }

-- default newline handling
<0> {
	\n ;
}

-- fallback, unrecognizable
-- $printable_no_nl+ {tkStr C_Unknown}


{
------------------------------------------------------------------------------------------------
-- The token variations
------------------------------------------------------------------------------------------------

data TokenKind =
    Sym Char
  | Var String
  | Int Integer

  -- Reserved keywords shared by all clike variants: C, C++
  | C_auto
  | C_break
  | C_case
  | C_char
  | C_const
  | C_continue
  | C_default
  | C_do
  | C_double
  | C_else
  | C_enum
  | C_extern
  | C_float
  | C_for
  | C_goto
  | C_if
  | C_inline
  | C_int
  | C_long
  | C_register
  | C_restrict
  | C_return
  | C_short
  | C_signed
  | C_sizeof
  | C_static
  | C_struct
  | C_switch
  | C_typedef
  | C_union
  | C_unsigned
  | C_void
  | C_volatile
  | C_while

  -- Reserved keywords on top of shared, for: C++
  | C_alignas 
  | C_alignof 
  | C_and
  | C_and_eq
  | C_asm
  | C_bitand
  | C_bitor
  | C_bool
  | C_catch
  | C_char16_t
  | C_char32_t
  | C_class
  | C_compl
  | C_const_cast
  | C_constexpr
  | C_decltype
  | C_delete
  | C_dynamic_cast
  | C_explicit
  | C_export
  | C_false
  | C_friend
  | C_mutable
  | C_namespace
  | C_new
  | C_noexcept
  | C_not
  | C_not_eq
  | C_nullptr 
  | C_operator
  | C_or
  | C_or_eq
  | C_private
  | C_protected
  | C_public
  | C_reinterpret_cast
  | C_static_assert
  | C_static_cast
  | C_template
  | C_this
  | C_thread_local
  | C_throw
  | C_true
  | C_try
  | C_typeid
  | C_typename
  | C_using
  | C_virtual
  | C_wchar_t
  | C_xor
  | C_xor_eq

  -- Ident
  | C_Name      String
  
  -- Literal
  | C_String    String
  | C_Int       String
  | C_Float     Rational
  
  -- Comment
  | C_Comment   String      -- comment including delimiter(s)
  
  -- Preprocessor
  | C_hash
  | C_hash_define
  | C_hash_elif
  | C_hash_else
  | C_hash_endif
  | C_hash_error
  | C_hash_if
  | C_hash_ifdef
  | C_hash_ifndef
  | C_hash_include
  | C_hash_pragma
  | C_hash_undef
  | C_hash_EOL
  
  -- Meta
  | C_EOF
  | C_Unknown   String      -- unrecognizable
  deriving (Eq,Show)

------------------------------------------------------------------------------------------------
-- Position utils
------------------------------------------------------------------------------------------------

alexNoPos :: AlexPosn
alexNoPos = AlexPn (-1) (-1) (-1)

alexPosEqual :: AlexPosn -> AlexPosn -> Bool
alexPosEqual (AlexPn p1 _ _) (AlexPn p2 _ _) = p1 == p2

------------------------------------------------------------------------------------------------
-- The token type:
------------------------------------------------------------------------------------------------

data Token
  = Token Int		-- ^ context/state
          AlexPosn TokenKind (Maybe String)
  deriving (Eq,Show)

------------------------------------------------------------------------------------------------
-- Hooks used by machinery
------------------------------------------------------------------------------------------------

alexEOF :: Alex Token
alexEOF = do
  c <- alexGetStartCode
  return (Token c alexNoPos C_EOF Nothing)

------------------------------------------------------------------------------------------------
-- Result combinators, token actions
------------------------------------------------------------------------------------------------

tk :: TokenKind -> AlexAction Token
tk t (p, _, _, _) _ = do
  c <- alexGetStartCode
  return (Token c p t Nothing)

tkStr :: (String -> TokenKind) -> AlexAction Token
tkStr t (p, _, _, input) len = do
  c <- alexGetStartCode
  return (Token c p (t s) (Just s))
 where s = take len input

{-
-- ignore this token
tkSkip :: AlexAction Token
tkSkip input len = alexMonadScanUser
-}

-- ignore this token, but set the start code to a new value
cxSet :: Int -> AlexAction ()
cxSet code input len = do alexSetStartCode code -- ; alexMonadScanUser

cxPush :: Int -> AlexAction ()
cxPush code input len = do alexPushStartCode code -- ; alexMonadScanUser

cxPop :: AlexAction ()
cxPop input len = do alexPopStartCode -- ; alexMonadScanUser

-- sequence two actions
andAction :: AlexAction a -> AlexAction b -> AlexAction b
(a1 `andAction` a2) input len = do a1 input len; a2 input len

-- perform an action for this token, and set the start code to a new value
andCxPush :: AlexAction result -> Int -> AlexAction result
action `andCxPush` code = cxPush code `andAction` action
-- (action `andCxPush` code) input len = do alexPushStartCode code; action input len


------------------------------------------------------------------------------------------------
-- AlexInput utils
------------------------------------------------------------------------------------------------

alexInputEqual :: AlexInput -> AlexInput -> Bool
alexInputEqual (p1,_,_,_) (p2,_,_,_) = p1 `alexPosEqual` p2

------------------------------------------------------------------------------------------------
-- User level onfiguration
------------------------------------------------------------------------------------------------

data ScannerLanguage
  = ScLang_C                -- C
  | ScLang_CXX              -- C++
  | ScLang_CLike            -- Intersection of them all
  deriving (Eq,Enum,Bounded)

data ScannerOpt
  = ScOpt_Preprocessing     -- do CPP preprocessing
  | ScOpt_CommentAs1Token   -- pass comment through as single token
  deriving (Enum,Bounded)

data ScannerConfig = ScannerConfig
  { scfgLanguage        :: ScannerLanguage
  , scfgOpts            :: [ScannerOpt]
  }

initScannerConfig :: ScannerConfig
initScannerConfig = ScannerConfig
  { scfgLanguage        = ScLang_CLike
  , scfgOpts            = []
  }

scannerConfigCXX, scannerConfigC :: ScannerConfig

scannerConfigCXX = initScannerConfig
  { scfgLanguage        = ScLang_CXX
  }

scannerConfigC = initScannerConfig
  { scfgLanguage        = ScLang_C
  }

scfgAddOpts :: [ScannerOpt] -> ScannerConfig -> ScannerConfig
scfgAddOpts o c = c {scfgOpts = o ++ scfgOpts c}

------------------------------------------------------------------------------------------------
-- User state
------------------------------------------------------------------------------------------------

type Bitmap = Int

data AlexUserState = AlexUserState
  { ausOptsBitmap       :: !Bitmap
  , ausLangBitmap       :: !Bitmap
  , ausConfig           :: ScannerConfig
  , ausStartCodeStack   :: [Int]
  , ausErrorAccum       :: Maybe (AlexPosn,String)  -- accumulation of error input, finally leading to additional error token
  , ausNonLexedStrings  :: [(AlexPosn,String)]      -- non recognized parts, all in reverse order
  }

alexInitUserState :: AlexUserState
alexInitUserState = AlexUserState
  { ausOptsBitmap       = 0
  , ausLangBitmap       = 0
  , ausConfig           = initScannerConfig
  , ausStartCodeStack   = []
  , ausErrorAccum       = Nothing
  , ausNonLexedStrings  = []
  }

-- User state access

-- This all should be state monad stuff instead of DIY...
ausModify' :: (AlexUserState -> (AlexUserState,x)) -> Alex x
ausModify' upd = Alex $ \s@AlexState{alex_ust=us} ->
                          let (us',x) = upd us
                          in  Right (s {alex_ust = us'}, x)

ausModify :: (AlexUserState -> AlexUserState) -> Alex ()
ausModify upd = ausModify' (\us -> (upd us,()))

ausGets :: (AlexUserState -> x) -> Alex x
ausGets get = Alex $ \s@AlexState{alex_ust=us} -> Right (s, get us)

ausGet = ausGets id
ausPut us = ausModify (const us)

------------------------------------------------------------------------------------------------
-- Alex & user state interaction
------------------------------------------------------------------------------------------------

alexPushStartCode :: Int -> Alex ()
alexPushStartCode newc = do
  c <- alexGetStartCode
  ausModify $ \us -> us {ausStartCodeStack = c : ausStartCodeStack us}
  alexSetStartCode newc

-- | pop start code, when empty stack ignore and leave start code untouched
alexPopStartCode :: Alex ()
alexPopStartCode = do
  us <- ausGet
  case ausStartCodeStack us of
    (c:st) -> do ausPut $ us {ausStartCodeStack = st}
                 alexSetStartCode c 
    _      -> return ()

-- | Possibly inject accumulated error token
alexInjectError :: Alex Token -> Alex Token
alexInjectError next = do
  us <- ausGet
  case ausErrorAccum us of
    Just (p,s) -> do ausPut $ us {ausErrorAccum = Nothing}
                     c <- alexGetStartCode
                     return (Token c p (C_Unknown s) (Just s))
    _          -> next

-- | Accumulate 1 char from erroneous input
alexAccum1ErrorChar :: AlexAction ()
alexAccum1ErrorChar (p,_,_,input) len = do
  ausModify $ \us -> let i = take len input
                     in  us {ausErrorAccum = Just $ maybe (p,i) (\(p,s) -> (p, s ++ i)) $ ausErrorAccum us}

------------------------------------------------------------------------------------------------
-- Flags
------------------------------------------------------------------------------------------------

ifUserStatePred :: (AlexUserState -> Bool) -> AlexAccPred AlexUserState
ifUserStatePred pred s _ _ _ = pred s

ifScannerOpt :: ScannerOpt -> AlexAccPred AlexUserState
ifScannerOpt opt = ifUserStatePred (\s -> testBit (ausOptsBitmap s) (fromEnum opt))

ifLang :: ScannerLanguage -> AlexAccPred AlexUserState
ifLang lang = ifUserStatePred (\s -> scfgLanguage (ausConfig s) == lang)

ifLangs :: Bitmap -> AlexAccPred AlexUserState
ifLangs langs = ifUserStatePred (\s -> (ausLangBitmap s .&. langs) > 0)

langsAllCLike :: Bitmap
langsAllCLike = mkBitmap [minBound..(maxBound::ScannerLanguage)]

langsC :: Bitmap
langsC = mkBitmap [ScLang_C]

langsCXX :: Bitmap
langsCXX = mkBitmap [ScLang_CXX]

------------------------------------------------------------------------------------------------
-- Utils
------------------------------------------------------------------------------------------------

mkBitmap :: Enum x => [x] -> Bitmap
mkBitmap xs = foldr (.|.) 0 [bit $ fromEnum x | x <- xs]

------------------------------------------------------------------------------------------------
-- Execution
------------------------------------------------------------------------------------------------

scanner :: ScannerConfig -> Int -> String -> Either String [Token]
scanner cfg startcode str
  = runAlex str (do
        alexSetStartCode startcode
        ausModify $ \s ->
          s { ausOptsBitmap = mkBitmap (scfgOpts cfg)
            , ausLangBitmap = mkBitmap [scfgLanguage cfg]
            , ausConfig = cfg
            }
        loop
      )
  where loop = do -- (t, m) <- alexComplementError alexMonadScan
                  t <- alexMonadScanUser
                  -- when (isJust m) (lexerError (fromJust m))
                  let tok@(Token _ _ knd _) = t
                  if (knd == C_EOF)
                     then return []
                     {-
                     then do f1 <- getLexerStringState
                             d2 <- getLexerCommentDepth
                             if ((not f1) && (d2 == 0))
                                then return [tok]
                                else if (f1)
                                     then alexError "String not closed at end of file"
                                     else alexError "Comment not closed at end of file"
                     -}
                     else do toks <- loop
                             return (tok : toks)

-- Adapted alexMonadScan which propagates user state
alexMonadScanUser :: Alex Token
alexMonadScanUser = do
  inp <- alexGetInput
  sc <- alexGetStartCode
  us <- ausGet
  case alexScanUser us inp sc of
    AlexEOF -> alexInjectError $ alexEOF
    AlexError inp'
      | alexInputEqual inp inp' -> alexError "lexical error"
      | otherwise -> do
            {- -- erronous, is looping... sometimes... apparently not always inp /= inp', TBD...
            -}
            alexAccum1ErrorChar inp 1
            alexSetInput inp'
            alexMonadScanUser
            -- alexError "lexical error"
    AlexSkip  inp' len -> alexInjectError $ do
        alexSetInput inp'
        alexMonadScanUser
    AlexToken inp' len action -> alexInjectError $ do
        alexSetInput inp'
        action (ignorePendingBytes inp) len


}
