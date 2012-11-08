package com.bazaarvoice.infrastructure.cftemplate;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ListMultimap;

import java.util.List;

import static com.google.common.base.Preconditions.checkArgument;
import static java.util.Collections.unmodifiableList;

/**
 * Results from compiling a CloudFormation template.
 *
 * @see TemplateCompiler
 */
public class CompileResult {
    private final List<CompileIssue> _issues;
    private final ListMultimap<CompileIssueLevel, CompileIssue> _issuesByLevel = ArrayListMultimap.create();

    /**
     * Initialize a new instance.
     *
     * @param issues compilation issues or empty if compile completed with no issues
     */
    public CompileResult(Iterable<CompileIssue> issues) {
        _issues = ImmutableList.copyOf(issues);

        for (CompileIssue issue : _issues) {
            checkArgument(issue != null, "issues can not contain null");
            _issuesByLevel.put(issue.getLevel(), issue);
        }
    }

    /**
     * Compilation issues or empty if compile completed with no issues.
     *
     * @return compilation issues
     */
    public List<CompileIssue> getIssues() {
        return _issues;
    }

    /**
     * Get the issues at the given level.
     *
     * @param level level to get the issues for
     * @return issues at the given level or empty if no issues occurred for that level
     */
    public List<CompileIssue> getIssues(CompileIssueLevel level) {
        return unmodifiableList(_issuesByLevel.get(level));
    }
}
