package com.bazaarvoice.infrastructure;

import com.google.common.collect.Iterables;

import java.io.File;
import java.io.FilenameFilter;
import java.util.List;
import java.util.regex.Pattern;

import static com.google.common.collect.Lists.newArrayList;

/**
 * File name matcher that accepts a glob.
 */
public class GlobFilenameFilter implements FilenameFilter {
    private final Pattern[] _includes;
    private final Pattern[] _excludes;

    public GlobFilenameFilter(Iterable<String> includes, Iterable<String> excludes) {
        _includes = createRegexesFromGlobs(includes);
        _excludes = createRegexesFromGlobs(excludes);
    }

    @Override
    public boolean accept(File dir, String name) {
        return matchesAny(_includes, name) && !matchesAny(_excludes, name);
    }

    private static boolean matchesAny(Pattern[] patterns, String value) {
        for (Pattern pattern : patterns) {
            if (pattern.matcher(value).matches()) {
                return true;
            }
        }

         return false;
    }

    private static Pattern[] createRegexesFromGlobs(Iterable<String> globs) {
        List<Pattern> regexes = newArrayList();

        for (String glob : globs) {
            regexes.add(createRegexFromGlob(glob));
        }

        return Iterables.toArray(regexes, Pattern.class);
    }

    /**
     * Borrowed from http://stackoverflow.com/questions/1247772/is-there-an-equivalent-of-java-util-regex-for-glob-type-patterns
     */
    private static Pattern createRegexFromGlob(String glob) {
        StringBuilder buffer = new StringBuilder(glob.length() + 10);
        buffer.append('^');

        for (int i = 0; i < glob.length(); ++i) {
            final char c = glob.charAt(i);

            switch (c) {
                case '*':
                    buffer.append(".*");
                    break;
                case '?':
                    buffer.append('.');
                    break;
                case '.':
                    buffer.append("\\.");
                    break;
                case '\\':
                    buffer.append("\\\\");
                    break;
                default:
                    buffer.append(c);
                    break;
            }
        }

        buffer.append('$');
        return Pattern.compile(buffer.toString(), Pattern.CASE_INSENSITIVE);
    }
}
