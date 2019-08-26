# Troubleshooting API ML

As an API Mediation Layer user, you may encounter problems with the functioning of API ML. This article presents known API ML issues and their solutions.

## Enable API ML Debug Mode

Use debug mode to activate the following functions:

- Display additional debug messages for the API ML 
- Enable changing log level for individual code components
    
**Important:** We highly recommend that you enable debug mode only when you want to troubleshoot issues.
Disable debug mode when you are not troubleshooting. Running in debug mode while operating API ML can adversely affect
its performance and create large log files that consume a large volume of disk space.

**Follow these steps:**

1. Locate the following shell script files in the `<Zowe install directory>/api-mediation/scripts` directory:

    - ```api-mediation-start-catalog.sh```
    - ```api-mediation-start-discovery.sh```
    - ```api-mediation-start-gateway.sh```

2. Open a file, for which you want to enable the debug mode.

3. Find the line which contains the `spring.profiles.include` parameter and change the value to `debug`: 
    ```
    -Dspring.profiles.include=debug \
    ```

4. Restart Zowe.

    You have enabled the debug mode.

5. (Optional) Reproduce a bug that causes issues and review debug messages. If you are unable to resolve the issue, contact CA Support.

6. Disable the debug mode. Modify the line which contains the `spring.profiles.include` parameter back to default:
    ```
    -Dspring.profiles.include= \
    ```
7. Restart Zowe.

    You have disabled the debug mode.
 ___
## Change the Log Level of Individual Code Components

You can change the log level of a particular code component of the API ML internal service at run time.

**Follow these steps:**

1. Enable API ML Debug Mode as described in Enable API ML Debug Mode.
This activates the application/loggers endpoints in each API ML internal service (Gateway, Discovery Service, and Catalog).
2. List the available loggers of a service by issuing the GET request for the given service URL:

    ```
    GET scheme://hostname:port/application/loggers
    ```
    
    Where:
    - **scheme**
    
        API ML service scheme (http or https)
    
    - **hostname**
    
        API ML service hostname
    
    - **port**
    
        TCP port where API ML service listens on. The port is defined by the configuration parameter MFS_GW_PORT for the Gateway,
    MFS_DS_PORT for the Discovery Service (by default, set to gateway port + 1), and MFS_AC_PORT for the Catalog 
    (by default, set to gateway port + 2).
    
    **Exception:** For the catalog you will able to get list the available loggers by issuing the GET request for the given service URL:
    ```
    GET [gateway-scheme]://[gateway-hostname]:[gateway-port]/api/v1/apicatalog/application/loggers
    ```

    **Tip:** One way to issue REST calls is to use the http command in the free HTTPie tool: https://httpie.org/.
    
    **Example:**
 
    ```
    HTTPie command:
    http GET https://lpar.ca.com:10000/application/loggers

    Output:
    {"levels":["OFF","ERROR","WARN","INFO","DEBUG","TRACE"],
     "loggers":{
       "ROOT":{"configuredLevel":"INFO","effectiveLevel":"INFO"},
       "com":{"configuredLevel":null,"effectiveLevel":"INFO"},
       "com.ca":{"configuredLevel":null,"effectiveLevel":"INFO"},
       ...
     }
    }
    ```
 
3. Alternatively, you extract the configuration of a specific logger using the extended **GET** request:

    ```
    GET scheme://hostname:port/application/loggers/{name}
    ```
    Where:

    - **{name}**

         is the logger name
    
4. Change the log level of the given component of the API ML internal service. Use the POST request for the given service URL:

    ```
    POST scheme://hostname:port/application/loggers/{name}
    ```
    The POST request requires a new log level parameter value that is provided in the request body:
    ```
    {

    "configuredLevel": "level"

    }
    ```
    Where:

    - **level**
    
        is the new log level: **OFF**, **ERROR**, **WARN**, **INFO**, **DEBUG**, **TRACE**
    
    **Example:**

    ```
    http POST https://hostname:port/application/loggers/com.ca.mfaas.enable.model configuredLevel=WARN
    ```



## Known Issues 

### API ML stops accepting connections after z/OS TCP/IP stack is recycled

**Symptom:**

When z/OS TCP/IP stack is restarted, it is possible that the internal services of API Mediation Layer 
(Gateway, Catalog, and Discovery Service) stop accepting all incoming connections, go into a continuous loop, 
and write a numerous error messages in the log.

**Sample message:**

The following message is a typical error message displayed in STDOUT:

```
2018-Sep-12 12:17:22.850. org.apache.tomcat.util.net.NioEndpoint -- Socket accept failed java.io.IOException: EDC5122I Input/output error. 

.at sun.nio.ch.ServerSocketChannelImpl.accept0(Native Method) ~.na:1.8.0.
.at sun.nio.ch.ServerSocketChannelImpl.accept(ServerSocketChannelImpl.java:478) ~.na:1.8.0.
.at sun.nio.ch.ServerSocketChannelImpl.accept(ServerSocketChannelImpl.java:287) ~.na:1.8.0.
.at org.apache.tomcat.util.net.NioEndpoint$Acceptor.run(NioEndpoint.java:455) ~.tomcat-coyote-8.5.29.jar!/:8.5.29. 
.at java.lang.Thread.run(Thread.java:811) .na:2.9 (12-15-2017).
```
**Solution:**

Restart API Mediation Layer. 

**Tip:**  To prevent this issue from occurring, it is strongly recommended not to restart TCP/IP stack while the API ML is running.


### SEC0002 error when logging in to API Catalog

SEC0002 error typically appears when users fail to log in to API Catalog. The following image shows how the API Catalog login page with the SEC0002 error looks.

<img src="Error.png" alt="SEC0002 Error" title="SEC0002 Error" width="450" height="350"/>

The error is caused by failed z/OSMF authentication. To find out the reason, open ZOWESVR joblog and look for a message that contains `ZosmfAuthenticationProvider`. The following is the example of the message that contains `ZosmfAuthenticationProvider`:

```
2019-06-21 11:25:03.441 ERROR 5 --- .0.0-7552-exec-3. c.c.m.s.l.ZosmfAuthenticationProvider    : Can not access z/OSMF service. Uri 'https://MVSDE25.lvn.broadcom.net:1443' returned: I/O error on GET request for "https://MVSDE25.lvn.broadcom.net:1443/zosmf/info": ... 
```

 Depending on the content of the message, you can identify the exact cause of the problem. The following list provides the possible reasons and solutions for the z/OSMF authentication issue:

- [Connection refused](#connection-refused)
- [Missing z/OSMF host name in subject alternative names](#missing-z/osmf-host-name-in-subject-alternative-names)
- [Invalid z/OSMF host name in subject alternative names](#invalid-z/osmf-host-name-in-subject-alternative-names)

#### Connection refused

Based on the following message, failure to connect to API Catalog is caused by the refused connection message:

```
Connect to MVSDE25.lvn.broadcom.net:1443 .MVSDE25.lvn.broadcom.net/127.0.0.1. failed: EDC8128I Connection refused.; nested exception is org.apache.http.conn.HttpHostConnectException: 
```
The reason for the refused connection message is invalid z/OSMF configuration. Provided the message above, z/OSMF is not listening on 127.0.0.1.

**Solution:**

Change z/OSMF configuration.

**Follow these steps:**

1. Ensure that z/OSMF listens on localhost 127.0.0.1.
2. Identify z/OSMF PARMLIB member IZUPRMxx in SYS1.PARMLIB(IZUPRM00).
3. Change the current `HOSTNAME` configuration to `HOSTNAME('*')`.

For more information, see [Syntax rules for IZUPRMxx](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua300/izuconfig_IZUPRMxx.htm).

If changing the z/OSMF confifuration does not fix the issue, reconfigure Zowe. 

**Follow these steps:**

1. Open `.zowe_profile` in home directory of a user who installed Zowe. 
2. Modify the value of the `ZOWE_ZOSMF_PORT` variable. 
3. Reinstall Zowe.


#### Missing z/OSMF host name in subject alternative names

Based on the following message, failure to connect to API Catalog is caused by a missing z/OSMF host name in the subject alternative names:

```
Certificate for <MVSDE25.lvn.broadcom.net> doesn't match any of the subject alternative names: ..; nested exception is javax.net.ssl.SSLPeerUnverifiedException: Certificate for <MVSDE25.lvn.broadcom.net> doesn't match any of the subject alternative names: ..
```

**Solutions:**

Fix the missing z/OSMF host name in subject alternative names using the following methods:

**Note:** Apply the insecure fix only if you use API Catalog for testing purposes.

- [Secure fix](#Secure-fix)
- [Insecure fix](#insecure-fix)

#### Secure fix

**Follow these steps:**

1. Obtain a valid certificate for z/OSMF and place it into the z/OSMF keyring. For more information, see [Configure the z/OSMF Keyring and Certificate](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua300/izuconfig_KeyringAndCertificate.htm).
2. Navigate to `$ZOWE_RUNTIME/api-mediation` and run the following command:
    ```
    scripts/apiml_cm.sh --action trust-zosmf 
    ```

    2a. (Optional) If you do not use the default z/OSMF userid (IZUSVR) and keyring (IZUKeyring.IZUDFLT), issue the following command: 

       scripts/apiml_cm.sh --action trust-zosmf--zosmf-userid **ZOSMF_USER** --zosmf-keyring **ZOSMF_KEYRING**
    
    where
    - `--zosmf-keyring` and `--zosmf-userid` - options that override the default userid and keyring accordingly.

#### Insecure fix

**Follow these steps:**

1. Reinstall Zowe.
2. Set the value of the `verifyCertificatesOfServices` property to `false` in `zowe-install.yaml`, to disable verification of certificates in Zowe.

#### Invalid z/OSMF host name in subject alternative names

Based on the following message, failure to connect to API Catalog is caused by an invalid z/OSMF host name in the subject alternative names:

```
Certificate for <USILCA32.lvn.broadcom.net> doesn't match any of the subject alternative names: [ca32.ca.com, ca32, localhost, ca32-virt, ca32-virt.ca.com, ca32-virt1, ca32-virt1.ca.com, ca32-virt2, ca32-virt2.ca.com, usilca32, usilca32.ca.com]; 
nested exception is javax.net.ssl.SSLPeerUnverifiedException: Certificate for <USILCA32.lvn.broadcom.net> doesn't match any of the subject alternative names: [ca32.ca.com, ca32, localhost, ca32-virt, ca32-virt.ca.com, ca32-virt1, ca32-virt1.ca.com, ca32-virt2, ca32-virt2.ca.com, usilca32, usilca32.ca.com]
```

**Solutions:**

Fix the invalid z/osmf host name in the subject alternative names using the following methods:

- [Request a new certificate](#request-a-new-certificate)
- [Change the ZOWE_EXPLORER_HOST variable](#change-the-zowe_explorer_host-variable)

#### Request a new certificate

Request a new certificate that contains a valid z/OSMF host name in the subject alternative names.

#### Change the ZOWE_EXPLORER_HOST variable

Change `ZOWE_EXPLORER_HOST` variable to fix the issue.

**Follow these steps:**

1. Open .zowe_profile in home directory of the user who installed Zowe.
2. Change  `ZOWE_EXPLORER_HOST` to to a host name from the subject alternative names of the z/OSMF certificate. For example, issue the following command:
    ```
    export ZOWE_EXPLORER_HOST=SAN (change this to the correct one > in the code block).
    ```
3. Reinstall Zowe. 
