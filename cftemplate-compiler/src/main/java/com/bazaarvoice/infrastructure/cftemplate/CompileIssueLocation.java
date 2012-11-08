package com.bazaarvoice.infrastructure.cftemplate;

import java.io.File;

import static com.google.common.base.Preconditions.checkArgument;
import static com.google.common.base.Preconditions.checkNotNull;

/**
 * Location of a {@link CompileIssue}.
 */
public class CompileIssueLocation {
    private final File _file;
    private final int _line;

    /**
     * Initialize a new instance.
     *
     * @param file file where the issue is located
     */
    public CompileIssueLocation(File file) {
        this(file, -1);
    }

    /**
     * Initialize a new instance.
     *
     * @param file file where the issue is located
     * @param line line number, starting from 0, or -1 if not applicable
     */
    public CompileIssueLocation(File file, int line) {
        _file = checkNotNull(file);

        checkArgument(line >= -1, "line must be >= 0 or -1");
        _line = line;
    }

    @Override
    public String toString() {
        String result = getFile().toString();
        return _line < 0 ? result : result + ":" + _line;
    }

    /**
     * File where the issue is located.
     *
     * @return file where issue is located
     */
    public File getFile() {
        return _file;
    }

    /**
     * Line number where issue is located.
     *
     * @return starting from 0 or -1 if not applicable
     */
    public int getLine() {
        return _line;
    }
}
