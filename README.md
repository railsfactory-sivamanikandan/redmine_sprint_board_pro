# 🧩 Redmine Sprint Board Pro

`redmine_sprint_board_pro` is a powerful plugin for Redmine that brings Agile project management features like Sprint Planning, Trello-style Agile Boards, Burndown Charts, Smart Backlog Suggestions, and more.

---

## ✨ Features

- 🗂 Sprint CRUD (Create, Edit, Complete, Delete)
- 📋 Agile Board (Drag & Drop Kanban view)
- 🎯 Story Points and Sprint Assignment
- 🏷 **Tags for Issues** (with color coding & autocomplete)
- 🔍 **Tag Filters in Sprints**
- 📉 Burndown & Velocity Charts
- 🧠 Smart Backlog Suggestions (AI-assisted)
- 🎨 Card Color Coding (e.g., based on priority)
- 🪄 Optional Swimlanes (group by assignee, tracker, etc.)
- 🧾 Export formats: CSV, PDF for Sprint list

---

## 🛠 Installation

1. **Clone the plugin inside Redmine plugins directory**

```bash
cd /path/to/redmine/plugins
git clone https://github.com/railsfactory-sivamanikandan/redmine_sprint_board_pro.git
```

## Install dependencies

```bash
bundle install
```

## Run migrations

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_sprint_board_pro RAILS_ENV=production
```

## 🏷 Tags Support
### Enable Tags
We use acts-as-taggable-on to manage tags.

- Tags can be added when creating or editing an Issue.
- Multiple tags are supported via an autocomplete multi-select.
- Tags are displayed on Issue cards in the Agile Board and Sprint pages.
- Each tag is color-coded for better visual separation.

### Tag Filters
- Sprints Page: Filter sprints by tags applied to their issues.
- Agile Board: Filter visible issues by tags without reloading the entire board. (coming soon)

## 📚 Usage
- Go to your project → Agile Board
- Select/Create a Sprint
- Drag & drop issues across status columns
- Create or edit a Sprint with smart issue suggestions
- Use the charts tab for burndown/velocity metrics
### Charts & Metrics

- 📈 **Cumulative Flow Diagram (CFD)**  
  Track the number of issues in each workflow state over time to identify bottlenecks.

- 🚀 **Velocity Chart**  
  See how many story points (or issues) your team completes each sprint.

- 📉 **Burndown Chart**  
  Monitor remaining work vs. time to ensure you're on track.

- 🔍 **Open vs. Closed Issues**  
  Compare counts of open and completed issues within the sprint.

- 🗂 **Issue Type Breakdown**  
  Visualize the distribution of Bugs, Features, Tasks, etc., in your sprint.

- 👥 **Team Contribution**  
  See who’s contributing the most in terms of issues completed or story points delivered.


### Benefits
- **Early risk detection**: Spot workflow bottlenecks from the CFD.
- **Team performance insights**: Use Velocity and Contribution charts to plan future sprints.
- **Balanced workload**: Monitor open vs. closed issues daily.


## 🔐 Permissions
The plugin adds the following permissions:

- View agile board
- Manage sprints
- View agile charts

Configure them under:
Admin → Settings → Project → Agile board

## 🎨 Customization

- Card Colors: Priority-based color classes (configured via CSS)
- Drag-and-Drop: Customizable via agile_board.js
- Smart Suggestions: You can plug in your own AI/ML logic

## 🔄 Supported Redmine Versions

- ✅ Redmine 4.x and 5.x
- ✅ Ruby 2.6+ to 3.3+
- ✅ Rails 5.2 to 6.1

## 📦 Export Formats
Available on the Sprint listing page:

- CSV Export
- PDF Export

## 🚧 Development
To start developing:

```bash
bundle exec rails server
```

## Here is a screenshot of the plugin:

![Settings Screen](images/settings-screen.png)

![Agile Board](images/Agile-board.png)

![Sprint Listing](images/Sprint-listing.png)

![Sprint Show Page](images/Sprint-Showpage.png)

![Sprint Dashboard](images/Sprint-dashboard.png)


## 💡 Roadmap

- Filter issues by tracker/user in board
- Add WIP limits per column
- Add in-place editing for cards
- Add REST API support

## 📄 License
MIT License.

## 🙌 Credits
Built with ❤️ by sivamanikandan.

Inspired by RedmineUP Agile Plugin and the Redmine community.

```yaml

---

Would you like me to include a badge section (e.g., version, downloads, build status), or generate a basic `gemspec` or plugin `.rb` stub too?
```