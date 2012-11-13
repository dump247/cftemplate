package com.bazaarvoice.infrastructure.cftemplate;

import com.google.common.collect.Iterables;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.map.SerializationConfig;
import org.codehaus.jackson.node.ObjectNode;
import org.jruby.CompatVersion;
import org.jruby.embed.EvalFailedException;
import org.jruby.embed.PathType;
import org.jruby.embed.ScriptingContainer;
import org.jruby.exceptions.RaiseException;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import static com.google.common.base.Preconditions.checkNotNull;
import static com.google.common.collect.Lists.newArrayList;
import static com.google.common.collect.Maps.newHashMap;
import static com.google.common.collect.Maps.newLinkedHashMap;

/**
 * Compiles Ruby DSL templates to CloudFormation JSON.
 */
public class RubyTemplateCompiler extends TemplateCompiler {


    @Override
    public CompileResult compile(File inputFile, File outputFile, CompileOptions options)
            throws IOException {
        checkNotNull(inputFile);
        checkNotNull(outputFile);
        checkNotNull(options);

        if (outputFile.exists()) {
            outputFile.delete();
        } else if (!outputFile.getParentFile().exists()) {
            outputFile.getParentFile().mkdirs();
        }

        CompileOutput output = new CompileOutput();
        CompileResult result = null;
        ObjectNode resultNode = null;

        try {
            ScriptingContainer engine = new ScriptingContainer();
            engine.getLoadPaths().add("templates");
            engine.put("$cftemplate_parameters", options.getParameters());
            engine.put("$cftemplate_output", output);
            engine.setCurrentDirectory(inputFile.getParent());
            engine.setCompatVersion(CompatVersion.RUBY1_9);
            engine.runScriptlet(PathType.ABSOLUTE, inputFile.getAbsolutePath());

            Map<String, Object> templateMap = newHashMap();
            templateMap.put("AWSTemplateFormatVersion", output.version);
            templateMap.put("Description", output.description);
            templateMap.put("Parameters", output.parameters);
            templateMap.put("Mappings", output.mappings);
            templateMap.put("Outputs", output.outputs);
            templateMap.put("Resources", output.resources);

            resultNode = compile(templateMap, output.issues);
        } catch (EvalFailedException ex) {
            CompileIssueLocation location = null;

            if (ex.getCause() instanceof RaiseException) {
                location = new CompileIssueLocation(
                        new File(((RaiseException) ex.getCause()).getStackTrace()[0].getFileName()),
                        ((RaiseException) ex.getCause()).getStackTrace()[0].getLineNumber());
            }

            output.issues.add(new CompileIssue(CompileIssueLevel.ERROR, ex.getMessage(), location));
        }

        result = new CompileResult(output.issues);

        if (resultNode != null && result.getIssues(CompileIssueLevel.ERROR).size() == 0) {
            new ObjectMapper()
                    .configure(SerializationConfig.Feature.INDENT_OUTPUT, true)
                    .writeValue(outputFile, resultNode);
        }

        return result;
    }

    public static class CompileOutput {
        public String description;
        public String version;

        public final Map<String, Map<String, String>> parameters = newLinkedHashMap();
        public final Map<String, Map<String, Map<String, Object>>> mappings = newLinkedHashMap();
        public final Map<String, Map<String, Object>> outputs = newLinkedHashMap();
        public final Map<String, Map<String, Object>> resources = newLinkedHashMap();

        public final List<CompileIssue> issues = newArrayList();

        private static <T> T clone(T obj) {
            if (obj instanceof Map) {
                Map<String, Object> copy = newLinkedHashMap();

                for (Map.Entry<String, Object> entry : ((Map<String, Object>) obj).entrySet()) {
                    copy.put(entry.getKey(), clone(entry.getValue()));
                }

                return (T) copy;
            } else if (obj instanceof Object[]) {
                List<Object> copy = newArrayList();

                for (Object value : ((Object[]) obj)) {
                    copy.add(clone(value));
                }

                return (T) Iterables.toArray(copy, (Class) obj.getClass().getComponentType());
            } else {
                return obj;
            }
        }

        // Called from crtemplate.rb
        public void setVersion(String caller, String version, String description) {
            this.version = version;
            this.description = description;
        }

        // Called from crtemplate.rb
        public void addParameter(String caller, String name, Map<String, String> value) {
            Map<String, String> args = clone(value); // Must copy the map, otherwise errors occur later

            if (parameters.containsKey(name)) {
                error(caller, "Duplicate parameter name: %s", name);
            } else {
                parameters.put(name, args);
            }
        }

        // Called from crtemplate.rb
        public void addMapping(String caller, String name, Map<String, Map<String, Object>> value) {
            Map<String, Map<String, Object>> mapValue = clone(value); // Must copy the map, otherwise errors occur later

            if (mappings.containsKey(name)) {
                error(caller, "Duplicate mapping name: %s", name);
            } else {
                mappings.put(name, mapValue);
            }
        }

        // Called from crtemplate.rb
        public void addOutput(String caller, String name, Map<String, Object> value) {
            Map<String, Object> args = clone(value); // Must copy the map, otherwise errors occur later

            if (outputs.containsKey(name)) {
                error(caller, "Duplicate output name: %s", name);
            } else {
                outputs.put(name, args);
            }
        }

        // Called from crtemplate.rb
        public void addResource(String caller, String name, Map<String, Object> value) {
            Map<String, Object> args = clone(value); // Must copy the map, otherwise errors occur later

            if (resources.containsKey(name)) {
                error(caller, "Duplicate resource name: %s", name);
            } else {
                resources.put(name, args);
            }
        }

        // Called from crtemplate.rb
        private CompileIssueLocation parseCaller(String value) {
            if (value == null) {
                return null;
            }

            String[] info = value.split(":");
            File file = new File(info[0]);
            int line = -1;

            if (info.length > 1) {
                line = Integer.parseInt(info[1]);
            }

            return new CompileIssueLocation(file, line);
        }

        // Called from crtemplate.rb
        public void error(String caller, String message) {
            issues.add(new CompileIssue(CompileIssueLevel.ERROR, message, parseCaller(caller)));
        }

        // Called from crtemplate.rb
        public void error(String caller, String format, Object... args) {
            issues.add(new CompileIssue(CompileIssueLevel.ERROR, String.format(format, args), parseCaller(caller)));
        }

        // Called from crtemplate.rb
        public void warn(String caller, String message) {
            issues.add(new CompileIssue(CompileIssueLevel.WARN, message, parseCaller(caller)));
        }

        // Called from crtemplate.rb
        public void info(String caller, String message) {
            issues.add(new CompileIssue(CompileIssueLevel.INFO, message, parseCaller(caller)));
        }
    }
}
