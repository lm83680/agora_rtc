// 类型与工具方法
export type EventValue = Object | number | string | boolean | null;
export type EventMap = Map<string, EventValue>;
export type ArgsMap = Map<string, Object>;

export class EventPayload {
  type: string;
  data: Record<string, Object>;

  constructor(type: string, data: Record<string, Object>) {
    this.type = type;
    this.data = data;
  }
}

export function getArg(argsMap: ArgsMap | undefined, key: string): Object | undefined {
  return argsMap?.get(key) as Object;
}

export function mapValueToObject(value: Object): Object {
  if (value instanceof Map) {
    return mapToRecord(value as Map<string, Object>);
  }
  return value;
}

export function mapToRecord(map: Map<string, Object>): Record<string, Object> {
  let record: Record<string, Object> = {};
  for (let entry of map.entries()) {
    record[entry[0]] = mapValueToObject(entry[1]);
  }
  return record;
}

export function eventDataToRecord(data: EventMap): Record<string, Object> {
  let record: Record<string, Object> = {};
  for (let entry of data.entries()) {
    record[entry[0]] = mapValueToObject(entry[1] as Object);
  }
  return record;
}

export function toRecord(value: Object | undefined): Record<string, Object> | undefined {
  if (value == null) {
    return undefined;
  }
  if (value instanceof Map) {
    return mapToRecord(value as Map<string, Object>);
  }
  return value as Record<string, Object>;
}
