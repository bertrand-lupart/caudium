#ifndef _CAUDIUM_H_
#define _CAUDIUM_H_
static void f_parse_headers( INT32 args );
static void f_parse_query_string( INT32 args );
void pike_module_init( void );
void pike_module_exit( void );
static void free_buf_struct(struct object *);
static void alloc_buf_struct(struct object *);
void init_nbio(void);
void exit_nbio(void);

#define READ_BUFFER_SIZE 65536
#define READ_MORE_SIZE   40000 


#define BUFSIZE 16535
#define BUF ((buffer *)fp->current_storage)
#define STRS(x) strs.x.u.string
#define SVAL(x) (&(strs.x))

typedef struct
{
  struct svalue data;
  struct svalue file;
  struct svalue method;
  struct svalue protocol;
  struct svalue query;
  struct svalue raw_url;

  struct pike_string *h_clength;
  struct pike_string *h_auth;
  struct pike_string *h_proxyauth;
  struct pike_string *h_pragma;
  struct pike_string *h_useragent;
  struct pike_string *h_referrer;
  struct pike_string *h_range;
  struct pike_string *h_conn;
  struct pike_string *h_ctype;
  
} static_strings;

typedef struct
{
  unsigned char *pos;
  int free;
  struct mapping *headers;
  struct mapping *other;
  unsigned char *data;
} buffer;

/* Input data (object or string) */
typedef struct _input_struct
{
  int len;  /* Length of input, or -1 for 'till end' */
  int pos;  /* current position */
  INT16 type; /* type of input  */
  union {
    struct object *file;      /* Pike file object */
    struct pike_string *data; /* Data */
  } u;
  int read_off;
  int fd; /* Numerical FD or -1 if fake object */
  struct _input_struct *next;
} input;

/* Output data (fd or fake fd) */
typedef struct
{
  struct object *file;      /* Pike file object */
  int set_b_off;
  int set_nb_off;
  int write_off;
  int fd; /* Numerical FD or -1 if fake object */
} output;

typedef struct
{
  int written;
  int buf_len;
  char buf[READ_BUFFER_SIZE];
  output *outp;
  input *inputs;
  input *last_input;
  struct array *args;
  struct svalue cb;

} nbio_storage;

#ifndef MIN
#define MIN(x,y) (((x) < (y)) ? (x) : (y))
#endif
#ifndef MAX
#define MAX(x,y) (((x) > (y)) ? (x) : (y))
#endif
#endif
