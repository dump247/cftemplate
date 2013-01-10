package com.bazaarvoice.infrastructure.cftemplate;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ListMultimap;

import java.io.File;
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

    private final List<String> _files;

    /**
     * Initialize a new instance.
     *
     * @param files files that were part of the compilation unit
     * @param issues compilation issues or empty if compile completed with no issues
     */
    public CompileResult(Iterable<String> files, Iterable<CompileIssue> issues) {
        _files = ImmutableList.copyOf(files);
        _issues = ImmutableList.copyOf(issues);

        for (CompileIssue issue : _issues) {
            checkArgument(issue != null, "issues can not contain null");
            _issuesByLevel.put(issue.getLevel(), issue);
        }
    }

    /**
     * Initialize a new instance.
     *
     * @param file file that was compiled
     * @param issues compilation issues or empty if compile completed with no issues
     */
    public CompileResult(String file, Iterable<CompileIssue> issues) {
        this(ImmutableList.of(file), issues);
    }

    /**
     * Initialize a new instance.
     *
     * @param file file that was compiled
     * @param issues compilation issues or empty if compile completed with no issues
     */
    public CompileResult(File file, Iterable<CompileIssue> issues) {
        this(ImmutableList.of(file.toString()), issues);
    }

    /**
     * Files that made up the compilation unit.
     *
     * @return files that were compiled
     */
    public List<String> getFiles() {
        return _files;
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
