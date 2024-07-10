#define nostub(_symbol) \
    struct _stubber_nostub_meta_##_symbol \
        { size_t nostub_sym_length; char nostub_sym[sizeof( #_symbol )]; \
          size_t nostub_file_path_length; char nostub_file_path[sizeof(__FILE__)]; \
          int nostub_line_number; }; \
    __attribute__((used)) \
    __attribute__((section ("__TEXT,__stbr_nostub"))) \
    __attribute__((__visibility__("hidden"))) \
    static struct _stubber_nostub_meta_##_symbol _stubber_nostub_##_symbol = \
        { .nostub_sym_length = sizeof( #_symbol ), .nostub_sym = #_symbol, \
          .nostub_file_path_length = sizeof(__FILE__), .nostub_file_path = __FILE__, \
          .nostub_line_number = __LINE__ };
