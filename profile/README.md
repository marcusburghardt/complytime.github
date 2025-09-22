# ComplyTime: Cloud Native Compliance. Reimagined.

> From Code to Compliance, Intelligently.

ComplyTime is an engineering-first, API-driven framework designed to automate and unify compliance across the modern, cloud-native landscape. For the Cloud Native Developer and DevOps Engineer, it's a solution that simplifies compliance checks, making them an integral part of your workflow rather than an added burden.

## About ComplyTime

ComplyTime bridges the gap between high-level policy and technical implementation, empowering developers and securing your entire product portfolio. We believe that effective compliance automation must be built on a foundation that respects and integrates with your existing workflows.

## Our Philosophy: Engineering-First

We believe that effective compliance automation must be built on a foundation that understands and respects developer workflows.

* **Engineering-First:** We focus on machine-readable data for "compliance-as-code," moving beyond traditional, document-centric models.
* **Built for Automation:** Our architecture is designed for the ephemeral, API-driven nature of cloud-native systems, allowing for programmatic interaction with compliance data.
* **Flexible and Extensible:** ComplyTime is scanner-agnostic and multi-standard, ensuring it remains relevant and adaptable to various compliance frameworks.

## Project Architecture

ComplyTime is built on a foundation of modern, microservice-based components designed for flexibility and scale.

* **[complyctl](https://github.com/complytime/complyctl)**: A CLI tool providing a consistent compliance foundation for platforms like RHEL.
* **[complyscribe](https://github.com/complytime/complyscribe)**: A key component of our pluggable framework, this service acts as a compliance-to-policy (C2P) engine, designed to be extensible for various compliance frameworks, not only OSCAL.
 <!-- TODO: A key component of our pluggable framework, this compliance authoring tool operates behind the scenes for an extensible integration for various compliance frameworks, not specific to OSCAL. -->
* **[complybeacon](https://github.com/complytime/complybeacon)**: A observability toolkit leveraging OpenTelemetry to simplify audit logging and evidence collection in distributed environments like Kubernetes.
* **[complytime-demos](https://github.com/complytime/complytime-demos)**: A collection of demonstrations and examples for using the ComplyTime framework.

We leverage powerful, targeted open source components to achieve our goals. For instance, we utilize `oscal-sdk-go` and `compliance-to-policy-go`, sub-projects of OSCAL-Compass that align with our engineering-first, multi-standard vision.

## Community & Contributing

We are committed to the open source community. All the information you need to get started is in our **[community repository](https://github.com/complytime/community)**.

* **How to Contribute:** Check out our [Contributing Guide](https://github.com/complytime/community/blob/main/CONTRIBUTING.md) to learn how to submit your first pull request, find an issue to work on, and understand our development process.
* **Community Standards:** Our [Code of Conduct](https://github.com/complytime/community/blob/main/CODE_OF_CONDUCT.md) outlines the standards we uphold to maintain a welcoming and inclusive environment for everyone.
* **Project Governance:** Read our [Governance](https://github.com/complytime/community/blob/main/GOVERNANCE.md) document to understand our project roles and decision-making processes.

## The Road Ahead

Our vision is to establish ComplyTime as the definitive framework for modern, automated compliance. Our roadmap includes:

* **Deepening Cloud-Native Integration**: Enhancing our integration with core cloud-native technologies, including StackRox and OpenTelemetry.

<!-- > Find our Frequently Asked Questions (FAQ) [here](./community/FAQ.md) -->

<!-- ## Frequently Asked Questions (FAQ)

**Q: Does ComplyTime use OSCAL?**

A: Yes, but it is not limited to it. ComplyTime is a multi-standard platform. It leverages specific, targeted modules like `compliance-to-policy-go` to process OSCAL artifacts, but its architecture is designed to support a variety of formats, including Gemara, to avoid dependency on a single standard.

**Q: Why the focus on Gemara?**

A: Gemara represents an engineering-first approach to compliance automation, making it a natural fit for cloud-native workflows. Its backing by the OSSF and its role in the strategic OSPS Baseline initiative signal a major shift in the industry. Supporting Gemara allows us to address critical gaps left by document-centric standards and position ComplyTime at the forefront of modern compliance automation. -->
