---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Terraform Registry API **(FREE)**

This is the API documentation for [Terraform Modules](../../user/packages/terraform_module_registry/index.md).

WARNING:
This API is used by the [terraform cli](https://www.terraform.io/)
and is generally not meant for manual consumption.

For instructions on how to upload and install Terraform modules from the GitLab
infrastructure registry, see the [Terraform modules registry documentation](../../user/packages/terraform_module_registry/index.md).

## List available versions for a specific module

Get a list of available versions for a specific module.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/versions"
```

Example response:

```shell
{
  "modules": [
    {
      "versions": [
        {
          "version": "1.0.0",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        },
        {
          "version": "0.9.3",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        }
      ],
      "source": "https://gitlab.example.com/group/hello-world"
    }
  ]
}
```

## Latest version for a specific module

Get information about the latest version for a given module.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local"
```

Example response:

```shell
{
  "name": "hellow-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## Get specific version for a specific module

Get information about a specific version for a given module.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/1.0.0
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0"
```

Example response:

```shell
{
  "name": "hellow-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## Get URL for downloading latest module version

Get the download URL for latest module version in `X-Terraform-Get` header

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/download"
```

Example response:

```shell
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

Under the hood, this API endpoint redirects to `packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download`

## Get URL for downloading specific module version

Get the download URL for a specific module version in `X-Terraform-Get` header

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |
| `module_version` | string | yes | Specific module version to download. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/download"
```

Example response:

```shell
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

## Download module

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | yes | The group to which Terraform module's project belongs. |
| `module_name` | string | yes | The module name. |
| `module_system` | string | yes | The name of the module system or [provider](https://www.terraform.io/registry/providers). |
| `module_version` | string | yes | Specific module version to download. |

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file"
```

To write the output to file:

```shell
curl --header "Private-Token: <personal_access_token>" "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file" --output hello-world-local.tgz
```
