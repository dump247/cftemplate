package com.bazaarvoice.infrastructure.cftemplate;

import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.map.SerializationConfig;
import org.codehaus.jackson.node.ObjectNode;
import org.codehaus.jackson.type.TypeReference;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import static com.google.common.collect.Lists.newArrayList;

/**
 * Compiles JSON CloudFormation templates to JSON.
 * <p/>
 * Performs validations on the input template.
 */
public class JsonTemplateCompiler extends TemplateCompiler {
    @Override
    public CompileResult compile(File inputFile, File outputFile)
            throws IOException {
        List<CompileIssue> issues = newArrayList();
        CompileResult result = null;
        ObjectNode resultNode = null;

        try {
            Map<String, Object> inputData = new ObjectMapper().readValue(inputFile, new TypeReference<Map<String, Object>>() {
            });

            checkOverrides(inputData);

            resultNode = compile(inputData, issues);
        } catch (Exception ex) {
            issues.add(new CompileIssue(CompileIssueLevel.ERROR, ex.getMessage(), new CompileIssueLocation(inputFile)));
        }

        result = new CompileResult(inputFile, issues);

        if (resultNode != null && result.getIssues(CompileIssueLevel.ERROR).size() == 0) {
            new ObjectMapper().configure(SerializationConfig.Feature.INDENT_OUTPUT, true).writeValue(outputFile, resultNode);
        }

        return result;
    }

    private void checkOverrides(Map<String, Object> template) {
        Object parameters = template.get("Parameters");

        if (parameters instanceof Map) {
            Map parametersMap = (Map) parameters;

            for (Map.Entry<String, String> override : getParameters().entrySet()) {
                if (override.getValue() != null) {
                    Object parameter = parametersMap.get(override.getKey());

                    if (parameter instanceof Map) {
                        ((Map) parameter).put("Default", override.getValue());
                    }
                }
            }
        }
    }
}
