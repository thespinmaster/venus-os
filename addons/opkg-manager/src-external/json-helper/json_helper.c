#define _DEFAULT_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>
#include <ctype.h>

#define MAX_LINE 2048
#define MAX_FIELD 256
#define MAX_FIELDS 50
#define CACHE_DIR "/tmp/opkg-manager"
#define OPKG_CONFIG "/etc/opkg/opkg-manager.conf"
#define OPKG_STATUS "/usr/lib/opkg/status"
#define OPKG_LISTS_DIR "/usr/lib/opkg/lists"

typedef struct {
    char key[MAX_FIELD];
    char value[MAX_LINE];
} Field;

typedef struct {
    Field fields[MAX_FIELDS];
    int field_count;
} Package;

/* Simple JSON escaping for string values */
static void json_escape_print(FILE *fp, const char *str) {
    if (!str) return;
    fputc('"', fp);
    while (*str) {
        switch (*str) {
            case '"':
                fputs("\\\"", fp);
                break;
            case '\\':
                fputs("\\\\", fp);
                break;
            case '\n':
                fputs("\\n", fp);
                break;
            case '\r':
                fputs("\\r", fp);
                break;
            case '\t':
                fputs("\\t", fp);
                break;
            default:
                if ((unsigned char)*str < 32) {
                    fprintf(fp, "\\u%04x", (unsigned char)*str);
                } else {
                    fputc(*str, fp);
                }
        }
        str++;
    }
    fputc('"', fp);
}

/* Trim leading/trailing whitespace */
static void trim(char *str) {
    if (!str) return;
    char *start = str;
    while (*start && isspace((unsigned char)*start)) start++;
    char *end = start + strlen(start) - 1;
    while (end >= start && isspace((unsigned char)*end)) end--;
    *(end + 1) = '\0';
    memmove(str, start, strlen(start) + 1);
}

/* Normalize field names (lowercase, replace - with _) */
static void normalize_field_name(const char *input, char *output, size_t outlen) {
    size_t i = 0;
    for (; input[i] && i < outlen - 1; i++) {
        char c = input[i];
        if (c == '-') {
            output[i] = '_';
        } else if (c == ' ') {
            output[i] = '_';
        } else {
            output[i] = tolower((unsigned char)c);
        }
    }
    output[i] = '\0';
}

/* Check if file has been modified since cache time */
static int file_newer_than(const char *filepath, time_t ctime) {
    struct stat st;
    if (stat(filepath, &st) != 0) return 0;
    return st.st_mtime > ctime;
}

typedef struct {
    char name[MAX_FIELD];
    char version[MAX_FIELD];
} InstalledEntry;

typedef struct {
    InstalledEntry *items;
    size_t count;
    size_t capacity;
} InstalledMap;

static int append_installed_entry(InstalledMap *map, const char *name, const char *version)
{
    if (!map || !name) {
        return 0;
    }

    if (map->count == map->capacity) {
        size_t new_capacity = map->capacity == 0 ? 64 : map->capacity * 2;
        InstalledEntry *new_items = (InstalledEntry *)realloc(map->items, new_capacity * sizeof(*new_items));
        if (!new_items) {
            return 0;
        }
        map->items = new_items;
        map->capacity = new_capacity;
    }

    snprintf(map->items[map->count].name, sizeof(map->items[map->count].name), "%s", name);
    snprintf(map->items[map->count].version, sizeof(map->items[map->count].version), "%s", version ? version : "");
    map->count++;
    return 1;
}

static const char *lookup_installed_version(const InstalledMap *map, const char *name)
{
    if (!map || !name) {
        return "";
    }
    for (size_t i = 0; i < map->count; ++i) {
        if (strcmp(map->items[i].name, name) == 0) {
            return map->items[i].version;
        }
    }
    return "";
}

static void free_installed_map(InstalledMap *map)
{
    if (!map) {
        return;
    }
    free(map->items);
    map->items = NULL;
    map->count = 0;
    map->capacity = 0;
}

static int parse_installed_status(InstalledMap *map)
{
    FILE *fp = fopen(OPKG_STATUS, "r");
    if (!fp) {
        return 0;
    }

    char line[MAX_LINE];
    char package[MAX_FIELD] = "";
    char version[MAX_FIELD] = "";
    char status[MAX_LINE] = "";

    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = '\0';

        if (line[0] == '\0') {
            if (package[0] != '\0' && strstr(status, "installed") != NULL) {
                if (!append_installed_entry(map, package, version)) {
                    fclose(fp);
                    return 0;
                }
            }
            package[0] = '\0';
            version[0] = '\0';
            status[0] = '\0';
            continue;
        }

        char *colon = strchr(line, ':');
        if (!colon) {
            continue;
        }

        *colon = '\0';
        char *key = line;
        char *value = colon + 1;
        trim(key);
        trim(value);

        if (strcmp(key, "Package") == 0) {
            snprintf(package, sizeof(package), "%s", value);
        } else if (strcmp(key, "Version") == 0) {
            snprintf(version, sizeof(version), "%s", value);
        } else if (strcmp(key, "Status") == 0) {
            snprintf(status, sizeof(status), "%s", value);
        }
    }

    if (package[0] != '\0' && strstr(status, "installed") != NULL) {
        if (!append_installed_entry(map, package, version)) {
            fclose(fp);
            return 0;
        }
    }

    fclose(fp);
    return 1;
}

static int load_feed_names(char feed_names[][MAX_FIELD], int max_feeds)
{
    FILE *fp = fopen(OPKG_CONFIG, "r");
    if (!fp) {
        return 0;
    }

    int feed_count = 0;
    char line[MAX_LINE];

    while (fgets(line, sizeof(line), fp) && feed_count < max_feeds) {
        line[strcspn(line, "\n")] = '\0';
        trim(line);
        if (!line[0] || line[0] == '#') {
            continue;
        }

        char *type = strtok(line, " \t");
        if (!type) {
            continue;
        }

        char *name = strtok(NULL, " \t");
        if (!name) {
            continue;
        }

        char *url = strtok(NULL, " \t");
        if (!url) {
            continue;
        }

        snprintf(feed_names[feed_count], MAX_FIELD, "%s", name);
        feed_count++;
    }

    fclose(fp);
    return feed_count;
}

/* Parse an opkg stanza file and extract fields */
static void flush_package_json(const Package *pkg,
                               const char *feed_name,
                               FILE *out_json,
                               int *first_item,
                               const InstalledMap *installed_map)
{
    if (!pkg || pkg->field_count <= 0) {
        return;
    }

    const char *package_name = NULL;
    int first_field = 1;

    if (!*first_item) {
        fputs(",", out_json);
    }
    fputs("{", out_json);

    for (int i = 0; i < pkg->field_count; i++) {
        if (strcmp(pkg->fields[i].key, "package") == 0) {
            package_name = pkg->fields[i].value;
        }

        if (!first_field) {
            fputs(",", out_json);
        }
        first_field = 0;
        fprintf(out_json, "\"%s\":", pkg->fields[i].key);
        json_escape_print(out_json, pkg->fields[i].value);
    }

    if (feed_name) {
        if (!first_field) {
            fputs(",", out_json);
        }
        fputs("\"feed\":", out_json);
        json_escape_print(out_json, feed_name);
        first_field = 0;
    }

    /* Match Python behavior: always include installed_version for package list entries. */
    if (installed_map) {
        const char *installed_version = lookup_installed_version(installed_map, package_name);
        if (!first_field) {
            fputs(",", out_json);
        }
        fputs("\"installed_version\":", out_json);
        json_escape_print(out_json, installed_version);
    }

    fputs("}", out_json);
    *first_item = 0;
}

static int parse_stanza_file(const char *filepath,
                             const char *feed_name,
                             FILE *out_json,
                             int *first_item,
                             const InstalledMap *installed_map,
                             const char *const *allowed_fields,
                             int allowed_count) {
    FILE *fp = fopen(filepath, "r");
    if (!fp) return 0;
    
    char line[MAX_LINE];
    Package pkg;
    int last_kept_index = -1;
    memset(&pkg, 0, sizeof(pkg));
    
    while (fgets(line, sizeof(line), fp)) {
        /* Remove trailing newline */
        line[strcspn(line, "\n")] = '\0';
        
        /* Blank line separates stanzas */
        if (strlen(line) == 0) {
            flush_package_json(&pkg,
                               feed_name,
                               out_json,
                               first_item,
                               installed_map);
            memset(&pkg, 0, sizeof(pkg));
            last_kept_index = -1;
            continue;
        }
        
        /* Handle continuation lines (start with space) */
        if (line[0] == ' ' && last_kept_index >= 0) {
            char *value = line;
            while (*value && isspace((unsigned char)*value)) value++;
            if (strstr(pkg.fields[last_kept_index].value, value) != NULL) {
                continue;
            }
            size_t cur_len = strlen(pkg.fields[last_kept_index].value);
            size_t value_len = strlen(value);
            if (cur_len < (MAX_LINE - 1) && value_len > 0) {
                char *dest = pkg.fields[last_kept_index].value;
                size_t pos = cur_len;

                if (pos > 0 && pos < (MAX_LINE - 1)) {
                    dest[pos++] = ' ';
                }

                if (pos < (MAX_LINE - 1)) {
                    size_t copy_len = value_len;
                    size_t avail = (MAX_LINE - 1) - pos;
                    if (copy_len > avail) {
                        copy_len = avail;
                    }
                    memcpy(dest + pos, value, copy_len);
                    pos += copy_len;
                    dest[pos] = '\0';
                }
            }
            continue;
        }
        
        /* Parse key: value line */
        char *colon = strchr(line, ':');
        if (!colon) continue;
        
        *colon = '\0';
        const char *key = line;
        char *value = colon + 1;
        char normalized_key[MAX_FIELD];
        
        trim((char *)key);
        trim(value);

        normalize_field_name(key, normalized_key, sizeof(normalized_key));

        int allowed = 0;
        for (int j = 0; j < allowed_count; j++) {
            if (strcmp(normalized_key, allowed_fields[j]) == 0) {
                allowed = 1;
                break;
            }
        }

        if (!allowed) {
            last_kept_index = -1;
            continue;
        }
        
        if (pkg.field_count < MAX_FIELDS) {
            snprintf(pkg.fields[pkg.field_count].key,
                     sizeof(pkg.fields[pkg.field_count].key),
                     "%s",
                     normalized_key);
            snprintf(pkg.fields[pkg.field_count].value,
                     sizeof(pkg.fields[pkg.field_count].value),
                     "%s",
                     value);
            last_kept_index = pkg.field_count;
            pkg.field_count++;
        }
    }

    /* Flush final stanza when file does not end with a blank line. */
    flush_package_json(&pkg,
                       feed_name,
                       out_json,
                       first_item,
                       installed_map);
    
    fclose(fp);
    return 1;
}

/* Write feeds list as JSON */
static int write_feeds_json(const char *output_file) {
    FILE *fp = fopen(OPKG_CONFIG, "r");
    if (!fp) {
        fprintf(stderr, "Error: cannot read %s\n", OPKG_CONFIG);
        return 0;
    }
    
    FILE *out = fopen(output_file, "w");
    if (!out) {
        fprintf(stderr, "Error: cannot write %s\n", output_file);
        fclose(fp);
        return 0;
    }
    
    fprintf(out, "[");
    int first = 1;
    char line[MAX_LINE];
    
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = '\0';
        trim(line);
        
        /* Skip comments and empty lines */
        if (!line[0] || line[0] == '#') continue;
        
        /* Parse: src/gz <name> <url> */
        char *type = strtok(line, " \t");
        if (!type) continue;
        
        char *name = strtok(NULL, " \t");
        if (!name) continue;
        
        char *url = strtok(NULL, " \t");
        if (!url) continue;
        
        if (first) first = 0;
        else fprintf(out, ",");

        fprintf(out, "{");
        fprintf(out, "\"name\":");
        json_escape_print(out, name);
        fprintf(out, ",\"url\":");
        json_escape_print(out, url);
        fprintf(out, ",\"builtin\":false}");
    }

    fprintf(out, "]\n");
    fclose(fp);
    fclose(out);
    return 1;
}

/* Write packages list as JSON */
static int write_packages_json(const char *output_file) {
    /* Match json-helper.py fields_list = ["Package", "Description", "Version", "Size"] */
    const char *allowed_fields[] = {
        "package", "description", "version", "size"
    };
    int allowed_count = sizeof(allowed_fields) / sizeof(allowed_fields[0]);

    InstalledMap installed = {0};
    if (!parse_installed_status(&installed)) {
        /* Continue with empty installed lookup if status parse fails. */
        installed.items = NULL;
        installed.count = 0;
        installed.capacity = 0;
    }
    
    FILE *out = fopen(output_file, "w");
    if (!out) {
        fprintf(stderr, "Error: cannot write %s\n", output_file);
        free_installed_map(&installed);
        return 0;
    }
    
    fprintf(out, "[");
    int first_item = 1;

    char feed_names[256][MAX_FIELD];
    int feed_count = load_feed_names(feed_names, 256);
    for (int i = 0; i < feed_count; ++i) {
        char filepath[2048];
        size_t base_len = strlen(OPKG_LISTS_DIR);
        size_t name_len = strnlen(feed_names[i], MAX_FIELD);

        if (base_len + 1 + name_len >= sizeof(filepath)) {
            continue;
        }

        memcpy(filepath, OPKG_LISTS_DIR, base_len);
        filepath[base_len] = '/';
        memcpy(filepath + base_len + 1, feed_names[i], name_len);
        filepath[base_len + 1 + name_len] = '\0';

        struct stat file_st;
        if (stat(filepath, &file_st) != 0 || !S_ISREG(file_st.st_mode)) {
            continue;
        }

        parse_stanza_file(filepath,
                         feed_names[i],
                         out,
                         &first_item,
                         &installed,
                         allowed_fields,
                         allowed_count);
    }
    
    fprintf(out, "]\n");
    fclose(out);
    free_installed_map(&installed);
    return 1;
}

/* Check if cache is still valid based on source file mtimes */
static int cache_is_valid(const char *cache_file, const char *src_file1, const char *src_file2) {
    struct stat cache_st;
    if (stat(cache_file, &cache_st) != 0) return 0;
    
    time_t cache_time = cache_st.st_mtime;
    
    if (file_newer_than(src_file1, cache_time)) return 0;
    if (src_file2 && file_newer_than(src_file2, cache_time)) return 0;
    
    return 1;
}

static time_t latest_package_source_mtime(void)
{
    time_t latest_src = 0;
    struct stat st;

    if (stat(OPKG_CONFIG, &st) == 0 && st.st_mtime > latest_src) {
        latest_src = st.st_mtime;
    }
    if (stat(OPKG_STATUS, &st) == 0 && st.st_mtime > latest_src) {
        latest_src = st.st_mtime;
    }

    char feed_names[256][MAX_FIELD];
    int feed_count = load_feed_names(feed_names, 256);
    for (int i = 0; i < feed_count; ++i) {
        char filepath[2048];
        size_t base_len = strlen(OPKG_LISTS_DIR);
        size_t name_len = strnlen(feed_names[i], MAX_FIELD);

        if (base_len + 1 + name_len >= sizeof(filepath)) {
            continue;
        }

        memcpy(filepath, OPKG_LISTS_DIR, base_len);
        filepath[base_len] = '/';
        memcpy(filepath + base_len + 1, feed_names[i], name_len);
        filepath[base_len + 1 + name_len] = '\0';

        if (stat(filepath, &st) == 0 && st.st_mtime > latest_src) {
            latest_src = st.st_mtime;
        }
    }

    return latest_src;
}

static int handle_feed_list(const char *feeds_cache)
{
    if (cache_is_valid(feeds_cache, OPKG_CONFIG, NULL)) {
        return 0;
    }

    if (!write_feeds_json(feeds_cache)) {
        fprintf(stderr, "Error: failed to write feeds cache\n");
        return 1;
    }

    return 0;
}

static int handle_package_list(const char *packages_cache)
{
    time_t latest_src = latest_package_source_mtime();
    struct stat cache_st;
    int needs_update = (stat(packages_cache, &cache_st) != 0) || (cache_st.st_mtime < latest_src);

    if (!needs_update) {
        return 0;
    }

    if (!write_packages_json(packages_cache)) {
        fprintf(stderr, "Error: failed to write packages cache\n");
        return 1;
    }

    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: json_helper [feed|package] [list] [update]\n");
        return 1;
    }
    
    /* Ensure cache directory exists */
    mkdir(CACHE_DIR, 0755);
    
    const char *feeds_cache = CACHE_DIR "/feeds.json";
    const char *packages_cache = CACHE_DIR "/packages.json";
    
    const char *family = argv[1];
    const char *action = argv[2];

    for (int i = 3; i < argc; ++i) {
        if (strcmp(argv[i], "update") == 0) {
            int rc = system("opkg update");
            if (rc != 0) {
                fprintf(stderr, "Error: opkg update failed (status=%d)\n", rc);
                return 1;
            }
            break;
        }
    }

    if (strcmp(action, "list") != 0) {
        fprintf(stderr, "Error: unsupported action: %s\n", action);
        return 1;
    }

    if (strcmp(family, "feed") == 0) {
        return handle_feed_list(feeds_cache);
    }

    if (strcmp(family, "package") == 0) {
        return handle_package_list(packages_cache);
    }
    
    fprintf(stderr, "Error: unknown command: %s\n", family);
    return 1;
}
