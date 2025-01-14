/*

  Wordle solver using DCG in SWI Prolog

  This Wordle solver use DCGs for checking the Wordle constraints.
  It also includes a DCG for generating all the 2315 Wordle target words.

  This is a port of my Picat program http://hakank.org/picat/wordle_dcg.pi .

  Model created by Hakan Kjellerstrand, hakank@gmail.com
  See also my SWI Prolog page: http://www.hakank.org/swi_prolog/

*/
% :- set_prolog_flag(double_quotes, string).  % default


/*
  Some realistic tests.
*/
go :-

        wordle("...n.",["","","","",""],"slat"),
        % ->  [crone,brine,crony,briny,prone,corny,borne,prune,drone,phone,brink,phony,bound,pound,grind,frond,found,bring,drink,being,whine,fiend,chunk,whiny,prong,mound,horny,urine,round,drunk,irony,doing,wound,hound,opine,wring,rhino,downy,wrong,wrung,ebony,ovine,dying,young,owing,eying,vying,eking,penne,penny,bunny,funny,going,ninny,ozone,icing]

        wordle(".r.n.",["","","","",""],"slatcoe"),
        % -> [briny,brink,grind,bring,drink,drunk,wring,wrung]
  
        wordle("...st",["s","","","",""],"flancre"),
        % -> [moist,hoist,ghost,midst,joist,joust,boost,twist]
  
        wordle(".r.n.",["","","","",""],"slatcoe"),
        % -> [briny,brink,grind,bring,drink,drunk,wring,wrung]
  
        wordle(".r.n.",["","","","",""],"slatcoebiy"),
        % -> [drunk,wrung]
  
        wordle(".run.",["","","","",""],"slatcoebiydk"),
        % ->  [wrung]

        wordle(".l...",["","","a","","t"],"sn"),
        % -> [alter,ultra,altar]

        % 2022-03-16: Wordle word of today
        wordle(".....",["","","a","","t"],"sln"),
        % [cater,triad,tread,today,tamer,party,matey,taper,faith,tardy,batch,water,tapir,patch,hater,warty,haute,taker,patio,tweak,bathe,amity,match,acute,earth,watch,tacky,ratio,actor,datum,after,topaz,quota,extra,catty,batty,tatty,patty,catch,fatty,eater,terra,ratty,aorta,theta,hatch,tibia,taboo,tabby,taffy,cacti,attic]

        % 2022-03-27: Wordle word of today
        wordle(".....",["","","n","n","y"],"slatboe"),
        
        % wordle(".....",["","","","",""],""),
        % -> All words...

        nl.


%
% wordle(Words,CorrectPos,CorrectChar,NotInWord)
% - Words: the wordlist/candidates
% 
% - CorrectPos: correct character in correct position,
%   Example: n is in position 4 and t is in position 5: "...nt":
%   
% - CorrectChar: correct character but in wrong position.
%   Example: a is not in position 1, l is not in position 2: ["a","l","","",""]
%   
% - NotInWord: characters not in word.
%   Example: s, a, and t are not in the word: "sat"
%
wordle(CorrectPos, CorrectChar, NotInWord) :-
        writeln(wordle(words,CorrectPos,CorrectChar,NotInWord)),
        % Get all the words via the wordle_words DCG.
        findall(S,(wordle_words(L,[]),string_chars(L,S)),Words),

        wordle(Words, CorrectPos, CorrectChar, NotInWord,[],Candidates),
        length(Candidates,CandidatesLen),
        writeln(candidates=Candidates),
        writeln(len=CandidatesLen),
        
        (Candidates \= [] ->
         Candidates = [Suggestion|_], writeln(suggestion=Suggestion)
        ;
         true
        ),
  
        nl.

%
% The main engine:
% Loop through all words and check if they are in the scope.
% 
wordle([],_CorrectPos,_CorrectChar,_NotInWord, AllWords,Sorted) :-
        sort_candidates(AllWords,Sorted).
wordle([Word|Words],CorrectPos1,CorrectChar1,NotInWord1, AllWords0,AllWords) :-
        string_chars(CorrectPos1,CorrectPos),
        string_chars(NotInWord1,NotInWord),
        maplist(string_chars,CorrectChar1,CorrectChar),

        % connect Word + CorrectPos into pairs
        zip(Word,CorrectPos,Zip1),
        % connect Word + CorrectChar into pairs        
        zip(Word,CorrectChar,Zip2),
        ( (correct_pos(Zip1,_,_),
           correct_char(Word,Zip2,_,_),
           not_in_word(Word,NotInWord,_,_)) ->
          append(AllWords0,[Word],AllWords1),
          wordle(Words, CorrectPos, CorrectChar, NotInWord, AllWords1,AllWords)
        ;
          wordle(Words, CorrectPos, CorrectChar, NotInWord, AllWords0,AllWords)
        ).


            
%
% Correct position.
%
% Ensure that all chars != "." are in correct position.
% 
correct_pos([[C,C2]|Cs]) --> {(C == C2 ; C2 == '.')}, correct_pos(Cs).
correct_pos([]) --> [].

%
% Correct char.
% Ensure that the character is in the word, but not
% in the given position.
% 
correct_char(Word,[[W,CC]|WCC]) --> { (CC == [] ; (member(C,CC), C \= W, memberchk(C,Word)) ) }, 
                                    correct_char(Word,WCC).
correct_char(_Word,[]) --> [].

%
% Characters not in word.
% Ensure that the given chararacter are not in the
% candidate word.
% 
not_in_word(Word,[C|Cs]) --> {\+ memberchk(C,Word)}, not_in_word(Word,Cs).
not_in_word(_Word,[]) --> [].

%
%
% Sort the candidates.
%
sort_candidates(Candidates,Sorted) :-
        % The probability order for each position in the word.
        % Reversed and with missing chars.
        % See http://hakank.org/picat/wordle.pi (go2/0) for the method to get this.
        Alphas1 = ["zyjkquinovhewlrmdgfaptbcsx",
                   "zqfkgxvbsdymcwptnhulieroaj",
                   "qjhzkxfwyvcbpmgdstlnrueoia",
                   "xyzbwhfvpkmdguotcrilasnejq",
                   "uzxbiwfcsgmpoakdnhlrtyejqv"
                  ],
        maplist(string_chars,Alphas1,Alphas),
        score_words(Candidates,Alphas,[],Scores),
        keysort(Scores,Sorted1),
        reverse(Sorted1,Sorted2),
        pairs_values(Sorted2,SortedList),
        maplist(string_chars,Sorted,SortedList).


%
% Score all words
% 
score_words([],_Alpha,Scores,Scores).
score_words([Word|Words],Alphas,Scores0,[Score-Word|Scores]) :-
        % We boost words with distinct characters.
        list_to_set(Word,Unique),
        length(Word,WordLen),
        length(Unique,UniqueLen),
        (WordLen == UniqueLen -> Score1 = 100 ; Score1 = 0),
        score_word(Word,Alphas,Score1,Score),
        score_words(Words,Alphas,Scores0,Scores).

% Score each character in a word
score_word([],_Alpha,Score,Score).
score_word([C|Cs],[Alpha|Alphas],Score0,Score) :-
        nth1(N,Alpha,C),        % find the position of this character
        S is N / 2,
        Score1 is Score0 + S,
        score_word(Cs,Alphas,Score1,Score).

%
% zip(L1,L2,Zip)
% * zipping the lists L1 and L2 into pairs in Zip.
% * extracts the first and second element into L1 and L2 of the list of lists Zip.
%
zip(L1,L2,Zip) :-
        zip(L1,L2,[],Zip).
zip([],[],Zip,Zip).
zip([A|As],[B|Bs],Zip0,[[A,B]|Zip]) :-
          zip(As,Bs,Zip0,Zip).


% Print an empty board
empty() :-
        writeln("wordle(\".....\",[\"\",\"\",\"\",\"\",\"\"],\"\").").

wordle_words --> ("a",("b",("a",("ck";"se";"te");"b",("ey";"ot");"o",("de";"rt";"ut";"ve");"hor";"ide";"led";"use";"yss");"c",("orn";"rid";"tor";"ute");"d",("a",("ge";"pt");"m","i",("n";"t");"o",("r",("e";"n");"be";"pt");"ept";"ult");"f",("o",("ot";"ul");"fix";"ire";"ter");"g",("a",("in";"pe";"te");"i",("le";"ng");"o",("ny";"ra");"ent";"low";"ree");"i",("der";"sle");"l",("i",("bi";"en";"gn";"ke";"ve");"l",("o",("t";"w";"y");"ay";"ey");"o",("n",("e";"g");"ft";"of";"ud");"t",("ar";"er");"arm";"bum";"ert";"gae";"pha");"m",("a",("ss";"ze");"b",("er";"le");"i",("ss";"ty");"p","l",("e";"y");"end";"ong";"use");"n",("g",("e",("l";"r");"le";"ry";"st");"n",("ex";"oy";"ul");"ime";"kle";"ode";"tic";"vil");"p",("p","l",("e";"y");"art";"hid";"ing";"nea";"ron";"tly");"r",("o",("ma";"se");"r",("ay";"ow");"bor";"dor";"ena";"gue";"ise";"mor";"son";"tsy");"s",("s",("ay";"et");"cot";"hen";"ide";"kew");"t",("o",("ll";"ne");"tic");"u",("d","i",("o";"t");"gur";"nty");"v",("ail";"ert";"ian";"oid");"w",("a",("r",("d";"e");"it";"ke";"sh");"ful";"oke");"x","i",("o",("m";"n");"al");"head";"orta";"zure");"b",("a",("d",("ge";"ly");"g",("el";"gy");"l",("er";"my");"n",("al";"jo");"r",("ge";"on");"s",("i",("c";"l";"n";"s");"al";"te");"t",("ch";"he";"on";"ty");"con";"ker";"wdy";"you");"e",("a",("ch";"dy";"rd";"st");"e",("ch";"fy");"g",("a",("n";"t");"et";"in";"un");"l",("l",("e";"y");"ch";"ie";"ow");"r",("et";"ry";"th");"fit";"ing";"nch";"set";"tel";"vel";"zel");"i",("l",("ge";"ly");"n","g",("e";"o");"r",("ch";"th");"ble";"cep";"ddy";"got";"ome";"son";"tty");"l",("a",("n",("d";"k");"ck";"de";"me";"re";"st";"ze");"e",("a",("k";"t");"e",("d";"p");"nd";"ss");"i",("n",("d";"k");"mp";"ss";"tz");"o",("o",("d";"m");"at";"ck";"ke";"nd";"wn");"u",("r",("b";"t");"er";"ff";"nt";"sh"));"o",("a",("rd";"st");"n",("ey";"go";"us");"o",("t",("h";"y");"z",("e";"y");"by";"st");"r",("ax";"ne");"s",("om";"sy");"u",("gh";"le";"nd");"bby";"tch";"wel";"xer");"r",("a",("i",("d";"n");"s",("h";"s");"v",("e";"o");"w",("l";"n");"ce";"ke";"nd");"e",("a",("d";"k");"ed");"i",("n",("e";"g";"k";"y");"ar";"be";"ck";"de";"ef";"sk");"o",("o",("d";"k";"m");"ad";"il";"ke";"th";"wn");"u",("nt";"sh";"te"));"u",("d",("dy";"ge");"g",("gy";"le");"i","l",("d";"t");"l",("ge";"ky";"ly");"n",("ch";"ny");"r",("ly";"nt";"st");"s",("ed";"hy");"t",("ch";"te");"xom";"yer");"ylaw");"c",("a",("b",("al";"by";"in";"le");"c",("ao";"he";"ti");"d",("dy";"et");"m","e",("l";"o");"n",("o",("e";"n");"al";"dy";"ny");"p",("er";"ut");"r",("at";"go";"ol";"ry";"ve");"t",("ch";"er";"ty");"u",("lk";"se");"gey";"irn";"ste";"vil");"e",("ase";"dar";"llo");"h",("a",("f",("e";"f");"i",("n";"r");"r",("d";"m";"t");"s",("e";"m");"lk";"mp";"nt";"os");"e",("a",("p";"t");"e",("k";"r");"s",("s";"t");"ck");"i",("l",("d";"i";"l");"ck";"de";"ef";"me";"na";"rp");"o",("r",("d";"e");"ck";"ir";"ke";"se");"u",("ck";"mp";"nk";"rn";"te"));"i",("v","i",("c";"l");"der";"gar";"nch";"rca");"l",("a",("n",("g";"k");"s",("h";"p";"s");"ck";"im";"mp");"e",("a",("n";"r";"t");"ft";"rk");"i",("n",("g";"k");"ck";"ff";"mb");"o",("u",("d";"t");"ak";"ck";"ne";"se";"th";"ve";"wn");"u",("ck";"ed";"mp";"ng"));"o",("a",("ch";"st");"l","o",("n";"r");"m",("et";"fy";"ic";"ma");"n",("ch";"do";"ic");"r",("al";"er";"ny");"u",("ch";"gh";"ld";"nt";"pe";"rt");"v","e",("n";"r";"t";"y");"bra";"coa";"pse";"wer";"yly");"r",("a",("n",("e";"k");"s",("h";"s");"z",("e";"y");"ck";"ft";"mp";"te";"ve";"wl");"e",("a",("k";"m");"e",("d";"k";"p");"p",("e";"t");"s",("s";"t");"do";"me");"i",("e",("d";"r");"m",("e";"p");"ck";"sp");"o",("n",("e";"y");"w",("d";"n");"ak";"ck";"ok";"ss";"up");"u",("m",("b";"p");"s",("h";"t");"de";"el");"ypt");"u",("r",("v",("e";"y");"io";"ly";"ry";"se");"bic";"min";"tie");"y",("ber";"cle";"nic"));"d",("a",("i",("ly";"ry";"sy");"n",("ce";"dy");"ddy";"lly";"tum";"unt");"e",("a",("lt";"th");"b",("u",("g";"t");"ar";"it");"c",("a",("l";"y");"o",("r";"y");"ry");"i",("gn";"ty");"l",("ay";"ta";"ve");"m",("on";"ur");"n",("im";"se");"p",("ot";"th");"t",("er";"ox");"fer";"rby";"uce";"vil");"i",("n",("g",("o";"y");"er");"r",("ge";"ty");"t",("t",("o";"y");"ch");"ary";"cey";"git";"lly";"mly";"ode";"sco";"ver";"zzy");"o",("d","g",("e";"y");"n",("or";"ut");"u",("bt";"gh");"w",("dy";"el";"ny";"ry");"gma";"ing";"lly";"pey";"zen");"r",("a",("w",("l";"n");"ft";"in";"ke";"ma";"nk";"pe");"e",("a",("d";"m");"ss");"i",("e",("d";"r");"ft";"ll";"nk";"ve");"o",("o",("l";"p");"it";"ll";"ne";"ss";"ve";"wn");"u",("id";"nk");"y",("er";"ly"));"u",("m",("my";"py");"s",("ky";"ty");"chy";"lly";"nce";"tch";"vet");"w",("e","l",("l";"t");"arf");"ying");"e",("a",("g",("er";"le");"r",("ly";"th");"t","e",("n";"r");"sel");"d","i",("ct";"fy");"l",("e",("ct";"gy");"i",("de";"te");"ate";"bow";"der";"fin";"ope";"ude");"m",("b","e",("d";"r");"ail";"cee";"pty");"n",("e","m",("a";"y");"t",("er";"ry");"act";"dow";"joy";"nui";"sue";"voy");"p","o",("ch";"xy");"q","u",("al";"ip");"r",("ase";"ect";"ode";"ror";"upt");"s",("say";"ter");"t",("h",("er";"ic";"os");"ude");"v",("e",("nt";"ry");"ade";"ict";"oke");"x",("a",("ct";"lt");"i",("le";"st");"t",("ol";"ra");"cel";"ert";"pel";"ult");"bony";"clat";"erie";"gret";"ight";"ject";"king";"ying");"f",("a",("i",("nt";"ry";"th");"n",("cy";"ny");"t",("al";"ty");"u",("lt";"na");"ble";"cet";"lse";"rce";"vor");"e",("l",("la";"on");"m",("me";"ur");"r",("al";"ry");"t",("al";"ch";"id";"us");"ast";"cal";"ign";"nce";"ver";"wer");"i",("b",("er";"re");"e",("ld";"nd";"ry");"f","t",("h";"y");"l",("e",("r";"t");"ly";"my";"th");"n",("al";"ch";"er");"cus";"ght";"rst";"shy";"xer";"zzy");"l",("a",("i",("l";"r");"k",("e";"y");"s",("h";"k");"ck";"me";"nk";"re");"e",("ck";"et";"sh");"i",("n",("g";"t");"ck";"er";"rt");"o",("o",("d";"r");"u",("r";"t");"at";"ck";"ra";"ss";"wn");"u",("n",("g";"k");"ff";"id";"ke";"me";"sh";"te");"yer");"o",("c",("al";"us");"l",("io";"ly");"r",("g",("e";"o");"t",("e";"h";"y");"ay";"ce";"um");"amy";"ggy";"ist";"und";"yer");"r",("a",("il";"me";"nk";"ud");"e",("e",("d";"r");"ak";"sh");"i",("ar";"ed";"ll";"sk";"tz");"o",("n",("d";"t");"ck";"st";"th";"wn";"ze");"uit");"u",("n",("gi";"ky";"ny");"r",("or";"ry");"dge";"gue";"lly";"ssy";"zzy");"jord");"g",("a",("m",("er";"ma";"ut");"u",("dy";"ge";"nt";"ze");"y",("er";"ly");"ffe";"ily";"ssy";"vel";"wky";"zer");"e",("e",("ky";"se");"n",("ie";"re");"cko");"h","o",("st";"ul");"i",("r",("ly";"th");"v","e",("n";"r");"ant";"ddy";"psy");"l",("a",("de";"nd";"re";"ss";"ze");"e","a",("m";"n");"i",("de";"nt");"o",("at";"be";"om";"ry";"ss";"ve");"yph");"n",("ash";"ome");"o",("l",("em";"ly");"n",("ad";"er");"o",("dy";"ey";"fy";"se");"u",("ge";"rd");"dly";"ing";"rge");"r",("a",("i",("l";"n");"n",("d";"t");"p",("e";"h");"s",("p";"s");"v",("e";"y");"ce";"de";"ft";"te";"ze");"e",("e",("d";"n";"t");"at");"i",("m",("e";"y");"ef";"ll";"nd";"pe");"o",("u",("p";"t");"w",("l";"n");"an";"in";"om";"pe";"ss";"ve");"u",("el";"ff";"nt"));"u",("a",("rd";"va");"e","s",("s";"t");"i",("l",("d";"e";"t");"de";"se");"l",("ch";"ly");"m",("bo";"my");"s","t",("o";"y");"ppy");"ypsy");"h",("a",("r",("dy";"em";"py";"ry";"sh");"s","t",("e";"y");"t",("ch";"er");"u",("nt";"te");"v",("en";"oc");"bit";"iry";"lve";"ndy";"ppy";"zel");"e",("a",("r",("d";"t");"v",("e";"y");"dy";"th");"l",("ix";"lo");"dge";"fty";"ist";"nce";"ron");"i",("p","p",("o";"y");"lly";"nge";"tch");"o",("n",("ey";"or");"r",("de";"ny";"se");"t",("el";"ly");"u",("nd";"se");"v","e",("l";"r");"ard";"bby";"ist";"lly";"mer";"wdy");"u",("m",("an";"id";"or";"ph";"us");"n",("ch";"ky");"s",("ky";"sy");"rry";"tch");"y",("dro";"ena";"men";"per"));"i",("c","i",("ly";"ng");"d",("i","o",("m";"t");"eal";"ler";"yll");"m",("p",("el";"ly");"age";"bue");"n",("e",("pt";"rt");"l",("ay";"et");"t",("er";"ro");"ane";"box";"cur";"dex";"fer";"got";"ner";"put");"r",("ate";"ony");"s",("let";"sue");"gloo";"liac";"onic";"tchy";"vory");"j",("a",("unt";"zzy");"e",("lly";"rky";"tty";"wel");"o",("i",("nt";"st");"ker";"lly";"ust");"u",("i","c",("e";"y");"m",("bo";"py");"n","t",("a";"o");"dge";"ror");"iffy");"k",("a",("ppa";"rma";"yak");"i",("nky";"osk";"tty");"n",("a",("ck";"ve");"e",("e",("d";"l");"ad";"lt");"o",("ck";"ll";"wn");"ife");"ebab";"haki";"oala";"rill");"l",("a",("b",("el";"or");"d",("en";"le");"n",("ce";"ky");"p",("el";"se");"r",("ge";"va");"t",("ch";"er";"he";"te");"ger";"sso";"ugh";"yer");"e",("a",("s",("e";"h";"t");"ch";"fy";"ky";"nt";"pt";"rn";"ve");"e",("ch";"ry");"g",("al";"gy");"m",("on";"ur");"v","e",("l";"r");"dge";"fty";"per");"i",("m",("bo";"it");"n",("e",("n";"r");"go");"v",("er";"id");"bel";"ege";"ght";"ken";"lac";"pid";"the");"o",("a",("my";"th");"c",("al";"us");"g","i",("c";"n");"o",("py";"se");"u","s",("e";"y");"w",("er";"ly");"bby";"dge";"fty";"rry";"ser";"ver";"yal");"u",("c",("id";"ky");"m",("en";"py");"n",("ar";"ch";"ge");"r",("ch";"id");"pus";"sty");"y",("ing";"mph";"nch";"ric");"lama");"m",("a",("c",("aw";"ho";"ro");"d",("am";"ly");"g",("ic";"ma");"m",("m",("a";"y");"bo");"n",("g",("a";"e";"o";"y");"i",("a";"c");"ly";"or");"r",("ch";"ry";"sh");"s",("on";"se");"t",("ch";"ey");"y",("be";"or");"fia";"ize";"jor";"ker";"ple";"uve";"xim");"e",("a",("ly";"nt";"ty");"d",("i",("a";"c");"al");"l",("ee";"on");"r",("cy";"ge";"it";"ry");"t",("al";"er";"ro");"cca");"i",("d",("ge";"st");"n",("ce";"er";"im";"or";"ty";"us");"s",("er";"sy");"cro";"ght";"lky";"mic";"rth");"o",("d",("e",("l";"m");"al");"l",("ar";"dy");"n",("ey";"th");"o",("dy";"se");"r",("al";"on";"ph");"t",("el";"if";"or";"to");"u",("n",("d";"t");"lt";"rn";"se";"th");"v",("er";"ie");"cha";"gul";"ist";"ssy";"wer");"u",("c",("ky";"us");"r",("al";"ky");"s",("hy";"ic";"ky";"ty");"ddy";"lch";"mmy";"nch");"yrrh");"n",("a",("s",("al";"ty");"v",("al";"el");"dir";"ive";"nny";"tal");"e",("r",("dy";"ve");"w",("er";"ly");"edy";"igh";"ver");"i",("c",("er";"he");"n",("ja";"ny";"th");"ece";"ght");"o",("b","l",("e";"y");"i","s",("e";"y");"mad";"ose";"rth";"sey";"tch";"vel");"u",("dge";"rse";"tty");"y",("lon";"mph"));"o",("c",("t",("al";"et");"cur";"ean");"d","d",("er";"ly");"f",("f",("al";"er");"ten");"l",("d","e",("n";"r");"ive");"m",("bre";"ega");"n",("ion";"set");"p",("i",("ne";"um");"era";"tic");"r",("bit";"der";"gan");"t",("her";"ter");"u",("t",("do";"er";"go");"ght";"nce");"v",("a",("ry";"te");"ert";"ine";"oid");"w",("ing";"ner");"aken";"bese";"xide";"zone");"p",("a",("l",("er";"sy");"n",("el";"ic";"sy");"p",("al";"er");"r",("er";"ka";"ry";"se";"ty");"s","t",("a";"e";"y");"t",("ch";"io";"sy";"ty");"y","e",("e";"r");"ddy";"gan";"int";"use");"e",("a",("c",("e";"h");"rl");"n",("n",("e";"y");"al";"ce");"r",("ch";"il";"ky");"s",("ky";"to");"t",("al";"ty");"can";"dal");"h",("o",("n",("e";"y");"to");"ase");"i",("e",("ce";"ty");"n",("ch";"ey";"ky";"to");"t",("ch";"hy");"x",("el";"ie");"ano";"cky";"ggy";"lot";"per";"que";"vot";"zza");"l",("a",("i",("d";"n";"t");"n",("e";"k";"t");"ce";"te";"za");"e","a",("d";"t");"i","e",("d";"r");"u",("m",("b";"e";"p");"ck";"nk";"sh"));"o",("i",("nt";"se");"l",("ar";"ka";"yp");"s",("er";"it";"se");"u",("ch";"nd";"ty");"esy";"ker";"och";"ppy";"rch";"wer");"r",("a",("nk";"wn");"e",("en";"ss");"i",("c",("e";"k");"m",("e";"o");"de";"ed";"nt";"or";"sm";"vy";"ze");"o",("n",("e";"g");"be";"of";"se";"ud";"ve";"wl";"xy");"u",("de";"ne"));"u",("l",("py";"se");"p",("al";"il";"py");"r",("e",("e";"r");"ge";"se");"bic";"dgy";"ffy";"nch";"shy";"tty");"salm";"ygmy");"q","u",("a",("r",("k";"t");"s",("h";"i");"ck";"il";"ke";"lm");"e",("e",("n";"r");"ll";"ry";"st";"ue");"i",("l",("l";"t");"ck";"et";"rk";"te");"o","t",("a";"e";"h"));"r",("a",("b",("bi";"id");"d",("i",("i";"o");"ar");"i",("ny";"se");"l",("ly";"ph");"n",("ch";"dy";"ge");"t",("io";"ty");"cer";"jah";"men";"pid";"rer";"spy";"ven";"yon";"zor");"e",("a",("c",("h";"t");"dy";"lm";"rm");"b",("u",("s";"t");"ar";"el");"c",("u",("r";"t");"ap");"f",("er";"it");"l",("a",("x";"y");"ic");"n",("al";"ew");"p",("ay";"el";"ly");"s",("et";"in");"t",("r",("o";"y");"ch");"v",("el";"ue");"edy";"gal";"hab";"ign";"mit";"run";"use");"h",("ino";"yme");"i",("d",("er";"ge");"g",("ht";"id";"or");"p","e",("n";"r");"s",("e",("n";"r");"ky");"v",("e",("r";"t");"al");"fle";"nse");"o",("a",("ch";"st");"b",("in";"ot");"g",("er";"ue");"o",("my";"st");"u",("g",("e";"h");"nd";"se";"te");"w",("dy";"er");"cky";"deo";"tor";"ver";"yal");"u",("d",("dy";"er");"m",("ba";"or");"gby";"ler";"pee";"ral";"sty"));"s",("a",("l",("v",("e";"o");"ad";"ly";"on";"sa";"ty");"n",("dy";"er");"t",("in";"yr");"u",("c",("e";"y");"na";"te");"v",("o",("r";"y");"vy");"dly";"fer";"int";"ppy";"ssy");"c",("a",("l",("d";"e";"p";"y");"r",("e";"f";"y");"mp";"nt");"e","n",("e";"t");"o",("r",("e";"n");"u",("r";"t");"ff";"ld";"ne";"op";"pe";"wl");"r",("a",("m";"p");"e",("e";"w");"u",("b";"m"));"ion";"uba");"e",("r",("if";"um";"ve");"v","e",("n";"r");"dan";"edy";"gue";"ize";"men";"nse";"pia";"tup";"wer");"h",("a",("d",("e";"y");"k",("e";"y");"l",("e";"l";"t");"r",("d";"e";"k";"p");"ck";"ft";"me";"nk";"pe";"ve";"wl");"e",("e",("n";"p";"r";"t");"l",("f";"l");"ar";"ik");"i",("n",("e";"y");"r",("e";"k";"t");"ed";"ft");"o",("o",("k";"t");"r",("e";"n";"t");"w",("n";"y");"al";"ck";"ne";"ut";"ve");"r",("u",("b";"g");"ew");"u",("ck";"nt";"sh");"yly");"i",("e",("ge";"ve");"g",("ht";"ma");"l",("ky";"ly");"n",("ce";"ew";"ge");"x","t",("h";"y");"ren";"ssy");"k",("i",("er";"ff";"ll";"mp";"rt");"u",("l",("k";"l");"nk");"ate");"l",("a",("n",("g";"t");"ck";"in";"sh";"te";"ve");"e",("e",("k";"p";"t");"pt");"i",("c",("e";"k");"m",("e";"y");"n",("g";"k");"de");"o",("op";"pe";"sh";"th");"u",("n",("g";"k");"mp";"rp";"sh");"yly");"m",("a",("ck";"ll";"rt";"sh");"e",("l",("l";"t");"ar");"i",("t",("e";"h");"le";"rk");"o",("k",("e";"y");"ck";"te"));"n",("a",("k",("e";"y");"r",("e";"l");"ck";"il");"e",("ak";"er");"i",("de";"ff";"pe");"o",("r",("e";"t");"op";"ut";"wy");"u",("ck";"ff"));"o",("l",("ar";"id";"ve");"n",("ar";"ic");"o","t",("h";"y");"u",("nd";"th");"apy";"ber";"ggy";"rry";"wer");"p",("a",("r",("e";"k");"ce";"de";"nk";"sm";"wn");"e",("a",("k";"r");"l",("l";"t");"n",("d";"t");"ck";"ed";"rm");"i",("c",("e";"y");"e",("d";"l");"k",("e";"y");"l",("l";"t");"n",("e";"y");"re";"te");"l",("at";"it");"o",("o",("f";"k";"l";"n");"r",("e";"t");"il";"ke";"ut");"r",("ay";"ee";"ig");"u",("r",("n";"t");"nk"));"q","u",("a",("d";"t");"ib");"t",("a",("i",("d";"n";"r");"l",("e";"k";"l");"n",("d";"k");"r",("e";"k";"t");"ck";"ff";"ge";"ke";"mp";"sh";"te";"ve");"e",("a",("d";"k";"l";"m");"e",("d";"l";"p";"r");"in";"rn");"i",("l",("l";"t");"n",("g";"k";"t");"ck";"ff");"o",("n",("e";"y");"o",("d";"l";"p");"r",("e";"k";"m";"y");"ck";"ic";"ke";"le";"mp";"ut";"ve");"r",("a",("p";"w";"y");"ip";"ut");"u",("n",("g";"k";"t");"ck";"dy";"ff";"mp");"yle");"u",("i",("ng";"te");"l",("ky";"ly");"r",("er";"ge";"ly");"ave";"gar";"mac";"nny";"per";"shi");"w",("a",("m",("i";"p");"rm";"sh";"th");"e",("a",("r";"t");"e",("p";"t");"ll";"pt");"i",("n",("e";"g");"ft";"ll";"rl";"sh");"o",("o",("n";"p");"r",("d";"e";"n"));"ung");"y",("nod";"rup"));"t",("a",("b",("by";"le";"oo");"c",("it";"ky");"k","e",("n";"r");"l",("ly";"on");"n","g",("o";"y");"p",("er";"ir");"r",("dy";"ot");"s","t",("e";"y");"ffy";"int";"mer";"tty";"unt";"wny");"e",("a",("ch";"ry";"se");"n",("et";"or";"se";"th");"p",("ee";"id");"r",("ra";"se");"ddy";"eth";"mpo";"sty");"h",("e",("ft";"ir";"me";"re";"se";"ta");"i",("n",("g";"k");"ck";"ef";"gh";"rd");"o",("ng";"rn";"se");"r",("e",("e";"w");"o",("b";"w");"um");"u","m",("b";"p");"ank";"yme");"i",("g",("er";"ht");"m",("er";"id");"t",("an";"he";"le");"ara";"bia";"dal";"lde";"psy");"o",("d",("ay";"dy");"n",("al";"ga";"ic");"p",("az";"ic");"r",("ch";"so";"us");"t",("al";"em");"u",("ch";"gh");"w","e",("l";"r");"x","i",("c";"n");"ast";"ken";"oth");"r",("a",("c",("e";"k";"t");"i",("l";"n";"t");"de";"mp";"sh";"wl");"e",("a",("d";"t");"nd");"i",("a",("d";"l");"c",("e";"k");"be";"ed";"pe";"te");"o",("ll";"op";"pe";"ut";"ve");"u",("c",("e";"k");"s",("s";"t");"er";"ly";"mp";"nk";"th");"yst");"u",("b",("al";"er");"l",("ip";"le");"mor";"nic";"rbo";"tor");"w",("e",("e",("d";"t");"ak");"i",("ce";"ne";"rl";"st";"xt");"ang");"ying");"u",("l",("cer";"tra");"n",("c",("le";"ut");"d",("er";"id";"ue");"f",("ed";"it");"i",("t",("e";"y");"fy";"on");"t","i",("e";"l");"lit";"met";"set";"wed";"zip");"p",("per";"set");"r",("ban";"ine");"s",("u",("al";"rp");"age";"her";"ing");"t",("ile";"ter");"dder";"mbra");"v",("a",("l",("et";"id";"or";"ue";"ve");"p",("id";"or");"u",("lt";"nt");"gue");"e",("n",("om";"ue");"r",("s",("e";"o");"ge";"ve");"gan");"i",("g",("il";"or");"r",("al";"us");"s",("it";"or";"ta");"car";"deo";"lla";"nyl";"ola";"per";"tal";"vid";"xen");"o",("i",("ce";"la");"cal";"dka";"gue";"mit";"ter";"uch";"wel");"ying");"w",("a",("g",("er";"on");"i",("st";"ve");"t",("ch";"er");"cky";"fer";"ltz";"rty";"ste";"ver";"xen");"e",("a",("ry";"ve");"i",("gh";"rd");"l",("ch";"sh");"dge";"edy";"nch");"h",("a",("ck";"le";"rf");"e",("at";"el";"lp";"re");"i",("n",("e";"y");"ch";"ff";"le";"rl";"sk";"te");"o",("le";"op";"se"));"i",("d",("e",("n";"r");"ow";"th");"n",("c",("e";"h");"dy");"s",("er";"py");"t",("ch";"ty");"eld";"ght";"lly";"mpy");"o",("m",("an";"en");"o",("dy";"er";"ly";"zy");"r",("s",("e";"t");"dy";"ld";"ry";"th");"u",("ld";"nd");"ken";"ven");"r",("a",("ck";"th");"e",("ak";"ck";"st");"i",("ng";"st";"te");"o",("ng";"te");"ung";"yly"));"y",("e","a",("rn";"st");"o","u",("ng";"th");"acht";"ield");"z",("e",("bra";"sty");"onal")).
