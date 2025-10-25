# KPI-DRIVE Kanban Board

A professional Flutter Kanban board application inspired by Trello, built for KPI-DRIVE with their brand colors and style.

## Features

### 🎯 Core Functionality
- **Drag & Drop**: Intuitive task movement between columns
- **Real-time Updates**: Immediate visual feedback for task operations
- **Dual Mode**: Demo mode with sample data + API mode for real backend integration
- **Task Details**: Click on any task to view detailed information

### 🎨 Design Highlights
- **KPI-DRIVE Theme**: Dark theme with signature colors
  - Black (#1A1A1A) background
  - Green (#00FF00) accents  
  - Yellow (#FFFF00) for in-progress items
  - Blue (#0066FF) for new tasks
  - Orange (#FF9900) for review items
  - Red (#FF0000) for errors/urgent items

- **Modern UI Elements**:
  - Gradient backgrounds and shadows
  - Animated drag indicators
  - Professional card layouts
  - Contextual icons for each column
  - Responsive hover effects

### 📱 User Experience
- **Minimal Clicks**: Primary actions accessible via drag & drop
- **Visual Feedback**: Color-coded columns and progress indicators
- **Error Handling**: Graceful fallbacks and user-friendly messages
- **Accessibility**: Clear labels and intuitive navigation

## Technical Implementation

### Backend Integration
- **API Endpoint**: `https://api.dev.kpi-drive.ru/_api/indicators/get_mo_indicators`
- **Authentication**: Bearer token system
- **Data Sync**: Automatic save via `save_indicator_instance_field` endpoint

### Architecture
- **State Management**: Flutter's built-in setState for simplicity
- **API Service**: HTTP package for backend communication
- **Error Handling**: Comprehensive error states and recovery options

## Demo Mode Features

The application includes a rich demo mode with:
- 4 predefined columns (Новые задачи, В работе, На проверке, Выполнено)
- 13 sample tasks with realistic business scenarios
- Full drag & drop functionality
- Simulated API delays for realistic UX

## Usage

1. **Switch Modes**: Use the toggle button in the app bar
2. **Move Tasks**: Long press and drag tasks between columns
3. **View Details**: Tap any task card to see full information
4. **Refresh Data**: Use the refresh button to reload

## Project Structure

```
lib/
  main.dart           # Complete application code
  models/            # Data models (Task, KanbanColumn)
  service/           # API service layer
  views/             # UI components and screens
```

## Build & Run

```bash
flutter pub get
flutter run
```

Choose Chrome (web) for development or Linux (desktop) for native app.

---

**Note**: This is a demonstration project showcasing modern Flutter development practices and professional UI/UX design for Kanban-style task management.
