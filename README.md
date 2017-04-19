## Service Fabric Tools

### Package Versioning Task

Applies versioning to a Service Fabric package.

By using hashing to version packages, this task can easily build [diffential packages](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-application-upgrade-advanced#upgrade-with-a-diff-package), which can dramatically improve upgrade performance, with less disruptions to the services (unchanged services are not restarted).

#### Parameters

* Application/Service version - appends a string to the version in the manifest
* Code/Config/Data package version mode:
  * None - does nothing
  * Specify - appends the specified string
  * Hash - hashes all the files and appends the hash value to the version
* Differential package:
  * Connects to a cluster and retrieves the currently registered package versions
  * If a code/config/data package's version has not changed (binary-compared), it is REMOVED from the package
  * Note that for C# code packages to be binary-compatible, you must [enable deterministic builds](https://gist.github.com/aelij/b20271f4bd0ab1298e49068b388b54ae) and exclude PDBs from hashing (latter is the default)
   
#### Sample output

```
Application Application1Type     2.0.0          -> 2.0.0+Release-7
  Service Stateless1               1.0.0        ->   1.0.0+Release-7
    CodePackage Code                 1.0.0      ->     1.0.0+4b75913eb670a571c98a12737308ba91b27c2984 [REMOVED]
    ConfigPackage Config             1.0.0      ->     1.0.0
  Service Stateless2               1.0.0        ->   1.0.0+Release-7
    CodePackage Code                 1.0.0      ->     1.0.0+3407a7ba597707a0ec60730431d09fd002428430 
    ConfigPackage Config             1.0.0      ->     1.0.0
    DataPackage Data                 1.0.0      ->     1.0.0
```

### Learn More

The [source](https://github.com/aelij/vsts-service-fabric) of this extension is available.
