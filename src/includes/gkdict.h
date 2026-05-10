/*
#define WORDLIST "gkdict/gkdict"
#define INDECLIST "gkdict/indices/indecl"
#define IRREGLIST "gkdict/indices/irrverb"
#define STEMLIST "gkdict/indices/stindex"
*/
#ifndef WORDLIST
#define WORDLIST "hqdict/hqdict"
#endif
#ifndef COMPHEADS
#define COMPHEADS "/tmp/nom.heads"
#endif
#ifndef NOMLIST
#define NOMLIST "/tmp/nommorph"
#endif
#ifndef NOMINDEX
#define NOMINDEX "steminds/nomind"
#endif
#ifndef VBLIST
#define VBLIST "/tmp/vbmorph"
#endif
#ifndef VBINDEX
#define VBINDEX "steminds/vbind"
#endif
#ifndef INDECLIST
#define INDECLIST "hqdict/indices/indecl"
#endif
#ifndef IRREGLIST
#define IRREGLIST "hqdict/indices/irrverb"
#endif
#ifndef STEMLIST
#define STEMLIST "hqdict/indices/stindex"
#endif

#define LEMMTAG		":le:"

typedef struct {
	int clen;
	char **citem;
	int curindex;
} Stemcache;
