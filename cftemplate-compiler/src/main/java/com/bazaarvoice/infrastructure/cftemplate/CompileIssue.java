package com.bazaarvoice.infrastructure.cftemplate;

import static com.google.common.base.Preconditions.checkNotNull;

/**
 * Issue resulting from compiling a template.
 */
public class CompileIssue {
    private final CompileIssueLevel _level;
    private final String _message;
    private final CompileIssueLocation _location;

    /**
     * Initialize a new instance.
     *
     * @param level issue level
     * @param message message describing the issue
     * @param location location of the issue or null if not applicable
     */
    public CompileIssue(CompileIssueLevel level, String message, CompileIssueLocation location) {
        _level = checkNotNull(level);
        _message = checkNotNull(message);
        _location = location;
    }

    /**
     * Initialize a new instance.
     *
     * @param level issue level
     * @param message message describing the issue
     */
    public CompileIssue(CompileIssueLevel level, String message) {
        this(level, message, null);
    }

    /**
     * Get the issue level.
     *
     * @return issue level
     */
    public CompileIssueLevel getLevel() {
        return _level;
    }

    /**
     * Location of the issue.
     *
     * @return location or null if not applicable
     */
    public CompileIssueLocation getLocation() {
        return _location;
    }

    /**
     * Get the issue message.
     *
     * @return issue message
     */
    public String getMessage() {
        return _message;
    }

    public static CompileIssue error(String format, Object... args) {
        return new CompileIssue(CompileIssueLevel.ERROR, String.format(format, args));
    }

    public static CompileIssue warn(String format, Object... args) {
        return new CompileIssue(CompileIssueLevel.ERROR, String.format(format, args));
    }
}
