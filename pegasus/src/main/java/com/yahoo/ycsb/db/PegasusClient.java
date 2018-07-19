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

import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;
import com.yahoo.ycsb.Status;
import com.yahoo.ycsb.StringByteIterator;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.Vector;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.tuple.Pair;

import com.xiaomi.infra.pegasus.client.PegasusClientFactory;
import com.xiaomi.infra.pegasus.client.PegasusClientInterface;

import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonGenerator;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.node.ObjectNode;

import org.apache.log4j.Logger;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Concrete Pegasus client implementation.
 */
public class PegasusClient extends DB {

  private final Logger logger = Logger.getLogger(getClass());

  protected static final ObjectMapper MAPPER = new ObjectMapper();

  public static final String CONFIG_PROPERTY = "pegasus.config";

  /**
   * The PegasusClient implementation that will be used to communicate
   * with the pegasus server.
   */
  private PegasusClientInterface client = null;

  /**
   * @returns Underlying Pegasus client implementation.
   */
  protected PegasusClientInterface pegasusClient() {
    return client;
  }

  @Override
  public void init() throws DBException {
    try {
      String configPath = getProperties().getProperty(CONFIG_PROPERTY);
      if (configPath == null) {
        client = PegasusClientFactory.getSingletonClient();
      } else {
        client = PegasusClientFactory.getSingletonClient(configPath);
      }
    } catch (Exception e) {
      throw new DBException(e);
    }
  }

  public static byte[] getMD5(String input) {
    try {
      MessageDigest md = MessageDigest.getInstance("MD5");
      byte[] messageDigest = md.digest(input.getBytes());
      return messageDigest;
    }
    catch (NoSuchAlgorithmException e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public Status read(
      String table, String key, Set<String> fields,
      HashMap<String, ByteIterator> result) {
    try {
      /*byte[] value = pegasusClient().get(table, key.getBytes(), null);
      if (value != null) {
        fromJson(value, fields, result);
      }*/
      int intKey = Integer.parseInt(key.substring(key.length()-8,key.length()-1));

      List<Pair<byte[], byte[]>> keys = new ArrayList<Pair<byte[], byte[]>>();
      for(int i=0;i<10000;i++) {
        byte[] hashKey = getMD5(Integer.toString(intKey+i));
        keys.add(Pair.of(hashKey,"".getBytes()));
      }
      List<byte[]> values = new ArrayList<byte[]>();

      pegasusClient().batchGet(table,keys,values);
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error reading value from table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
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
    try {
      pegasusClient().set(table, key.getBytes(), null, toJson(values));
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error updating value to table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
  }

  @Override
  public Status insert(
      String table, String key, HashMap<String, ByteIterator> values) {
    try {
      pegasusClient().set(table, key.getBytes(), null, toJson(values));
      return Status.OK;
    } catch (Exception e) {
      logger.error("Error inserting value into table[" + table + "] with key: " + key, e);
      return Status.ERROR;
    }
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
