# Abbey Starter Kit Policies with OPA Bundles Example

This example shows how to create a Grant Kit.
The example features requesting access to a [Snowflake Role Grant](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs/resources/role_grants)
from multiple reviewers, requiring only `one_of` the reviewers to approve the access.

This Grant Kit is the same as policies-with-jit-access except that it organizes
the ad-hoc OPA Policy into an OPA Bundle.

This Grant Kit will auto-grant access upon approval.

However, it will automatically revoke access after a 24-hour period because
of the `deny[msg] { ... }` rule in the Rego code. If you want the OPA policy evaluation to pass the check,
then you can replace `deny` (mandatory enforcement) with `warn` (advisory enforcement).
If you want to disable the policy evaluation, then delete the `policies` block in the `grant_kit` resource.

## Usage

Visit this [Starter Kit's docs](https://docs.abbey.so/tutorials/open-policy-agent-opa-policies/policies-with-opa-bundles) for a short usage walkthrough.

## :books: Learn More

To learn more about Grant Kits and Grant Workflows, visit the following resources:

- [Abbey Labs Documentation](https://docs.abbey.so) - learn about automating access management with Abbey Labs.
