package com.bazaarvoice.infrastructure;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.apache.maven.plugin.MojoExecutionException;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;

/**
 * Some helper functions.
 */
public abstract class AbstractMojo extends org.apache.maven.plugin.AbstractMojo {
    public void debug(String message) {
        getLog().debug(message);
    }

    public void debug(String format, Object... args) {
        getLog().debug(String.format(format, args));
    }

    public void info(String message) {
        getLog().info(message);
    }

    public void info(String format, Object... args) {
        getLog().info(String.format(format, args));
    }

    public void warn(String message) {
        getLog().warn(message);
    }

    public void warn(String format, Object... args) {
        getLog().warn(String.format(format, args));
    }

    public void error(String message) {
        getLog().error(message);
    }

    public void error(String format, Object... args) {
        getLog().error(String.format(format, args));
    }

    public void createDirectory(File path) {
        if (!path.exists()) {
            debug("Creating directory %s", path);
            path.mkdirs();
        }
    }

    protected void createParentDirectory(File path) {
        createDirectory(path.getParentFile());
    }

    protected void copyResourceToFile(String resource, File file)
            throws MojoExecutionException {
        debug("Copying resource %s to %s", resource, file);

        InputStream resourceStream = getClass().getResourceAsStream(resource);

        if (resourceStream == null) {
            throw new MojoExecutionException("Unable to find resource " + resource);
        }

        createParentDirectory(file);

        try {
            FileUtils.copyInputStreamToFile(resourceStream, file);
        } catch (IOException ex) {
            throw new MojoExecutionException("Error copying resource " + resource + " to file " + file, ex);
        } finally {
            IOUtils.closeQuietly(resourceStream);
        }
    }
}
