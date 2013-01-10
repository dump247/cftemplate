package com.bazaarvoice.infrastructure;

import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;

import java.io.File;
import java.util.List;

/**
 * Generate the main method class that will be executed to deploy a stack.
 *
 * @phase generate-sources
 * @goal generate-main
 */
public class GenerateMainClassMojo extends AbstractMojo {
    /**
     * Name of the main class.
     */
    public static final String MAIN_NAME = "DeployCloudFormationStack";

    /**
     * Directory to write the resulting JSON template files to.
     *
     * @parameter default-value="${project.build.directory}/generated-sources/cftemplate"
     */
    private File outputDirectory;

    /**
     * The source directories containing the sources to be processed.
     *
     * @parameter default-value="${project.compileSourceRoots}"
     * @required
     * @readonly
     */
    private List<String> compileSourceRoots;

    @Override
    public void execute()
            throws MojoExecutionException, MojoFailureException {
        createDirectory(outputDirectory);

        info("Generating %s source file...", MAIN_NAME);
        copyResourceToFile("/" + MAIN_NAME + ".java", new File(outputDirectory, MAIN_NAME + ".java"));

        debug("Adding %s to compile source roots", outputDirectory);
        compileSourceRoots.add(outputDirectory.getPath());

        // TODO set MAIN_NAME as main class?
        // TODO package AWS SDK with resulting jar
    }
}
