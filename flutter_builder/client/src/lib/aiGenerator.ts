import type { WidgetNode, DataModel, LogicAction, FlutterWidgetType } from "./types";
import { createWidgetNode } from "./widgetDefs";
import { generateId } from "./types";

// ===== AI App Generator =====
// Template-based generation from natural language prompts

export interface AITemplate {
  keywords: string[];
  name: string;
  description: string;
  generate: () => { tree: WidgetNode; models: DataModel[]; logic: LogicAction[] };
}

function createScaffoldWithAppBar(title: string, body: WidgetNode): WidgetNode {
  const scaffold = createWidgetNode("Scaffold");
  const appBar = createWidgetNode("AppBar");
  appBar.props.title = title;
  appBar.props.backgroundColor = "#6750A4";
  appBar.props.foregroundColor = "#FFFFFF";
  scaffold.slots = {
    appBar,
    body,
    drawer: null,
    bottomNavigationBar: null,
  };
  return scaffold;
}

export const AI_TEMPLATES: AITemplate[] = [
  {
    keywords: ["fitness", "workout", "training", "exercise", "gym"],
    name: "Fitness App",
    description: "Login, Dashboard, Trainingsplan",
    generate: () => {
      // Dashboard body
      const dashColumn = createWidgetNode("Column");
      dashColumn.props.mainAxisAlignment = "start";
      dashColumn.props.crossAxisAlignment = "stretch";
      dashColumn.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };

      const title = createWidgetNode("Text");
      title.props.text = "Your Workouts";
      title.props.fontSize = 28;
      title.props.fontWeight = "bold";

      const subtitle = createWidgetNode("Text");
      subtitle.props.text = "Stay fit and healthy";
      subtitle.props.fontSize = 16;
      subtitle.props.color = "#666666";

      // Workout cards
      const card1 = createWidgetNode("Card");
      card1.props.elevation = 2;
      card1.props.borderRadius = 12;
      const card1Col = createWidgetNode("Column");
      card1Col.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };
      const card1Title = createWidgetNode("Text");
      card1Title.props.text = "Upper Body Workout";
      card1Title.props.fontSize = 18;
      card1Title.props.fontWeight = "bold";
      const card1Sub = createWidgetNode("Text");
      card1Sub.props.text = "45 min - 8 exercises";
      card1Sub.props.fontSize = 14;
      card1Sub.props.color = "#666666";
      const startBtn1 = createWidgetNode("ElevatedButton");
      startBtn1.props.label = "Start Workout";
      startBtn1.props.backgroundColor = "#6750A4";
      startBtn1.props.foregroundColor = "#FFFFFF";
      card1Col.children = [card1Title, card1Sub, startBtn1];
      card1.children = [card1Col];

      const card2 = createWidgetNode("Card");
      card2.props.elevation = 2;
      card2.props.borderRadius = 12;
      const card2Col = createWidgetNode("Column");
      card2Col.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };
      const card2Title = createWidgetNode("Text");
      card2Title.props.text = "Cardio Session";
      card2Title.props.fontSize = 18;
      card2Title.props.fontWeight = "bold";
      const card2Sub = createWidgetNode("Text");
      card2Sub.props.text = "30 min - High intensity";
      card2Sub.props.fontSize = 14;
      card2Sub.props.color = "#666666";
      const startBtn2 = createWidgetNode("ElevatedButton");
      startBtn2.props.label = "Start Cardio";
      startBtn2.props.backgroundColor = "#E53935";
      startBtn2.props.foregroundColor = "#FFFFFF";
      card2Col.children = [card2Title, card2Sub, startBtn2];
      card2.children = [card2Col];

      // Progress container
      const progressCard = createWidgetNode("Card");
      progressCard.props.elevation = 1;
      progressCard.props.borderRadius = 12;
      const progressCol = createWidgetNode("Column");
      progressCol.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };
      const progressTitle = createWidgetNode("Text");
      progressTitle.props.text = "Weekly Progress";
      progressTitle.props.fontSize = 18;
      progressTitle.props.fontWeight = "bold";
      const progressText = createWidgetNode("Text");
      progressText.props.text = "5 of 7 days completed";
      progressText.props.fontSize = 14;
      progressText.props.color = "#4CAF50";
      progressCol.children = [progressTitle, progressText];
      progressCard.children = [progressCol];

      dashColumn.children = [title, subtitle, card1, card2, progressCard];

      const scaffold = createScaffoldWithAppBar("Fitness Dashboard", dashColumn);

      // Add bottom nav
      const bottomNav = createWidgetNode("NavigationBar");
      bottomNav.props.destinations = "Home,Workouts,Stats,Profile";
      bottomNav.props.selectedIndex = 0;
      scaffold.slots!.bottomNavigationBar = bottomNav;

      // Models
      const models: DataModel[] = [
        {
          id: generateId(),
          name: "Workout",
          fields: [
            { name: "title", type: "String" },
            { name: "duration", type: "int" },
            { name: "exercises", type: "List" },
            { name: "completed", type: "bool" },
          ],
        },
        {
          id: generateId(),
          name: "Exercise",
          fields: [
            { name: "name", type: "String" },
            { name: "sets", type: "int" },
            { name: "reps", type: "int" },
          ],
        },
      ];

      return { tree: scaffold, models, logic: [] };
    },
  },
  {
    keywords: ["shop", "store", "e-commerce", "commerce", "product", "shopping"],
    name: "E-Commerce App",
    description: "Product list, detail, cart",
    generate: () => {
      const col = createWidgetNode("Column");
      col.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };

      const title = createWidgetNode("Text");
      title.props.text = "Products";
      title.props.fontSize = 28;
      title.props.fontWeight = "bold";

      const searchField = createWidgetNode("TextField");
      searchField.props.label = "Search";
      searchField.props.hintText = "Search products...";

      // Product grid
      const grid = createWidgetNode("GridView");
      grid.props.crossAxisCount = 2;
      grid.props.crossAxisSpacing = 12;
      grid.props.mainAxisSpacing = 12;
      grid.props.childAspectRatio = 0.75;

      for (let i = 1; i <= 4; i++) {
        const card = createWidgetNode("Card");
        card.props.borderRadius = 12;
        const cardCol = createWidgetNode("Column");
        cardCol.props.padding = { top: 8, right: 8, bottom: 8, left: 8 };

        const img = createWidgetNode("Image");
        img.props.src = `https://picsum.photos/200/200?random=${i}`;
        img.props.width = 120;
        img.props.height = 120;
        img.props.borderRadius = 8;

        const name = createWidgetNode("Text");
        name.props.text = `Product ${i}`;
        name.props.fontSize = 14;
        name.props.fontWeight = "bold";

        const price = createWidgetNode("Text");
        price.props.text = `€${(i * 19.99).toFixed(2)}`;
        price.props.fontSize = 14;
        price.props.color = "#6750A4";

        const btn = createWidgetNode("ElevatedButton");
        btn.props.label = "Add to Cart";
        btn.props.backgroundColor = "#6750A4";
        btn.props.foregroundColor = "#FFFFFF";

        cardCol.children = [img, name, price, btn];
        card.children = [cardCol];
        grid.children.push(card);
      }

      col.children = [title, searchField, grid];
      const scaffold = createScaffoldWithAppBar("Shop", col);

      const bottomNav = createWidgetNode("NavigationBar");
      bottomNav.props.destinations = "Home,Cart,Orders,Profile";
      scaffold.slots!.bottomNavigationBar = bottomNav;

      const models: DataModel[] = [
        {
          id: generateId(),
          name: "Product",
          fields: [
            { name: "title", type: "String" },
            { name: "price", type: "double" },
            { name: "imageUrl", type: "String" },
            { name: "description", type: "String" },
          ],
        },
        {
          id: generateId(),
          name: "CartItem",
          fields: [
            { name: "product", type: "String" },
            { name: "quantity", type: "int" },
          ],
        },
      ];

      return { tree: scaffold, models, logic: [] };
    },
  },
  {
    keywords: ["todo", "task", "reminder", "productivity", "note"],
    name: "Todo App",
    description: "Task list, add task, mark complete",
    generate: () => {
      const col = createWidgetNode("Column");
      col.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };

      const title = createWidgetNode("Text");
      title.props.text = "My Tasks";
      title.props.fontSize = 28;
      title.props.fontWeight = "bold";

      const subtitle = createWidgetNode("Text");
      subtitle.props.text = "3 of 5 completed";
      subtitle.props.fontSize = 14;
      subtitle.props.color = "#4CAF50";

      // Input row
      const inputRow = createWidgetNode("Row");
      inputRow.props.mainAxisAlignment = "spaceBetween";
      const taskInput = createWidgetNode("TextField");
      taskInput.props.label = "New Task";
      taskInput.props.hintText = "Enter task...";
      const addBtn = createWidgetNode("ElevatedButton");
      addBtn.props.label = "Add";
      addBtn.props.backgroundColor = "#6750A4";
      inputRow.children = [taskInput, addBtn];

      // Task list
      const listView = createWidgetNode("ListView");
      listView.props.padding = { top: 8, right: 0, bottom: 8, left: 0 };

      const tasks = ["Buy groceries", "Finish project report", "Call dentist", "Workout session"];
      for (const task of tasks) {
        const card = createWidgetNode("Card");
        card.props.borderRadius = 8;
        card.props.elevation = 1;
        const cardRow = createWidgetNode("Row");
        cardRow.props.mainAxisAlignment = "spaceBetween";
        cardRow.props.padding = { top: 12, right: 12, bottom: 12, left: 12 };

        const taskText = createWidgetNode("Text");
        taskText.props.text = task;
        taskText.props.fontSize = 16;

        const delBtn = createWidgetNode("ElevatedButton");
        delBtn.props.label = "Done";
        delBtn.props.backgroundColor = "#4CAF50";

        cardRow.children = [taskText, delBtn];
        card.children = [cardRow];
        listView.children.push(card);
      }

      col.children = [title, subtitle, inputRow, listView];
      const scaffold = createScaffoldWithAppBar("Todo App", col);

      const models: DataModel[] = [
        {
          id: generateId(),
          name: "Task",
          fields: [
            { name: "title", type: "String" },
            { name: "completed", type: "bool" },
            { name: "createdAt", type: "DateTime" },
          ],
        },
      ];

      return { tree: scaffold, models, logic: [] };
    },
  },
  {
    keywords: ["social", "chat", "message", "messenger", "community"],
    name: "Social App",
    description: "Feed, profile, messages",
    generate: () => {
      const col = createWidgetNode("Column");
      col.props.padding = { top: 16, right: 16, bottom: 16, left: 16 };

      const title = createWidgetNode("Text");
      title.props.text = "Feed";
      title.props.fontSize = 28;
      title.props.fontWeight = "bold";

      const listView = createWidgetNode("ListView");
      listView.props.padding = { top: 8, right: 0, bottom: 8, left: 0 };

      const posts = [
        { user: "Alice", text: "Just finished my morning run!", time: "2h ago" },
        { user: "Bob", text: "Working on a new Flutter project.", time: "5h ago" },
        { user: "Carol", text: "Beautiful sunset today.", time: "1d ago" },
      ];

      for (const post of posts) {
        const card = createWidgetNode("Card");
        card.props.borderRadius = 12;
        card.props.elevation = 2;
        const cardCol = createWidgetNode("Column");
        cardCol.props.padding = { top: 12, right: 12, bottom: 12, left: 12 };

        const userRow = createWidgetNode("Row");
        userRow.props.mainAxisAlignment = "spaceBetween";
        const userName = createWidgetNode("Text");
        userName.props.text = post.user;
        userName.props.fontSize = 16;
        userName.props.fontWeight = "bold";
        const timeText = createWidgetNode("Text");
        timeText.props.text = post.time;
        timeText.props.fontSize = 12;
        timeText.props.color = "#999999";
        userRow.children = [userName, timeText];

        const postText = createWidgetNode("Text");
        postText.props.text = post.text;
        postText.props.fontSize = 14;

        const likeBtn = createWidgetNode("ElevatedButton");
        likeBtn.props.label = "Like";
        likeBtn.props.backgroundColor = "#6750A4";

        cardCol.children = [userRow, postText, likeBtn];
        card.children = [cardCol];
        listView.children.push(card);
      }

      col.children = [title, listView];
      const scaffold = createScaffoldWithAppBar("Social Feed", col);

      const bottomNav = createWidgetNode("NavigationBar");
      bottomNav.props.destinations = "Feed,Search,Messages,Profile";
      scaffold.slots!.bottomNavigationBar = bottomNav;

      const models: DataModel[] = [
        {
          id: generateId(),
          name: "Post",
          fields: [
            { name: "userName", type: "String" },
            { name: "content", type: "String" },
            { name: "timestamp", type: "DateTime" },
            { name: "likes", type: "int" },
          ],
        },
        {
          id: generateId(),
          name: "User",
          fields: [
            { name: "name", type: "String" },
            { name: "avatarUrl", type: "String" },
          ],
        },
      ];

      return { tree: scaffold, models, logic: [] };
    },
  },
  {
    keywords: ["login", "auth", "sign in", "register", "authentication"],
    name: "Login App",
    description: "Login screen with form",
    generate: () => {
      const col = createWidgetNode("Column");
      col.props.mainAxisAlignment = "center";
      col.props.crossAxisAlignment = "stretch";
      col.props.padding = { top: 32, right: 24, bottom: 32, left: 24 };

      const title = createWidgetNode("Text");
      title.props.text = "Welcome Back";
      title.props.fontSize = 32;
      title.props.fontWeight = "bold";
      title.props.textAlign = "center";

      const subtitle = createWidgetNode("Text");
      subtitle.props.text = "Sign in to continue";
      subtitle.props.fontSize = 16;
      subtitle.props.color = "#666666";
      subtitle.props.textAlign = "center";

      const emailField = createWidgetNode("TextField");
      emailField.props.label = "Email";
      emailField.props.hintText = "Enter your email";
      emailField.props.prefixIcon = "email";

      const passwordField = createWidgetNode("TextField");
      passwordField.props.label = "Password";
      passwordField.props.hintText = "Enter your password";
      passwordField.props.obscureText = true;
      passwordField.props.prefixIcon = "lock";

      const loginBtn = createWidgetNode("ElevatedButton");
      loginBtn.props.label = "Sign In";
      loginBtn.props.backgroundColor = "#6750A4";
      loginBtn.props.foregroundColor = "#FFFFFF";

      const signupText = createWidgetNode("Text");
      signupText.props.text = "Don't have an account? Sign Up";
      signupText.props.fontSize = 14;
      signupText.props.color = "#6750A4";
      signupText.props.textAlign = "center";

      col.children = [title, subtitle, emailField, passwordField, loginBtn, signupText];
      const scaffold = createScaffoldWithAppBar("Login", col);

      return { tree: scaffold, models: [], logic: [] };
    },
  },
  {
    keywords: ["weather", "forecast", "temperature", "climate"],
    name: "Weather App",
    description: "Weather dashboard with forecast",
    generate: () => {
      const col = createWidgetNode("Column");
      col.props.mainAxisAlignment = "center";
      col.props.crossAxisAlignment = "center";
      col.props.padding = { top: 32, right: 24, bottom: 32, left: 24 };

      const location = createWidgetNode("Text");
      location.props.text = "Berlin, DE";
      location.props.fontSize = 24;
      location.props.fontWeight = "bold";
      location.props.textAlign = "center";

      const temp = createWidgetNode("Text");
      temp.props.text = "18°C";
      temp.props.fontSize = 64;
      temp.props.fontWeight = "bold";
      temp.props.color = "#6750A4";
      temp.props.textAlign = "center";

      const condition = createWidgetNode("Text");
      condition.props.text = "Partly Cloudy";
      condition.props.fontSize = 18;
      condition.props.color = "#666666";
      condition.props.textAlign = "center";

      const forecastRow = createWidgetNode("Row");
      forecastRow.props.mainAxisAlignment = "spaceEvenly";
      const days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
      const temps = ["20°", "22°", "19°", "24°", "21°"];
      for (let i = 0; i < 5; i++) {
        const dayCol = createWidgetNode("Column");
        dayCol.props.mainAxisAlignment = "center";
        const dayText = createWidgetNode("Text");
        dayText.props.text = days[i];
        dayText.props.fontSize = 14;
        const icon = createWidgetNode("Icon");
        icon.props.iconName = "cloud";
        icon.props.size = 32;
        icon.props.color = "#6750A4";
        const tempText = createWidgetNode("Text");
        tempText.props.text = temps[i];
        tempText.props.fontSize = 14;
        tempText.props.fontWeight = "bold";
        dayCol.children = [dayText, icon, tempText];
        forecastRow.children.push(dayCol);
      }

      col.children = [location, temp, condition, forecastRow];
      const scaffold = createScaffoldWithAppBar("Weather", col);

      return { tree: scaffold, models: [], logic: [] };
    },
  },
];

export function generateFromPrompt(prompt: string): { tree: WidgetNode; models: DataModel[]; logic: LogicAction[] } | null {
  const lower = prompt.toLowerCase();
  for (const template of AI_TEMPLATES) {
    if (template.keywords.some(kw => lower.includes(kw))) {
      return template.generate();
    }
  }
  // Default: generic app
  const { widgetTree } = { widgetTree: createDefaultScaffold(prompt) };
  return { tree: widgetTree, models: [], logic: [] };
}

function createDefaultScaffold(prompt: string): WidgetNode {
  const col = createWidgetNode("Column");
  col.props.mainAxisAlignment = "center";
  col.props.crossAxisAlignment = "center";
  col.props.padding = { top: 32, right: 24, bottom: 32, left: 24 };

  const title = createWidgetNode("Text");
  title.props.text = prompt.slice(0, 40) || "My App";
  title.props.fontSize = 24;
  title.props.fontWeight = "bold";
  title.props.textAlign = "center";

  const btn = createWidgetNode("ElevatedButton");
  btn.props.label = "Get Started";
  btn.props.backgroundColor = "#6750A4";

  col.children = [title, btn];
  return createScaffoldWithAppBar("My App", col);
}

export { createScaffoldWithAppBar };
