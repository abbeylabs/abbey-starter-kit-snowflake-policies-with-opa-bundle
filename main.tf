terraform {
  required_providers {
    abbey = {
      source = "abbeylabs/abbey"
      version = "0.1.0-rc.4"
    }

    snowflake = {
      source = "Snowflake-Labs/snowflake"
      version = "0.56.5"
    }
  }
}

provider "abbey" {
  # Configuration options
}

provider "snowflake" {
  account   = var.account
  username  = var.username
  password  = var.password
}

# This example shows how you might manage Snowflake databases within Terraform.
# Notice that we're using `data` here which implies creation of databases
# and their schemas already happened out-of-band.
#
# You can provision databases and schemas in Terraform, but you may want
# to consider using native Snowflake or database-friendly tooling to manage
# schemas. Terraform and the Abbey Provider on the other hand would be great
# for managing access.
#
# Make sure to put in valid values as they exist in Snowflake, otherwise you will
# get Null data references when trying to `plan` or `apply`.
data "snowflake_database" "pii_database" {
  name = "..."
}

# This example shows how you might manage Snowflake roles within Terraform.
# Notice that we're using `data` here which implies creation of the role
# already happened out-of-band, for example, within the Snowflake console.
#
# If you would like to configure roles directly within Terraform, you can
# visit the open source Snowflake-Labs/snowflake provider documentation.
#
# Make sure to put in valid values as they exist in Snowflake, otherwise you will
# get Null data references when trying to `plan` or `apply`.
data "snowflake_role" "pii_readonly_role" {
  name = "..."
}

# This example shows how you might manage Snowflake identities within Terraform.
# If you don't manage identities within Terraform, you can exclude this block.
data "snowflake_users" "my_snowflake_user" {
  pattern = "..."
}

# Provision an example table grant. Feel free to replace with your own table grant.
# Before running, replace the stubbed fields in this block.
resource "snowflake_table_grant" "pii_readonly__can_read__pii__table" {
  database_name     = data.snowflake_database.pii_database.name
  schema_name       = "..."
  table_name        = "..."
  privilege         = "SELECT"
  roles             = [data.snowflake_role.pii_readonly_role.name]
  with_grant_option = false
}

resource "abbey_grant_kit" "role__pii_readonly" {
  name = "PII READONLY role grant"
  description = <<-EOT
    Grants access to the PII READONLY Snowflake Role Grant.
    This Grant Kit uses a single-step Grant Workflow that requires only a single reviewer
    from a list of reviewers to approve access.

    This Grant Kit will auto-grant access upon approval.

    However, it will automatically revoke access after a 24-hour period because
    of the `deny[msg] { ... }` rule in the Rego code. If you want the OPA policy evaluation to pass the check,
    then you can replace `deny` (mandatory enforcement) with `warn` (advisory enforcement).
    If you want to disable the policy evaluation, then delete the `policies` block in the `grant_kit` resource.
  EOT

  workflow = {
    steps = [
      {
        reviewers = {
          # Replace with your Primary Identity.
          # For more information on what a Primary Identity is, visit https://docs.abbey.so.
          one_of = ["..."]
        }
      }
    ]
  }

  policies = {
    revoke_if = [
      {
        # This revocation policy revokes access for anyone that has access to
        # this target after 24 hours as determined by the `deny` rule.
        #
        # Optionally, you can build an OPA bundle and keep it in your repo.
        # `opa build -b policies/jit -o policies/jit.tar.gz`
        #
        # If you do, you can then specify `bundle` with:
        # bundle = "github://organization/repo/policies/jit.tar.gz"
        #
        # Otherwise you can specify the directory. Abbey will build an
        # OPA bundle for you and recursively add all your policies.
        bundle = "github://organization/repo/policies/jit"
      }
    ]
  }

  output = {
    # Replace with your own path pointing to where you want your access changes to manifest.
    # Path is an RFC 3986 URI, such as `github://{organization}/{repo}/path/to/file.tf`.
    location = "github://organization/repo/access.tf"
    append = <<-EOT
      resource "snowflake_role_grants" "pii_readonly__{{ $.data.system.abbey.primary_identity.username }}" {
        role_name = "${data.snowflake_role.pii_readonly_role.name}"
        users     = ["{{ $.data.system.abbey.secondary_identities.snowflake.username }}"]
      }
    EOT
  }
}
