package com.bazaarvoice.infrastructure;

import com.bazaarvoice.infrastructure.cftemplate.CompileIssue;
import com.bazaarvoice.infrastructure.cftemplate.CompileIssueLevel;
import com.bazaarvoice.infrastructure.cftemplate.CompileResult;
import com.bazaarvoice.infrastructure.cftemplate.JsonTemplateCompiler;
import com.bazaarvoice.infrastructure.cftemplate.RubyTemplateCompiler;
import com.bazaarvoice.infrastructure.cftemplate.TemplateCompiler;
import org.apache.commons.io.FilenameUtils;
import org.apache.maven.model.Resource;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.project.MavenProject;
import org.jruby.embed.PathType;
import org.jruby.embed.ScriptingContainer;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Set;

import static com.google.common.collect.Lists.newArrayListWithCapacity;
import static com.google.common.collect.Sets.newHashSet;

/**
 * Goal which compiles CloudFormation templates.
 * <p/>
 * Compiles JSON and Ruby DSL templates to CloudFormation JSON. Performs validations
 * on the resulting template to ensure correctness.
 *
 * @goal cftemplates
 * @phase process-resources
 */
public class TemplateCompilerMojo
        extends AbstractMojo {
    /**
     * @parameter default-value="${project}"
     * @required
     * @readonly
     */
    private MavenProject project;

    /**
     * Directory to load templates from.
     *
     * @parameter expression="${basedir}/src/main/cftemplates"
     * @required
     */
    private File inputDirectory;

    /**
     * Directory to store the compiled templates in.
     *
     * @parameter expression="${project.build.directory}/processed-resources/cftemplates"
     * @required
     */
    private File outputDirectory;

    /**
     * Set of patterns for files to include in compilation. Default is *.rb and *.json.
     *
     * @parameter
     */
    private Set<String> includes = newHashSet("*.rb", "*.json");

    /**
     * Set of patterns for files to exclude from compilation. Default is no excludes.
     *
     * @parameter
     */
    private Set<String> excludes = newHashSet();

    private RubyTemplateCompiler _rubyTemplateCompiler = new RubyTemplateCompiler();
    private JsonTemplateCompiler _jsonTemplateCompiler = new JsonTemplateCompiler();

    public void execute()
            throws MojoExecutionException {
        if (!inputDirectory.isDirectory()) {
            getLog().info(String.format("No templates found in %s", inputDirectory));
            return;
        }

        File outDir = getOutputDirectory();
        File[] sourceFiles = inputDirectory.listFiles(new GlobFilenameFilter(includes, excludes));
        List<Compilation> compiles = newArrayListWithCapacity(sourceFiles.length);

        for (File file : sourceFiles) {
            String extension = FilenameUtils.getExtension(file.getName());
            File outputFile = new File(outDir, changeExtension(file.getName(), ".json"));
            TemplateCompiler compiler = null;

            if (extension.equals("rb")) {
                compiler = _rubyTemplateCompiler;
            } else if (extension.equals("json")) {
                compiler = _jsonTemplateCompiler;
            } else {
                getLog().warn(String.format("Unknown CloudFormation template type: %s", file));
            }

            if (compiler != null) {
                if (isNewer(file, outputFile)) {
                    compiles.add(new Compilation(file, outputFile, compiler));
                } else {
                    getLog().debug(String.format("Skipping compile; output is newer than source. %s => %s", file, outputFile));
                }
            }
        }

        if (compiles.size() == 0) {
            getLog().info(String.format("No templates to compile in %s", inputDirectory));
        } else {
            getLog().info(String.format("Compiling %d CloudFormation templates to %s", compiles.size(), outDir));
            int failures = 0;

            for (Compilation c : compiles) {
                getLog().info(String.format("Compiling %s to %s", c.sourceFile, c.targetFile));

                try {
                    CompileResult result = c.compile();
                    failures += outputResults(result);
                } catch (IOException ex) {
                    throw new MojoExecutionException(String.format("Error compiling %s", c.sourceFile), ex);
                }
            }

            if (failures > 0) {
                throw new MojoExecutionException(String.format("%d errors compiling CloudFormation templates", failures));
            }
        }
    }

    private int outputResults(CompileResult result) {
        int failureCount = 0;

        for (CompileIssue issue : result.getIssues()) {
            CompileIssueLevel level = issue.getLevel();
            String message;

            if (issue.getLocation() != null) {
                message = String.format("%s\n%s", issue.getLocation(), issue.getMessage());
            } else {
                message = issue.getMessage();
            }

            if (level.compareTo(CompileIssueLevel.ERROR) >= 0) {
                failureCount += 1;
                getLog().error(message);
            } else if (level.compareTo(CompileIssueLevel.WARN) >= 0) {
                getLog().warn(message);
            } else if (level.compareTo(CompileIssueLevel.INFO) >= 0) {
                getLog().info(message);
            } else {
                getLog().debug(message);
            }
        }

        return failureCount;
    }

    private static String changeExtension(String name, String extension) {
        int dotIndex = name.lastIndexOf('.');

        if (dotIndex < 0) {
            return name + extension;
        } else if (dotIndex == 0) {
            return extension;
        } else {
            return name.substring(0, dotIndex) + extension;
        }
    }

    private File getOutputDirectory() {
        if (!outputDirectory.exists()) {
            outputDirectory.mkdirs();
        }

        boolean found = false;

        for (Resource r : (Iterable<Resource>) project.getResources()) {
            if (r.getDirectory().equals(outputDirectory)) {
                found = true;
            }
        }

        if (!found) {
            Resource resource = new Resource();
            resource.setDirectory(outputDirectory.getPath());
            project.addResource(resource);
        }

        return outputDirectory;
    }

    private static boolean isNewer(File source, File target) {
        return !target.exists() || source.lastModified() > target.lastModified();
    }

    private static class Compilation {
        public final File sourceFile;
        public final File targetFile;
        public final TemplateCompiler compiler;

        public Compilation(File sourceFile, File targetFile, TemplateCompiler compiler) {
            this.sourceFile = sourceFile;
            this.targetFile = targetFile;
            this.compiler = compiler;
        }

        public CompileResult compile()
                throws IOException {
            return compiler.compile(sourceFile, targetFile);
        }
    }
}
