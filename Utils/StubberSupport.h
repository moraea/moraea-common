#define nostub(_symbol) \
    struct _nostub_meta_##_symbol \
        { size_t nostub_sym_size; char nostub_sym[sizeof( #_symbol )]; }; \
    __attribute__((used)) \
    __attribute__((section ("__TEXT,__stbr_nostub"))) \
    __attribute__((__visibility__("hidden"))) \
    static struct _nostub_meta_##_symbol nostub_##_symbol = \
        { .nostub_sym_size = sizeof( #_symbol ), .nostub_sym = #_symbol };