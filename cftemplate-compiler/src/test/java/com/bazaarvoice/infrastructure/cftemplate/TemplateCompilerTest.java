package com.bazaarvoice.infrastructure.cftemplate;

import com.google.common.base.Predicates;
import com.google.common.base.Throwables;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.map.SerializationConfig;
import org.junit.After;
import org.junit.Before;
import org.reflections.Reflections;
import org.reflections.scanners.ResourcesScanner;
import org.reflections.util.ClasspathHelper;
import org.reflections.util.ConfigurationBuilder;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.Charset;
import java.util.List;

import static com.google.common.collect.Lists.newArrayList;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

/**
 * Base class for template compiler unit tests.
 */
public class TemplateCompilerTest {
    private File tempResourcesDir;
    private List<File> tempPaths;

    @Before
    public void beforeTest() {
        tempResourcesDir = null;
        tempPaths = newArrayList();
    }

    @After
    public void afterTest() {
        for (File path : tempPaths) {
            FileUtils.deleteQuietly(path);
        }
    }

    protected void assertJsonEquals(File expected, File actual) {
        ObjectMapper mapper = new ObjectMapper().configure(SerializationConfig.Feature.INDENT_OUTPUT, true);

        try {
            JsonNode expectedNode = mapper.readTree(expected);
            JsonNode actualNode = mapper.readTree(actual);

            // expectedNode.equals(actualNode) works, however, do string comparison here so IntelliJ can show a decent diff view
            assertEquals(mapper.writeValueAsString(expectedNode), mapper.writeValueAsString(actualNode));
        } catch (Exception ex) {
            throw Throwables.propagate(ex);
        }
    }

    protected void assertTextEquals(File expected, File actual, Charset charset) {
        try {
            assertEquals(
                    FileUtils.readFileToString(expected, charset),
                    FileUtils.readFileToString(actual, charset)
            );
        } catch (IOException ex) {
            throw Throwables.propagate(ex);
        }
    }

    protected File resourceFile(String name) {
        File path = new File(resourcesDir(), name);
        assertTrue("Resource file not found: " + name, path.isFile());
        return path;
    }

    protected File tempDir(String suffix) {
        try {
            File tempPath = File.createTempFile(getClass().getSimpleName(), suffix);
            tempPath.delete();
            tempPath.mkdirs();
            tempPaths.add(tempPath);
            return tempPath;
        } catch (Exception ex) {
            throw Throwables.propagate(ex);
        }
    }

    private void copyResource(String name, File output) {
        output.getParentFile().mkdirs();

        InputStream inputStream = null;
        OutputStream outputStream = null;

        try {
            inputStream = this.getClass().getClassLoader().getResourceAsStream(name);

            if (inputStream == null) {
                throw new RuntimeException("Failed to find resource: " + name);
            }

            outputStream = new FileOutputStream(output);

            IOUtils.copy(inputStream, outputStream);
        } catch (IOException ex) {
            throw Throwables.propagate(ex);
        } finally {
            IOUtils.closeQuietly(inputStream);
            IOUtils.closeQuietly(outputStream);
        }
    }

    protected File resourcesDir() {
        if (tempResourcesDir == null) {
            try {
                tempResourcesDir = tempDir(".resources");

                String resourcesPrefix = this.getClass().getName();
                String resourcesPath = resourcesPrefix.replace('.', '/') + '/';
                Reflections reflections = new Reflections(new ConfigurationBuilder()
                        .setUrls(ClasspathHelper.forPackage(resourcesPrefix))
                        .setScanners(new ResourcesScanner()));

                for (String resourceName : reflections.getResources(Predicates.<String>alwaysTrue())) {
                    if (resourceName.startsWith(resourcesPath)) {
                        copyResource(resourceName, new File(tempResourcesDir, resourceName.substring(resourcesPrefix.length() + 1)));
                    }
                }
            } catch (Exception ex) {
                throw Throwables.propagate(ex);
            }
        }

        return tempResourcesDir;
    }
}
