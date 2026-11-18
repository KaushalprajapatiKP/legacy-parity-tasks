/*
 * oldbook - a small contacts and calendar keeper.
 *
 * MIT License
 * Copyright (c) 2026 the task author
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 */
#include <ctype.h>
#include <dirent.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

__attribute__((used)) static const char MARK[] = "oldbook-store-reader/7f3a91 build 3.4.1";

/* ------------------------------------------------------------ utilities */
static void *xmalloc(size_t n) {
    void *p = malloc(n ? n : 1);
    if (!p) { fprintf(stderr, "oldbook: out of memory\n"); exit(2); }
    return p;
}

typedef struct { char *s; size_t n, cap; } Buf;
static void bput(Buf *b, const char *s, size_t n) {
    if (b->n + n + 1 > b->cap) {
        b->cap = (b->n + n + 1) * 2;
        b->s = realloc(b->s, b->cap);
        if (!b->s) exit(2);
    }
    memcpy(b->s + b->n, s, n);
    b->n += n;
    b->s[b->n] = 0;
}
static void bput_cp(Buf *b, uint32_t cp) {
    char t[4];
    if (cp < 0x80) { t[0] = (char)cp; bput(b, t, 1); }
    else if (cp < 0x800) { t[0] = (char)(0xC0 | (cp >> 6)); t[1] = (char)(0x80 | (cp & 63)); bput(b, t, 2); }
    else if (cp < 0x10000) {
        t[0] = (char)(0xE0 | (cp >> 12)); t[1] = (char)(0x80 | ((cp >> 6) & 63)); t[2] = (char)(0x80 | (cp & 63));
        bput(b, t, 3);
    } else {
        t[0] = (char)(0xF0 | (cp >> 18)); t[1] = (char)(0x80 | ((cp >> 12) & 63));
        t[2] = (char)(0x80 | ((cp >> 6) & 63)); t[3] = (char)(0x80 | (cp & 63));
        bput(b, t, 4);
    }
}

static uint32_t crc_tab[256];
static void crc_init(void) {
    for (uint32_t i = 0; i < 256; i++) {
        uint32_t c = i;
        for (int k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320u ^ (c >> 1) : c >> 1;
        crc_tab[i] = c;
    }
}
static uint32_t crc32b(const uint8_t *p, size_t n) {
    uint32_t c = 0xFFFFFFFFu;
    for (size_t i = 0; i < n; i++) c = crc_tab[(c ^ p[i]) & 0xFF] ^ (c >> 8);
    return c ^ 0xFFFFFFFFu;
}

/* sha256 */
static const uint32_t K256[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
#define ROR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
static void sha256_block(uint32_t h[8], const uint8_t *p) {
    uint32_t w[64], a, b, c, d, e, f, g, hh;
    for (int i = 0; i < 16; i++) w[i] = (uint32_t)p[4*i] << 24 | (uint32_t)p[4*i+1] << 16 | (uint32_t)p[4*i+2] << 8 | p[4*i+3];
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = ROR(w[i-15], 7) ^ ROR(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = ROR(w[i-2], 17) ^ ROR(w[i-2], 19) ^ (w[i-2] >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    a = h[0]; b = h[1]; c = h[2]; d = h[3]; e = h[4]; f = h[5]; g = h[6]; hh = h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = ROR(e, 6) ^ ROR(e, 11) ^ ROR(e, 25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = hh + S1 + ch + K256[i] + w[i];
        uint32_t S0 = ROR(a, 2) ^ ROR(a, 13) ^ ROR(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        hh = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
    }
    h[0] += a; h[1] += b; h[2] += c; h[3] += d; h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
}
static void sha256_hex(const uint8_t *p, size_t n, char out[65]) {
    uint32_t h[8] = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    size_t i = 0;
    uint8_t blk[64];
    for (; i + 64 <= n; i += 64) sha256_block(h, p + i);
    size_t r = n - i;
    memset(blk, 0, 64);
    memcpy(blk, p + i, r);
    blk[r] = 0x80;
    if (r >= 56) { sha256_block(h, blk); memset(blk, 0, 64); }
    uint64_t bits = (uint64_t)n * 8;
    for (int k = 0; k < 8; k++) blk[63 - k] = (uint8_t)(bits >> (8 * k));
    sha256_block(h, blk);
    for (int k = 0; k < 8; k++) sprintf(out + 8 * k, "%08x", h[k]);
}

/* ------------------------------------------------------------- calendar */
static int64_t days_from_civil(int64_t y, int m, int d) {
    y -= m <= 2;
    int64_t era = (y >= 0 ? y : y - 399) / 400;
    int64_t yoe = y - era * 400;
    int64_t doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    int64_t doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}
static void civil_from_days(int64_t z, int64_t *y, int *m, int *d) {
    z += 719468;
    int64_t era = (z >= 0 ? z : z - 146096) / 146097;
    int64_t doe = z - era * 146097;
    int64_t yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    int64_t yy = yoe + era * 400;
    int64_t doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    int64_t mp = (5 * doy + 2) / 153;
    *d = (int)(doy - (153 * mp + 2) / 5 + 1);
    *m = (int)(mp < 10 ? mp + 3 : mp - 9);
    *y = yy + (*m <= 2);
}
static int month_len(int64_t y, int m) {
    static const int ml[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
    if (m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) return 29;
    return ml[m - 1];
}
static void fmt_date(int64_t day, char *out) {
    int64_t y; int m, d;
    civil_from_days(day, &y, &m, &d);
    sprintf(out, "%04lld-%02d-%02d", (long long)y, m, d);
}
static void fmt_off(int off, char *out) {
    int a = off < 0 ? -off : off;
    sprintf(out, "%c%02d:%02d", off < 0 ? '-' : '+', a / 60, a % 60);
}
static int parse_date(const char *s, int64_t *out) {
    int y, m, d;
    if (sscanf(s, "%d-%d-%d", &y, &m, &d) != 3 || m < 1 || m > 12 || d < 1 || d > month_len(y, m)) return 0;
    *out = days_from_civil(y, m, d);
    return 1;
}

/* ------------------------------------------------------------- reading */
typedef struct { const uint8_t *p, *end; int err; } Rd;
static uint64_t rd_uv(Rd *r) {
    uint64_t v = 0; int sh = 0;
    while (r->p < r->end) {
        uint8_t b = *r->p++;
        if (sh < 64) v |= (uint64_t)(b & 0x7F) << sh;
        sh += 7;
        if (!(b & 0x80)) return v;
    }
    r->err = 1;
    return 0;
}
static int64_t unzz(uint64_t v) { return (int64_t)(v >> 1) ^ -(int64_t)(v & 1); }

static const uint16_t table_cp[64] = {
    0x20ac, 0x00e7, 0x00ca, 0x00d1, 0x00df, 0x00f1, 0x00cc, 0x00d2, 0x00ea, 0x00d9, 0x00e4, 0x00e9, 0x00c0, 0x00c7, 0x00a3, 0x00d5, 0x00dc, 0x00fe, 0x00e1, 0x00f9, 0x00cb, 0x00c4, 0x00fc, 0x00d4, 0x00e6, 0x00ed, 0x00c6, 0x00cf, 0x00fb, 0x00d6, 0x00d3, 0x00da, 0x00e5, 0x00fa, 0x00f4, 0x00de, 0x00f3, 0x00eb, 0x00e0, 0x00cd, 0x00dd, 0x00e2, 0x00c1, 0x00f5, 0x00f2, 0x00ec, 0x00c9, 0x00ee, 0x00f6, 0x00e3, 0x00f8, 0x00d0, 0x00ce, 0x00c8, 0x00f0, 0x00e8, 0x00c2, 0x00ff, 0x00d8, 0x00c5, 0x00fd, 0x00c3, 0x00ef, 0x00db};

static char *decode_text(const uint8_t *p, size_t n, int version) {
    Buf b = {0};
    bput(&b, "", 0);
    Rd r = {p, p + n, 0};
    while (r.p < r.end) {
        uint8_t c = *r.p++;
        if (version == 2) {
            bput_cp(&b, c);
        } else if (c == 0x1E) {
            bput_cp(&b, '\n');
        } else if (c < 0x80) {
            bput_cp(&b, c);
        } else if (c < 0xC0) {
            bput_cp(&b, table_cp[c - 0x80]);
        } else if (c == 0xC0) {
            uint64_t cp = rd_uv(&r);
            bput_cp(&b, cp > 0x10FFFF ? '?' : (uint32_t)cp);
        } else {
            bput_cp(&b, '?');
        }
    }
    return b.s;
}

typedef struct {
    char name[256];
    uint8_t *data;
    size_t len;
    int ok, version, default_tz;
    int64_t base_day;
    size_t nfree;
    size_t *free_off, *free_len;
} File;

enum { K_PERSON = 0x11, K_ORG, K_EVENT, K_RECUR, K_TASK, K_NOTE, K_BLOB = 0x1B, K_TOMB = 0x1D };

typedef struct {
    int kind, file;
    uint64_t id, rev;
    const uint8_t *body; /* fields start */
    size_t blen;
} Cell;

typedef struct { uint64_t id; const uint8_t *data; size_t len; } Blob;

static File *files; static int nfiles;
static Cell *cells; static size_t ncells, capcells;
static Blob *blobs; static size_t nblobs, capblobs;

static const char *kind_name(int k) {
    switch (k) {
    case K_PERSON: return "person";
    case K_ORG: return "org";
    case K_EVENT: return "event";
    case K_RECUR: return "recurring";
    case K_TASK: return "task";
    case K_NOTE: return "note";
    }
    return "unknown";
}

static int cmp_str(const void *a, const void *b) { return strcmp(*(char *const *)a, *(char *const *)b); }

static void add_cell(Cell c) {
    if (ncells == capcells) { capcells = capcells ? capcells * 2 : 256; cells = realloc(cells, capcells * sizeof(Cell)); }
    cells[ncells++] = c;
}
static void add_blob(Blob b) {
    if (nblobs == capblobs) { capblobs = capblobs ? capblobs * 2 : 64; blobs = realloc(blobs, capblobs * sizeof(Blob)); }
    blobs[nblobs++] = b;
}
static uint32_t rd32(const uint8_t *p) { return (uint32_t)p[0] | (uint32_t)p[1] << 8 | (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24; }

static void scan_file(int fi) {
    File *f = &files[fi];
    const uint8_t *d = f->data;
    size_t n = f->len;
    if (n < 20 || memcmp(d, "OBK\x1a", 4) != 0) {
        fprintf(stderr, "oldbook: skipping %s: not an oldbook store\n", f->name);
        return;
    }
    if (crc32b(d, n - 4) != rd32(d + n - 4)) {
        fprintf(stderr, "oldbook: skipping %s: integrity check failed\n", f->name);
        return;
    }
    size_t cs, ce, fto = 0;
    f->version = d[4];
    if (f->version == 2) {
        f->base_day = days_from_civil(1900, 1, 1);
        f->default_tz = 0;
        cs = rd32(d + 8); ce = rd32(d + 12);
    } else if (f->version == 3 && n >= 28) {
        f->default_tz = (d[5] & 1) ? (int16_t)(d[6] | d[7] << 8) : 0;
        f->base_day = (int32_t)rd32(d + 8);
        fto = rd32(d + 12); cs = rd32(d + 16); ce = rd32(d + 20);
    } else {
        fprintf(stderr, "oldbook: skipping %s: unsupported version %d\n", f->name, d[4]);
        return;
    }
    if (cs > n - 4 || ce > n - 4 || cs > ce) {
        fprintf(stderr, "oldbook: skipping %s: damaged header\n", f->name);
        return;
    }
    if (fto) {
        Rd r = {d + fto, d + n - 4, 0};
        uint64_t cnt = rd_uv(&r);
        if (cnt > n) cnt = 0;
        f->free_off = xmalloc(cnt * sizeof(size_t));
        f->free_len = xmalloc(cnt * sizeof(size_t));
        for (uint64_t i = 0; i < cnt && !r.err; i++) {
            f->free_off[i] = rd_uv(&r);
            f->free_len[i] = rd_uv(&r);
            f->nfree++;
        }
    }
    f->ok = 1;
    size_t pos = cs;
    while (pos < ce) {
        int jumped = 0;
        for (size_t i = 0; i < f->nfree; i++)
            if (f->free_off[i] == pos && f->free_len[i] > 0) { pos += f->free_len[i]; jumped = 1; break; }
        if (jumped) continue;
        int kind = d[pos];
        Rd r = {d + pos + 1, d + ce, 0};
        uint64_t len = rd_uv(&r);
        if (r.err || len > (uint64_t)(r.end - r.p)) {
            fprintf(stderr, "oldbook: %s: truncated cell at offset %zu\n", f->name, pos);
            break;
        }
        const uint8_t *body = r.p;
        pos = (size_t)(body - d) + len;
        Rd b = {body, body + len, 0};
        if (kind == K_BLOB) {
            Blob bl;
            bl.id = rd_uv(&b);
            bl.data = b.p;
            bl.len = (size_t)(b.end - b.p);
            add_blob(bl);
        } else if ((kind >= K_PERSON && kind <= K_NOTE) || kind == K_TOMB) {
            Cell c;
            c.kind = kind; c.file = fi;
            c.id = rd_uv(&b);
            c.rev = rd_uv(&b);
            c.body = b.p;
            c.blen = (size_t)(b.end - b.p);
            add_cell(c);
        }
    }
}

static void load(const char *dir) {
    DIR *dd = opendir(dir);
    if (!dd) { fprintf(stderr, "oldbook: cannot open data directory %s\n", dir); exit(2); }
    char **names = NULL; int nn = 0;
    struct dirent *e;
    while ((e = readdir(dd))) {
        size_t l = strlen(e->d_name);
        if (l > 4 && strcmp(e->d_name + l - 4, ".obk") == 0) {
            names = realloc(names, (nn + 1) * sizeof(char *));
            names[nn++] = strdup(e->d_name);
        }
    }
    closedir(dd);
    qsort(names, nn, sizeof(char *), cmp_str);
    files = calloc(nn ? nn : 1, sizeof(File));
    nfiles = nn;
    for (int i = 0; i < nn; i++) {
        char path[4096];
        snprintf(path, sizeof path, "%s/%s", dir, names[i]);
        snprintf(files[i].name, sizeof files[i].name, "%s", names[i]);
        FILE *fp = fopen(path, "rb");
        if (!fp) continue;
        fseek(fp, 0, SEEK_END);
        long sz = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        files[i].data = xmalloc((size_t)sz);
        files[i].len = fread(files[i].data, 1, (size_t)sz, fp);
        fclose(fp);
        scan_file(i);
    }
}

/* resolution: winners[] = highest revision cell per id */
static Cell **winners; static size_t nwin;
static int cmp_cell(const void *a, const void *b) {
    const Cell *x = a, *y = b;
    if (x->id != y->id) return x->id < y->id ? -1 : 1;
    if (x->rev != y->rev) return x->rev < y->rev ? -1 : 1;
    return 0;
}
static void resolve(void) {
    qsort(cells, ncells, sizeof(Cell), cmp_cell);
    winners = xmalloc((ncells + 1) * sizeof(Cell *));
    for (size_t i = 0; i < ncells; i++)
        if (i + 1 == ncells || cells[i + 1].id != cells[i].id) winners[nwin++] = &cells[i];
}
static Cell *find_winner(uint64_t id) {
    size_t lo = 0, hi = nwin;
    while (lo < hi) {
        size_t mid = (lo + hi) / 2;
        if (winners[mid]->id == id) return winners[mid];
        if (winners[mid]->id < id) lo = mid + 1; else hi = mid;
    }
    return NULL;
}
static Cell *find_live(uint64_t id) {
    Cell *c = find_winner(id);
    return c && c->kind != K_TOMB ? c : NULL;
}
static Blob *find_blob(uint64_t id) {
    for (size_t i = 0; i < nblobs; i++) if (blobs[i].id == id) return &blobs[i];
    return NULL;
}

/* ------------------------------------------------------------- records */
#define MAXR 64
typedef struct {
    char *fname, *mime;
    uint8_t *data; size_t dlen;
    int has_data, has_blob, unavailable;
    uint64_t blob, flags;
} Att;
typedef struct {
    int kind; uint64_t id, rev;
    char *label, *phone, *website, *address, *location, *body;
    char *emails[MAXR]; int nemails;
    int has_date; int64_t date;
    int has_start; int64_t sday; int smin;
    uint64_t dur;
    int tz;
    uint64_t refs[MAXR]; int nrefs;
    int has_ref; uint64_t ref;
    uint64_t freq, interval, count; int has_count;
    int has_until; int64_t until;
    int64_t exc[MAXR]; int nexc;
    uint64_t state;
    Att att[16]; int natt;
} Rec;

static void decode_att(Att *a, const uint8_t *p, size_t n, int version) {
    memset(a, 0, sizeof *a);
    Rd r = {p, p + n, 0};
    const uint8_t *raw = NULL; size_t rawlen = 0;
    while (r.p < r.end && !r.err) {
        uint64_t key = rd_uv(&r);
        int fno = (int)(key >> 3), wt = (int)(key & 7);
        uint64_t v = 0; const uint8_t *bp = NULL; uint64_t bl = 0;
        if (wt == 2 || wt == 3 || wt == 6) { bl = rd_uv(&r); bp = r.p; r.p += bl; if (r.p > r.end) { r.err = 1; break; } }
        else v = rd_uv(&r);
        if (fno == 1 && wt == 2) a->fname = decode_text(bp, bl, version);
        else if (fno == 2 && wt == 2) a->mime = decode_text(bp, bl, version);
        else if (fno == 3 && wt == 3) { raw = bp; rawlen = bl; }
        else if (fno == 4 && wt == 0) { a->blob = v; a->has_blob = 1; }
        else if (fno == 5 && wt == 0) a->flags = v;
    }
    if (raw) {
        if (a->flags & 1) {
            size_t total = 0;
            for (size_t i = 0; i + 1 < rawlen; i += 2) total += raw[i];
            a->data = xmalloc(total);
            size_t o = 0;
            for (size_t i = 0; i + 1 < rawlen; i += 2) { memset(a->data + o, raw[i + 1], raw[i]); o += raw[i]; }
            a->dlen = total;
        } else {
            a->data = xmalloc(rawlen);
            memcpy(a->data, raw, rawlen);
            a->dlen = rawlen;
        }
        a->has_data = 1;
    } else if (a->has_blob) {
        Blob *b = find_blob(a->blob);
        if (b) { a->data = (uint8_t *)b->data; a->dlen = b->len; a->has_data = 1; }
        else a->unavailable = 1;
    } else {
        a->unavailable = 1;
    }
    if (!a->fname) a->fname = strdup("(unnamed)");
    if (!a->mime) a->mime = strdup("application/octet-stream");
}

static void decode(const Cell *c, Rec *R) {
    memset(R, 0, sizeof *R);
    File *f = &files[c->file];
    R->kind = c->kind; R->id = c->id; R->rev = c->rev;
    R->tz = f->default_tz;
    R->dur = 60;
    R->interval = 1;
    Rd r = {c->body, c->body + c->blen, 0};
    while (r.p < r.end && !r.err) {
        uint64_t key = rd_uv(&r);
        int fno = (int)(key >> 3), wt = (int)(key & 7);
        uint64_t v = 0; const uint8_t *bp = NULL; uint64_t bl = 0;
        if (wt == 2 || wt == 3 || wt == 6) { bl = rd_uv(&r); bp = r.p; r.p += bl; if (r.p > r.end) { r.err = 1; break; } }
        else if (wt <= 5) v = rd_uv(&r);
        else { r.err = 1; break; }
        char *txt = wt == 2 ? decode_text(bp, bl, f->version) : NULL;
        int64_t dv = f->base_day + unzz(v);
        if (fno == 7 && wt == 6) {
            if (R->natt < 16) decode_att(&R->att[R->natt++], bp, bl, f->version);
            continue;
        }
        switch (c->kind) {
        case K_PERSON:
            if (fno == 1 && txt) R->label = txt;
            else if (fno == 2 && txt && R->nemails < MAXR) R->emails[R->nemails++] = txt;
            else if (fno == 3 && txt) R->phone = txt;
            else if (fno == 4 && wt == 4) { R->has_date = 1; R->date = dv; }
            else if (fno == 5 && wt == 0) { R->has_ref = 1; R->ref = v; }
            break;
        case K_ORG:
            if (fno == 1 && txt) R->label = txt;
            else if (fno == 2 && txt) R->website = txt;
            else if (fno == 3 && txt) R->address = txt;
            else if (fno == 4 && wt == 0) { R->has_ref = 1; R->ref = v; }
            break;
        case K_EVENT: case K_RECUR:
            if (fno == 1 && txt) R->label = txt;
            else if (fno == 2 && wt == 5) {
                R->has_start = 1;
                R->sday = f->base_day + unzz(v >> 11);
                R->smin = (int)(v & 0x7FF);
            } else if (fno == 3 && wt == 0) R->dur = v;
            else if (fno == 4 && wt == 1) R->tz = (int)unzz(v) * 15;
            else if (fno == 5 && txt) R->location = txt;
            else if (fno == 6 && wt == 0 && R->nrefs < MAXR) R->refs[R->nrefs++] = v;
            else if (c->kind == K_RECUR) {
                if (fno == 8 && wt == 0) R->freq = v;
                else if (fno == 9 && wt == 0) R->interval = v ? v : 1;
                else if (fno == 10 && wt == 0) { R->has_count = 1; R->count = v; }
                else if (fno == 11 && wt == 4) { R->has_until = 1; R->until = dv; }
                else if (fno == 12 && wt == 4 && R->nexc < MAXR) R->exc[R->nexc++] = dv;
            }
            break;
        case K_TASK:
            if (fno == 1 && txt) R->label = txt;
            else if (fno == 2 && wt == 4) { R->has_date = 1; R->date = dv; }
            else if (fno == 3 && wt == 0) R->state = v;
            else if (fno == 4 && wt == 0) { R->has_ref = 1; R->ref = v; }
            break;
        case K_NOTE:
            if (fno == 1 && txt) R->body = txt;
            else if (fno == 2 && wt == 0 && R->nrefs < MAXR) R->refs[R->nrefs++] = v;
            else if (fno == 3 && txt) R->label = txt;
            break;
        }
    }
}

static const char *label_of(uint64_t id) {
    static Rec tmp;
    Cell *c = find_live(id);
    if (!c) return NULL;
    decode(c, &tmp);
    return tmp.label ? tmp.label : "(untitled)";
}

static void print_multi(const char *key, const char *val) {
    printf("%s: ", key);
    for (const char *p = val; *p; p++) {
        if (*p == '\n') printf("\n  | ");
        else putchar(*p);
    }
    putchar('\n');
}
static void print_ref(const char *key, uint64_t id) {
    const char *l = label_of(id);
    if (l) printf("%s: %s (#%llu)\n", key, l, (unsigned long long)id);
    else printf("%s: #%llu (unavailable)\n", key, (unsigned long long)id);
}
static const char *FREQ[] = {"daily", "weekly", "monthly", "yearly"};
static const char *PRIO[] = {"none", "low", "normal", "high"};

static void show_rec(const Rec *R) {
    char a[32], b[32], o[16];
    printf("#%llu %s (rev %llu)\n", (unsigned long long)R->id, kind_name(R->kind), (unsigned long long)R->rev);
    switch (R->kind) {
    case K_PERSON:
        if (R->label) printf("Name: %s\n", R->label);
        for (int i = 0; i < R->nemails; i++) printf("Email: %s\n", R->emails[i]);
        if (R->phone) printf("Phone: %s\n", R->phone);
        if (R->has_date) { fmt_date(R->date, a); printf("Birthday: %s\n", a); }
        if (R->has_ref) print_ref("Org", R->ref);
        break;
    case K_ORG:
        if (R->label) printf("Name: %s\n", R->label);
        if (R->website) printf("Website: %s\n", R->website);
        if (R->address) print_multi("Address", R->address);
        if (R->has_ref) print_ref("Parent", R->ref);
        break;
    case K_EVENT: case K_RECUR: {
        if (R->label) printf("Title: %s\n", R->label);
        fmt_off(R->tz, o);
        fmt_date(R->sday, a);
        printf("Start: %s %02d:%02d %s\n", a, R->smin / 60, R->smin % 60, o);
        int64_t endm = R->sday * 1440 + R->smin + (int64_t)R->dur;
        int64_t ed = endm >= 0 ? endm / 1440 : -((-endm + 1439) / 1440);
        int em = (int)(endm - ed * 1440);
        fmt_date(ed, b);
        printf("End: %s %02d:%02d %s\n", b, em / 60, em % 60, o);
        if (R->location) printf("Location: %s\n", R->location);
        for (int i = 0; i < R->nrefs; i++) print_ref("Attendee", R->refs[i]);
        if (R->kind == K_RECUR) {
            printf("Repeats: %s, every %llu", R->freq < 4 ? FREQ[R->freq] : "never", (unsigned long long)R->interval);
            if (R->has_count) printf(", %llu times", (unsigned long long)R->count);
            if (R->has_until) { fmt_date(R->until, a); printf(", until %s", a); }
            putchar('\n');
            for (int i = 0; i < R->nexc; i++) { fmt_date(R->exc[i], a); printf("Except: %s\n", a); }
        }
        break;
    }
    case K_TASK:
        if (R->label) printf("Title: %s\n", R->label);
        if (R->has_date) { fmt_date(R->date, a); printf("Due: %s\n", a); }
        printf("Priority: %s\n", PRIO[(R->state >> 1) & 3]);
        printf("Status: %s\n", (R->state & 1) ? "done" : "open");
        if (R->has_ref) print_ref("Person", R->ref);
        break;
    case K_NOTE:
        if (R->label) printf("Title: %s\n", R->label);
        if (R->body) print_multi("Body", R->body);
        for (int i = 0; i < R->nrefs; i++) print_ref("Link", R->refs[i]);
        break;
    }
    for (int i = 0; i < R->natt; i++) {
        const Att *t = &R->att[i];
        if (t->has_data) {
            char h[65];
            sha256_hex(t->data, t->dlen, h);
            printf("Attachment: %s (%s, %zu bytes, sha256 %s)\n", t->fname, t->mime, t->dlen, h);
        } else {
            printf("Attachment: %s (%s, data unavailable)\n", t->fname, t->mime);
        }
    }
}

/* ------------------------------------------------------------- commands */
static void list_line(const Rec *R) {
    printf("#%llu %s %s\n", (unsigned long long)R->id, kind_name(R->kind), R->label ? R->label : "(untitled)");
}
static int cmd_list(int deleted) {
    for (size_t i = 0; i < nwin; i++) {
        Cell *c = winners[i];
        if (!deleted && c->kind != K_TOMB) {
            Rec R; decode(c, &R); list_line(&R);
        } else if (deleted && c->kind == K_TOMB) {
            int k = 0;
            for (Cell *p = c; p > cells && (p - 1)->id == c->id; p--)
                if ((p - 1)->kind != K_TOMB) { k = (p - 1)->kind; break; }
            printf("#%llu %s deleted at rev %llu\n", (unsigned long long)c->id, kind_name(k), (unsigned long long)c->rev);
        }
    }
    return 0;
}
static int ci_contains(const char *hay, const char *needle) {
    size_t n = strlen(needle);
    for (const char *p = hay; *p; p++) {
        size_t i = 0;
        while (i < n && p[i] && tolower((unsigned char)p[i]) == tolower((unsigned char)needle[i])) i++;
        if (i == n) return 1;
    }
    return n == 0;
}
static int cmd_search(const char *q) {
    int hits = 0;
    for (size_t i = 0; i < nwin; i++) {
        if (winners[i]->kind == K_TOMB) continue;
        Rec R; decode(winners[i], &R);
        int m = (R.label && ci_contains(R.label, q)) || (R.body && ci_contains(R.body, q)) ||
                (R.location && ci_contains(R.location, q));
        for (int k = 0; k < R.nemails; k++) m |= ci_contains(R.emails[k], q);
        if (m) { list_line(&R); hits++; }
    }
    if (!hits) printf("no matches\n");
    return 0;
}
static int cmd_show(uint64_t id, int history, int attn) {
    Cell *w = find_winner(id);
    if (!w) { fprintf(stderr, "oldbook: no record #%llu\n", (unsigned long long)id); return 1; }
    if (history) {
        printf("#%llu history\n", (unsigned long long)id);
        for (size_t i = 0; i < ncells; i++) {
            if (cells[i].id != id) continue;
            printf("rev %llu%s%s\n", (unsigned long long)cells[i].rev, cells[i].kind == K_TOMB ? " tombstone" : "",
                   &cells[i] == w ? " current" : "");
        }
        return 0;
    }
    if (w->kind == K_TOMB) { printf("#%llu deleted (rev %llu)\n", (unsigned long long)id, (unsigned long long)w->rev); return 0; }
    Rec R; decode(w, &R);
    if (attn) {
        if (attn < 1 || attn > R.natt) { fprintf(stderr, "oldbook: no attachment %d\n", attn); return 1; }
        Att *t = &R.att[attn - 1];
        if (!t->has_data) { fprintf(stderr, "oldbook: attachment data unavailable\n"); return 1; }
        fwrite(t->data, 1, t->dlen, stdout);
        return 0;
    }
    show_rec(&R);
    return 0;
}

typedef struct { int64_t utc; int64_t day; int min, off; uint64_t id, dur; const char *title; } Occ;
static Occ *occs; static size_t nocc, capocc;
static void add_occ(const Rec *R, int64_t day) {
    if (nocc == capocc) { capocc = capocc ? capocc * 2 : 256; occs = realloc(occs, capocc * sizeof(Occ)); }
    Occ o;
    o.day = day; o.min = R->smin; o.off = R->tz; o.id = R->id; o.dur = R->dur;
    o.title = R->label ? R->label : "(untitled)";
    o.utc = day * 1440 + R->smin - R->tz;
    occs[nocc++] = o;
}
static int cmp_occ(const void *a, const void *b) {
    const Occ *x = a, *y = b;
    if (x->utc != y->utc) return x->utc < y->utc ? -1 : 1;
    if (x->id != y->id) return x->id < y->id ? -1 : 1;
    return 0;
}
static int cmd_agenda(int64_t from, int64_t to) {
    for (size_t i = 0; i < nwin; i++) {
        Cell *c = winners[i];
        if (c->kind != K_EVENT && c->kind != K_RECUR) continue;
        Rec *R = xmalloc(sizeof(Rec));
        decode(c, R);
        if (!R->has_start) continue;
        if (c->kind == K_EVENT) {
            if (R->sday >= from && R->sday <= to) add_occ(R, R->sday);
            continue;
        }
        int64_t y0; int m0, d0;
        civil_from_days(R->sday, &y0, &m0, &d0);
        uint64_t n = 0;
        for (uint64_t k = 0; k < 200000; k++) {
            int64_t day;
            uint64_t step = k * R->interval;
            if (R->freq == 0) day = R->sday + (int64_t)step;
            else if (R->freq == 1) day = R->sday + 7 * (int64_t)step;
            else if (R->freq == 2) {
                int64_t mi = (int64_t)(m0 - 1) + (int64_t)step;
                int64_t yy = y0 + mi / 12; int mm = (int)(mi % 12) + 1;
                if (d0 > month_len(yy, mm)) continue;
                day = days_from_civil(yy, mm, d0);
            } else if (R->freq == 3) {
                int64_t yy = y0 + (int64_t)step;
                if (d0 > month_len(yy, m0)) continue;
                day = days_from_civil(yy, m0, d0);
            } else break;
            if (R->has_until && day > R->until) break;
            if (day > to) break;
            n++;
            if (R->has_count && n > R->count) break;
            int ex = 0;
            for (int e = 0; e < R->nexc; e++) if (R->exc[e] == day) ex = 1;
            if (ex) continue;
            if (day >= from) add_occ(R, day);
        }
    }
    qsort(occs, nocc, sizeof(Occ), cmp_occ);
    for (size_t i = 0; i < nocc; i++) {
        char a[32], o[16];
        fmt_date(occs[i].day, a);
        fmt_off(occs[i].off, o);
        printf("%s %02d:%02d %s  #%llu %s (%llu min)\n", a, occs[i].min / 60, occs[i].min % 60, o,
               (unsigned long long)occs[i].id, occs[i].title, (unsigned long long)occs[i].dur);
    }
    if (!nocc) printf("nothing scheduled\n");
    return 0;
}

static void csv_field(const char *s, int maxlen) {
    char out[64]; int n = 0;
    const unsigned char *p = (const unsigned char *)(s ? s : "");
    while (*p && n < maxlen) {
        if (*p >= 0x80) {
            out[n++] = '?';
            p++;
            while ((*p & 0xC0) == 0x80) p++;
        } else {
            out[n++] = *p == '\n' ? ' ' : (char)*p;
            p++;
        }
    }
    out[n] = 0;
    if (strpbrk(out, ",\"")) {
        putchar('"');
        for (char *q = out; *q; q++) { if (*q == '"') putchar('"'); putchar(*q); }
        putchar('"');
    } else fputs(out, stdout);
}
static int cmd_export(void) {
    printf("id,kind,label,email,phone,date,location,status\n");
    for (size_t i = 0; i < nwin; i++) {
        if (winners[i]->kind == K_TOMB) continue;
        Rec R; decode(winners[i], &R);
        char a[32] = "";
        if (R.has_date) fmt_date(R.date, a);
        if (R.has_start) fmt_date(R.sday, a);
        printf("%llu,%s,", (unsigned long long)R.id, kind_name(R.kind));
        csv_field(R.label, 20); putchar(',');
        csv_field(R.nemails ? R.emails[0] : "", 40); putchar(',');
        csv_field(R.phone, 40); putchar(',');
        printf("%s,", a);
        csv_field(R.location, 20); putchar(',');
        if (R.kind == K_TASK) fputs((R.state & 1) ? "done" : "open", stdout);
        putchar('\n');
    }
    return 0;
}

static void usage(void) {
    fprintf(stderr,
            "usage: oldbook [-d DIR] COMMAND\n"
            "  list [--deleted]\n"
            "  show ID [--history | --attachment N]\n"
            "  search TEXT\n"
            "  agenda FROM TO        (dates as YYYY-MM-DD, inclusive)\n"
            "  export-csv\n"
            "  version\n");
}

int main(int argc, char **argv) {
    const char *dir = getenv("OLDBOOK_DATA");
    if (!dir) dir = "/data/legacy";
    int ai = 1;
    if (ai + 1 < argc && strcmp(argv[ai], "-d") == 0) { dir = argv[ai + 1]; ai += 2; }
    if (ai >= argc) { usage(); return 2; }
    const char *cmd = argv[ai++];
    if (strcmp(cmd, "version") == 0) { printf("oldbook 3.4.1\n"); return 0; }
    crc_init();
    load(dir);
    resolve();
    if (strcmp(cmd, "list") == 0) {
        int del = ai < argc && strcmp(argv[ai], "--deleted") == 0;
        return cmd_list(del);
    }
    if (strcmp(cmd, "show") == 0 && ai < argc) {
        char *end;
        uint64_t id = strtoull(argv[ai][0] == '#' ? argv[ai] + 1 : argv[ai], &end, 10);
        ai++;
        if (ai < argc && strcmp(argv[ai], "--history") == 0) return cmd_show(id, 1, 0);
        if (ai + 1 < argc && strcmp(argv[ai], "--attachment") == 0) return cmd_show(id, 0, atoi(argv[ai + 1]));
        return cmd_show(id, 0, 0);
    }
    if (strcmp(cmd, "search") == 0 && ai < argc) return cmd_search(argv[ai]);
    if (strcmp(cmd, "agenda") == 0 && ai + 1 < argc) {
        int64_t a, b;
        if (!parse_date(argv[ai], &a) || !parse_date(argv[ai + 1], &b)) {
            fprintf(stderr, "oldbook: dates must be YYYY-MM-DD\n");
            return 2;
        }
        return cmd_agenda(a, b);
    }
    if (strcmp(cmd, "export-csv") == 0) return cmd_export();
    usage();
    return 2;
}
