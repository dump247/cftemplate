package com.bazaarvoice.infrastructure.cftemplate;

import com.google.common.base.Throwables;
import org.junit.Test;

import java.io.File;
import java.util.Map;

import static com.google.common.collect.Maps.newHashMap;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

/**
 * Unit test for {@link RubyTemplateCompiler}.
 *
 * TODO 31 parameters/outputs, 32 parameters/outputs, invalid parameter name, duplicate symbol/long name parameter attributes
 * TODO invalid parameter attributes (i.e. non integer MinLength), incorrect parameter attributes for parameter type (i.e. MinLength for Number)
 */
public class RubyTemplateCompilerTest extends TemplateCompilerTest {
    private CompileResult assertCompile(String name) {
        return assertCompile(name, 0);
    }

    private CompileResult assertCompile(String name, int errors) {
        return assertCompile(new RubyTemplateCompiler(), name, errors);
    }

    private CompileResult assertCompile(RubyTemplateCompiler compiler, String name, int errors) {
        try {
            String templateName = name + ".rb";
            String outputName = name + ".json";

            File templateFile = resourceFile(templateName);
            File outputFile = new File(tempDir(".output"), outputName);

            CompileResult result = compiler.compile(templateFile, outputFile);

            if (errors == 0) {
                assertEquals(0, result.getIssues().size());
                assertJsonEquals(resourceFile(outputName), outputFile);
            } else {
                assertEquals(errors, result.getIssues().size());
                assertEquals(errors, result.getIssues(CompileIssueLevel.ERROR).size());
                assertFalse(outputFile.exists());
            }

            return result;
        } catch (Exception ex) {
            throw Throwables.propagate(ex);
        }
    }

    @Test
    public void testCompile_simple_template() {
        assertCompile("minimalTemplate");
    }

    @Test
    public void testCompile_with_invalid_version() {
        assertCompile("invalidVersion", 1);
    }

    @Test
    public void testCompile_with_no_version() {
        assertCompile("noVersion", 1);
    }

    @Test
    public void testCompile_with_description() {
        assertCompile("withDescription");
    }

    @Test
    public void testCompile_with_long_description() {
        assertCompile("longDescription");
    }

    @Test
    public void testCompile_with_invalid_description() {
        assertCompile("invalidDescription", 1);
    }

    @Test
    public void testCompile_with_parameter() {
        assertCompile("parameters");
    }

    @Test
    public void testCompile_with_invalid_parameter_type() {
        assertCompile("invalidParameterType", 3);
    }

    @Test
    public void testCompile_with_invalid_parameter_description() {
        assertCompile("invalidParameterDescription", 1);
    }

    @Test
    public void testCompile_with_duplicate_parameter() {
        assertCompile("duplicateParameter", 2);
    }

    @Test
    public void testCompile_parameter_length_configuration() {
        assertCompile("parameterLength");
    }

    @Test
    public void testCompile_number_parameter_with_value_range_constraint() {
        assertCompile("parameterValueConstraint");
    }

    @Test
    public void testCompile_parameter_no_echo_configuration() {
        assertCompile("parameterNoEcho");
    }

    @Test
    public void testCompile_string_parameter_with_default() {
        assertCompile("parameterStringDefault");
    }

    @Test
    public void testCompile_number_parameter_with_default() {
        assertCompile("parameterNumberDefault");
    }

    @Test
    public void testCompile_list_parameter_with_default() {
        assertCompile("parameterListDefault");
    }

    @Test
    public void testCompile_parameters_with_invalid_defaults() {
        assertCompile("invalidParameterDefault", 6);
    }

    @Test
    public void testCompile_with_parameter_allowed_values() {
        assertCompile("parameterAllowedValues");
    }

    @Test
    public void testCompile_mappings() {
        assertCompile("mappings");
    }

    @Test
    public void testCompile_outputs() {
        assertCompile("outputs");
    }

    @Test
    public void testCompile_file_utility_method() {
        assertCompile("fileUtility");
    }

    @Test
    public void testCompile_tags_utility_methods() {
        assertCompile("tagsUtility");
    }

    @Test
    public void testCompile_resources() {
        assertCompile("resources");
    }

    @Test
    public void testCompile_resources_with_circular_dependency_chain() {
        assertCompile("circularDependsOn", 1);
    }

    @Test
    public void testCompile_resource_with_dependency_that_does_not_exist() {
        assertCompile("resourceDependencyNotFound", 1);
    }

    @Test
    public void testCompile_with_duplicate_parameter_and_resource() {
        assertCompile("duplicateParameterAndResource", 1);
    }

    @Test
    public void testCompile_wait_condition_resource_utility() {
        assertCompile("resourceWaitCondition");
    }

    @Test
    public void testCompile_stack_resource_utility() {
        assertCompile("resourceStack");
    }

    @Test
    public void testCompile_iam_instance_profile_utility() {
        assertCompile("resourceIamProfile");
    }

    @Test
    public void testCompile_parameter_overrides() {
        Map<String, String> parameters = newHashMap();
        parameters.put("NotFound", "AAAA");
        parameters.put("NullValue", null);
        parameters.put("Param1", "");
        parameters.put("Param2", "BBBB");

        RubyTemplateCompiler compiler = new RubyTemplateCompiler();
        compiler.setParameters(parameters);
        assertCompile(compiler, "parameterOverrides", 0);
    }

    @Test
    public void testCompile_select_builtin_function() {
        assertCompile("fnSelect");
    }
}
