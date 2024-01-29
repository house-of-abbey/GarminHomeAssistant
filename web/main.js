let api_url = localStorage.getItem('api_url') ?? '';
let menu_url = localStorage.getItem('menu_url') ?? '';
let api_token = localStorage.getItem('api_token') ?? '';

/**
 * Get all entities in HomeAssistant.
 * @returns {Promise<Record<string, string>>} [id, name]
 */
async function get_entities() {
  try {
    const res = await fetch(api_url + '/template', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${api_token}`,
      },
      mode: 'cors',
      body: `{"template":"[{% for entity in states %}[\\"{{ entity.entity_id }}\\",\\"{{ entity.name }}\\"]{% if not loop.last %},{% endif %}{% endfor %}]"}`,
    });
    if (res.status == 401 || res.status == 403) {
      document.querySelector('#api_token').classList.add('invalid');
      return {};
    }
    document.querySelector('#api_url').classList.remove('invalid');
    document.querySelector('#api_token').classList.remove('invalid');
    return Object.fromEntries(await res.json());
  } catch {
    document.querySelector('#api_url').classList.add('invalid');
    return {};
  }
}

/**
 * Get all devices in HomeAssistant.
 * @returns {Promise<Record<string, string>>} [id, name]
 */
async function get_devices() {
  try {
    const res = await fetch(api_url + '/template', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${api_token}`,
      },
      mode: 'cors',
      body: `{"template":"{% set devices = states | map(attribute='entity_id') | map('device_id') | unique | reject('eq', None) | list %}[{% for device in devices %}[\\"{{ device }}\\",\\"{{ device_attr(device, 'name') }}\\"]{% if not loop.last %},{% endif %}{% endfor %}]"}`,
    });
    if (res.status == 401 || res.status == 403) {
      document.querySelector('#api_token').classList.add('invalid');
      return {};
    }
    document.querySelector('#api_url').classList.remove('invalid');
    document.querySelector('#api_token').classList.remove('invalid');
    return Object.fromEntries(await res.json());
  } catch {
    document.querySelector('#api_url').classList.add('invalid');
    return {};
  }
}

/**
 * Get all areas in HomeAssistant.
 * @returns {Promise<Record<string, string>>} [id, name]
 */
async function get_areas() {
  try {
    const res = await fetch(api_url + '/template', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${api_token}`,
      },
      mode: 'cors',
      body: `{"template":"[{% for area in areas() %}[\\"{{ area }}\\",\\"{{ area_name(area) }}\\"]{% if not loop.last %},{% endif %}{% endfor %}]"}`,
    });
    if (res.status == 401 || res.status == 403) {
      document.querySelector('#api_token').classList.add('invalid');
      return {};
    }
    document.querySelector('#api_url').classList.remove('invalid');
    document.querySelector('#api_token').classList.remove('invalid');
    return Object.fromEntries(await res.json());
  } catch {
    document.querySelector('#api_url').classList.add('invalid');
    return {};
  }
}

/**
 * Get all services in HomeAssistant.
 * @returns {Promise<[string, { name: string; description: string; fields:
 *     Record<string, { name: string; description: string; example: string;
 *     selector: unknown; required?: boolean }> }][]>} [id, data]
 */
async function get_services() {
  try {
    const res = await fetch(api_url + '/services', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${api_token}`,
      },
      mode: 'cors',
    });
    if (res.status == 401 || res.status == 403) {
      document.querySelector('#api_token').classList.add('invalid');
      return {};
    }
    document.querySelector('#api_url').classList.remove('invalid');
    document.querySelector('#api_token').classList.remove('invalid');
    const data = await res.json();
    const services = [];
    for (const d of data) {
      for (const service in d.services) {
        services.push([`${d.domain}.${service}`, d.services[service]]);
      }
    }
    return services;
  } catch {
    document.querySelector('#api_url').classList.add('invalid');
    return [];
  }
}

/**
 * Get schema from GitHub.
 * @returns {Promise<{}>}
 */
async function get_schema() {
  const res = await fetch(
    'https://raw.githubusercontent.com/house-of-abbey/GarminHomeAssistant/main/config.schema.json'
  );
  return res.json();
}

/**
 * Generate schema for HomeAssistant.
 * @param {Record<string, string>} entities
 * @param {Record<string, string>} devices
 * @param {Record<string, string>} areas
 * @param {[string, { name: string; description: string; fields:
 *     Record<string, { name: string; description: string; example: string;
 *     selector: unknown; required?: boolean }> }][]} services
 * @param {{}} schema
 * @returns {Promise<{}>}
 */
async function generate_schema(entities, devices, areas, services, schema) {
  schema.$defs.entity = {
    enum: Object.keys(entities),
  };
  schema.$defs.device = {
    enum: Object.keys(devices),
  };
  schema.$defs.area = {
    enum: Object.keys(areas),
  };

  const oneOf = [];
  for (const [id, data] of services) {
    const i_properties = {
      service: {
        title: data.name,
        description: data.description,
        const: id,
      },
      data: {
        type: 'object',
        properties: {},
        additionalProperties: false,
      },
    };
    const required = [];
    for (const [field, f] of Object.entries(data.fields)) {
      i_properties.data.properties[field] = {
        title: f.name,
        description: f.description,
        example: f.example,
      };
      if (f.required) {
        required.push(field);
      }

      const selector = f.selector;
      if (selector) {
        if (Object.hasOwn(selector, 'action')) {
          i_properties.data.properties[field].type = 'array';
          i_properties.data.properties[field].items = {
            $ref: '#/$defs/tap_action',
          };
        } else if (Object.hasOwn(selector, 'area')) {
          if (selector.area?.multiple) {
            i_properties.data.properties[field].type = 'array';
            i_properties.data.properties[field].items = {
              $ref: '#/$defs/area',
            };
          } else {
            i_properties.data.properties[field].$ref = '#/$defs/area';
          }
        } else if (Object.hasOwn(selector, 'boolean')) {
          i_properties.data.properties[field].type = 'boolean';
        } else if (Object.hasOwn(selector, 'number')) {
          i_properties.data.properties[field].type = 'number';
          i_properties.data.properties[field].minimum = selector.number?.min;
          i_properties.data.properties[field].maximum = selector.number?.max;
          i_properties.data.properties[field].multipleOf =
            selector.number?.step;
        } else if (Object.hasOwn(selector, 'color_temp')) {
          i_properties.data.properties[field].type = 'number';
          i_properties.data.properties[field].minimum =
            selector.color_temp?.min;
          i_properties.data.properties[field].maximum =
            selector.color_temp?.max;
          i_properties.data.properties[field].multipleOf =
            selector.color_temp?.step;
        } else if (Object.hasOwn(selector, 'date')) {
          i_properties.data.properties[field].type = 'string';
          i_properties.data.properties[field].pattern =
            '^\\d{4}-\\d{2}-\\d{2}$';
        } else if (Object.hasOwn(selector, 'datetime')) {
          i_properties.data.properties[field].type = 'string';
          i_properties.data.properties[field].pattern =
            '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}(\\:\\d{2})?$';
        } else if (Object.hasOwn(selector, 'time')) {
          i_properties.data.properties[field].type = 'string';
          i_properties.data.properties[field].pattern =
            '^\\d{2}:\\d{2}(\\:\\d{2})?$';
        } else if (Object.hasOwn(selector, 'device')) {
          if (selector.device?.multiple) {
            i_properties.data.properties[field].type = 'array';
            i_properties.data.properties[field].items = {
              $ref: '#/$defs/device',
            };
          } else {
            i_properties.data.properties[field].$ref = '#/$defs/device';
          }
        } else if (Object.hasOwn(selector, 'entity')) {
          if (selector.entity?.multiple) {
            i_properties.data.properties[field].type = 'array';
            i_properties.data.properties[field].items = {
              $ref: '#/$defs/entity',
            };
          } else {
            i_properties.data.properties[field].$ref = '#/$defs/entity';
          }
        } else if (Object.hasOwn(selector, 'icon')) {
          i_properties.data.properties[field].type = 'string';
          i_properties.data.properties[field].pattern = '^[^.]+:[^.]+$';
        } else if (Object.hasOwn(selector, 'location')) {
          i_properties.data.properties[field].type = 'object';
          i_properties.data.properties[field].properties = {
            longitude: {
              type: 'number',
            },
            latitude: {
              type: 'number',
            },
            radius: {
              type: 'number',
              minimum: 0,
            },
          };
        } else if (Object.hasOwn(selector, 'color_rgb')) {
          i_properties.data.properties[field].type = 'array';
          i_properties.data.properties[field].prefixItems = [
            {
              type: 'number',
              minimum: 0,
              maximum: 255,
              multipleOf: 1,
            },
            {
              type: 'number',
              minimum: 0,
              maximum: 255,
              multipleOf: 1,
            },
            {
              type: 'number',
              minimum: 0,
              maximum: 255,
              multipleOf: 1,
            },
          ];
        } else if (Object.hasOwn(selector, 'select')) {
          const oneOf2 = [];
          if (selector.select?.options) {
            for (let o of selector.select.options) {
              if (typeof o == 'string') {
                oneOf2.push({
                  const: o,
                });
              } else {
                oneOf2.push({
                  const: o.value || '',
                });
              }
            }
          }
          if (selector.select?.custom) {
            oneOf2.push({
              type: 'string',
            });
          }
          if (selector.select?.multiple) {
            i_properties.data.properties[field].type = 'array';
            i_properties.data.properties[field].items = {
              oneOf: oneOf2,
            };
          } else {
            i_properties.data.properties[field].oneOf = oneOf2;
          }
        } else if (Object.hasOwn(selector, 'state' in selector || 'template')) {
          i_properties.data.properties[field].type = 'string';
        } else if (Object.hasOwn(selector, 'text')) {
          let pattern;
          const p = selector.text?.type;
          if (p == 'color') {
            pattern = '^#[0-9a-fA-F]{6}$';
          } else if (p == 'date') {
            pattern = '^\\d{4}-\\d{2}-\\d{2}$';
          } else if (p == 'datetime-local') {
            pattern = '^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$';
          } else if (p == 'email') {
            pattern =
              '^([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x22([^\\x0d\\x22\\x5c\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x22)(\\x2e([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x22([^\\x0d\\x22\\x5c\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x22))*\\x40([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x5b([^\\x0d\\x5b-\\x5d\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x5d)(\\x2e([^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+|\\x5b([^\\x0d\\x5b-\\x5d\\x80-\\xff]|\\x5c[\\x00-\\x7f])*\\x5d))*$';
          } else if (p == 'month') {
            pattern = '^\\d{4}-\\d{2}$';
          } else if (p == 'number') {
            pattern = '^d*.?d+$';
          } else if (p == 'time') {
            pattern = '^\\d{2}:\\d{2}$';
          } else if (p == 'url') {
            pattern =
              "^[a-z](?:[-a-z0-9\\+\\.])*:(?:\\/\\/(?:(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD])*@)?(?:\\[(?:(?:(?:[0-9a-f]{1,4}:){6}(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|::(?:[0-9a-f]{1,4}:){5}(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|(?:[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){4}(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|(?:[0-9a-f]{1,4}:[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){3}(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|(?:(?:[0-9a-f]{1,4}:){0,2}[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:){2}(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|(?:(?:[0-9a-f]{1,4}:){0,3}[0-9a-f]{1,4})?::[0-9a-f]{1,4}:(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|(?:(?:[0-9a-f]{1,4}:){0,4}[0-9a-f]{1,4})?::(?:[0-9a-f]{1,4}:[0-9a-f]{1,4}|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3})|(?:(?:[0-9a-f]{1,4}:){0,5}[0-9a-f]{1,4})?::[0-9a-f]{1,4}|(?:(?:[0-9a-f]{1,4}:){0,6}[0-9a-f]{1,4})?::)|v[0-9a-f]+[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:]+)\\]|(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(?:\\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}|(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD])*)(?::[0-9]*)?(?:\\/(?:(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD]))*)*|\\/(?:(?:(?:(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD]))+)(?:\\/(?:(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD]))*)*)?|(?:(?:(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD]))+)(?:\\/(?:(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD]))*)*|(?!(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD])))(?:\\?(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\/\\?\\xA0-\\uD7FF\\uE000-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E\\uDB80-\\uDBBE\\uDBC0-\\uDBFE][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F\\uDBBF\\uDBFF][\\uDC00-\\uDFFD])*)?(?:\\#(?:%[0-9a-f][0-9a-f]|[-a-z0-9\\._~!\\$&'\\(\\)\\*\\+,;=:@\\/\\?\\xA0-\\uD7FF\\uF900-\\uFDCF\\uFDF0-\\uFFEF]|[\\uD800-\\uD83E\\uD840-\\uD87E\\uD880-\\uD8BE\\uD8C0-\\uD8FE\\uD900-\\uD93E\\uD940-\\uD97E\\uD980-\\uD9BE\\uD9C0-\\uD9FE\\uDA00-\\uDA3E\\uDA40-\\uDA7E\\uDA80-\\uDABE\\uDAC0-\\uDAFE\\uDB00-\\uDB3E\\uDB44-\\uDB7E][\\uDC00-\\uDFFF]|[\\uD83F\\uD87F\\uD8BF\\uD8FF\\uD93F\\uD97F\\uD9BF\\uD9FF\\uDA3F\\uDA7F\\uDABF\\uDAFF\\uDB3F\\uDB7F][\\uDC00-\\uDFFD])*)?$";
          } else if (p == 'week') {
            pattern = '^\\d{4}-W\\d{2}$';
          }
          if (selector.text?.multiple) {
            i_properties.data.properties[field].type = 'array';
            i_properties.data.properties[field].items = {
              type: 'string',
              pattern: pattern,
            };
          } else {
            i_properties.data.properties[field].type = 'string';
            i_properties.data.properties[field].pattern = pattern;
          }
        }
      }
      if (required.length > 0) {
        i_properties.data.required = required;
      }
    }
    oneOf.push({
      title: data.name,
      description: data.description,
      properties: i_properties,
    });
  }
  schema.$defs.tap_action = {
    type: 'object',
    oneOf: oneOf,
    properties: {
      service: {
        type: 'string',
      },
      confirm: {
        $ref: '#/$defs/confirm',
      },
      data: {
        type: 'object',
        properties: {},
      },
    },
  };
  delete schema.$defs.tap.properties.service;
  delete schema.$schema;

  return schema;
}

function get(d, p) {
  for (let i = 0; i < p.length; i++) {
    d = d[p[i]];
  }
  return d;
}

/**
 * @param {{ text: string; color: string }} options
 */
function toast({ text, color }) {
  const t = Toastify({
    text,
    gravity: 'bottom', // `top` or `bottom`
    position: 'right', // `left`, `center` or `right`
    stopOnFocus: true, // Prevents dismissing of toast on hover
    // close: true,
    style: {
      background: 'var(--ctp-mocha-base)',
      outline: '1px solid ' + (color ?? 'var(--ctp-mocha-blue)'),
    },
  });
  t.showToast();
  return t;
}

/** @type {Awaited<ReturnType<typeof get_entities>>} */
let entities;
/** @type {Awaited<ReturnType<typeof get_devices>>} */
let devices;
/** @type {Awaited<ReturnType<typeof get_areas>>} */
let areas;
/** @type {Awaited<ReturnType<typeof get_services>>} */
let services;
let schema;
async function loadSchema() {
  [entities, devices, areas, services, schema] = await Promise.all([
    get_entities(),
    get_devices(),
    get_areas(),
    get_services(),
    get_schema(),
  ]);
  if (window.makeMarkers) {
    window.makeMarkers();
  }
  try {
    schema = await generate_schema(entities, devices, areas, services, schema);
  } catch {}
  console.log(schema);
  if (window.m && window.modelUri) {
    // configure the JSON language support with schemas and schema associations
    window.m.languages.json.jsonDefaults.setDiagnosticsOptions({
      validate: true,
      schemas: [
        {
          uri: 'https://raw.githubusercontent.com/house-of-abbey/GarminHomeAssistant/main/config.schema.json',
          fileMatch: [window.modelUri.toString()],
          schema,
        },
      ],
    });
  }
}
loadSchema();

// require is provided by loader.min.js.
require.config({
  paths: {
    vs: 'https://unpkg.com/monaco-editor@0.45.0/min/vs',
  },
});
require(['vs/editor/editor.main'], async () => {
  window.m = monaco;
  var modelUri = monaco.Uri.parse('/config/www/garmin/menu.json'); // a made up unique URI for our model
  window.modelUri = modelUri;

  if (schema) {
    // configure the JSON language support with schemas and schema associations
    monaco.languages.json.jsonDefaults.setDiagnosticsOptions({
      validate: true,
      schemas: [
        {
          uri: 'https://raw.githubusercontent.com/house-of-abbey/GarminHomeAssistant/main/config.schema.json',
          fileMatch: [modelUri.toString()],
          schema,
        },
      ],
    });
  }

  document.querySelector('#api_url').value = api_url;
  document.querySelector('#menu_url').value = menu_url;
  document.querySelector('#api_token').value = api_token;

  document.querySelector('#troubleshooting').addEventListener('click', (e) => {
    document.querySelector('#troubleshooting-dialog').showModal();
  });

  document.querySelector('#test-api').addEventListener('click', async (e) => {
    try {
      document.querySelector('#test-api-response').innerText = 'Testing...';
      const res = await fetch(api_url + '/', {
        headers: {
          Authorization: `Bearer ${api_token}`,
        },
        cache: 'no-cache',
        mode: 'cors',
      });
      const text = await res.text();
      if (res.status == 200) {
        document.querySelector('#test-api-response').innerText =
          JSON.parse(text).message;
        document.querySelector('#api_token').classList.remove('invalid');
        document.querySelector('#api_url').classList.remove('invalid');
      } else if (res.status == 400) {
        document.querySelector('#api_url').classList.add('invalid');
        try {
          document.querySelector('#test-api-response').innerText =
            JSON.parse(text).message;
        } catch {
          document.querySelector('#test-api-response').innerText = text;
        }
      } else if (res.status == 401 || res.status == 403) {
        document.querySelector('#api_token').classList.add('invalid');
        document.querySelector('#test-api-response').innerText =
          'Invalid token.';
      } else {
        document.querySelector('#test-api-response').innerText = text;
      }
    } catch (e) {
      document.querySelector('#test-api-response').innerText =
        'Check CORS settings on HomeAssistant server.';
      document.querySelector('#api_token').classList.add('invalid');
    }
  });
  document.querySelector('#test-menu').addEventListener('click', async (e) => {
    try {
      document.querySelector('#test-menu-response').innerText = 'Testing...';
      const res = await fetch(menu_url, {
        cache: 'no-cache',
        mode: 'cors',
      });
      if (res.status == 200) {
        document.querySelector('#menu_url').classList.remove('invalid');
        document.querySelector('#test-menu-response').innerText = 'Available';
      } else if (res.status == 400) {
        document.querySelector('#menu_url').classList.add('invalid');
        document.querySelector('#test-menu-response').innerText =
          await res.text();
      } else {
        document.querySelector('#menu_url').classList.add('invalid');
        document.querySelector('#test-menu-response').innerText =
          await res.text();
      }
    } catch (e) {
      document.querySelector('#menu_url').classList.add('invalid');
      document.querySelector('#test-menu-response').innerText =
        'Check CORS settings on HomeAssistant server.';
    }
  });
  document.querySelector('#download').addEventListener('click', async (e) => {
    try {
      const t = toast({
        text: 'Downloading...',
      });
      const res = await fetch(menu_url, {
        cache: 'no-cache',
        mode: 'cors',
      });
      t.hideToast();
      if (res.status == 200) {
        document.querySelector('#menu_url').classList.remove('invalid');
        const text = await res.text();
        model.setValue(text);
        toast({
          text: 'Downloaded!',
          color: 'var(--ctp-mocha-green)',
        });
      } else {
        document.querySelector('#menu_url').classList.add('invalid');
        toast({
          text: await res.text(),
          color: 'var(--ctp-mocha-red)',
        });
      }
    } catch (e) {
      toast({
        text: 'Check CORS settings on HomeAssistant server.',
        color: 'var(--ctp-mocha-red)',
      });
      document.querySelector('#menu_url').classList.add('invalid');
    }
  });
  document.querySelector('#copy').addEventListener('click', async (e) => {
    navigator.clipboard.writeText(model.getValue());
    toast({
      text: 'Copied!',
      color: 'var(--ctp-mocha-green)',
    });
  });

  document.querySelector('#api_url').addEventListener('change', (e) => {
    api_url = e.target.value;
    localStorage.setItem('api_url', api_url);
    document.querySelector('#test-api-response').innerText = 'Check now!';
    loadSchema();
  });
  document.querySelector('#menu_url').addEventListener('change', (e) => {
    menu_url = e.target.value;
    localStorage.setItem('menu_url', menu_url);
    document.querySelector('#test-menu-response').innerText = 'Check now!';
    checkRemoteMenu();
  });
  document.querySelector('#api_token').addEventListener('change', (e) => {
    api_token = e.target.value;
    localStorage.setItem('api_token', api_token);
    document.querySelector('#api_token').classList.remove('invalid');
    document.querySelector('#test-api-response').innerText = 'Check now!';
    loadSchema();
  });
  checkRemoteMenu();

  async function checkRemoteMenu() {
    if (menu_url != '') {
      try {
        const remote = await fetch(menu_url, {
          cache: 'no-cache',
          mode: 'cors',
        });
        if (remote.status == 200) {
          document.querySelector('#menu_url').classList.remove('invalid');
          document.querySelector('#download').disabled = false;
          const text = await remote.text();
          if (model.getValue() === text) {
            document.querySelector('#menu_url').classList.remove('outofsync');
          } else {
            document.querySelector('#menu_url').classList.add('outofsync');
          }
        } else {
          document.querySelector('#menu_url').classList.add('invalid');
          document.querySelector('#download').disabled = true;
        }
      } catch {
        document.querySelector('#menu_url').classList.add('invalid');
        document.querySelector('#download').disabled = true;
      }
    } else {
      document.querySelector('#menu_url').classList.remove('invalid');
      document.querySelector('#download').disabled = true;
    }
  }

  setInterval(checkRemoteMenu, 30000);

  var model = monaco.editor.createModel(
    localStorage.getItem('json') ?? '{}',
    'json',
    modelUri
  );

  monaco.editor.defineTheme(
    'mocha',
    await fetch(
      'https://josephabbey.github.io/catppuccin-monaco/mocha.json'
    ).then((r) => r.json())
  );

  monaco.languages.registerCompletionItemProvider('json', {
    triggerCharacters: ['.'],
    provideCompletionItems: function (model, position) {
      // find out if we are completing a property in the 'dependencies' object.
      var textUntilPosition = model.getValueInRange({
        startLineNumber: 1,
        startColumn: 1,
        endLineNumber: position.lineNumber,
        endColumn: position.column,
      });
      var match = /"content"\s*:\s*"[^"]*[^\w]?\w+\.[^.\s{}()[\]'"]*$/.test(
        textUntilPosition
      );
      if (!match) {
        return { suggestions: [] };
      }
      var word = model.getWordUntilPosition(position);
      let i = word.word.length - 1;
      while (word.word[i] != '.') {
        i--;
      }
      do {
        i--;
      } while (
        i >= 0 &&
        (word.word[i] == '_' ||
          word.word[i].toUpperCase() != word.word[i].toLowerCase())
      );
      i++;
      var range = {
        startLineNumber: position.lineNumber,
        endLineNumber: position.lineNumber,
        startColumn: word.startColumn + i,
        endColumn: word.endColumn,
      };
      return {
        suggestions: Object.entries(entities).map(([entity, name]) => ({
          label: entity,
          kind: monaco.languages.CompletionItemKind.Variable,
          documentation: name,
          insertText: entity,
          range,
        })),
      };
    },
  });

  const editor = monaco.editor.create(document.getElementById('container'), {
    model: model,
    theme: 'mocha',
    automaticLayout: true,
    glyphMargin: true,
  });

  window.addEventListener('keydown', (e) => {
    if (e.key == 's' && e.ctrlKey) {
      e.preventDefault();
      model.setValue(
        JSON.stringify(JSON.parse(editor.getValue()), undefined, 2) + '\n'
      );
    }
  });

  var decorations = editor.createDecorationsCollection([]);

  let markers = [];

  const renderTemplate = editor.addCommand(
    0,
    async function (_, template) {
      const t = toast({
        text: 'Rendering template...',
      });
      try {
        const res = await fetch(api_url + '/template', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${api_token}`,
          },
          mode: 'cors',
          body: `{"template":"${template}"}`,
        });
        t.hideToast();
        if (res.status == 200) {
          toast({
            text: await res.text(),
            color: 'var(--ctp-mocha-green)',
          });
        } else if (res.status == 400) {
          toast({
            text: (await res.json()).message,
            color: 'var(--ctp-mocha-red)',
          });
        } else if (res.status == 401 || res.status == 403) {
          document.querySelector('#api_token').classList.add('invalid');
        } else {
          toast({
            text: await res.text(),
            color: 'var(--ctp-mocha-red)',
          });
        }
      } catch (e) {
        t.hideToast();
        toast({
          text: 'Check CORS settings on HomeAssistant server.',
          color: 'var(--ctp-mocha-red)',
        });
        document.querySelector('#api_url').classList.add('invalid');
      }
    },
    ''
  );

  const runAction = editor.addCommand(
    0,
    async function (_, action) {
      const service = action.tap_action.service.split('.');
      let data = action.tap_action.data;
      if (data) {
        data.entity_id = action.entity;
      } else {
        data = {
          entity_id: action.entity,
        };
      }
      const t = toast({
        text: 'Running action...',
      });
      try {
        const res = await fetch(
          api_url + '/services/' + service[0] + '/' + service[1],
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${api_token}`,
            },
            mode: 'cors',
            body: JSON.stringify(data),
          }
        );
        t.hideToast();
        if (res.status == 200) {
          toast({
            text: 'Success',
            color: 'var(--ctp-mocha-green)',
          });
        } else if (res.status == 400) {
          const text = await res.text();
          try {
            toast({
              text: JSON.parse(text).message,
              color: 'var(--ctp-mocha-red)',
            });
          } catch {
            toast({
              text: text,
              color: 'var(--ctp-mocha-red)',
            });
          }
        } else if (res.status == 401 || res.status == 403) {
          document.querySelector('#api_token').classList.add('invalid');
        } else {
          toast({
            text: await res.text(),
            color: 'var(--ctp-mocha-red)',
          });
        }
        makeMarkers();
      } catch (e) {
        t.hideToast();
        toast({
          text: 'Check CORS settings on HomeAssistant server.',
          color: 'var(--ctp-mocha-red)',
        });
        document.querySelector('#api_url').classList.add('invalid');
      }
    },
    ''
  );

  const toggle = editor.addCommand(
    0,
    async function (_, item) {
      const entity = item.entity.split('.');
      const t = toast({
        text: 'Toggling...',
      });
      try {
        const res = await fetch(
          api_url + '/services/' + entity[0] + '/toggle',
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${api_token}`,
            },
            mode: 'cors',
            body: JSON.stringify({
              entity_id: item.entity,
            }),
          }
        );
        t.hideToast();
        if (res.status == 200) {
          toast({
            text: 'Success',
            color: 'var(--ctp-mocha-green)',
          });
        } else if (res.status == 400) {
          const text = await res.text();
          try {
            toast({
              text: JSON.parse(text).message,
              color: 'var(--ctp-mocha-red)',
            });
          } catch {
            toast({
              text: text,
              color: 'var(--ctp-mocha-red)',
            });
          }
        } else if (res.status == 401 || res.status == 403) {
          document.querySelector('#api_token').classList.add('invalid');
        } else {
          toast({
            text: await res.text(),
            color: 'var(--ctp-mocha-red)',
          });
        }
        makeMarkers();
      } catch (e) {
        t.hideToast();
        toast({
          text: 'Check CORS settings on HomeAssistant server.',
          color: 'var(--ctp-mocha-red)',
        });
        document.querySelector('#api_url').classList.add('invalid');
      }
    },
    ''
  );

  async function makeMarkers() {
    try {
      const ast = json.parse(model.getValue());
      const data = JSON.parse(model.getValue());
      markers = [];
      const glyphs = [];
      async function testToggle(range, entity) {
        const res = await fetch(api_url + '/states/' + entity, {
          method: 'GET',
          headers: {
            Authorization: `Bearer ${api_token}`,
          },
          mode: 'cors',
        });
        const d = await res.json();
        if (d.state == 'on') {
          decorations.append([
            {
              range,
              options: {
                isWholeLine: true,
                glyphMarginClassName: 'toggle_on',
              },
            },
          ]);
        } else {
          decorations.append([
            {
              range,
              options: {
                isWholeLine: true,
                glyphMarginClassName: 'toggle_off',
              },
            },
          ]);
        }
      }
      const toggles = [];
      async function testTemplate(range, template) {
        const l = model.getValueInRange(range);
        let trim = 0;
        while (trim < l.length && l[trim] == ' ') {
          trim++;
        }
        trim++;
        const res = await fetch(api_url + '/template', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${api_token}`,
          },
          mode: 'cors',
          body: `{"template":"${template}"}`,
        });
        if (res.status == 200) {
          markers.push({
            message: await res.text(),
            severity: monaco.MarkerSeverity.Info,
            ...range,
            startColumn: trim,
          });
        } else if (res.status == 400) {
          markers.push({
            message: (await res.json()).message,
            severity: monaco.MarkerSeverity.Error,
            ...range,
            startColumn: trim,
          });
        } else if (res.status == 401 || res.status == 403) {
          document.querySelector('#api_token').classList.add('invalid');
        } else {
          markers.push({
            message: res.statusText,
            severity: monaco.MarkerSeverity.Error,
            ...range,
            startColumn: trim,
          });
        }
      }
      const templates = [];
      /**
       * @param {import('json-ast-comments').JsonAst |
       *     import('json-ast-comments').JsonProperty} node
       * @param {string[]} path
       */
      function recurse(node, path) {
        if (node.type === 'property') {
          if (node.key[0].value === 'content') {
            templates.push([
              {
                startLineNumber: node.key[0].range.start.line + 1,
                startColumn: 0,
                endLineNumber: node.value[0].range.end.line + 1,
                endColumn: 10000,
              },
              node.value[0].value,
            ]);
          } else if (entities != null && node.key[0].value === 'entity') {
            const range = {
              startLineNumber: node.key[0].range.start.line + 1,
              startColumn: 0,
              endLineNumber: node.value[0].range.end.line + 1,
              endColumn: 10000,
            };
            const l = model.getValueInRange(range);
            let trim = 0;
            while (trim < l.length && l[trim] == ' ') {
              trim++;
            }
            trim++;
            markers.push({
              message: entities[node.value[0].value] ?? 'Entity not found',
              severity: monaco.MarkerSeverity.Hint,
              ...range,
              startColumn: trim,
            });
          } else if (node.key[0].value === 'type') {
            if (node.value[0].value === 'toggle') {
              toggles.push([
                {
                  startLineNumber: node.key[0].range.start.line + 1,
                  startColumn: 0,
                  endLineNumber: node.value[0].range.end.line + 1,
                  endColumn: 10000,
                },
                get(data, path).entity,
              ]);
            } else {
              glyphs.push({
                range: {
                  startLineNumber: node.key[0].range.start.line + 1,
                  startColumn: 0,
                  endLineNumber: node.value[0].range.end.line + 1,
                  endColumn: 10000,
                },
                options: {
                  isWholeLine: true,
                  glyphMarginClassName: node.value[0].value,
                },
              });
            }
          } else {
            recurse(node.value[0], [...path, node.key[0].value]);
          }
        } else if (node.type === 'array') {
          for (let i = 0; i < node.members.length; i++) {
            recurse(node.members[i], [...path, i]);
          }
        } else if (node.type === 'object') {
          for (let member of node.members) {
            recurse(member, path);
          }
        }
      }
      recurse(ast.body[0], []);
      decorations.clear();
      decorations.append(glyphs);
      await Promise.all(templates.map((t) => testTemplate(...t)));
      toggles.forEach((t) => testToggle(...t));
      monaco.editor.setModelMarkers(model, 'template', markers);
    } catch {}
  }
  window.makeMarkers = makeMarkers;
  makeMarkers();

  model.onDidChangeContent(async function () {
    localStorage.setItem('json', model.getValue());
    makeMarkers();
  });

  monaco.languages.registerCodeLensProvider('json', {
    provideCodeLenses: function (model, token) {
      const lenses = [];
      try {
        const ast = json.parse(model.getValue());
        const data = JSON.parse(model.getValue());
        /**
         * @param {import('json-ast-comments').JsonAst |
         *     import('json-ast-comments').JsonProperty} node
         * @param {string[]} path
         */
        function recurse(node, path) {
          if (node.type === 'property') {
            if (node.key[0].value === 'tap_action') {
              const d = get(data, path);
              if (d.tap_action.service) {
                lenses.push({
                  range: {
                    startLineNumber: node.key[0].range.start.line + 1,
                    startColumn: 0,
                    endLineNumber: node.key[0].range.start.line + 1,
                    endColumn: 0,
                  },
                  id: Math.random().toString(36).substring(7),
                  command: {
                    id: runAction,
                    title: 'Run Action',
                    arguments: [d],
                  },
                });
              } else {
                recurse(node.value[0], [...path, node.key[0].value]);
              }
            } else if (node.key[0].value === 'content') {
              lenses.push({
                range: {
                  startLineNumber: node.key[0].range.start.line + 1,
                  startColumn: 0,
                  endLineNumber: node.key[0].range.start.line + 1,
                  endColumn: 0,
                },
                id: Math.random().toString(36).substring(7),
                command: {
                  id: renderTemplate,
                  title: 'Render Template',
                  arguments: [node.value[0].value],
                },
              });
            } else if (
              node.key[0].value === 'type' &&
              node.value[0].value === 'toggle'
            ) {
              lenses.push({
                range: {
                  startLineNumber: node.key[0].range.start.line + 1,
                  startColumn: 0,
                  endLineNumber: node.key[0].range.start.line + 1,
                  endColumn: 0,
                },
                id: Math.random().toString(36).substring(7),
                command: {
                  id: toggle,
                  title: 'Toggle',
                  arguments: [get(data, path)],
                },
              });
            } else {
              recurse(node.value[0], [...path, node.key[0].value]);
            }
          } else if (node.type === 'array') {
            for (let i = 0; i < node.members.length; i++) {
              recurse(node.members[i], [...path, i]);
            }
          } else if (node.type === 'object') {
            for (let member of node.members) {
              recurse(member, path);
            }
          }
        }
        recurse(ast.body[0], []);
      } catch {}
      return {
        lenses,
        dispose: () => {},
      };
    },
    resolveCodeLens: function (model, codeLens, token) {
      return codeLens;
    },
  });
});
