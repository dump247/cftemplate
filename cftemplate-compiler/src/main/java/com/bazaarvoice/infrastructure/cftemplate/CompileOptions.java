package com.bazaarvoice.infrastructure.cftemplate;

import java.util.Map;

import static com.google.common.base.Preconditions.checkNotNull;
import static com.google.common.collect.Maps.newHashMap;

/**
 * Options to compile a CloudFormation template.
 */
public class CompileOptions {
    private Map<String, Object> _parameters;
    private Map<String, Object> _options;

    /**
     * Get the parameters to override in the compiled templates.
     *
     * @return parameter value overrides
     */
    public Map<String, Object> getParameters() {
        if (_parameters == null) {
            _parameters = newHashMap();
        }

        return _parameters;
    }

    /**
     * Set the parameters to override in the compiled template.
     * <p/>
     * If the parameter exists in the compiled template, it's default value is
     * set to the value provided by this map. An error will result if the types
     * do not match. If the parameter does not exist, the override is ignored.
     *
     * @param parameters parameter value overrides
     */
    public void setParameters(Map<String, Object> parameters) {
        _parameters = checkNotNull(parameters);
    }

    /**
     * Get options used to control compiled output.
     *
     * @return compile time options
     */
    public Map<String, Object> getOptions() {
        return _options;
    }

    /**
     * Set options used to control the compiled output.
     *
     *
     * @param options
     */
    public void setOptions(Map<String, Object> options) {
        _options = options;
    }
}
