/**
 * Copyright (c) 2014-2015 YCSB contributors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License. You
 * may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License. See accompanying
 * LICENSE file.
 */

package com.yahoo.ycsb.db;

import com.xiaomi.infra.pegasus.client.PException;
import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;
import com.yahoo.ycsb.Status;
import com.yahoo.ycsb.StringByteIterator;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;

import com.xiaomi.infra.pegasus.client.PegasusClientFactory;
import com.xiaomi.infra.pegasus.client.PegasusClientInterface;

import org.apache.commons.lang3.tuple.Pair;
import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.node.ObjectNode;

import org.apache.log4j.Logger;

/**
 * Concrete Pegasus client implementation.
 */
public class PegasusClient extends DB {

  private final Logger logger = Logger.getLogger(getClass());

  protected static final ObjectMapper MAPPER = new ObjectMapper();

  public static final String CONFIG_PROPERTY = "pegasus.config";

  public static final String OPERATOR_WRITE_MODE = "write_mode";

  public static final String OPERATOR_READ_MODE = "read_mode";

  public static final String SORT_KEYS_COUT = "sort_keys_count";
  /**
   * The PegasusClient implementation that will be used to communicate
   * with the pegasus server.
   */
  private PegasusClientInterface client = null;

  /**
   * The PegasusClient set/get mode
   * S=Single: set/get M=multi:multiSet/multiGet B=Batch:batchSet/batchGet IV=invalid mode
   * example:SS is set value and get value
   */
  private enum OperatorMode {
    SS,MM,BB,MB,BM,IV
  }

  private OperatorMode operatorMode = OperatorMode.IV;
  private List<byte[]> sortKeys = new ArrayList<>();

  /**
   * @returns Underlying Pegasus client implementation.
   */
  protected PegasusClientInterface pegasusClient() {
    return client;
  }

  @Override
  public void init() throws DBException {
    try {
      initOperatorMode();
      initPegasusClient();
    } catch (Exception e) {
      throw new DBException(e);
    }
  }

  private void initOperatorMode() throws Exception {
    String writeMode = getProperties().getProperty(OPERATOR_WRITE_MODE, "single");
    String readMode = getProperties().getProperty(OPERATOR_READ_MODE, "single");
    String sortKeysCount = getProperties().getProperty(SORT_KEYS_COUT, "10");

    int count = Integer.parseInt(sortKeysCount);
    while (--count >= 0) {
      sortKeys.add(String.valueOf(count).getBytes());
    }

    if (writeMode.equals("single") && readMode.equals("single")) {
      operatorMode = OperatorMode.SS;
    } else if (writeMode.equals("multi") && readMode.equals("multi")) {
      operatorMode = OperatorMode.MM;
    } else if (writeMode.equals("batch") && readMode.equals("batch")) {
      operatorMode = OperatorMode.BB;
    } else if (writeMode.equals("multi") && readMode.equals("batch")) {
      operatorMode = OperatorMode.MB;
    } else if (writeMode.equals("batch") && readMode.equals("multi")) {
      operatorMode = OperatorMode.BM;
    } else {
      operatorMode = OperatorMode.IV;
      throw new Exception("The operator mode set error");
    }
  }

  private void initPegasusClient() throws PException {
    String configPath = getProperties().getProperty(CONFIG_PROPERTY);
    if (configPath == null) {
      client = PegasusClientFactory.getSingletonClient();
    } else {
      client = PegasusClientFactory.getSingletonClient(configPath);
    }
  }

  @Override
  public Status read(
      String table, String key, Set<String> fields,
      HashMap<String, ByteIterator> result) {
    switch (operatorMode) {
      case SS :return singleGet(table, key, fields, result);
      case MM :return multiGet(table, key, fields, result);
      case MB :return multiGet(table, key, fields, result);
      case BM :return batchGet(table, key, fields, result);
      case BB :return batchGet(table, key, fields, result);
      default: return Status.ERROR;
    }
  }

  private Status singleGet(
    String table, String key, Set<String> fields,
    Map<String, ByteIterator> result) {
    try {
      byte[] value = pegasusClient().get(table, key.getBytes(), null);
      if (value != null) {
        fromJson(value, fields, result);
      }
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error reading value from table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
  }

  private Status multiGet(
    String table, String key, Set<String> fields,
    Map<String, ByteIterator> result) {
    try {
      List<Pair<byte[], byte[]>> values = new LinkedList<>();
      boolean res = pegasusClient().multiGet(table, key.getBytes(), sortKeys, values);
      if (res && !values.isEmpty()) {
        for (Pair<byte[], byte[]> value : values) {
          fromJson(value.getValue(), fields, result);
        }
      }
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error reading value from table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
  }

  private Status batchGet(
    String table, String key, Set<String> fields,
    Map<String, ByteIterator> result
  ){
    return null;
  }

  @Override
  public Status scan(
      String table, String startkey, int recordcount, Set<String> fields,
      Vector<HashMap<String, ByteIterator>> result){
    return Status.NOT_IMPLEMENTED;
  }

  @Override
  public Status update(
      String table, String key, HashMap<String, ByteIterator> values) {
    switch (operatorMode) {
      case SS :return singleSet(table, key, values);
      case MM :return multiSet(table, key,values);
      case MB :return multiSet(table, key, values);
      case BM :return batchSet(table, key, values);
      case BB :return batchSet(table, key, values);
      default: return Status.ERROR;
    }
  }

  @Override
  public Status insert(
      String table, String key, HashMap<String, ByteIterator> values) {
    switch (operatorMode) {
      case SS :return singleSet(table, key, values);
      case MM :return multiSet(table, key,values);
      case MB :return multiSet(table, key, values);
      case BM :return batchSet(table, key, values);
      case BB :return batchSet(table, key, values);
      default: return Status.ERROR;
    }
  }

  private Status singleSet(String table, String key, Map<String, ByteIterator> values) {
    try {
      pegasusClient().set(table, key.getBytes(), null, toJson(values));
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error updating value to table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
  }

  private Status multiSet(String table, String key, Map<String, ByteIterator> values) {
    try {
      List<Pair<byte[], byte[]>> sortValues = new LinkedList<>();
      byte[] value = toJson(values);
      for (byte[] sortKey : sortKeys) {
        sortValues.add(Pair.of(sortKey, value));
      }
      pegasusClient().multiSet(table, key.getBytes(), sortValues);
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error updating value to table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
  }

  private Status batchSet(String table, String key, HashMap<String, ByteIterator> values) {
    return null;
  }

  @Override
  public Status delete(String table, String key) {
    try {
      pegasusClient().del(table, key.getBytes(), null);
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error deleting value from table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
  }

  @Override
  public void cleanup() throws DBException {
    // Don't close the underlying client handler 
    // as it may be used by multiple PegasusClient object
    // try {
    //   PegasusClientFactory.closeSingletonClient();
    // } catch (Exception e) {
    //   throw new DBException(e);
    // }
  }

  protected static void fromJson(
      byte[] value, Set<String> fields,
      Map<String, ByteIterator> result) throws IOException {
    JsonNode json = MAPPER.readTree(value);
    boolean checkFields = fields != null && !fields.isEmpty();
    for (Iterator<Map.Entry<String, JsonNode>> jsonFields = json.getFields();
         jsonFields.hasNext();
         /* increment in loop body */) {
      Map.Entry<String, JsonNode> jsonField = jsonFields.next();
      String name = jsonField.getKey();
      if (checkFields && fields.contains(name)) {
        continue;
      }
      JsonNode jsonValue = jsonField.getValue();
      if (jsonValue != null && !jsonValue.isNull()) {
        result.put(name, new StringByteIterator(jsonValue.asText()));
      }
    }
  }

  protected static byte[] toJson(Map<String, ByteIterator> values)
      throws IOException {
    ObjectNode node = MAPPER.createObjectNode();
    HashMap<String, String> stringMap = StringByteIterator.getStringMap(values);
    for (Map.Entry<String, String> pair : stringMap.entrySet()) {
      node.put(pair.getKey(), pair.getValue());
    }
    JsonFactory jsonFactory = new JsonFactory();
    ByteArrayOutputStream out = new ByteArrayOutputStream(1024);
    JsonGenerator jsonGenerator = jsonFactory.createJsonGenerator(out);
    MAPPER.writeTree(jsonGenerator, node);
    return out.toByteArray();
  }
}
