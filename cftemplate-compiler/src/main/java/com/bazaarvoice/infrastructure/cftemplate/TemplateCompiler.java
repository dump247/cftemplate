package com.bazaarvoice.infrastructure.cftemplate;

import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Iterables;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.ObjectUtils;
import org.apache.commons.lang3.StringUtils;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.node.ArrayNode;
import org.codehaus.jackson.node.JsonNodeFactory;
import org.codehaus.jackson.node.ObjectNode;

import java.io.File;
import java.io.IOException;
import java.util.Deque;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static com.google.common.base.Preconditions.checkNotNull;
import static com.google.common.collect.Lists.newArrayList;
import static com.google.common.collect.Maps.newHashMap;
import static com.google.common.collect.Queues.newArrayDeque;
import static com.google.common.collect.Sets.newHashSet;
import static java.util.Collections.emptyList;
import static org.apache.commons.lang3.StringUtils.isBlank;
import static org.apache.commons.lang3.StringUtils.isEmpty;

/**
 * Compiles and verifies AWS CloudFormation templates.
 */
public abstract class TemplateCompiler {
    private Map<String, String> _parameters = newHashMap();

    /**
     * Compile a template file to CloudFormation JSON.
     *
     * @param inputFile template file to compile
     * @param outputFile file to write the CloudFormation JSON to
     * @return result of compilation
     */
    public abstract CompileResult compile(File inputFile, File outputFile)
            throws IOException;

    /**
     * Get parameter overrides.
     *
     * @return map from parameter name to value override
     */
    public Map<String, String> getParameters() {
        return _parameters;
    }

    /**
     * Set parameter overrides.
     * <p/>
     * If the parameter exists in the template, the default value is set to the
     * given value. Overrides with null values are ignored.
     *
     * @param parameters parameter overrides
     */
    public void setParameters(Map<String, String> parameters) {
        _parameters = checkNotNull(parameters);
    }

    private static class TemplateValue {
        public final String stringValue;
        public final Double numericValue;

        public TemplateValue(String value) {
            this.stringValue = value;
            this.numericValue = null;
        }

        public TemplateValue(String value, Double numericValue) {
            this.stringValue = value;
            this.numericValue = numericValue;
        }

        @Override
        public String toString() {
            return stringValue;
        }
    }

    private static class NodePathEntry {
        public final String name;
        public final Map<String, Object> node;

        public NodePathEntry(String name, Map<String, Object> node) {
            this.name = name;
            this.node = node;
        }
    }

    private static abstract class NodeCompiler {
        private static final int MAX_DESCRIPTION_LENGTH = 4000;
        private static final Pattern LOGICAL_NAME_PATTERN = Pattern.compile("^[A-Za-z0-9]+$");
        private static final Pattern INTEGER_PATTERN = Pattern.compile("^[0-9]+$");
        private static final Pattern NUMBER_PATTERN = Pattern.compile("^([\\+\\-]?)([0-9]+)(\\.[0-9]+)?$");

        protected final List<CompileIssue> _issues;

        protected NodePathEntry[] _currentPath;
        protected Map<String, Object> _currentNode;

        public NodeCompiler(List<CompileIssue> issues) {
            _issues = issues;
        }

        public abstract String getName();

        public Set<String> allowedKeys() {
            return null;
        }

        public final ObjectNode compile(NodePathEntry[] path, Map<String, Object> node) {
            if (node == null) {
                return null;
            }

            _currentNode = node;
            _currentPath = path;

            try {
                validateKeys();
                return compile();
            } catch (Exception ex) {
                error("Internal compiler error: %s", ex.toString());
                return null;
            } finally {
                _currentNode = null;
                _currentPath = null;
            }
        }

        protected abstract ObjectNode compile();

        private void validateKeys() {
            Set<String> allowedKeys = allowedKeys();

            if (allowedKeys != null) {
                for (String nodeKey : _currentNode.keySet()) {
                    if (!allowedKeys.contains(nodeKey)) {
                        errorWithNearest(nodeKey, allowedKeys, "Unexpected key in %1$s: %2$s. Valid keys for %1$s: %3$s.", getName().toLowerCase(), nodeKey, StringUtils.join(allowedKeys, ", "));
                    }
                }
            }
        }

        protected void errorWithNearest(String value, Iterable<String> values, String format, Object... args) {
            String message = String.format(format, args);
            String nearestValue = findNearest(value, values);

            if (nearestValue != null) {
                message += String.format(" Perhaps you meant %s?", nearestValue);
            }

            error(message);
        }

        protected void error(String format, Object... args) {
            _issues.add(CompileIssue.error(format, args));
        }

        protected void warn(String format, Object... args) {
            _issues.add(CompileIssue.warn(format, args));
        }

        protected boolean validateDescription(String name, String value) {
            if (value.length() > MAX_DESCRIPTION_LENGTH) {
                error("%s description is %d characters, which exceeds the max description length of %d characters.", name, value.length(), MAX_DESCRIPTION_LENGTH);
                return false;
            }

            return true;
        }

        protected boolean validateLogicalName(String name, String value) {
            if (isBlank(value)) {
                error("A %s can not be blank. Only alphanumeric characters are allowed (A-Z, a-z, 0-9).", name.toLowerCase());
            } else if (!LOGICAL_NAME_PATTERN.matcher(value).matches()) {
                error("%s is not a valid %s. Only alphanumeric characters are allowed (A-Z, a-z, 0-9).", value, name.toLowerCase());
                return false;
            }

            // TODO max length?

            return true;
        }

        protected int validateInteger(String name, String value) {
            int intValue = -1;

            if (INTEGER_PATTERN.matcher(value).matches()) {
                try {
                    intValue = Integer.parseInt(value);
                } catch (NumberFormatException ex) {
                    // Ignore
                }
            }

            if (intValue < 0) {
                error("%s is not a valid value for %s. The value must be a positive integer.", value, name);
            }

            return intValue;
        }

        protected TemplateValue validateNumber(String name, String value) {
            Matcher matcher = NUMBER_PATTERN.matcher(value);
            Double result = null;

            if (matcher.matches()) {
                if (matcher.group(3) == null) {
                    try {
                        result = Integer.valueOf(value).doubleValue();
                    } catch (NumberFormatException ex) {
                        // Ignore
                    }
                } else {
                    try {
                        result = Float.valueOf(value).doubleValue();
                    } catch (NumberFormatException ex) {
                        // Ignore
                    }
                }
            }

            if (result == null) {
                error("%s is not a valid value for %s. The value must be an integer or float.", value, name);
            }

            return new TemplateValue(value, result);
        }

        protected NodePathEntry[] appendPath(String name, Map<String, Object> node) {
            return appendPath(_currentPath, name, node);
        }

        protected static NodePathEntry[] appendPath(NodePathEntry[] path, String name, Map<String, Object> node) {
            return ArrayUtils.add(path, new NodePathEntry(name, node));
        }

        protected String getLastPathName() {
            return ArrayUtils.isEmpty(_currentPath) ? "" : _currentPath[_currentPath.length - 1].name;
        }

        protected static JsonNode copyOf(Object value) {
            if (value instanceof Map) {
                ObjectNode result = JsonNodeFactory.instance.objectNode();

                for (Map.Entry<String, Object> entry : ((Map<String, Object>) value).entrySet()) {
                    result.put(entry.getKey(), copyOf(entry.getValue()));
                }

                return result;
            } else if (value instanceof Iterable) {
                ArrayNode result = JsonNodeFactory.instance.arrayNode();

                for (Object entry : ((Iterable) value)) {
                    result.add(copyOf(entry));
                }

                return result;
            } else if (value instanceof Object[]) {
                ArrayNode result = JsonNodeFactory.instance.arrayNode();

                for (Object entry : ((Object[]) value)) {
                    result.add(copyOf(entry));
                }

                return result;
            } else {
                return JsonNodeFactory.instance.textNode(ObjectUtils.toString(value));
            }
        }
    }

    private static class TemplateNodeCompiler extends NodeCompiler {
        private static final Set<String> ALLOWED_KEYS = ImmutableSet.of("AWSTemplateFormatVersion", "Description", "Parameters", "Resources", "Outputs", "Mappings");
        private static final String TEMPLATE_VERSION = "2010-09-09";
        private static final int MAX_PARAMETERS = 32;
        private static final int MAX_OUTPUTS = 32;

        public TemplateNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            return "Template";
        }

        @Override
        public Set<String> allowedKeys() {
            return ALLOWED_KEYS;
        }

        @Override
        protected ObjectNode compile() {
            String version = (String) _currentNode.get("AWSTemplateFormatVersion");

            if (version == null) {
                error("AWSTemplateFormatVersion is required. Valid versions: %s", TEMPLATE_VERSION);
                return null;
            } else if (!version.equals(TEMPLATE_VERSION)) {
                error("Unknown template version: %s. Supported template versions: %s", version, TEMPLATE_VERSION);
                return null;
            }

            ObjectNode templateNode = JsonNodeFactory.instance.objectNode();
            templateNode.put("AWSTemplateFormatVersion", version);

            String description = (String) _currentNode.get("Description");

            if (!isEmpty(description)) {
                validateDescription(getName(), description);
                templateNode.put("Description", description);
            }

            Map<String, Object> parameters = (Map<String, Object>) _currentNode.get("Parameters");

            if (parameters != null && parameters.size() > 0) {
                Set<String> parameterNames = newHashSet();
                ParameterNodeCompiler parameterCompiler = new ParameterNodeCompiler(_issues);
                NodePathEntry[] parametersPath = appendPath("Parameters", _currentNode);
                ObjectNode parametersNode = templateNode.putObject("Parameters");

                for (Map.Entry<String, Object> parameter : parameters.entrySet()) {
                    if (parameterNames.contains(parameter.getKey().toLowerCase())) {
                        error("Duplicate parameter name: %s", parameter.getKey());
                    } else {
                        validateLogicalName("Parameter name", parameter.getKey());

                        NodePathEntry[] parameterPath = appendPath(parametersPath, parameter.getKey(), parameters);
                        ObjectNode parameterNode = parameterCompiler.compile(parameterPath, (Map<String, Object>) parameter.getValue());

                        if (parameterNode != null) {
                            parameterNames.add(parameter.getKey().toLowerCase());
                            parametersNode.put(parameter.getKey(), parameterNode);
                        }
                    }
                }

                if (parametersNode.size() > MAX_PARAMETERS) {
                    error("There are %d parameters defined. This exceeds the limit of %d parameters.", parametersNode.size(), MAX_PARAMETERS);
                }
            }

            Map<String, Object> mappings = (Map<String, Object>) _currentNode.get("Mappings");

            if (mappings != null && mappings.size() > 0) {
                NodePathEntry[] mappingsPath = appendPath("Mappings", _currentNode);
                ObjectNode mappingsNode = new MappingsNodeCompiler(_issues).compile(mappingsPath, mappings);

                if (mappingsNode != null && mappingsNode.size() > 0) {
                    templateNode.put("Mappings", mappingsNode);
                }
            }

            Map<String, Object> resources = (Map<String, Object>) _currentNode.get("Resources");

            if (resources == null || resources.size() == 0) {
                error("At least one resource definition is required.");
            } else {
                NodePathEntry[] resourcesPath = appendPath("Resources", _currentNode);
                ObjectNode resourcesNode = new ResourcesNodeCompiler(_issues).compile(resourcesPath, resources);

                if (resourcesNode != null && resourcesNode.size() > 0) {
                    templateNode.put("Resources", resourcesNode);
                }
            }

            Map<String, Object> outputs = (Map<String, Object>) _currentNode.get("Outputs");

            if (outputs != null && outputs.size() > 0) {
                NodePathEntry[] outputsPath = appendPath("Outputs", _currentNode);
                ObjectNode outputsNode = new OutputsNodeCompiler(_issues).compile(outputsPath, outputs);

                if (outputsNode != null && outputsNode.size() > 0) {
                    if (outputsNode.size() > MAX_OUTPUTS) {
                        error("There are %d outputs defined. This exceeds the limit of %d outputs.", outputsNode.size(), MAX_OUTPUTS);
                    }

                    templateNode.put("Outputs", outputsNode);
                }
            }

            checkForDuplicateResources(templateNode);
            checkDependsOn(templateNode);
            // TODO validate Ref, FindInMap, GetAtt and other function calls

            return templateNode;
        }

        private void checkDependsOn(ObjectNode templateNode) {
            ObjectNode resourcesNode = (ObjectNode) templateNode.get("Resources");

            if (resourcesNode != null) {
                Set<String> checkedResources = newHashSet();

                for (String resourceName : asIterable(resourcesNode.getFieldNames())) {
                    Deque<String> parents = newArrayDeque();
                    if (!checkedResources.contains(resourceName) && checkCircular(resourcesNode, resourceName, (ObjectNode) resourcesNode.get(resourceName), parents, checkedResources)) {
                        error("Circular DependsOn dependency chain with resource %s", resourceName);
                    }
                }
            }
        }

        private boolean checkCircular(ObjectNode resourcesNode, String resourceName, ObjectNode resourceNode, Deque<String> parents, Set<String> checked) {
            checked.add(resourceName);

            JsonNode dependsOn = resourceNode.get("DependsOn");

            if (dependsOn != null) {
                String dependsOnName = dependsOn.asText();
                ObjectNode dependsOnNode = (ObjectNode) resourcesNode.get(dependsOnName);

                if (dependsOnNode == null) {
                    error("DependsOn for resource %s targets resource %s, which does not exist.", resourceName, dependsOnName);
                } else if (parents.contains(dependsOnName)) {
                    return true;
                } else if (!checked.contains(dependsOnName)) {
                    parents.push(resourceName);

                    try {
                        return checkCircular(resourcesNode, dependsOnName, dependsOnNode, parents, checked);
                    } finally {
                        parents.pop();
                    }
                }
            }

            return false;
        }

        private void checkForDuplicateResources(ObjectNode templateNode) {
            ObjectNode parametersNode = (ObjectNode) templateNode.get("Parameters");
            ObjectNode resourcesNode = (ObjectNode) templateNode.get("Resources");

            if (parametersNode != null && resourcesNode != null) {
                Set<String> parameterNames = newHashSet();

                for (String name : asIterable(parametersNode.getFieldNames())) {
                    parameterNames.add(name.toLowerCase());
                }

                for (String resourceName : asIterable(resourcesNode.getFieldNames())) {
                    if (parameterNames.contains(resourceName.toLowerCase())) {
                        error("A parameter and a resource both have name %s. All parameters and resources must have unique names.", resourceName);
                    }
                }
            }
        }
    }

    private static class ResourcesNodeCompiler extends NodeCompiler {
        public ResourcesNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            return "Resources";
        }

        @Override
        protected ObjectNode compile() {
            ObjectNode resourcesNode = JsonNodeFactory.instance.objectNode();
            ResourceNodeCompiler resourceNodeCompiler = new ResourceNodeCompiler(_issues);
            Set<String> resourceNames = newHashSet();

            for (Map.Entry<String, Map<String, Object>> resource : ((Map<String, Map<String, Object>>) (Map) _currentNode).entrySet()) {
                String resourceName = resource.getKey();

                if (resourceNames.contains(resourceName.toLowerCase())) {
                    error("Duplicate resource: %s", resourceName);
                } else {
                    resourceNames.add(resourceName.toLowerCase());

                    Map<String, Object> resourceConfig = resource.getValue();

                    validateLogicalName("Resource name", resourceName);

                    NodePathEntry[] resourcePath = appendPath(resourceName, _currentNode);
                    ObjectNode resourceNode = resourceNodeCompiler.compile(resourcePath, resourceConfig);

                    if (resourceNode != null) {
                        resourcesNode.put(resourceName, resourceNode);
                    }
                }
            }

            return resourcesNode;
        }
    }

    private static class ResourceNodeCompiler extends NodeCompiler {
        private static final Set<String> ALLOWED_KEYS = ImmutableSet.of("Type", "Properties", "DeletionPolicy", "DependsOn", "Metadata");
        private static final Set<String> DELETION_POLICIES = ImmutableSet.of("Delete", "Retain", "Snapshot");

        /**
         * Map from resource type name (e.g. AWS::S3::Bucket) to the compiler for the properties of that type.
         */
        private final Map<String, NodeCompiler> _resourceCompilers;

        public ResourceNodeCompiler(List<CompileIssue> issues) {
            super(issues);

            _resourceCompilers = ImmutableMap.of();
        }

        @Override
        public String getName() {
            String resourceName = getResourceName();
            return "Resource" + (isEmpty(resourceName) ? "" : " " + resourceName);
        }

        protected String getResourceName() {
            return getLastPathName();
        }

        @Override
        public Set<String> allowedKeys() {
            return ALLOWED_KEYS;
        }

        @Override
        protected ObjectNode compile() {
            ObjectNode resourceNode = JsonNodeFactory.instance.objectNode();
            String type = ObjectUtils.toString(_currentNode.get("Type"));

            if (isEmpty(type)) {
                error("Type is required for resource %s", getResourceName());
                return null;
            }

            resourceNode.put("Type", type);

            Map<String, Object> properties = (Map<String, Object>) _currentNode.get("Properties");

            if (properties == null) {
                properties = newHashMap();
            }

            NodeCompiler resourceCompiler = _resourceCompilers.get(type);

            if (resourceCompiler == null) {
                resourceNode.put("Properties", copyOf(properties));
            } else {
                NodePathEntry[] propertiesPath = appendPath("Properties", _currentNode);
                resourceNode.put("Properties", resourceCompiler.compile(propertiesPath, properties));
            }

            Object metadata = _currentNode.get("Metadata");

            if (metadata != null) {
                resourceNode.put("Metadata", copyOf(metadata));
            }

            String dependsOn = ObjectUtils.toString(_currentNode.get("DependsOn"));

            if (!isEmpty(dependsOn)) {
                if (validateLogicalName("DependsOn for resource " + getResourceName(), dependsOn)) {
                    resourceNode.put("DependsOn", dependsOn);
                }
            }

            String deletionPolicy = ObjectUtils.toString(_currentNode.get("DeletionPolicy"));

            if (!isEmpty(deletionPolicy)) {
                if (!DELETION_POLICIES.contains(deletionPolicy)) {
                    errorWithNearest(deletionPolicy, DELETION_POLICIES, "Unexpected deletion policy in resource %s. Allowed values: %s.", getResourceName(), StringUtils.join(DELETION_POLICIES, ", "));
                }

                resourceNode.put("DeletionPolicy", deletionPolicy);
            }

            return resourceNode;
        }
    }

    private abstract class ResourcePropertiesNodeCompiler extends NodeCompiler {
        public ResourcePropertiesNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            String resourceName = getResourceName();
            return "Resource" + (isEmpty(resourceName) ? "" : " " + resourceName) + " Properties";
        }

        protected String getResourceName() {
            return (_currentPath == null || _currentPath.length < 2) ? "" : _currentPath[_currentPath.length - 2].name;
        }
    }

    private static class OutputsNodeCompiler extends NodeCompiler {
        public OutputsNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            return "Outputs";
        }

        @Override
        protected ObjectNode compile() {
            ObjectNode outputsNode = JsonNodeFactory.instance.objectNode();
            OutputNodeCompiler outputNodeCompiler = new OutputNodeCompiler(_issues);
            Set<String> outputNames = newHashSet();

            for (Map.Entry<String, Object> output : _currentNode.entrySet()) {
                // TODO validate output name (output.getKey())
                if (outputNames.contains(output.getKey().toLowerCase())) {
                    error("Duplicate Output: %s", output.getKey());
                } else {
                    outputNames.add(output.getKey().toLowerCase());

                    NodePathEntry[] outputPath = appendPath(output.getKey(), _currentNode);
                    ObjectNode outputNode = outputNodeCompiler.compile(outputPath, (Map<String, Object>) output.getValue());

                    if (outputNode != null) {
                        outputsNode.put(output.getKey(), outputNode);
                    }
                }
            }

            return outputsNode;
        }
    }

    private static class OutputNodeCompiler extends NodeCompiler {
        private static final Set<String> ALLOWED_KEYS = ImmutableSet.of("Value", "Description");

        public OutputNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            String outputName = getOutputName();
            return "Output" + (isEmpty(outputName) ? "" : " " + outputName);
        }

        private String getOutputName() {
            return getLastPathName();
        }

        @Override
        public Set<String> allowedKeys() {
            return ALLOWED_KEYS;
        }

        @Override
        protected ObjectNode compile() {
            ObjectNode outputNode = JsonNodeFactory.instance.objectNode();

            String description = ObjectUtils.toString(_currentNode.get("Description"));

            if (!isEmpty(description)) {
                validateDescription(getName(), description);
                outputNode.put("Description", description);
            }

            Object value = _currentNode.get("Value");

            if (value == null) {
                error("Value is required for output %s.", getOutputName());
            } else {
                outputNode.put("Value", copyOf(value));
            }

            return outputNode;
        }
    }

    private static class MappingsNodeCompiler extends NodeCompiler {
        public MappingsNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            return "Mappings";
        }

        @Override
        protected ObjectNode compile() {
            ObjectNode mappingsNode = JsonNodeFactory.instance.objectNode();

            for (Map.Entry<String, Object> mapping : _currentNode.entrySet()) {
                // TODO validate mapping name (mapping.getKey())
                ObjectNode mappingNode = JsonNodeFactory.instance.objectNode();

                for (Map.Entry<String, Object> map : ((Map<String, Object>) mapping.getValue()).entrySet()) {
                    // TODO validate map name (map.getKey())
                    ObjectNode mapNode = JsonNodeFactory.instance.objectNode();

                    for (Map.Entry<String, Object> entry : ((Map<String, Object>) map.getValue()).entrySet()) {
                        // TODO validate entry name (entry.getKey())

                        if (entry.getValue() instanceof Iterable) {
                            ArrayNode entryValue = mapNode.putArray(entry.getKey());

                            for (Object item : ((Iterable) entry.getValue())) {
                                entryValue.add(ObjectUtils.toString(item));
                            }
                        } else if (entry.getValue() instanceof Object[]) {
                            ArrayNode entryValue = mapNode.putArray(entry.getKey());

                            for (Object item : ((Object[]) entry.getValue())) {
                                entryValue.add(ObjectUtils.toString(item));
                            }
                        } else {
                            mapNode.put(entry.getKey(), ObjectUtils.toString(entry.getValue()));
                        }
                    }

                    if (mapNode.size() > 0) {
                        mappingNode.put(map.getKey(), mapNode);
                    }
                }

                if (mappingNode.size() > 0) {
                    mappingsNode.put(mapping.getKey(), mappingNode);
                }
            }

            return mappingsNode;
        }
    }

    private static class ParameterNodeCompiler extends NodeCompiler {
        private static final Set<String> ALLOWED_KEYS = ImmutableSet.of("Type", "Default", "NoEcho", "AllowedValues", "AllowedPattern", "MaxLength", "MinLength", "MaxValue", "MinValue", "Description", "ConstraintDescription");
        private static final Set<String> PARAMETER_TYPES = ImmutableSet.of("String", "Number", "CommaDelimitedList");

        public ParameterNodeCompiler(List<CompileIssue> issues) {
            super(issues);
        }

        @Override
        public String getName() {
            String paramName = getParameterName();
            return "Parameter" + (isEmpty(paramName) ? "" : " " + paramName);
        }

        @Override
        public Set<String> allowedKeys() {
            return ALLOWED_KEYS;
        }

        private String getParameterName() {
            return getLastPathName();
        }

        @Override
        protected ObjectNode compile() {
            String type = ObjectUtils.toString(_currentNode.get("Type"));

            if (isEmpty(type)) {
                error("Type is missing for parameter %s.", getParameterName().toLowerCase());
                return null;
            } else if (!PARAMETER_TYPES.contains(type)) {
                errorWithNearest(type, PARAMETER_TYPES, "Unexpected type %s for parameter %s. Possible parameter types: %s.", type, getParameterName(), StringUtils.join(PARAMETER_TYPES, ", "));
                return null;
            }

            ObjectNode parameterNode = JsonNodeFactory.instance.objectNode();
            parameterNode.put("Type", type);

            String description = ObjectUtils.toString(_currentNode.get("Description"));

            if (!isEmpty(description)) {
                validateDescription(getName(), description);
                parameterNode.put("Description", description);
            }

            TemplateValue defaultValue = parseDefault(type, parameterNode);

            String constraintDescription = ObjectUtils.toString(_currentNode.get("ConstraintDescription"));

            if (!isEmpty(constraintDescription)) {
                validateDescription(getName() + " constraint", constraintDescription);
                parameterNode.put("ConstraintDescription", constraintDescription);
            }

            parseLengthConstraint(type, defaultValue, parameterNode);
            parseRangeConstraint(type, defaultValue, parameterNode);
            parseAllowedValues(type, defaultValue, parameterNode);
            parseAllowedPattern(type, defaultValue, parameterNode);
            parseNoEcho(parameterNode);

            return parameterNode;
        }

        private void parseAllowedPattern(String type, TemplateValue defaultValue, ObjectNode parameterNode) {
            if (type.equals("String")) {
                String patternStr = ObjectUtils.toString(_currentNode.get("AllowedPattern"));

                if (!isEmpty(patternStr)) {
                    try {
                        Pattern allowedPattern = Pattern.compile(patternStr);

                        if (defaultValue != null && !allowedPattern.matcher(defaultValue.stringValue).matches()) {
                            error("Parameter %s Default value %s does not match AllowedPattern constraint.", getParameterName(), defaultValue);
                        }
                    } catch (Exception ex) {
                        error("%s is not a valid AllowedPattern for parameter %s. Value must be a regex. Error: %s", patternStr, getParameterName(), ex);
                    }

                    parameterNode.put("AllowedPattern", patternStr);
                }
            } else {
                if (_currentNode.containsKey("AllowedPattern")) {
                    error("Parameter %s is type %s, but has an AllowedPattern specified. AllowedPattern is only valid for String parameters.", getParameterName(), type);
                }
            }
        }

        private void parseAllowedValues(String type, TemplateValue defaultValue, ObjectNode parameterNode) {
            Object allowedValuesObj = _currentNode.get("AllowedValues");

            if (allowedValuesObj != null) {
                if (type.equals("Number") || type.equals("String")) {
                    Object[] allowedValues;
                    ArrayNode allowedValuesNode = JsonNodeFactory.instance.arrayNode();

                    if (allowedValuesObj instanceof Iterable) {
                        allowedValues = Iterables.toArray((Iterable) allowedValuesObj, Object.class);
                    } else if (allowedValuesObj.getClass().isArray()) {
                        allowedValues = (Object[]) allowedValuesObj;
                    } else {
                        allowedValues = new Object[] {ObjectUtils.toString(allowedValuesObj)};
                    }

                    boolean defaultFound = defaultValue == null;

                    for (Object allowedValue : allowedValues) {
                        String allowedValueStr = ObjectUtils.toString(allowedValue);

                        if (!defaultFound) {
                            defaultFound = allowedValueStr.equals(defaultValue.stringValue);
                        }

                        if (type.equals("Number")) {
                            validateNumber("AllowedValues in parameter " + getParameterName(), allowedValueStr);
                        }

                        allowedValuesNode.add(allowedValueStr);
                    }

                    if (!defaultFound) {
                        error("Parameter %s Default value %s does not exist in AllowedValues constraint. Allowed values: %s", getParameterName(), defaultValue, StringUtils.join(allowedValues, ", "));
                    }

                    parameterNode.put("AllowedValues", allowedValuesNode);
                } else {
                    error("Parameter %s is type %s, but has a AllowedValues specified. AllowedValues are only valid for String or Number parameters.", getParameterName(), type);
                }
            }
        }

        private void parseRangeConstraint(String type, TemplateValue defaultValue, ObjectNode parameterNode) {
            if (type.equals("Number")) {
                String minValueStr = ObjectUtils.toString(_currentNode.get("MinValue"), null);
                TemplateValue minValue = null;

                if (minValueStr != null) {
                    minValue = validateNumber("MinValue in parameter " + getParameterName(), minValueStr);
                    parameterNode.put("MinValue", minValueStr);
                }

                String maxValueStr = ObjectUtils.toString(_currentNode.get("MaxValue"), null);
                TemplateValue maxValue = null;

                if (maxValueStr != null) {
                    maxValue = validateNumber("MaxValue in parameter " + getParameterName(), maxValueStr);

                    if (minValue != null && minValue.numericValue != null && maxValue != null && maxValue.numericValue != null && minValue.numericValue.compareTo(maxValue.numericValue) > 0) {
                        error("MaxValue of %s exceeds MinValue of %s in parameter %s", maxValue, minValue, getParameterName());
                    }

                    parameterNode.put("MaxValue", maxValueStr);
                }

                if (minValue != null && minValue.numericValue != null && maxValue != null && maxValue.numericValue != null && defaultValue != null && defaultValue.numericValue != null) {
                    if (minValue.numericValue.compareTo(defaultValue.numericValue) > 0) {
                        error("Default value for parameter %s is %s, which is less than the MinValue constraint of %s.", getParameterName(), defaultValue, minValue);
                    } else if (maxValue.numericValue.compareTo(defaultValue.numericValue) < 0) {
                        error("Default value for parameter %s is %s, which is greater than the MaxValue constraint of %s.", getParameterName(), defaultValue, maxValue);
                    }
                }
            } else {
                if (_currentNode.containsKey("MinValue")) {
                    error("Parameter %s is type %s, but has a MinValue specified. MinValue and MaxValue are only valid for Number parameters.", getParameterName(), type);
                } else if (_currentNode.containsKey("MaxValue")) {
                    error("Parameter %s is type %s, but has a MaxValue specified. MinValue and MaxValue are only valid for Number parameters.", getParameterName(), type);
                }
            }
        }

        private void parseLengthConstraint(String type, TemplateValue defaultValue, ObjectNode parameterNode) {
            if (type.equals("String")) {
                String minLengthStr = ObjectUtils.toString(_currentNode.get("MinLength"), null);
                int minLength = 0;

                if (minLengthStr != null) {
                    minLength = validateInteger("MinLength in parameter " + getParameterName(), minLengthStr);
                    parameterNode.put("MinLength", minLengthStr);
                }

                String maxLengthStr = ObjectUtils.toString(_currentNode.get("MaxLength"), null);
                int maxLength = Integer.MAX_VALUE;

                if (maxLengthStr != null) {
                    maxLength = validateInteger("MaxLength in parameter " + getParameterName(), maxLengthStr);

                    if (maxLength >= 0 && minLength >= 0 && maxLength < minLength) {
                        error("MaxLength of %s exceeds MinLength of %s in parameter %s", maxLengthStr, minLengthStr, getParameterName());
                    }

                    parameterNode.put("MaxLength", maxLengthStr);
                }

                if (minLength >= 0 && maxLength >= 0 && defaultValue != null) {
                    if (defaultValue.stringValue.length() < minLength) {
                        error("Default value for parameter %s is %d characters, which is less than the MinLength constraint of %s.", getParameterName(), defaultValue.stringValue.length(), minLength);
                    } else if (defaultValue.stringValue.length() > maxLength) {
                        error("Default value for parameter %s is %d characters, which is greater than the MaxLength constraint of %s.", getParameterName(), defaultValue.stringValue.length(), maxLength);
                    }
                }
            } else {
                if (_currentNode.containsKey("MinLength")) {
                    error("Parameter %s is type %s, but has a MinLength specified. MinLength and MaxLength are only valid for String parameters.", getParameterName(), type);
                } else if (_currentNode.containsKey("MaxLength")) {
                    error("Parameter %s is type %s, but has a MaxLength specified. MinLength and MaxLength are only valid for String parameters.", getParameterName(), type);
                }
            }
        }

        private TemplateValue parseDefault(String type, ObjectNode parameterNode) {
            Object defaultObj = _currentNode.get("Default");
            TemplateValue defaultValue = null;

            if (defaultObj != null) {
                if (type.equals("Number")) {
                    defaultValue = validateNumber("Default for parameter " + getParameterName(), ObjectUtils.toString(defaultObj));
                    parameterNode.put("Default", defaultValue.stringValue);
                } else if (type.equals("CommaDelimitedList")) {
                    List<String> defaultList;

                    if (defaultObj instanceof Iterable) {
                        defaultList = buildList(Iterables.toArray((Iterable) defaultObj, Object.class));
                    } else if (defaultObj.getClass().isArray()) {
                        defaultList = buildList((Object[]) defaultObj);
                    } else {
                        defaultList = buildList(ObjectUtils.toString(defaultObj).split(","));
                    }

                    if (defaultList.size() > 0) {
                        defaultValue = new TemplateValue(StringUtils.join(defaultList, ", "));
                        parameterNode.put("Default", defaultValue.stringValue);
                    }
                } else {
                    String defaultStr = ObjectUtils.toString(defaultObj);
                    parameterNode.put("Default", defaultStr);
                    defaultValue = new TemplateValue(defaultStr);
                }
            }

            return defaultValue;
        }

        private List<String> buildList(Object[] values) {
            if (values == null || values.length == 0) {
                return emptyList();
            }

            List<String> buffer = newArrayList();

            for (int i = 0; i < values.length; ++i) {
                String valueStr = ObjectUtils.toString(values[i]).trim();

                if (valueStr.contains(",")) {
                    error("Element %d with value '%s' of Default for parameter %s contains a comma. Commas are the list delimiter and there is no way to escape a comma.", i, valueStr, getParameterName());
                }

                buffer.add(valueStr);
            }


            return buffer;
        }

        private void parseNoEcho(ObjectNode parameterNode) {
            Object noEcho = _currentNode.get("NoEcho");

            if (noEcho != null) {
                if (isEmpty(noEcho.toString())) {
                    warn("No value provided for NoEcho in parameter %s. Assuming false.", getParameterName());
                } else if (Boolean.TRUE.equals(noEcho) || "true".equalsIgnoreCase(noEcho.toString())) {
                    parameterNode.put("NoEcho", "TRUE");
                } else if (!Boolean.FALSE.equals(noEcho) && !"false".equalsIgnoreCase(noEcho.toString())) {
                    warn("Unexpected value %s for NoEcho in parameter %s. Assuming false.", noEcho, getParameterName());
                }
            }
        }
    }

    protected ObjectNode compile(Map<String, Object> data, List<CompileIssue> issues) {
        return new TemplateNodeCompiler(issues).compile(new NodePathEntry[0], data);
    }

    private static String findNearest(String value, Iterable<String> values) {
        String nearest = null;
        int distance = Integer.MAX_VALUE;

        for (String v : values) {
            int vd = StringUtils.getLevenshteinDistance(value, v, 6);

            if (vd >= 0 && vd < distance) {
                nearest = v;
                distance = vd;
            }
        }

        return nearest;
    }

    private static <T> Iterable<T> asIterable(final Iterator<T> iterator) {
        return new Iterable<T>() {
            @Override
            public Iterator<T> iterator() {
                return iterator;
            }
        };
    }
}
