# Ecosystem Dashboard

A dashboard for monitoring the ecosystem around an open source project.

## Features

### Organizations

Monitor activity across multiple organizations, both internal to your project and from external collaborators as well. For the IPFS project that means monitoring activity [internal orgs](https://ecosystem-research.herokuapp.com/orgs) from:

- https://github.com/ipfs
- https://github.com/libp2p
- https://github.com/ipfs-shipyard
- https://github.com/multiformats
- https://github.com/ipld
- https://github.com/protoschool
- https://github.com/ipfs-cluster

and [collaborator organizations](https://ecosystem-research.herokuapp.com/collabs) such as:

- https://github.com/orbitdb
- https://github.com/qri-io
- https://github.com/filecoin-project
- https://github.com/textileio
- https://github.com/ethereum
- and many more.

### [Collaborators](https://ecosystem-research.herokuapp.com/collabs)

[Collaborators](https://ecosystem-research.herokuapp.com/collabs) are a key feature of the ecosystem dashboard, many large open source projects have more incoming issues and pull requests than they can possibly handle and so being able to visualize and prioritise activity by people from organizations that have an existing relationship with the project is essential to keeping those collaborations running smoothly.

You can highlight any github organization as a collaborator and then any activity by members of that organization will be added to the various collaborator dashboard views. The public activity within collaborator organizations will also be monitored for discovering new contributors, package usage and searching for relevant issues and pull requests.

### [Collaborator Issues](https://ecosystem-research.herokuapp.com)

The default homepage view shows issues and pull requests that have been opened by contributors from any of the configured collaborator github organizations.

It's helpful to give an triage of all new issues and pull requests from collaborators that should be high priority to triage.

It also includes a graph of how many new issues and pull requests were opened each month since the project began.

The most active collabs and collab contributors are also shown on the right sidebar.

This view is also filterable by the standard set of issue and pull request filters:

- Author
- State (open/closed)
- Type (issue/pull request)
- Repository
- Org (internal github organizations)
- Language (repository programming language)
- Collaborator (external collaborator github organizations)
- No Core Contributors response
- Uncommented
- No milestone
- Unlabelled
- Recent (past 30 days)
- Sort (newest, oldest, recently updated, least recently updated)

### [This week in Collabs](https://ecosystem-research.herokuapp.com/weekly)

The "[This week in Collabs](https://ecosystem-research.herokuapp.com/weekly)" view gives an overview of the activity on internal repositories from collaborator contributors. It shows all the issues and pull requests opened by contributors from any of the configured collaborator github organizations in the past week.

It also includes a graph of how many new issues and pull requests were opened throughout the week as well as how many existing collaborator issues and pull requests were closed or merged in the past seven days.

The most active collabs and collab contributors are also shown.

This view is also filterable by the standard set of issue and pull request filters:

- Author
- State (open/closed)
- Type (issue/pull request)
- Repository
- Org (internal github organizations)
- Language (repository programming language)
- Collaborator (external collaborator github organizations)
- Uncommented
- No milestone
- Unlabelled
- Sort (newest, oldest, recently updated, least recently updated)

### [All Issues + PRs](https://ecosystem-research.herokuapp.com/all?recent=true)

[All Issues + PRs](https://ecosystem-research.herokuapp.com/all?recent=true) shows all issues and pull requests that have been opened by everyone (excluding bots), by default filtered to the last 30 days.

It's helpful to give an overview of all new issues and pull requests across all internal organizations for triage.

Issues and pull requests opened by Collaborators and Core contributors are highlighted.

It also includes a graph of how many new issues and pull requests were opened each day over the past month.

The most active contributors are also shown on the right sidebar.

This view is also filterable by the standard set of issue and pull request filters:

- Author
- State (open/closed)
- Type (issue/pull request)
- Repository
- Org (internal github organizations)
- Language (repository programming language)
- No Core Contributors response
- Uncommented
- No milestone
- Unlabelled
- Exclude core contributors
- Recent (past 30 days)
- Sort (newest, oldest, recently updated, least recently updated)

### [Slow Responses](https://ecosystem-research.herokuapp.com/slow_response)

The [Slow Responses](https://ecosystem-research.herokuapp.com/slow_response) page shows every internal issue and pull request that has not had a response from a core contributor within a reasonable time frame, which by default is 48 hours, over the past 7 days (plus the slow response window, so last 9 days by default).

It is helpful to give a view of all the issues and pull requests that have not been triaged by a core team member yet. Note that this does not mean all issues are expected to be fixed within 48 hours, but should have at least received some kind of response such as a comment, review or label.

It also shows a graph of the number of slow responses vs the number of new issues and pull requests for the week and a graph of the average response time per week over the past year.

Issues and pull requests opened by Collaborators are highlighted.

Issues and pull requests opened by core contributors are not included in this view.

The most active contributors and collaborators with slow responses are also shown on the right sidebar.

This view is also filterable by the standard set of issue and pull request filters:

- Author
- State (open/closed)
- Type (issue/pull request)
- Repository
- Org (internal github organizations)
- Language (repository programming language)
- Uncommented
- No milestone
- Unlabelled
- Recent (past 30 days)
- Sort (newest, oldest, recently updated, least recently updated)

### [Repositories](https://ecosystem-research.herokuapp.com/repositories)

[Repositories](https://ecosystem-research.herokuapp.com/repositories) gives a filterable view of all active repositories across all your internal organizations, ordered by which have been pushed to most recently.

It shows highlevel information such as:
- name
- description
- organization
- last pushed date and time
- repo size
- number of dependencies

Repositories are also filterable by:
- Organization
- Main language
- Source (not forked)
- Forks
- Active (not archived)
- Archived

### [Collab Repositories](https://ecosystem-research.herokuapp.com/collabs/repositories)

[Collab Repositories](https://ecosystem-research.herokuapp.com/collabs/repositories) gives a filterable view of all active repositories across all your collaborators organizations, ordered by which have been pushed to most recently.

It shows highlevel information such as:
- name
- description
- organization
- last pushed date and time
- repo size
- number of dependencies

Repositories are also filterable by:
- Organization
- Main language
- Source (not forked)
- Forks
- Active (not archived)
- Archived


### [Events](https://ecosystem-research.herokuapp.com/events)

The [Events](https://ecosystem-research.herokuapp.com/events) view is a list of all types of github activities across all internal organizations, including:

- Issue Comments
- Pushes
- Stars
- Pull Requests
- Review Comments
- Issues
- Branches created
- Forks
- Branches delete
- Releases
- Members added
- Commit Comments
- Repositories Open Sourced
- Wiki updates

Events are also filterable by:
- Organization
- Repository
- User
- Type

### [Collab Events](https://ecosystem-research.herokuapp.com/collabs/events)

The [Events](https://ecosystem-research.herokuapp.com/events) view is a list of all types of github activities across all internal organizations, including:

- Issue Comments
- Pushes
- Stars
- Pull Requests
- Review Comments
- Issues
- Branches created
- Forks
- Branches delete
- Releases
- Members added
- Commit Comments
- Repositories Open Sourced
- Wiki updates

Events are also filterable by:
- Organization
- Repository
- User
- Type

### [Packages](https://ecosystem-research.herokuapp.com/packages)

The [Packages](https://ecosystem-research.herokuapp.com/packages) view is a list of all internal packages that have been published from internal repositories.

For each package it shows:
- name
- platform (package manager)
- description
- latest release number
- Dependent collab repositories
- org icon

It also has a basic package search function.

## License

Copyright (c) Protocol Labs, Inc.

This package is dual-licensed under Apache 2.0 and MIT terms:

- Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)
