# 🧩 Redmine Sprint Board Pro

`redmine_sprint_board_pro` is a powerful plugin for Redmine that brings Agile project management features like Sprint Planning, Trello-style Agile Boards, Burndown Charts, Smart Backlog Suggestions, and more.

---

## ✨ Features

- 🗂 Sprint CRUD (Create, Edit, Complete, Delete)
- 📋 Agile Board (Drag & Drop Kanban view)
- 🎯 Story Points and Sprint Assignment
- 📉 Burndown & Velocity Charts
- 🧠 Smart Backlog Suggestions (AI-assisted)
- 🎨 Card Color Coding (e.g., based on priority)
- 🪄 Optional Swimlanes (group by assignee, tracker, etc.)
- 🧾 Export formats: Atom, CSV, PDF for Sprint list

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

## 📚 Usage
- Go to your project → Agile Board
- Select/Create a Sprint
- Drag & drop issues across status columns
- Create or edit a Sprint with smart issue suggestions
- Use the charts tab for burndown/velocity metrics

## 📊 Charts Available
- Burndown Chart: Track remaining effort over time
- Velocity Chart: See how many story points were completed across sprints

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

- Atom Feed
- CSV Export
- PDF Export

## 🚧 Development
To start developing:

```bash
bundle exec rails server
```

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