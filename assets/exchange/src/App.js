import React, { useEffect, useRef, useState } from "react";
import { RiAddLine, RiDeleteBinLine } from "@remixicon/react";
import classNames from "classnames";

export default function App({ ctx, payload }) {
  const [exchangeName, setExchangeName] = useState(payload.exchange_name);
  const [exchangeType, setExchangeType] = useState(payload.exchange_type);
  const [queues, setQueues] = useState(payload.queues);

  const exchangeTypeOption = [
    { value: "direct", label: "Direct" },
    { value: "fanout", label: "Fanout" },
    { value: "topic", label: "Topic" },
  ];

  const handleUpdateExchangeType = (exchange_type) => {
    ctx.pushEvent("update_exchange_type", exchange_type);
  };

  const handleUpdateExchangeName = (exchange_name) => {
    ctx.pushEvent("update_exchange_name", exchange_name);
  };

  const handleAddQueue = () => {
    ctx.pushEvent("add_queue");
  };

  useEffect(() => {
    ctx.handleEvent("update_exchange_type", (exchange_type) => {
      setExchangeType(exchange_type);
    });

    ctx.handleEvent("update_exchange_name", (exchange_name) => {
      setExchangeName(exchange_name);
    });

    ctx.handleEvent("set_queues", (queues) => {
      setQueues(queues);
    });
  }, []);

  return (
    <div className="font-sans">
      <Header>
        <FieldWrapper>
          <InlineLabel label="mode" />
          <SelectField
            name="exchange_type"
            value={exchangeType}
            options={exchangeTypeOption}
            onChange={(event) => handleUpdateExchangeType(event.target.value)}
          />
        </FieldWrapper>
        <FieldWrapper>
          <InlineLabel label="name" />
          <TextField
            name="exchange_name"
            value={exchangeName}
            onChange={(event) => handleUpdateExchangeName(event.target.value)}
          />
        </FieldWrapper>
      </Header>
      <div className="flex flex-col border rounded-b-lg">
        <div className="exchange-title">{exchangeName}</div>
        <QueueField queues={queues} ctx={ctx} />
        <ButtonField onClick={handleAddQueue} />
      </div>
    </div>
  );
}

function Header({ children }) {
  return (
    <div className="align-stretch flex flex-wrap justify-start gap-4 rounded-t-lg border border-gray-300 border-b-gray-200 bg-blue-100 px-4 py-2">
      {children}
    </div>
  );
}

function FieldWrapper({ children }) {
  return <div className="flex items-center gap-1.5">{children}</div>;
}

function InlineLabel({ label }) {
  return (
    <label className="text-sm font-medium uppercase text-gray-600">
      {label}
    </label>
  );
}

function SelectField({
  label = null,
  value,
  className,
  required = false,
  fullWidth = false,
  options,
  inputRef,
  ...props
}) {
  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && !value ? "border-red-300" : "border-gray-200",
        ])}
      >
        <select
          {...props}
          value={value}
          className={classNames([
            "w-full bg-transparent px-3 py-2 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        >
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}

function TextField({
  label = null,
  value,
  type = "text",
  className,
  required = false,
  fullWidth = false,
  inputRef,
  startAdornment,
  ...props
}) {
  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && !value ? "border-red-300" : "border-gray-200",
        ])}
      >
        {startAdornment}
        <input
          {...props}
          ref={inputRef}
          type={type}
          value={value}
          className={classNames([
            "w-full bg-transparent px-3 py-2 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        />
      </div>
    </div>
  );
}

function SwitchField({
  label = null,
  value,
  fullWidth = false,
  required = false,
  className,
  ...props
}) {
  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && !value ? "border-red-300" : "border-gray-200",
        ])}
      >
        {startAdornment}
        <input
          {...props}
          ref={inputRef}
          type={type}
          value={value}
          className={classNames([
            "w-full bg-transparent px-3 py-2 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        />
      </div>
    </div>
  );
}

function ButtonField({
  label = null,
  value,
  type = "text",
  className,
  required = false,
  fullWidth = true,
  inputRef,
  startAdornment,
  ...props
}) {
  return (
    <div className="items-center justify-center add_operation pb-3">
      <button
        {...props}
        className={classNames([
          "flex justify-center items-center bg-white text-gray-400 p-0.5 rounded-full text-center cursor-pointer transition-colors border-2 border-gray-200 border-dashed hover:border-green-300 hover:text-green-300 shadow-lg hover:shadow-green-300/50 w-7 h-7",
          className,
        ])}
      >
        <RiAddLine />
      </button>
    </div>
  );
}

function QueueField({ ctx = nil, queues = [] }) {
  const handleUpdateQueueNameWithIndex = (name, index) => {
    ctx.pushEvent("update_queue_name", { name, index });
  };

  const handleUpdateQueueRoutingWithIndex = (routing_key, index) => {
    ctx.pushEvent("update_queue_routing_key", { routing_key, index });
  };

  const handleRemoveQueueWithIndex = (index) => {
    ctx.pushEvent("remove_queue", index);
  };

  return (
    <div>
      {queues.map((queue, index) => {
        const isLast = index === queues.length - 1;
        const queueContent = (
          <div className="queue_field" key={index}>
            <div className="w-[140px]">
              <TextField
                label="Name"
                name="queue_name"
                value={queue.name}
                onChange={(event) =>
                  handleUpdateQueueNameWithIndex(event.target.value, index)
                }
              />
            </div>
            <div className="w-[140px]">
              <TextField
                label="Routing Key"
                name="queue_routing_key"
                value={queue.routing_key}
                onChange={(event) =>
                  handleUpdateQueueRoutingWithIndex(event.target.value, index)
                }
              />
            </div>
            <div className="items-center justify-center">
              <button
                onClick={(event) => handleRemoveQueueWithIndex(index)}
                className={classNames([
                  "flex justify-center items-center text-gray-400 p-0.5 rounded-full text-center cursor-pointer transition-colors hover:border-red-300 hover:text-red-300 shadow-lg hover:shadow-red-300/50 w-5 h-5",
                ])}
              >
                <RiDeleteBinLine />
              </button>
            </div>
          </div>
        );
        return isLast ? (
          <div className="config_field_last">{queueContent}</div>
        ) : (
          <div className="config_field">{queueContent}</div>
        );
      })}
    </div>
  );
}
