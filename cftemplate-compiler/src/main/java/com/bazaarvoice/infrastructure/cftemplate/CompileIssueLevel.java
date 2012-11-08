package com.bazaarvoice.infrastructure.cftemplate;

/**
 * Levels for compiler issues.
 * @see CompileIssue
 */
public enum CompileIssueLevel {
    ERROR(300000),
    WARN(200000),
    INFO(100000);

    private final int _value;

    CompileIssueLevel(int value) {
        _value = value;
    }

    /**
     * Level value to use for comparing priority (higher value means higher priority).
     *
     * @return value
     */
    public int getValue() {
        return _value;
    }
}
