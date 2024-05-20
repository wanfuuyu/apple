import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, info) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap",
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css",
  );

  const BaseSelect = {
    name: "BaseSelect",

    props: {
      label: {
        type: String,
        default: "",
      },
      selectClass: {
        type: String,
        default: "input",
      },
      modelValue: {
        type: String,
        default: "",
      },
      options: {
        type: Array,
        default: [],
        required: true,
      },
      required: {
        type: Boolean,
        default: false,
      },
      inline: {
        type: Boolean,
        default: false,
      },
      existent: {
        type: Boolean,
        default: false,
      },
      disabled: {
        type: Boolean,
        default: false,
      },
    },

    template: `
      <div v-bind:class="inline ? 'inline-field' : 'field'">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <select
          :value="modelValue"
          v-bind="$attrs"
          v-bind:disabled="disabled"
          @change="$emit('update:modelValue', $event.target.value)"
          v-bind:class="[selectClass, existent ? '' : 'nonexistent']"
        >
          <option
            v-for="option in options"
            :value="option.value"
            :key="option"
            :selected="option.value === modelValue"
          >{{ option.label }}</option>
        </select>
      </div>
      `,
  };

  const BaseInput = {
    name: "BaseInput",

    props: {
      label: {
        type: String,
        default: "",
      },
      inputClass: {
        type: String,
        default: "input",
      },
      modelValue: {
        type: [String, Number],
      },
      inline: {
        type: Boolean,
        default: false,
      },
      grow: {
        type: Boolean,
        default: false,
      },
      number: {
        type: Boolean,
        default: false,
      },
    },

    template: `
      <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <input
          :value="modelValue"
          @input="$emit('update:data', $event.target.value)"
          v-bind="$attrs"
          v-bind:class="[inputClass, number ? 'input-number' : '']"
        >
      </div>
      `,
  };

  const BaseSwitch = {
    name: "BaseSwitch",

    props: {
      label: {
        type: String,
        default: "",
      },
      modelValue: {
        type: Boolean,
        default: true,
      },
      inline: {
        type: Boolean,
        default: false,
      },
      grow: {
        type: Boolean,
        default: false,
      },
    },

    template: `
      <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <div class="input-container">
          <label class="switch-button">
            <input
              :checked="modelValue"
              type="checkbox"
              @input="$emit('update:modelValue', $event.target.checked)"
              v-bind="$attrs"
              class="switch-button-checkbox"
              v-bind:class="[inputClass, number ? 'input-number' : '']"
            >
            <div class="switch-button-bg" />
          </label>
        </div>
      </div>
      `,
  };

  const ToggleBox = {
    name: "ToggleBox",

    props: {
      toggle: {
        type: Boolean,
        default: true,
      },
    },

    template: `
      <div v-bind:class="toggle ? 'hidden' : ''">
        <slot></slot>
      </div>
      `,
  };
  const app = Vue.createApp({
    components: {
      BaseInput: BaseInput,
      BaseSelect: BaseSelect,
      BaseSwitch: BaseSwitch,
      ToggleBox: ToggleBox,
    },

    template: `
<div class="app">
		<div>
			<ToggleBox class="info-box" v-bind:toggle="isExchangeExists">
				<p>
					To 为了能正常发送消息，首先要创建 exchange 和相关的
					queue, 并将其绑定
				</p>
			</ToggleBox>
			<div class="header">
				<BaseSelect
                   @change="handleExchangeNameChange"
					name="exchange_name"
					label="EXCHANGE"
					v-model="exchange_name"
					selectClass="input input--md"
					:inline
					:options="availableExchanges"
				/>
				<BaseInput
                    @change="handleSendTimesChange"
					name="send_times"
					label="SEND TIMES"
                    number=true
                    type=number
					v-model.number="send_times"
					inputClass="input input--xs"
					:inline
				/>
				<BaseInput
                    @change="handleRoutingKeyChange"
					name="routing_key"
					label="routing_key"
					type="text"
					placeholder="routing_key"
					v-model="routing_key"
					inputClass="input input--xs"
					:inline
				/>

				<div class="grow"></div>
			</div>
		</div>
</div>
`,

    computed: {
      availableExchanges() {
        return this.exchanges.map((item) => ({
          label: item,
          value: item,
        }));
      },
    },
    data() {
      return {
        send_times: info.send_times,
        exchange_name: info.exchange_name,
        exchanges: info.exchanges,
        isExchangeExists: info.exchanges.length > 0,
      };
    },

    methods: {
      handleExchangeNameChange({ target: { value } }) {
        ctx.pushEvent("update_exchange_name", value);
      },
      handleSendTimesChange({ target: { value } }) {
        ctx.pushEvent("update_send_times", value);
      },
      handleRoutingKeyChange({ target: { value } }) {
        ctx.pushEvent("update_routing_key", value);
      },
    },
  }).mount(ctx.root);

  ctx.handleEvent("exchanges", ({ exchange_name, exchanges }) => {
    console.log("exchanges");
    console.log(exchange_name);
    console.log(exchanges);
    console.log("----");

    if (exchanges.length > 0) {
      app.isExchangeExists = true;
    } else {
      app.isExchangeExists = false;
    }
    app.exchanges = exchanges;
    app.exchange_name = exchange_name;
  });

  ctx.handleEvent("update_send_times", (send_times) => {
    console.log("get send_times");
    console.log(send_times);
    app.send_times = send_times;
  });

  ctx.handleEvent("update_exchange_name", (exchange_name) => {
    console.log("update_exchange_name");
    console.log(exchange_name);
    console.log("----");
    app.exchange_name = exchange_name;
  });
}
